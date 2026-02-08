# Homelab Backup

This repository contains the configuration for my homelab running on Raspberry Pi 5.

## Services

| Service | URL | Purpose |
|---------|-----|---------|
| Jellyfin | http://jellyfin.homelab | Media server |
| Sonarr | http://sonarr.homelab | TV show management |
| Radarr | http://radarr.homelab | Movie management |
| Prowlarr | http://prowlarr.homelab | Indexer management |
| Jellyseerr | http://jellyseerr.homelab | Request management |
| n8n | http://n8n.homelab | Workflow automation |
| qBittorrent | http://qbittorrent.homelab:8080 | Torrent client |
| FlareSolverr | http://flaresolverr.homelab | Cloudflare bypass |
| Nginx Proxy Manager | http://172.16.16.21:81 | Reverse proxy |

## Network Setup

- **Host IP:** 172.16.16.21
- **Domain:** *.homelab
- **DNS:** Configured on Keenetic Giga router

### Router DNS Configuration (Keenetic CLI)

```bash
ip host jellyfin.local 172.16.16.21
ip host sonarr.local 172.16.16.21
ip host radarr.local 172.16.16.21
ip host prowlarr.local 172.16.16.21
ip host jellyseerr.local 172.16.16.21
ip host n8n.local 172.16.16.21
ip host qbittorrent.local 172.16.16.21
ip host flaresolverr.local 172.16.16.21
system configuration save
```

## Environment Variables

- `PUID=1000`
- `PGID=1000`
- `TZ=Europe/Istanbul`

## Restore Instructions

1. Clone this repo to `/srv/homelab`
2. Create `/srv/homelab/config/` directories
3. Run `docker compose up -d`
4. Configure router DNS entries
5. Access Nginx Proxy Manager at `http://172.16.16.21:81`
6. Recreate proxy hosts for each service

## Notes

- qBittorrent uses `network_mode: host` for WireGuard VPN routing
- Nginx Proxy Manager proxies to Docker container names (not IPs)
- All configs stored in `/srv/homelab/config/`
