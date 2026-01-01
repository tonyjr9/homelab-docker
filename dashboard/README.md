# Dashboard (Homarr + Beszel)

Homarr: App dashboard. Beszel: Metrics overlay.

## Quick Start

```bash
cp .env.example .env
cd dashboard
docker compose up -d
```

Homarr: http://host:7575

## Config

- configs/: Homarr JSON/widgets.
- icons/imgs/: Custom images (ignored).
- beszel_data/: Metrics DB (ignored).

## Customization

Edit Homarr config.json: Add services (e.g., NPM proxy URL, Pi-hole stats).
Beszel: Prometheus/Grafana integration.

## Volumes

./configs:/app/data (Homarr)
./beszel_data:/data (ignored)

## Maintenance

```
docker compose logs homarr -f
```

Troubleshoot: Port 7575 open, config perms 1000:1000.