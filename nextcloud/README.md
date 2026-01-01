# Nextcloud Stack

Cloud sync/share + MariaDB/Redis.

## Quick Start

```bash
cp .env.example .env  # MYSQL_*, NEXTCLOUD_ADMIN_*
cd nextcloud
docker compose up -d
```

First: https://nextcloud.proxy (occ run).

## Env

MYSQL_ROOT_PASSWORD, NEXTCLOUD_ADMIN_USER/PASSWORD.

Volumes: ./db:/var/lib/mysql (ignored).

## Backup

```bash
docker exec db_container mysqldump nextcloud > backup.sql
```

Troubleshoot: occ maintenance:repair.