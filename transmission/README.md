# Transmission

Lightweight BitTorrent client configured for integration with the media stack.

## Access
- Web UI: http://server-ip:9091

## Ports
- 9091 (UI)
- 51413 TCP/UDP (peer)

## Volumes
- `/opt/docker/transmission/config:/config`
- `/mnt/media/media/transmission/downloads:/downloads`
- `/mnt/media/media/transmission/watch:/watch`

## Notes
- Integrates with *arr services (if used)
- Ensure correct PUID/PGID for file permissions
- Consider VPN routing (e.g., Gluetun) for privacy
