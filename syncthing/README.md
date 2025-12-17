# 🔄 Syncthing: Decentralized File Synchronization

**Peer-to-peer file sync across your devices without central servers.**

---

## 🏠 Overview

Syncthing is an open-source, decentralized file synchronization tool that keeps your files in sync across multiple devices (computers, phones, servers) without relying on a cloud provider. All data is encrypted end-to-end.

**Key Features:**
- ✅ **No central server** - Direct P2P synchronization
- ✅ **End-to-end encryption** - Your data stays private
- ✅ **Selective sync** - Don't sync everything everywhere
- ✅ **Conflict resolution** - Handles file conflicts gracefully
- ✅ **Web UI** - Easy device and folder management
- ✅ **Continuous sync** - Changes propagate instantly

---

## 📂 Quick Start

### 1. Start Syncthing Service

```bash
cd /opt/docker/syncthing

# Create .env if not exists
cp .env.example .env

# Start container
docker-compose up -d

# Wait for initialization
sleep 5
docker-compose logs syncthing | tail -20
```

### 2. Access Web UI

- **URL:** `http://192.168.0.10:8384`
- **Local LAN:** Access directly from your browser
- **Remote (VPN):** Connect via OpenVPN first, then access via VPN IP

### 3. Generate Device ID

Your Syncthing instance generates a unique **Device ID** on first run:

```bash
# View Device ID
docker exec syncthing curl -s http://localhost:8384/rest/config | grep deviceID

# Or check UI: Actions → Show ID
```

### 4. Add Another Device

1. Install Syncthing on another machine (laptop, phone, etc.)
2. Open Syncthing UI on both machines
3. Scan QR code or manually enter Device ID
4. Both devices automatically connect

---

## 틜 Configuration

### Environment Variables (`.env`)

```bash
# Syncthing container configuration
PUID=1000                    # User ID (same as Docker user)
PGID=1000                    # Group ID
TZ=Europe/Lisbon             # Timezone for timestamps
```

### Docker Compose Setup

```yaml
syncthing:
  image: linuxserver/syncthing:latest
  container_name: syncthing
  restart: unless-stopped
  environment:
    - PUID=${PUID:-1000}
    - PGID=${PGID:-1000}
    - TZ=${TZ:-Europe/Lisbon}
  volumes:
    - ./config:/config              # Config + Device ID
    - /mnt/media/sync:/sync         # Shared folder
    - /home/user/Documents:/docs    # Additional folder
  ports:
    - "8384:8384"  # Web UI
    - "22000:22000/tcp"  # Sync protocol (TCP)
    - "22000:22000/udp"  # Sync protocol (UDP)
    - "21027:21027/udp"  # Device discovery
  networks:
    - proxy_network
```

### Volumes

| Volume | Purpose | Notes |
|--------|---------|-------|
| `./config` | Configuration & state | Persists Device ID, certificates, config |
| `/mnt/media/sync` | Primary sync folder | Syncs across all connected devices |
| `/home/user/Documents` | Secondary sync folder | Optional; add multiple as needed |

---

## 🔗 Device Pairing

### Initial Setup (First Two Devices)

**Device A (Server in Docker):**
1. Open: `http://192.168.0.10:8384`
2. Note Device ID (or scan QR code)

**Device B (Laptop/Phone):**
1. Install Syncthing locally
2. Open: `http://localhost:8384` (or app)
3. Add device:
   - Click "+" or "Add Device"
   - Paste Device A's ID from server
   - Click "Save"

**Device A (back to server):**
1. Notification appears: "Device B wants to connect"
2. Click "Add" to approve
3. Both devices now paired 🆗

### Adding More Devices

Repeat the same process:
- Device A (✓ already configured) sees request from new device
- Approve the connection
- New device now syncs with all paired devices

---

## 📁 Folder Configuration

### Add a Sync Folder

1. **On the server (Device A):**
   - Web UI → "+ Add Folder"
   - Path: `/sync` (or any mounted path)
   - Label: "Media Sync" (descriptive name)
   - Folder Type: "Send & Receive" (bidirectional)
   - Click "Save"

