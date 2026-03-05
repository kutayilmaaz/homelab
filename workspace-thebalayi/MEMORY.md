# MEMORY.md - Thebalayi Project Memory

## Client Overview

**Thebalayi Travel Agency**
- **Website:** thebalayi.com
- **Location:** Cappadocia, Turkey
- **Status:** Active project

---

## Thebalayi QR / My Tour System — Deep Project Knowledge

### Project Summary
A comprehensive **Next.js + Supabase** application serving two distinct user groups:
1. **Admin/Staff Panel** — Internal booking management and tour creation
2. **Customer "My Tour" PWA** — Mobile-first itinerary viewer for travelers

**GitHub Repo:** `kutayilmaaz/thebalayi`  
**Tech Lead:** Crawl (solo developer)

---

### Architecture Overview

| Layer | Technology |
|-------|------------|
| **Framework** | Next.js 16.1.6 (App Router, React 19) |
| **Language** | TypeScript 5 |
| **Styling** | Tailwind CSS v4 |
| **Database** | Supabase (PostgreSQL) |
| **Auth** | Supabase Auth (JWT-based) |
| **PDF** | @react-pdf/renderer |
| **QR Codes** | qrcode (server) + react-qr-code (client) |
| **Validation** | Zod v4 |
| **Testing** | Playwright (E2E) |
| **PWA** | next-pwa |

---

### Database Schema (Core Tables)

**Primary Tables:**
- `tours` — Main booking records with access tokens
- `itinerary_items` — Daily schedule/activities
- `tour_assets` — Media gallery
- `hotels` — Hotel inventory
- `rooms` — Room types per hotel
- `providers` — Activity/tour providers
- `activities` — Bookable activities
- `restaurants` — Partner restaurants
- `default_activities` — Standard inclusions (breakfast, discounts, etc.)
- `profiles` — RBAC user roles (admin/employee)
- `settings` — System configuration

**Key Tour Fields:**
- Customer: `customer_name`, `customer_phone`, `customer_tc` (11-digit Turkish ID)
- Dates: `start_date`, `end_date`, `check_in_time`, `check_out_time`
- Accommodation: `hotel_id`, `room_id`, `room_number`, `pax_details` (JSONB)
- Financial: `total_price`, `advance_payment`, `hotel_payment_amount`
- Access: `access_token` (UUID for customer link), `whatsapp_number`
- Meta: `status` (pending/confirmed/completed/cancelled), `created_by`

---

### Admin Panel Features

**Tour Creation Wizard (4 Steps):**
1. **Müşteri Bilgileri** — Name, phone, TC, dates, WhatsApp
2. **Konaklama** — Hotel/room selection, pax details, pricing
3. **Program** — Itinerary builder with presets (transfers, activities, meals)
4. **Özet** — Review and create

**Management Pages:**
- `/admin/tours` — List all tours
- `/admin/hotels` — Hotel CRUD with rooms
- `/admin/providers` — Provider management
- `/admin/activities` — Activity catalog
- `/admin/restaurants` — Restaurant partners
- `/admin/performance` — Dashboard metrics

**Key Admin Features:**
- **Password Gate** — Simple session-based auth (token in sessionStorage)
- **Auto-save Draft** — localStorage persistence with version checking
- **PDF Generation** — Hotel voucher + Agency internal document
- **QR Code** — Generated on tour creation for customer sharing

**RBAC Roles:**
- `admin` — Full access to all tours and settings
- `employee` — Can only view/manage their own created tours

---

### Customer "My Tour" PWA

**Access Pattern:**
- Tokenized URLs: `/tour/{access_token}`
- No login required — link is the credential
- Mobile-first responsive design

**Page Sections:**
1. **TourHero** — Customer name, title, dates, destination
2. **ItineraryTimeline** — Day-by-day schedule with icons
3. **PaymentSummaryCard** — Price breakdown (if set)
4. **PackageInclusions** — Default activities (breakfast, discounts, etc.)
5. **DiscountedPlacesCard** — Partner restaurant discounts
6. **WhatsAppSupportFAB** — Direct chat button

**Tech Details:**
- Static generation with `revalidate: 0` (always fresh)
- PWA manifest with icons (72x72 to 512x512)
- OG metadata for link previews

---

### API Routes Structure

```
/api/tours              GET/POST    List/create tours
/api/tours/[id]         GET/PUT/DELETE  Single tour operations
/api/tours/[id]/itinerary   POST/PUT    Update itinerary
/api/tours/[id]/hotel-pdf   GET     Generate hotel voucher PDF
/api/tours/[id]/agency-pdf  GET     Generate agency PDF
/api/qr                 POST        Generate QR data URL
/api/hotels             GET/POST    Hotel management
/api/rooms              GET/POST    Room management
/api/providers          GET/POST    Provider management
/api/activities         GET/POST    Activity catalog
/api/restaurants        GET/POST    Restaurant management
/api/default-activities GET         Get package inclusions
```

