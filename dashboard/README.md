# Dashboard Services (Homarr, Beszel)

Back to [Main README](../README.md)

Central dashboard for service management with real-time system monitoring.

## Services Included

- **Homarr**: Unified dashboard with service shortcuts and widgets
- **Beszel**: System resource monitoring (CPU, memory, disk, network)

## Directory Structure

```
dashboard/
├── docker-compose.yml
├── README.md
├── configs/                 # Homarr config (not tracked)
├── data/                    # Beszel data (not tracked)
└── icons/                   # Custom service icons (not tracked)
```

## Environment Variables

```bash
# .env
TZ=Europe/Lisbon
HOMARR_SECRET_KEY=your_unique_secret_key
```

## Quick Start

```bash
cd dashboard
docker-compose up -d

# Verify
docker-compose ps
```

## Access Points

### Homarr Dashboard
- **URL**: http://192.168.0.10:7575
- **Setup Wizard**: First launch

### Beszel Monitoring
- **URL**: http://192.168.0.10:8090 (internal port)

## Configuration

### Homarr Setup

**First Launch:**
1. Navigate to http://192.168.0.10:7575
2. Complete setup wizard
3. Create categories (Networking, Media, Cloud, etc.)
4. Add service tiles:
   - Nginx Proxy Manager
   - Pi-hole
   - Nextcloud
   - Transmission
   - Home Assistant
   - etc.

**Tile Configuration:**
- Service name
- URL (http://service-name:port or via proxy)
- Icon (built-in or custom)
- Ping to verify availability

**Docker Socket Integration:**

Homarr can auto-discover Docker containers if socket is mounted:

```yaml
docker-compose.yml:
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro
```

Note: Requires careful permission handling. Consult Homarr docs for details.

### Beszel Monitoring

**Agent Installation (Optional):**

Beszel can monitor remote hosts via SSH. For this homelab, monitoring the local Debian host.

**Access from Homarr:**

Add Beszel widget to Homarr dashboard:
1. Homarr settings
2. Add widget
3. Select Beszel
4. Configure API endpoint: http://beszel:8090

## Usage

### Adding Services to Dashboard

1. **Edit Dashboard** (pencil icon)
2. **Add Tile** button
3. Fill in:
   - Title
   - URL: http://service-name:port (for local services)
   - Icon: Choose from library
   - Description (optional)
4. **Save**

### Quick Links

Organize by category:
- Networking (NPM, Pi-hole)
- Storage (Nextcloud, Syncthing)
- Media (Transmission, future Plex)
- Administration (Portainer, Homarr settings)
- Automation (Home Assistant)

### System Monitoring

Beszel displays:
- CPU usage and temperature
- Memory and swap usage
- Disk usage and I/O
- Network bandwidth
- Uptime

**View:**
- Real-time dashboard
- Historical graphs
- Alerts for thresholds (configurable)

## Troubleshooting

### Homarr can't reach services

**Symptom:** Tiles show "Offline" or "Unreachable"

**Solution:**
```bash
# Test from Homarr container
docker exec homarr ping service-name
docker exec homarr curl http://service-name:port

# Verify service is running
docker ps | grep [service]

# Use IP instead of hostname if DNS fails
# Update tile URL to http://192.168.0.10:port
```

### Beszel not collecting data

**Symptom:** No metrics displayed; empty graphs

**Solution:**
```bash
# Check Beszel logs
docker-compose logs beszel

# Verify database
docker exec beszel ls -la /config/

# Restart
docker-compose restart beszel
```

### Docker socket permission denied

**Symptom:** "Permission denied" when accessing /var/run/docker.sock

**Solution:**
```bash
# Check permissions
ls -la /var/run/docker.sock

# Temporary fix (not recommended)
sudo chmod 666 /var/run/docker.sock

# Proper fix: Create docker group and add user
sudo usermod -aG docker $USER

# Or adjust docker-compose socket mount permissions
```

## Maintenance

### Update containers

```bash
cd dashboard
docker-compose pull
docker-compose up -d
```

### Backup dashboard configuration

```bash
# Homarr config
sudo tar -czf homarr_backup.tar.gz configs/

# Beszel data
sudo tar -czf beszel_backup.tar.gz data/
```

### View logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f homarr
docker-compose logs -f beszel
```

## Advanced Configuration

### Custom Icons

Place PNG icons in `icons/` directory:

```bash
icons/
├── transmission.png
├── nextcloud.png
└── plex.png
```

Reference in tile configuration.

### Beszel Thresholds

Set alerts for resource usage:
- CPU: Alert if > 80% for 5 min
- Memory: Alert if > 85%
- Disk: Alert if > 90%

Configure via Beszel settings.

---

For more info:
- [Homarr Documentation](https://homarr.io/)
- [Beszel GitHub](https://github.com/henrywhitaker3/beszel)