2. **Share with other devices:**
   - Folder settings → "Edit" → "Sharing"
   - Toggle "Device B", "Device C", etc.
   - "Save"
   - Devices receive share offer

3. **On other devices:**
   - Notification: "Device A wants to share folder 'Media Sync'"
   - Click "Add"
   - Choose local storage path (e.g., `~/Syncthing/Media Sync`)
   - Click "Save"
   - Syncing begins automatically

### Folder Types

| Type | Behavior | Use Case |
|------|----------|----------|
| **Send & Receive** | Bidirectional sync | Documents, shared projects, user files |
| **Send Only** | One-way upload | Backups to server, archive copies |
| **Receive Only** | One-way download | Config distribution, read-only archives |

---

## 🔐 Security Configuration

### HTTPS for Web UI

Syncthing UI runs on HTTP by default. For remote access, use NPM:

```bash
# In Nginx Proxy Manager UI:
# Proxy Host:
#   Domain: syncthing.local
#   Forward to: syncthing:8384
#   Custom Headers: X-Forwarded-Proto
# SSL: Request Let's Encrypt cert (if public domain)
```

### API Key

If accessing REST API externally:

```bash
# Get API key from UI
# Settings (gear icon) → API Key

# Or extract from config
cat /opt/docker/syncthing/config/config.xml | grep -oP '<apikey>\K[^<]+'
```

### Encryption

- **In transit:** TLS encryption between devices
- **At rest:** Not encrypted by default (use device filesystem encryption if sensitive)
- **Per-folder:** Can enable additional encryption (experimental)

---

## 📆 Folder-Level Permissions

### Ignore Patterns

Create `.stignore` file in sync folder to exclude files:

```
# Exclude system files
.DS_Store
Thumbs.db
*.tmp

# Exclude by pattern
*.log
*.bak
*~

# Exclude large media
*.iso
*.zip
*.rar

# Exclude directories
.git/
node_modules/
__pycache__/
```

### Large Files

By default, Syncthing syncs all files. For large media:

1. **Option A - Selective Sync on Device:**
   - Folder settings → "Advanced"
   - Set "Max file size" to desired limit

2. **Option B - Separate Folders:**
   - Keep media library in a different folder ("Send Only")
   - Only archive/backup tier syncs to all devices

3. **Option C - Ignored Files:**
   - Use `.stignore` to exclude large files
   - Good for photo backups (originals stay on server, thumbnails sync)

---

## 📊 Conflict Resolution

### What Happens When Files Conflict

If the same file is edited on Device A and Device B simultaneously:

```
Original: file.txt on Server
  ⮙ Device A edits → file.txt (modified)
  ⮙ Device B edits → file.txt (modified differently)
  💫 Conflict!
```

### Syncthing's Resolution

1. **Detects conflict** (same file changed on multiple devices)
2. **Keeps both versions:**
   ```
   file.txt                     # Device A's version (kept)
   file.sync-conflict-XXX.txt   # Device B's version (renamed)
   ```
3. **Propagates to all devices** → You manually choose which to keep
4. **Delete or rename** the conflict copy
5. **Sync completes** once conflicts are resolved

**Best practice:** Use `Send Only` folders if you want one device to be the "source of truth" (no conflicts).

---

## 🛠️ Troubleshooting

### Devices Not Connecting

**Problem:** "Disconnected" status in Web UI

**Solutions:**
```bash
# 1. Check firewall rules
sudo ufw status
sudo ufw allow 22000/tcp
sudo ufw allow 22000/udp
sudo ufw allow 21027/udp

# 2. Check port forwarding (if remote)
# TP-Link Router → NAT → Port Forward
# External: 22000 TCP/UDP → Internal: [syncthing-ip]:22000

# 3. Verify container connectivity
docker exec syncthing curl -I http://localhost:8384

# 4. Check logs
docker-compose logs syncthing | tail -30

# 5. Restart container
docker-compose restart syncthing
```

