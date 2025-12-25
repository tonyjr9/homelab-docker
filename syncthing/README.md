# Syncthing (Peer-to-Peer File Sync)

Back to [Main README](../README.md)

Decentralized file synchronization across devices without relying on cloud services.

## Services Included

- **Syncthing**: Peer-to-peer file synchronization

## Directory Structure

```
syncthing/
├── docker-compose.yml
├── README.md
└── config/                # Syncthing config, device ID (not tracked)
```

## Environment Variables

```bash
# .env
PUID=1000
PGID=1000
TZ=Europe/Lisbon
```

## Quick Start

```bash
cd syncthing

# Create config directory
mkdir -p config

# Start Syncthing
docker-compose up -d

# Wait for initialization (10-30 sec)
sleep 10

# Verify
docker-compose ps
```

## Access Points

### Syncthing Web UI
- **URL**: http://192.168.0.10:8384
- **Setup**: Access immediately on first launch
- **API**: http://192.168.0.10:8384/rest/

## Configuration

### Initial Setup

1. Navigate to http://192.168.0.10:8384
2. Complete setup wizard:
   - Choose username/password
   - Set device name ("HomeServer", "Debian", etc.)
   - Enable/disable features
3. Configure sharing with other devices

### Add Folders to Sync

**From Web UI:**

1. Click **+ Add Folder** (or "Add Folder")
2. Fill in:
   - Folder Path: `/[path]` (within container)
   - Folder ID: Unique identifier (auto-generated)
   - Label: Human-readable name
3. **Save**
4. Share folder with other devices

**Example folders:**
- `/sync/documents` → Container internal
- `/opt/docker/synced_files` → Map to host

### Connect Second Device

**On first device (HomeServer):**
1. Get Device ID: Settings > This Device > Device ID (copy)
2. Share folder with new device: [Folder] > Sharing
3. Select/add the second device

**On second device (laptop, desktop, etc.):**
1. Install Syncthing (download from syncthing.net)
2. Get Device ID: Settings > This Device
3. Add HomeServer as remote device: Add Remot Device (use ID)
4. Accept folder share from HomeServer
5. Choose folder path to sync
6. Two-way sync starts automatically

### Advanced Configuration

**Ignore Patterns:**

Exclude files from syncing (e.g., .DS_Store, node_modules):

1. Folder Settings > Ignore Patterns
2. Add patterns:
   ```
   .DS_Store
   *.tmp
   node_modules/
   __pycache__/
   .git/
   ```

**Sync Conflicts:**

When same file modified on multiple devices:
- One version kept
- Other saved as `.sync-conflict` version
- Manual resolution in UI

**Bandwidth Limits:**

Limit upload/download to prevent congestion:
1. Settings > Options
2. Global rate limit (KB/s)
3. Per-device rate limits (optional)

## Usage

### Typical Workflows

**Example 1: Backup important documents**
```
Laptop:~/Documents/ <-> HomeServer:/opt/docker/synced_files/documents/
```

**Example 2: Share files between devices**
```
Desktop:/project/ <-> HomeServer:/opt/docker/synced_files/project/ <-> Laptop:~/project/
```

**Example 3: Centralized config**
```
HomeServer:/opt/docker/configs/ <-> Laptop:~/.config/
                                  <-> Desktop:~/.config/
```

### Monitoring

**Check sync status:**
1. Web UI shows real-time sync progress
2. Green checkmark = Synced
3. Progress bar = Currently syncing
4. Error indicator = Conflicts or failures

**View recent activity:**
- Settings > Change History
- Shows last 50 file changes

**Device Status:**
- Online/Offline indicator
- Last seen timestamp
- Sync completion %

## Troubleshooting

### Device can't connect

**Symptom:** "Disconnected" status; won't connect

**Solution:**
```bash
# Check firewall allows port 22000
sudo ufw status
sudo ufw allow 22000/tcp
sudo ufw allow 22000/udp

# Check if both devices have each other added
# Web UI: Settings > Remote Devices

# Verify Syncthing is running
docker-compose ps

# Check logs
docker-compose logs -f syncthing | head -20

# Force reconnect
# Web UI: Device > Disconnect, then wait for auto-reconnect
```

### Folder not syncing

**Symptom:** Files aren't transferring between devices

**Solution:**
```bash
# Check folder is shared with device
# Web UI: Folder > Sharing > Device list

# Verify permissions on local path
ls -la /opt/docker/synced_files/
# Should be readable/writable by container user

# Check ignore patterns aren't blocking files
# Web UI: Folder > Ignore Patterns

# Force rescan
# Web UI: Folder > Rescan

# Or restart container
docker-compose restart syncthing
```

### High CPU/disk usage

**Symptom:** Syncthing consuming resources

**Solution:**
```bash
# Check what's syncing
# Web UI: Activity > Recent events

# Pause sync temporarily
# Web UI: Folder > Pause

# Exclude large/unnecessary files
# Add to Ignore Patterns

# Increase file watching threshold
# Settings > Options > File watching > Max events

# Monitor activity
docker stats syncthing
```

### Sync conflicts

**Symptom:** `.sync-conflict` files appearing

**Solution:**
```
Conflicts occur when same file modified on multiple devices before sync.

Resolution:
1. Check Web UI: Settings > Conflict (Newer File)
2. Files with .sync-conflict in name are non-winning versions
3. Delete unwanted versions
4. Resync will fix
```

## Maintenance

### Update container

```bash
cd syncthing
docker-compose pull
docker-compose up -d
```

### Backup configuration

```bash
# Backup device ID and config
sudo tar -czf syncthing_backup.tar.gz config/
```

### View logs

```bash
# Follow logs
docker-compose logs -f syncthing

# Last 50 lines
docker-compose logs --tail 50 syncthing
```

## Advanced Configuration

### Docker Volume Binding

Edit docker-compose.yml to sync multiple folders:

```yaml
syncthing:
  volumes:
    - ./config:/home/syncthing/.config/syncthing
    - /opt/docker/synced_files:/sync/files:rw
    - /home/user/Documents:/sync/documents:rw
    - /mnt/media/backup:/sync/media_backup:rw
```

Then configure folders in Web UI pointing to `/sync/...` paths.

### REST API

Program interactions via API:

```bash
# Get sync status
curl http://192.168.0.10:8384/rest/db/status?folder=sync-folder-id

# List connected devices
curl http://192.168.0.10:8384/rest/config/devices

# Trigger rescan
curl -X POST http://192.168.0.10:8384/rest/db/scan?folder=sync-folder-id
```

Add API key in Settings > API Key for automation.

### Discovery Server

Sync devices via dedicated discovery server (optional):
- Default: Public Syncthing discovery servers
- Custom: Self-hosted discovery.syncthing.net clone
- Local only: Disable discovery, manually add via LAN IP

## Security Notes

- Device IDs are cryptographic certificates (not easily spoofed)
- All sync data encrypted in transit
- No cloud intermediary required
- Firewall port 22000 by default (open only if needed)
- API key should be protected like password
- Run behind NPM reverse proxy if exposing externally

## Storage Notes

Syncthing stores copies on all connected devices. Plan storage accordingly:

```
HomeServer: Full copies
Laptop: Selected folders only
Desktop: Selected folders only
```

Total storage = Sum of all synced folders on each device.

---

For more info:
- [Syncthing Project](https://syncthing.net/)
- [Syncthing Documentation](https://docs.syncthing.net/)
- [REST API Reference](https://docs.syncthing.net/rest/index.html)