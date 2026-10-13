# Cloud Storage Stack

Back to [Main README](../README.md)

Self-hosted cloud storage using Seafile, backed by MariaDB and Memcached.

## Services

| Service | Purpose |
|---------|--------|
| **Seafile** | File sync and share (web UI + desktop/mobile clients) |
| **seafile-db** (MariaDB) | Database backend |
| **seafile-memcached** | Cache layer |

## Quick Start

```bash
cp .env.example .env   # fill in DB credentials, admin email/password, hostname, JWT key
cd cloud && docker compose up -d
```

Access Seafile at the hostname configured in `SEAFILE_SERVER_HOSTNAME` (proxy via NPM recommended).

## Environment (`.env.example`)

See `cloud/.env.example` for all required variables:

```
SEAFILE_MYSQL_DB_USER=seafile
INIT_SEAFILE_MYSQL_ROOT_PASSWORD=strongpassword
SEAFILE_MYSQL_DB_PASSWORD=dbpassword
INIT_SEAFILE_ADMIN_EMAIL=admin@example.com
INIT_SEAFILE_ADMIN_PASSWORD=adminpassword
SEAFILE_SERVER_HOSTNAME=seafile.yourdomain.com
JWT_PRIVATE_KEY=a-long-random-string
```

## Storage

All data lives on the HDD:

```
/mnt/media/cloud/seafile/
├── data/     # Seafile libraries (user files)
└── db/       # MariaDB data files
```

## Reverse Proxy (NPM)

Seafile must be proxied correctly. In NPM, set:
- Forward to `seafile:80`
- Set `SEAFILE_SERVER_LETSENCRYPT: false` and `FORCE_HTTPS_IN_CONF: false` (TLS handled by NPM)
- Ensure `proxy_network` is shared between NPM and Seafile containers

## Backup

```bash
# Database
docker exec seafile-db mysqldump -u root -p --all-databases > seafile-db-backup.sql

# Data
rsync -av /mnt/media/cloud/seafile/data/ /mnt/external/seafile-backup/
```

## Maintenance

```bash
docker compose pull && docker compose up -d
docker compose logs seafile -f
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Seafile shows wrong URL | Check `SEAFILE_SERVER_HOSTNAME` matches your domain |
| 500 error on login | Check `seafile-db` is healthy: `docker compose logs seafile-db` |
| Files not syncing | Restart memcached: `docker compose restart seafile-memcached` |

---
Updated March 2026.
