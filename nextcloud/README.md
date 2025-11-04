# Nextcloud

Self-hosted cloud storage and collaboration platform.

## Access
- Web UI: http://server-ip:8080 (example; see compose for mapped port)

## Volumes
- `./app:/var/www/html`
- `./apps:/var/www/html/custom_apps`
- `./config:/var/www/html/config`
- `./data:/var/www/html/data`

## Notes
- Consider separate database service (e.g., MariaDB/PostgreSQL)
- Configure trusted proxies when using Nginx Proxy Manager
- Ensure backups of `config/` and `data/`
