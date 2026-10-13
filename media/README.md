# Media Stack

Back to [Main README](../README.md)

Full *arr + Plex/Jellyfin media stack with Transmission for downloads.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| **Plex** | host network | Media server (primary) |
| **Jellyfin** | 8096 | Media server (alternative) |
| **Transmission** | 9091 / 51413 | Torrent client |
| **Radarr** | 7878 | Movie management |
| **Sonarr** | 8989 | TV show management |
| **Prowlarr** | 9696 | Indexer manager |
| **Seerr** | 5055 | Request management |
| **Unpackerr** | — | Automatic archive extraction |

## Quick Start

```bash
cp .env.example .env
cd media && docker compose up -d
```

## Environment (`.env.example`)
```
PUID=1000
PGID=1000
TZ=Europe/Lisbon
MEDIA_PATH=/mnt/media
CONFIG_PATH=/opt/docker
PLEX_CLAIM_TOKEN=claim-xxxxx
SONARR_API_KEY=your_sonarr_api_key
RADARR_API_KEY=your_radarr_api_key
```


## Storage Layout
```
/mnt/media/media/
├── movies/ # Radarr output → Plex/Jellyfin source
├── tvseries/ # Sonarr output → Plex/Jellyfin source
└── transmission/
└── downloads/
└── complete/ # Radarr/Sonarr pick up completed downloads here
# Unpackerr extracts archives here before import
```


## Plex Notes

Plex runs with `network_mode: host` for best local network discovery. Hardware transcoding is enabled via `/dev/dri`. The `#ports` block is intentionally commented out — host networking handles port exposure.

## HDD Spindown Optimisation

To keep the drive sleeping as much as possible:

1. **Transmission** — set seed ratio limit to 0.1 and idle seeding timeout to 5 min.
2. **Radarr/Sonarr** — increase "check for finished downloads" interval to 120+ min.
3. **RSS polling** — disabled; manual refresh is preferred (a search is triggered automatically when you add a new title).
4. **Webhooks** — configure Radarr/Sonarr to call a webhook on download completion so media is moved to the Plex/Jellyfin directory immediately without constant polling.

> Webhook integration is still in progress — repo will be updated once stable.

## arr Stack Integration

1. **Prowlarr** — add your indexers here; it pushes them to Radarr and Sonarr automatically.
2. **Radarr/Sonarr** — point download client to Transmission (`transmission:9091`).
3. **Unpackerr** — runs as a sidecar; connects to Radarr and Sonarr via their APIs to automatically extract `.rar`/archive releases before import. Requires `SONARR_API_KEY` and `RADARR_API_KEY` in `.env`.
4. **Seerr** — connect to Radarr and Sonarr for request management.
5. **Plex/Jellyfin** — point libraries at `/data/movies` and `/data/tv`.

## Maintenance

```bash
docker compose pull && docker compose up -d
docker compose logs transmission -f
docker compose logs radarr -f
docker compose logs unpackerr -f
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Transmission web UI unreachable | Check binding — it's bound to `192.168.0.102:9091`, not `0.0.0.0` |
| Radarr/Sonarr can't move files | Verify `PUID/PGID` match ownership of `/mnt/media` |
| Plex not visible on LAN | Confirm `network_mode: host` and that port 32400 isn't blocked by UFW |
| Prowlarr not syncing indexers | Check Prowlarr → Settings → Apps — Radarr/Sonarr must be configured there |
| "Found archive file, might need to be extracted" | Verify Unpackerr is running and API keys are correct: `docker logs unpackerr` |

---
Updated April 2026.
