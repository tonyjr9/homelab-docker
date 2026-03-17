# Dashboard Stack

Back to [Main README](../README.md)

Homarr as the main service launcher dashboard, and Dashdot for real-time system metrics.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| **Homarr** | 7575 | App dashboard — links, widgets, Docker integration |
| **Dashdot** | 3001 (bound to 192.168.0.102) | CPU, RAM, storage, network metrics |
| **Beszel** + **Beszel Agent** | 8090 | Extended monitoring (commented out — enable when needed) |

## Quick Start

```bash
cp .env.example .env
cd dashboard && docker compose up -d
```

- Homarr: `http://192.168.0.102:7575`
- Dashdot: `http://192.168.0.102:3001`

## Environment (`.env.example`)

```
HOMARR_SECRET_KEY=your_secret_key
CONFIG_PATH=/opt/docker
```

## Volumes

| Path | Purpose |
|------|---------|
| `./configs` | Homarr config/widgets (tracked layout) |
| `./icons`, `./imgs/backgrounds` | Custom icons and backgrounds (gitignored) |
| `./data` | Homarr internal data (gitignored) |
| `./beszel_agent_data` | Beszel agent state (gitignored) |

## Dashdot Configuration

Key environment variables (see `docker-compose.yml` for the full list):

- `DASHDOT_NETWORK_INTERFACE` — set to your actual interface (e.g. `eno1`).
- `DASHDOT_ENABLE_CPU_TEMPS` — requires lm-sensors or psutil.
- `DASHDOT_WIDGET_LIST` — customize widget order: `os,cpu,storage,ram,network`.

## Beszel (optional)

Beszel and the Beszel Agent are commented out in `docker-compose.yml`. Uncomment both services to enable extended monitoring with a persistent metrics database.

## Maintenance

```bash
docker compose logs homarr -f
docker compose logs dash -f
docker compose pull && docker compose up -d
```

## Troubleshooting

- **Homarr blank/error**: check `SECRET_ENCRYPTION_KEY` is set and `./configs` has correct permissions (`chown -R 1000:1000 configs`).
- **Dashdot no CPU temps**: install `lm-sensors` on the host or switch `DASHDOT_CPU_TEMPS_MODE` to `psutil`.
- **Beszel agent can't connect**: verify `HUB_URL` points to the Beszel container and that the `KEY` matches.

---
Updated March 2026.