**Auth Pattern:**
- All admin routes check `Authorization: Bearer {token}` header
- Uses `verifyAdmin()` helper that validates JWT via Supabase

---

### PDF System

**Hotel Voucher Includes:**
- Customer details (name, TC, phone)
- Hotel info (name, location, contact)
- Room details (type, number, capacity)
- Dates (check-in/out, nights count)
- Pax breakdown (adults/children/infants with ages)
- Itinerary items
- Payment info (agency → hotel amount)
- Footer with TÜRSAB number

**Agency PDF Includes:**
- Same as hotel voucher PLUS:
- Total price charged to customer
- Advance payment received
- Remaining balance calculation

**PDF Tech:**
- React PDF components with custom styles
- A4 page format
- Turkish locale formatting

---

### WhatsApp AI Agent (Future — Phase 2/3)

**Documented in:** `docs/product-requirements.md`, `docs/ai-design.md`

**Planned Features:**
- **Intent Recognition** — Google Gemini 1.5 Pro via LangChain
- **Supported Intents:** Price inquiry, availability, booking, support
- **Multi-language:** DE, EN, ES, TR
- **Human-in-the-Loop** — AI drafts responses, admin approves before sending
- **WhatsApp Catalog** — Sync tours to Meta Commerce Manager
- **Supplier Communication** — Auto-DM suppliers for availability
- **Rich Messages** — Interactive buttons, media (pool room photos)

**Customer Intent Analysis (from chat data):**
1. Price inquiry (most common)
2. Room type availability (pool/jacuzzi)
3. Campaign details
4. Booking procedures/payment
5. Location questions
6. Activity inquiries (balloon, ATV)
7. Honeymoon packages
8. Child policies

**Agent Persona: "Atakan"**
- Professional yet warm
- Uses "Bey/Hanım" (formal) initially, "Abi/Abla" after rapport
- Structured bullet lists with emojis
- Visual-first (always mentions photos)
- Proactive with alternatives if room full

---

### Marketing Automation Engine (Future — Phase 3)

**Documented in:** `docs/marketing-automation-requirements.md`

**Core Modules:**
1. **Marketing Intelligence** — Correlate Meta Ads data with actual bookings
2. **Ad Creative Builder** — Auto-generate Reels/Stories from raw assets (Remotion/FFmpeg)
3. **Ad Manager** — Budget allocation based on ROAS, inventory-aware pausing

**Key Features:**
- Trend spotting ("Sunset ATV demand up 40%")
- WhatsApp Start Links with UTM tracking (`wa.me/...?text=balloon-ad-01`)
- Auto-pause ads when hotel fully booked

---

### Current State Assessment

**✅ COMPLETE & WORKING:**
- Next.js + Supabase foundation
- Admin panel with tour creation wizard
- Hotel/room/provider/activity/restaurant management
- PDF voucher generation
- QR code generation
- Customer "My Tour" PWA page
- RBAC (admin/employee roles)
- Database migrations and RLS policies

**🔄 IN PROGRESS / NEEDS ATTENTION:**
- Environment variables setup (needs NEXT_PUBLIC_APP_URL, Supabase keys)
- Deployment (likely local dev only currently)
- Error monitoring/logging
- Backup strategy testing

**⏳ NOT STARTED (Roadmap):**
- WhatsApp Cloud API integration
- Meta Commerce API sync
- AI Agent (Gemini/LangChain)
- Marketing automation engine
- Payment gateway (Iyzico/PayTR)
- Google Reviews automation
- Docker deployment setup

---

### Technical Debt & Notes

**Known Issues:**
- Turbopack config excludes canvas for react-pdf
- Bulk itinerary updates use Promise.all (not optimal but fine for small lists)
- PDF generation uses blob URLs (need cleanup to prevent memory leaks)

**Environment Variables Needed:**
```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
NEXT_PUBLIC_APP_URL=http://localhost:3000
```

**File Locations:**
- Main app: `/thebalayi_qr/`
- Docs: `/docs/`
- DB schema: `/thebalayi_qr/supabase/schema.sql`
- Migrations: `/thebalayi_qr/supabase/migrations/`

---

### Related Projects

**Taleway** (cappadociawondertour.com) — Similar scope, may share systems  
**Rota Rent a Car** — SEO/content work (separate skill set)

---

### Decisions Log

| Date | Decision | Notes |
|------|----------|-------|
| 2026-02-11 | Added TC kimlik validation | 11 digits, no leading zero |
| 2026-02-11 | Default activities system | Breakfast, maps, discounts |
| 2026-02-24 | Hotel management module | Hotels, rooms, pax JSONB |
| 2026-03-01 | RBAC implementation | Admin vs employee roles |

---

### Open Questions / Next Steps

1. **Deployment:** Local dev → VPS? Vercel? Docker?
2. **WhatsApp API:** Meta Business verification status?
3. **AI Agent:** Start with rule-based or go straight to Gemini?
4. **Marketing Engine:** Separate service or same Next.js app?
5. **Payment:** Iyzico or PayTR integration timeline?
