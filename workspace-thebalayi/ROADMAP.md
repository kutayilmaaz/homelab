# Thebalayi QR — Project Roadmap & Architecture Decision Record

**Created:** 2026-03-02  
**Context:** Post-code-review planning session — transitioning from single-customer MVP to SaaS platform

---

## Executive Summary

Thebalayi QR is currently a **functioning MVP** serving one travel agency (Thebalayi) with a Next.js + Supabase stack. The codebase has **critical security issues** that must be addressed before production, and **architectural debt** that will block multi-tenancy if not fixed now.

**Decision:** Fix security issues immediately, then implement multi-tenancy foundation before adding new features.

---

## Current State (As of 2026-03-02)

### ✅ What's Working
- Next.js 16 + React 19 + TypeScript + Tailwind v4
- Admin panel with 4-step tour creation wizard
- Hotel/room/provider/activity/restaurant management
- PDF voucher generation (Hotel + Agency versions)
- QR code generation for customer links
- Customer "My Tour" PWA (tokenized access)
- RBAC database structure (admin/employee roles)
- Supabase migrations and RLS policies (written but bypassed)

### ❌ Critical Issues (Fix Before Production)

#### 1. Service Role Key Bypasses All Security
**Location:** `lib/supabase/client.ts` → `createServerClient()`

```typescript
// CURRENT (BROKEN):
export const createServerClient = () => {
    const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY!;
    return createClient(supabaseUrl, serviceRoleKey); // Bypasses RLS
};
```

**Risk:** If service role key leaks, attacker has full database access.

**Fix:** Use user JWT for queries, service role only for migrations/background jobs.

#### 2. Auth Doesn't Check Roles
**Location:** `lib/auth.ts` → `verifyAdmin()`

```typescript
// CURRENT (BROKEN):
export async function verifyAdmin(request: NextRequest): Promise<boolean> {
    const { data: { user } } = await supabase.auth.getUser(token);
    return !!user; // ← Any logged-in user passes
}
```

**Risk:** Employees can access admin-only endpoints.

**Fix:** Query profiles table and check `role === 'admin'`.

#### 3. No UUID Validation on Route Parameters
**Location:** All `/api/*/[id]/route.ts` files

**Risk:** Invalid IDs hit database, potential SQL errors.

**Fix:** Add Zod validation: `z.object({ id: z.string().uuid() })`

#### 4. PDF Memory Leak
**Location:** `components/admin/TourForm.tsx`

`URL.createObjectURL()` is never revoked.

**Fix:** Call `URL.revokeObjectURL(url)` after download.

#### 5. No Rate Limiting
**Risk:** API spam, brute force on tokens.

**Fix:** Add rate limiting middleware.

---

## Architectural Problems

### 1. Monolithic Structure Won't Scale
Current plan: One app handles admin, customer PWA, future WhatsApp webhooks, future marketing engine.

**Problem:** WhatsApp webhooks need queue system, retries, background jobs. Marketing engine needs heavy media processing. These don't belong in Next.js.

**Solution:** Start separating now:
```
/thebalayi-platform/
├── apps/
│   ├── admin/              # Next.js — Admin + Customer PWA
│   ├── whatsapp-agent/     # Node.js — Webhook handler + AI
│   └── marketing-engine/   # Node.js/Python — Ad automation
├── packages/
│   ├── shared-types/       # TypeScript types
│   ├── shared-ui/          # Component library
│   └── sdk/                # API client
└── infra/
    ├── docker-compose.yml
    └── terraform/
```

### 2. No Event/Queue System
Current flow is synchronous:
```
Create Tour → Generate PDF → (future) Send WhatsApp
```

If any step fails, the whole request fails.

**Solution:** Introduce event bus (Bull + Redis, or Inngest):
```
Create Tour → Emit "tour.created" → PDF Worker → WhatsApp Worker
```

### 3. Database Anti-Patterns

| Problem | Current | Better |
|---------|---------|--------|
| Pax details | JSONB array | Normalized table |
| Deletions | Hard delete | Soft delete + audit log |
| Transactions | Two separate inserts | Database transaction |

### 4. State Management Over-Engineered
`useTourFormState` hook with localStorage versioning is complex for a 4-step form.

**Solution:** Use React Hook Form + Zod resolver. Simpler, standard.

---

## Future Vision: SaaS Platform

### Business Model
- **Target:** Multiple travel agencies
- **Pricing:** Per-agency subscription (starter/pro/enterprise)
- **Features:** White-labeling, custom domains, per-agency WhatsApp numbers

### Technical Requirements for SaaS

#### 1. Multi-Tenancy Foundation
Add `agency_id` to **every table** now:

```sql
ALTER TABLE tours ADD COLUMN agency_id UUID REFERENCES agencies(id);
ALTER TABLE hotels ADD COLUMN agency_id UUID REFERENCES agencies(id);
-- etc.
```

