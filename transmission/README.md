# Transmission

Lightweight BitTorrent client configured for integration with the media stack. Optionally route traffic via a VPN container (e.g., Gluetun) for privacy.

## Access
- Web UI: http://server-ip:9091

## Volumes
- `./config:/config`
- `/mnt/media/media/transmission/downloads:/downloads`
- `/mnt/media/media/transmission/watch:/watch`

## Notes
- Use *arr services (Radarr/Sonarr) to manage downloads
- Ensure proper permissions (PUID/PGID) for file access
- Consider VPN routing for privacy
