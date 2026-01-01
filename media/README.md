# Media Services

Transmission + Plex/Overseerr prep.

## Quick Start

```bash
cd media
docker compose up -d
```

Transmission: http://host:9091

## Setup

- watch/: Auto-import.
- transmission/downloads (ignored).
- overseerr/plex configs (ignored).

Webhook: For arr/Plex integration (progress).

Volumes: ./transmission:/config (ignored).

Maintenance: docker compose logs transmission