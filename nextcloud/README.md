# Nextcloud Stack

Self-hosted cloud storage with a dedicated database and Redis cache.

## Services
- **nextcloud-database** (MariaDB 11.3)
  - Data: `/mnt/media/nextcloud/db:/var/lib/mysql`
  - Credentials via `nextcloud.env`
- **nextcloud-redis** (Redis 7.2)
  - Use a password from `nextcloud.env` (avoid hardcoding)
- **nextcloud** (linuxserver/nextcloud)
  - Port: 8080 → 80
  - Config: `/mnt/media/nextcloud/config:/config`
  - Data: `/mnt/media/nextcloud/data:/data`
  - Env: `PUID=1000`, `PGID=1000`, `MYSQL_HOST=nextcloud-database`, `REDIS_HOST_PASSWORD=${REDIS_HOST_PASSWORD}`
  - `env_file: nextcloud.env`

## Example nextcloud.env
```
# MariaDB
MYSQL_DATABASE=nextcloud
MYSQL_USER=nextcloud
MYSQL_PASSWORD=change_me
MYSQL_ROOT_PASSWORD=change_me_root

# Redis
REDIS_HOST=nextcloud-redis
REDIS_HOST_PASSWORD=change_me_redis

# Optional
PUID=1000
PGID=1000
TZ=Europe/Lisbon
```

## Reverse Proxy
- Put Nextcloud behind NPM
- Set `trusted_proxies` and `overwriteprotocol` in Nextcloud config

## Backups
- Backup `config/`, `data/`, and MariaDB dumps under `/mnt/media/nextcloud/db`

## Notes
- Move any hardcoded secrets from `docker-compose.yml` into `nextcloud.env`
- All services attach to `proxy_network` and use `depends_on` for ordering