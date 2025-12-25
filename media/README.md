# Media Services (Transmission + Expandable)

Back to [Main README](../README.md)

Torrent downloading with event-driven automatic import to media library. Ready to expand with Sonarr, Radarr, Plex, and Immich.

## Services Included

- **Transmission**: BitTorrent client with webhook integration
- **Placeholder configs**: Ready for Sonarr, Radarr, Plex, Immich

## Directory Structure

```
media/
├── docker-compose.yml
├── README.md
└── transmission/
    ├── config/
    │   ├── scripts/
    │   │   └── torrent-done.sh       # Webhook script for download events
    │   └── settings.json         # Transmission config (not tracked)
    └── downloads/
        ├── complete/             # Seeded torrents (moved to media library)
        └── incomplete/           # In-progress downloads
```

**Media Library** (on `/mnt/media`):
```
/mnt/media/media/
├── movies/                  # Movie library (for Radarr/Plex)
├── tvseries/                # TV series library (for Sonarr/Plex)
└── transmission/
    ├── downloads/
    │   ├── complete/          # Finished torrents (read by Radarr/Sonarr)
    │   └── incomplete/        # In-progress
    └── watch/               # Optional: auto-import folder
```

## Environment Variables

```bash
# .env
MEDIA_PATH=/mnt/media
PUID=1000
PGID=1000
TZ=Europe/Lisbon

# Optional for future services
# RADARR_API_KEY=your_key_here
# SONARR_API_KEY=your_key_here
# PLEX_CLAIM=claim-token_here
```

## Quick Start

```bash
cd media

# Create necessary directories
mkdir -p transmission/config/scripts transmission/downloads/{complete,incomplete}
mkdir -p /mnt/media/media/{movies,tvseries}
mkdir -p /mnt/media/media/transmission/downloads/{complete,incomplete}

# Start Transmission
docker-compose up -d transmission

# Verify
docker-compose ps
```

## Access Points

### Transmission Web UI
- **URL**: http://192.168.0.102:9091
- **Default User**: transmission
- **Default Password**: transmission

### Torrent Port
- **Port 51413**: UDP/TCP (for DHT, PEX, uTP)

## Configuration

### Transmission Settings

**Change immediately via web UI:**

1. Settings (wrench icon)
2. Download folder: `/downloads/incomplete`
3. Completed downloads: Automatically move to `/downloads/complete`
4. Bandwidth: Set upload/download limits if needed
5. Seeding:
   - Stop seeding at ratio: `0.1` (give minimal upload)
   - Stop seeding if idle: `5` minutes
6. Save

**Stop current seeding:**
- Click "Pause All" button in web UI

### Webhook Script (torrent-done.sh)

When a torrent completes, Transmission runs this script to notify Radarr/Sonarr for automatic import.

**Location**: `/opt/docker/media/transmission/config/scripts/torrent-done.sh`

**Script content:**
```bash
#!/bin/bash
# Transmission torrent completion webhook
# Notifies Radarr/Sonarr to scan for new downloads

TORRENT_PATH="$TR_TORRENT_DIR/$TR_TORRENT_NAME"

# Log notification
echo "[$(date)] Torrent completed: $TR_TORRENT_NAME" >> /tmp/transmission-notify.log

# Notify Radarr (movies)
curl -s -X POST "http://radarr:7878/api/v3/command" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: YOUR_RADARR_API_KEY" \
    -d '{"name":"DownloadedMoviesScan"}' \
    >> /tmp/transmission-notify.log 2>&1

# Notify Sonarr (TV shows)
curl -s -X POST "http://sonarr:8989/api/v3/command" \
    -H "Content-Type: application/json" \
    -H "X-Api-Key: YOUR_SONARR_API_KEY" \
    -d '{"name":"DownloadedEpisodesScan"}' \
    >> /tmp/transmission-notify.log 2>&1

exit 0
```

**Replace API keys before using.**

### Enabling Webhook

The docker-compose.yml already enables the script:

```yaml
environment:
  - TRANSMISSION_SCRIPT_TORRENT_DONE_ENABLED=true
  - TRANSMISSION_SCRIPT_TORRENT_DONE_FILENAME=/config/scripts/torrent-done.sh
```

**Verify script is recognized:**
```bash
docker exec transmission cat /config/settings.json | grep -i script
# Should show:
# "script-torrent-done-enabled": true,
# "script-torrent-done-filename": "/config/scripts/torrent-done.sh",
```

## Usage

### Adding Torrents