### Files Not Syncing

**Problem:** Files appear on Device A but not Device B

**Solutions:**
```bash
# 1. Verify folder is shared with the device
# UI → Folder → Edit → Sharing → Check device toggle

# 2. Check ignore patterns
# UI → Folder → Edit → Advanced → Ignore Patterns

# 3. Check disk space on Device B
df -h ~/Syncthing/

# 4. Verify sync status
# UI: Last seen/Last status should show recent timestamp

# 5. Manual rescan
UI → Folder → ↓ (overflow menu) → Rescan
```

### Web UI Not Accessible

**Problem:** `Connection refused` when accessing `http://192.168.0.10:8384`

**Solutions:**
```bash
# 1. Check container is running
docker-compose ps

# 2. Check port binding
docker port syncthing

# 3. Check logs
docker-compose logs syncthing | grep -i listen

# 4. Test from container
docker exec syncthing curl http://localhost:8384

# 5. Restart
docker-compose restart syncthing
```

### High CPU/Memory Usage

**Problem:** Syncthing consuming excessive resources

**Solutions:**
```bash
# 1. Reduce sync frequency
# UI → Settings → Advanced → "Folder Rescan Interval"
# Increase to 3600s (1 hour) instead of 60s

# 2. Ignore more file types
# Add patterns to .stignore (especially temp/log files)

# 3. Limit number of concurrent file transfers
# UI → Settings → Advanced → "Max Concurrent Requests"

# 4. Move to separate filesystem
# Ensure /sync is on fast storage (SSD preferred)
```

---

## 💫 Backup Strategy

### Version History

Syncthing can keep versions of deleted files:

1. Folder settings → "File Versioning"
2. Select strategy:
   - **None** (default): No history, changes are permanent
   - **Simple**: Keep N previous versions
   - **Trashcan**: Move deleted files to trash folder
   - **Staggered**: Keep versions with increasing intervals

### Example Configuration

```bash
# Staggered versioning (good for important files)
# Keep:
#  - Last 5 versions (keep 1 hour)
#  - 1 version per day for 30 days
#  - 1 version per week for 1 year
```

### Manual Backup

```bash
# Backup Syncthing config (includes Device ID)
docker cp syncthing:/config /opt/backups/syncthing_config_$(date +%Y%m%d).tar

# Backup sync folder
tar -czf /opt/backups/syncthing_data_$(date +%Y%m%d).tar.gz /mnt/media/sync/
```

---

## 🚀 Advanced Configurations

### Using Relay Servers

If direct P2P connection fails (both devices behind NAT):

```yaml
# docker-compose.yml
syncthing:
  environment:
    - STRELAYSRV="relay://relay.syncthing.net:443"
```

Syncthing will automatically use relays if needed.

### Custom Relay (Optional)

```bash
# Run your own relay server
docker run -d \
  --name syncthing-relay \
  -p 22067:22067 \
  syncthing/relaysrv:latest
```

### Discovery Servers

Customize how devices discover each other:

```xml
<!-- In config/config.xml, discovery servers: -->
<discoveryServer>https://discovery.syncthing.net/v2/?device=&lt;device-id&gt;</discoveryServer>
```

---

## 📚 Documentation & Resources

- **Official Syncthing Docs:** https://docs.syncthing.net/
- **Docker Image:** https://hub.docker.com/r/linuxserver/syncthing
- **Mobile Apps:** iOS (Syncthing), Android (Syncthing-Fork)
- **Browser Extension:** (none official, but REST API is available)

---

## 📧 Support & Troubleshooting

- **Check Web UI**: Always your first stop for status/errors
- **Review Logs**: `docker-compose logs syncthing`
- **Official Forum**: https://forum.syncthing.net/
- **GitHub Issues**: https://github.com/syncthing/syncthing/issues

---

**Next Steps:**
- [Configure Nextcloud](../nextcloud/README.md) for cloud storage
- [Set up Nginx Proxy Manager](../proxy/README.md) for remote access
- [Review Security Best Practices](../SECURITY.md)
