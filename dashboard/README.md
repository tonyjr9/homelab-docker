# Dashboard Stack

Back to [Main README](../README.md)

Homepage is the service launcher, with Glances and Beszel for system monitoring.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| **Homepage** | 3000 | App dashboard — links, widgets, Docker integration |
| **Glances** | host network | CPU, RAM, storage, and network metrics |
| **Beszel** + **Beszel Agent** | 8090 / 45876 | Extended monitoring |

## Quick Start

```bash
cp .env.example .env
cd dashboard && docker compose up -d
```

- Homepage: `http://${MAIN_IP}:3000`
- Beszel: `http://${MAIN_IP}:8090`

## Environment (`.env.example`)

```
HOMARR_SECRET_KEY=your_secret_key
CONFIG_PATH=/opt/docker
MAIN_IP=192.168.20.102
```

## Volumes

| Path | Purpose |
|------|---------|
| `./homepage` | Homepage config/widgets |
| `./icons`, `./imgs/backgrounds` | Custom icons and backgrounds (gitignored) |
| `./data` | Dashboard runtime data (gitignored) |
| `./beszel_agent_data` | Beszel agent state (gitignored) |

## Glances Configuration

Glances runs with host networking and reads Docker metrics through the read-only Docker socket.

## Beszel (optional)

Beszel and its agent are active in `docker-compose.yml`; set their keys in `.env` before exposing the dashboard.

## Maintenance

```bash
docker compose logs homepage -f
docker compose logs beszel -f
docker compose pull && docker compose up -d
```

## Troubleshooting

- **Homarr blank/error**: check `SECRET_ENCRYPTION_KEY` is set and `./configs` has correct permissions (`chown -R 1000:1000 configs`).
- **Glances unavailable**: check that host networking and the Docker socket are available.
- **Beszel agent can't connect**: verify `HUB_URL` points to the Beszel container and that the `KEY` matches.

---
Updated October 2026.