1. **Via Web UI:**
   - Select "Add" (+ icon)
   - Choose .torrent file or paste magnet link
   - Adjust priority/bandwidth
   - Start download

2. **Via Watch Folder:**
   - Copy .torrent files to watch folder (if enabled)
   - Transmission auto-imports and starts

### Download Flow

```
1. Add torrent in Transmission
2. Download to /downloads/incomplete/
3. Torrent completes
4. Move to /downloads/complete/
5. Webhook script runs
6. Notifies Radarr/Sonarr (if added)
7. Radarr/Sonarr scans and imports
8. Files moved to /media/{movies|tvseries}/
```

### Monitoring

**Check webhook notifications:**
```bash
cat /tmp/transmission-notify.log

# Expected output:
# [Thu Dec 25 03:01:38 PM WET 2025] Torrent completed: Movie.Title.2023.1080p
```

**Check what Transmission is doing:**
```bash
# Disk I/O from Transmission
sudo iotop -aoP | grep transmission

# Transmission logs
docker-compose logs transmission | tail -20
```

## Power Management (HDD Spindown)

Transmission is configured to minimize HDD activity:

- **Seeding disabled**: Stops after ratio 0.1 or 5 min idle
- **Check interval**: Only checked when needed (event-driven)
- **Result**: HDD can sleep >90% of the time

Verify HDD is sleeping:
```bash
sudo hdparm -C /dev/sda
# Expected: "drive state is: standby"
```

## Future Expansion

### Add Radarr (Movie Library Management)

Configured to scan `/mnt/media/media/transmission/downloads/complete/` on webhook events:

- Automatic download search
- Quality management
- Automatic import to `/media/movies/`
- Manual or RSS-based requests

### Add Sonarr (TV Series Management)

Same webhook integration for TV shows:
- Episode tracking
- Automatic import to `/media/tvseries/`
- Calendar view
- Manual or RSS-based requests

### Add Plex (Media Server)

Host movies and TV to home network and remotely:
- Organized library
- Streaming to devices
- Remote access via Plex.com

### Add Immich (Photo Management)

Self-hosted photo backup and organization:
- Mobile app for auto-backup
- Library organization
- Sharing and collaboration

## Troubleshooting

### Torrent download stuck

**Symptom:** Download at 0% or very slow

**Solution:**
```bash
# Check disk space
df -h /mnt/media

# Check permissions on download folder
ls -la /mnt/media/media/transmission/downloads/

# Restart Transmission
docker-compose restart transmission

# Increase bandwidth limits if throttled
```

### Webhook not firing

**Symptom:** Torrent completes but Radarr/Sonarr don't scan

**Solution:**
```bash
# Verify script exists
ls -la /opt/docker/media/transmission/config/scripts/torrent-done.sh

# Check permissions (should be executable)
ls -l /opt/docker/media/transmission/config/scripts/torrent-done.sh
# Should show: -rwxr-xr-x or similar

# Make executable if needed
sudo chmod +x /opt/docker/media/transmission/config/scripts/torrent-done.sh

# Check Transmission sees it
docker exec transmission cat /config/settings.json | grep script

# Test script manually
docker exec transmission bash /config/scripts/torrent-done.sh

# Check logs
cat /tmp/transmission-notify.log
```

### HDD not spinning down

**Symptom:** HDD stays active; fan running constantly

**Solution:**
1. Stop seeding in Transmission settings (set ratio to 0.1)
2. Click "Pause All" to stop current seeding
3. Wait 10+ minutes for idle timeout
4. Check: `sudo hdparm -C /dev/sda`

If still active, check what's accessing disk:
```bash
sudo iotop -aoP | head -20
```

## Maintenance

### Update container

```bash
cd media
docker-compose pull transmission
docker-compose up -d transmission
```

### Backup Transmission settings

```bash
sudo tar -czf transmission_backup.tar.gz transmission/config/
```

### View logs

```bash
docker-compose logs transmission -f
```

## Storage Notes

Current setup uses single 12TB HDD. Future upgrade to RAID 1+ recommended for redundancy.

Monitor disk usage:
```bash
du -sh /mnt/media/media/*
df -h /mnt/media
```

---

For more info:
- [Transmission Project](https://transmissionbt.com/)
- [Transmission RPC API](https://github.com/transmission/transmission/blob/master/docs/rpc-spec.md)
- Future: [Radarr](https://radarr.video/) | [Sonarr](https://sonarr.tv/) | [Plex](https://www.plex.tv/) | [Immich](https://immich.app/)