# Minecraft Server

Java Edition.

## Quick Start

```bash
cp .env.example .env  # EULA=true
cd minecraft
docker compose up -d
```

Connect: host:25565

## World

./world/ (ignored): Persistent.
Backup: manage.sh or tar.

Perf: MEMORY=2G env.

Stop: /save-all