Create agencies table:
```sql
CREATE TABLE agencies (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  subdomain TEXT UNIQUE,
  custom_domain TEXT,
  logo_url TEXT,
  primary_color TEXT,
  tursab_number TEXT,
  iban TEXT,
  whatsapp_business_number TEXT,
  meta_business_id TEXT,
  plan TEXT DEFAULT 'starter',
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

Update RLS policies:
```sql
CREATE POLICY "Users can only see their agency's data" ON tours
FOR ALL USING (agency_id = current_setting('app.current_agency_id')::UUID);
```

#### 2. User-Agency Relationship
A user can belong to multiple agencies:

```sql
CREATE TABLE agency_members (
  user_id UUID REFERENCES auth.users(id),
  agency_id UUID REFERENCES agencies(id),
  role TEXT CHECK (role IN ('owner', 'admin', 'employee')),
  PRIMARY KEY (user_id, agency_id)
);
```

#### 3. Theming System
Replace hardcoded Thebalayi branding:

```typescript
// lib/theme.ts
export function getAgencyTheme(agencyId: string) {
  return {
    colors: {
      primary: agency.primary_color || '#D2691E',
      secondary: agency.secondary_color || '#8FBC8F',
    },
    logo: agency.logo_url,
    companyName: agency.name,
    tursabNumber: agency.tursab_number,
  };
}
```

Update Tailwind to use CSS variables:
```css
:root {
  --color-primary: #D2691E;
}
.text-brand { color: var(--color-primary); }
```

#### 4. WhatsApp Multi-Tenancy
Each agency has their own WhatsApp Business Account:

```typescript
interface AgencyWhatsAppConfig {
  agency_id: string;
  phone_number_id: string;
  waba_id: string;
  access_token: string; // Encrypted
  webhook_verify_token: string;
}
```

Webhook endpoint routes by agency:
```typescript
// /api/whatsapp/webhook
export async function POST(request: Request) {
  const agency = await identifyAgencyFromWebhook(request);
  // Route to correct handler
}
```

#### 5. Configuration Per Agency
Move hardcoded values to database:

```typescript
// Instead of:
const DEFAULT_CHECK_IN = '14:00';

// Use:
const checkInTime = await getAgencySetting(agencyId, 'check_in_time', '14:00');
```

Settings table:
```sql
CREATE TABLE agency_settings (
  agency_id UUID REFERENCES agencies(id),
  key TEXT,
  value JSONB,
  PRIMARY KEY (agency_id, key)
);
```

---

## Roadmap

### Phase 1: Security Fix (Week 1)
**Goal:** Make production-safe

- [ ] Fix `verifyAdmin()` to check profile role
- [ ] Add UUID validation to all `[id]` route parameters
- [ ] Add `URL.revokeObjectURL()` after PDF downloads
- [ ] Add rate limiting middleware
- [ ] Create auth middleware HOF (stop repeating verifyAdmin)

### Phase 2: SaaS Foundation (Week 2-3)
**Goal:** Enable multi-tenancy

- [ ] Create `agencies` table
- [ ] Create `agency_members` table
- [ ] Add `agency_id` to all existing tables
- [ ] Write migration for existing Thebalayi data
- [ ] Update RLS policies for agency isolation
- [ ] Extract Thebalayi branding to config
- [ ] Implement theming system with CSS variables

### Phase 3: Thebalayi Feature Complete (Month 2-3)
**Goal:** Finish all features for first customer

- [ ] Complete admin panel (all CRUD working)
- [ ] Polish "My Tour" PWA
- [ ] Add error monitoring (Sentry)
- [ ] Add request logging
- [ ] Write API documentation (OpenAPI)
- [ ] Docker deployment setup

### Phase 4: WhatsApp Integration (Month 3-4)
**Goal:** AI agent for customer communication

- [ ] Set up separate `/apps/whatsapp-agent` service
- [ ] Meta Business verification
- [ ] WhatsApp Cloud API integration
- [ ] LangChain + Gemini setup
- [ ] Human-in-the-loop approval flow
- [ ] Webhook handling with queue

### Phase 5: Beta Agency #2 (Month 4)
**Goal:** Validate multi-tenancy

- [ ] Onboard second agency
- [ ] Test agency isolation
- [ ] Fix multi-tenancy bugs
- [ ] Gather feedback

### Phase 6: SaaS Launch Prep (Month 5-6)
**Goal:** Ready for public

- [ ] Stripe integration
- [ ] Super admin dashboard
- [ ] Self-service onboarding flow
- [ ] White-labeling (custom domains)
- [ ] Marketing website
- [ ] Documentation

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-03-02 | Fix security before features | Service role bypass is critical risk |
| 2026-03-02 | Build SaaS foundation now | Retrofitting multi-tenancy later = nightmare |
| 2026-03-02 | Shared infrastructure (Option A) | Cheaper, easier to maintain than separate instances |
| 2026-03-02 | Separate WhatsApp agent service | Webhooks need queue/retry logic, doesn't belong in Next.js |
| 2026-03-02 | Use CSS variables for theming | Runtime theme switching without rebuild |

---

## Key Files Reference

| File | Purpose | Status |
|------|---------|--------|
| `lib/supabase/client.ts` | Database client | ❌ Needs fix (service role) |
| `lib/auth.ts` | Auth verification | ❌ Needs fix (role check) |
| `hooks/useTourFormState.ts` | Form state | 🟡 Over-engineered |
| `components/admin/TourForm.tsx` | Tour creation | 🟡 PDF memory leak |
| `lib/services/*` | Service layer | ❌ All use service role |
| `app/api/*/route.ts` | API routes | 🟡 Need rate limiting |
| `supabase/migrations/` | Database | ✅ Good structure |

---

## Next Steps

1. **Crawl to decide:** Start with security fixes or SaaS foundation?
2. **Priority:** Critical security fixes must happen before production deployment
3. **Timeline:** SaaS foundation should be done before WhatsApp integration starts

---

## Notes for Future Reference

- **AI Agent Persona:** "Atakan" — professional yet warm, uses structured lists
- **Customer Intents (from chat analysis):** Price inquiry > Room availability > Campaigns > Booking procedures > Location > Activities > Honeymoon > Child policies
- **Tech Stack Verified:** Next.js + Supabase + Tailwind + React PDF + QR codes — solid choices
- **Cost Estimate (per agency):** ~$15-30/month (hosting + database + AI)

---

*This document should be updated as decisions change and milestones are reached.*
