# 🚀 Deployment & Operations Guide

**Comprehensive guide for deploying and maintaining the homelab stack.**

---

## 📊 Table of Contents

- [Pre-Deployment Checklist](#-pre-deployment-checklist)
- [Step-by-Step Deployment](#-step-by-step-deployment)
- [Post-Deployment Configuration](#-post-deployment-configuration)
- [Service Health Checks](#-service-health-checks)
- [Scaling & Performance](#-scaling--performance)
- [Disaster Recovery](#-disaster-recovery)
- [Operations Runbook](#-operations-runbook)

---

## ✅ Pre-Deployment Checklist

### Hardware & OS

- [ ] Debian 12+ installed and fully updated
  ```bash
  sudo apt update && sudo apt upgrade -y
  sudo apt autoremove -y
  uname -a  # Verify kernel version
  ```

- [ ] Docker & Docker Compose installed
  ```bash
  docker --version    # Should be 20.10+
  docker-compose --version  # Should be 2.x
  
  # If not installed:
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  sudo usermod -aG docker $USER
  newgrp docker
  ```

- [ ] Sufficient disk space available
  ```bash
  df -h /opt/docker /mnt/media
  # Recommended: 50GB+ available, 500GB+ for /mnt/media
  ```

- [ ] Network connectivity
  ```bash
  ping 8.8.8.8           # Internet connectivity
  ping 192.168.0.1       # Gateway connectivity
  ip route show          # Verify routing
  ```

- [ ] Time synchronization
  ```bash
  timedatectl status     # Should show "NTP service: active"
  sudo timedatectl set-ntp on
  ```

### Repository & Configuration

- [ ] Clone homelab repository
  ```bash
  git clone https://github.com/tonyjr9/homelab-docker.git /opt/docker
  cd /opt/docker
  ```

- [ ] Create root `.env` file
  ```bash
  cp .env.example .env
  nano .env  # Fill in actual values
  chmod 600 .env
  ```

- [ ] Create per-service `.env` files (if needed)
  ```bash
  cd proxy && cp .env.example .env && nano .env && chmod 600 .env && cd ..
  cd nextcloud && cp .env.example nextcloud.env && nano nextcloud.env && chmod 600 nextcloud.env && cd ..
  cd dashboard && cp .env.example .env && nano .env && chmod 600 .env && cd ..
  ```

- [ ] Create data directories
  ```bash
  mkdir -p /mnt/media/{media,nextcloud,backups}
  mkdir -p /opt/docker/{proxy,dashboard,nextcloud,media,syncthing,minecraft}/data
  sudo chown -R $USER:$USER /opt/docker /mnt/media
  ```

- [ ] Verify .gitignore is protecting secrets
  ```bash
  git status
  # Should show .env as untracked (or red if already staged)
  # Should NOT show .env files in tracked files
  ```

---

## 🔵️ Step-by-Step Deployment

### Phase 1: Networking & Reverse Proxy (Critical)

```bash
cd /opt/docker/proxy

# Review docker-compose.yml
cat docker-compose.yml

# Verify .env is set
cat .env

# Start services
docker-compose up -d

# Wait for containers to be ready
sleep 10
docker-compose logs npm pihole

# Verify containers are running
docker-compose ps
# Expected: npm, pihole, ddns-updater all "Up"

cd ..
```

**Troubleshooting:**
```bash
# Check logs if services fail to start
docker-compose logs npm
docker-compose logs pihole

# Verify port binding
sudo netstat -tlnp | grep -E ":80|:443|:81|:53"

# Test NPM admin UI
curl http://192.168.0.197:81/

# Test Pi-hole
curl http://192.168.0.198/admin/
```

### Phase 2: Dashboard & Monitoring

```bash
cd /opt/docker/dashboard

# Verify .env (especially HOMARR_SECRET_KEY)
cat .env

# Start services
docker-compose up -d
sleep 10
docker-compose ps

# Access Homarr
# Browser: http://192.168.0.10:7575

cd ..
```

### Phase 3: Storage & Cloud Services

```bash
# Nextcloud stack (depends on proxy network)
cd /opt/docker/nextcloud
docker-compose up -d
sleep 15
docker-compose ps
# Wait for MariaDB to be healthy (first startup takes ~30s)

# Verify database initialization
docker-compose logs nextcloud-database | grep "ready for connections"

# Access Nextcloud
# Browser: http://192.168.0.10:8080
# Complete first-run setup in UI

cd ..

# Syncthing
cd /opt/docker/syncthing
docker-compose up -d
sleep 5
docker-compose ps

# Access Syncthing UI
# Browser: http://192.168.0.10:8384

cd ..
```

### Phase 4: Media Services

```bash
cd /opt/docker/media

# Optional: Transmission torrent client
docker-compose up -d transmission
sleep 5
docker-compose ps

# Access Transmission UI
# Browser: http://192.168.0.10:9091

cd ..
```

### Phase 5: Home Assistant VM (if applicable)

Home Assistant runs outside Docker on the Debian host:

```bash
# Option A: Using virt-manager GUI
virt-manager &
# Create new VM, point to Home Assistant ISO/OVA

# Option B: Using virsh CLI
virsh list --all
virsh start "Home Assistant"
virsh console "Home Assistant"

# Verify network bridge (if needed)
ip addr show
```

---

## 🏰 Post-Deployment Configuration

### Nginx Proxy Manager Setup

1. **Access Admin UI:**
   - URL: `http://192.168.0.197:81`
   - Default credentials: `admin@example.com` / `changeme`
   - **IMMEDIATELY change admin password**

2. **Create Proxy Hosts** (examples):
   ```
   # For Nextcloud (internal)
   Domain: nextcloud.local
   Scheme: http
   Forward Hostname: nextcloud
   Forward Port: 80
   Custom Headers: X-Forwarded-For, X-Forwarded-Proto
   
   # For Homarr (internal)
   Domain: homarr.local
   Scheme: http
   Forward Hostname: homarr
   Forward Port: 7575
   ```

3. **Enable SSL** (for public domains):
   - Select proxy host
   - Click "SSL" tab
   - Select "Request a new SSL Certificate"
   - Let's Encrypt will handle it automatically

### Pi-hole Setup

1. **Access Admin UI:**
   - URL: `http://192.168.0.198/admin/`
   - Password: Value from `.env` (PIHOLE_PASSWORD)

2. **Configure DNS Upstreams:**
   - Settings → DNS → Upstream DNS Servers
   - Add your preferred DNS (e.g., Cloudflare: 1.1.1.1, 1.0.0.1)

3. **Whitelist/Blacklist Domains:**
   - Adlists tab: Add block lists
   - Whitelist/Blacklist: Add domains as needed

4. **Set LAN DNS:**
   - From your TP-Link router, set DHCP DNS to Pi-hole IP (192.168.0.198)
   - Or manually configure clients to use 192.168.0.198 as DNS

### Nextcloud Setup

1. **First-Run Setup:**
   - Access: `http://192.168.0.10:8080`
   - Create admin user
   - Select data directory
   - Database already configured (MariaDB)

2. **Enable PHP Modules:**
   ```bash
   docker exec nextcloud php occ maintenance:repair
   ```

3. **Configure Trusted Proxies** (if behind NPM):
   ```bash
   docker exec nextcloud php -r 'require_once("/config/www/nextcloud/config/config.php"); echo "trusted_proxies: " . print_r($CONFIG["trusted_proxies"], true) . "\n";'
   ```

4. **Install Apps:**
   - Apps → + → Install your favorites (Contacts, Calendar, Tasks, etc.)

### Home Assistant Configuration

```bash
# Access Home Assistant UI
# URL: http://192.168.0.X:8123 (where X = VM IP)

# Complete onboarding in UI
# - Set location
# - Create automation & devices
# - Install integrations for services
```

---

## 💻 Service Health Checks

### Automated Health Verification

```bash
#!/bin/bash
# health_check.sh - Verify all services are running

echo "=== Docker Services Health Check ==="
echo ""

# Check each service
check_service() {
  local dir=$1
  local name=$2
  cd "/opt/docker/$dir" 2>/dev/null || return
  
  echo "Checking $name..."
  if docker-compose ps | grep -q "Up"; then
    echo "✅ $name: HEALTHY"
  else
    echo "❌ $name: UNHEALTHY - containers not running"
  fi
  echo ""
}

check_service "proxy" "Networking (NPM + Pi-hole)"
check_service "dashboard" "Dashboard (Homarr)"
check_service "nextcloud" "Nextcloud Stack"
check_service "syncthing" "Syncthing"
check_service "media" "Media Services"

echo "=== Port Accessibility ==="nslookup -type=A $(hostname)
sudo netstat -tlnp 2>/dev/null | grep -E ":80 |:443 |:81 |:53 |:7575 |:8080 |:8384"

echo ""
echo "=== Disk Usage ==="
df -h /opt/docker /mnt/media

echo ""
echo "=== Docker Memory Usage ==="
docker stats --no-stream --format "table {{.Container}}\t{{.MemUsage}}"
```

### Manual Health Checks

```bash
# Test all container connectivity
docker-compose exec npm ping pihole
docker-compose exec npm ping nextcloud

# Test DNS resolution
docker exec pihole nslookup google.com

# Check database connection
docker exec nextcloud mysql -u nextcloud -p -h nextcloud-database -e "SELECT 1;"

# Monitor real-time resource usage
docker stats

# Check disk space
du -sh /mnt/media/* | sort -h
```

---

## 📌 Scaling & Performance

### Resource Limits

Add to services in `docker-compose.yml` to prevent runaway containers:

```yaml
services:
  nextcloud:
    # ... other config ...
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
        reservations:
          cpus: '1'
          memory: 1G
```

### Database Optimization

```bash
# Nextcloud database optimization (monthly)
docker exec nextcloud-database mysqlcheck -u nextcloud -p nextcloud --auto-repair

# Vacuum SQLite if used
# docker exec [container] sqlite3 /path/to/db.sqlite "VACUUM;"
```

### Log Rotation

```bash
# Create logrotate config
sudo nano /etc/logrotate.d/docker-homelab

# Content:
/var/lib/docker/containers/*/*.log {
  rotate 7
  daily
  compress
  missingok
  delaycompress
  copytruncate
}

# Test
sudo logrotate -f /etc/logrotate.d/docker-homelab
```

---

## 🗪️ Disaster Recovery

### Backup Strategy

```bash
# Create automated backup script
cat > /opt/scripts/backup_homelab.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/mnt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

echo "Starting backup..."

# Backup Nextcloud database
echo "Backing up Nextcloud database..."
docker exec nextcloud-database mysqldump -u nextcloud -p"$NEXTCLOUD_DB_PASSWORD" nextcloud | gzip > "$BACKUP_DIR/nextcloud_db_$DATE.sql.gz"

# Backup configs
echo "Backing up configs..."
tar -czf "$BACKUP_DIR/configs_$DATE.tar.gz" /opt/docker/*/data /opt/docker/proxy/letsencrypt 2>/dev/null

# Backup Pi-hole gravity
echo "Backing up Pi-hole..."
docker cp pihole:/etc/pihole/gravity.db "$BACKUP_DIR/pihole_gravity_$DATE.db"

echo "Backup completed: $BACKUP_DIR"
EOF

chmod +x /opt/scripts/backup_homelab.sh

# Add to cron
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/scripts/backup_homelab.sh") | crontab -
```

### Restore from Backup

```bash
# Stop services
docker-compose down -v  # Remove volumes

# Restore database
gzip -dc /mnt/backups/nextcloud_db_*.sql.gz | docker exec -i nextcloud-database mysql -u nextcloud -p nextcloud

# Restore configs
tar -xzf /mnt/backups/configs_*.tar.gz -C /

# Start services
docker-compose up -d
```

---

## 💳 Operations Runbook

### Daily Operations

```bash
# Morning check
cd /opt/docker

# Monitor logs for errors
for dir in proxy dashboard nextcloud media syncthing; do
  echo "=== $dir ==="
  cd $dir && docker-compose logs --tail 20 2>/dev/null && cd ..
done

# Check disk usage
df -h /opt/docker /mnt/media

# Quick health check
echo "Testing connectivity..."
docker exec npm ping -c 1 pihole
docker exec npm ping -c 1 nextcloud
```

### Weekly Operations

```bash
# Update containers
cd /opt/docker
for dir in proxy dashboard nextcloud media syncthing minecraft; do
  echo "Updating $dir..."
  cd $dir && docker-compose pull && docker-compose up -d && cd ..
  sleep 5
done

# Review security logs
sudo tail -50 /var/log/auth.log | grep -i "failed\|ssh"

# Verify backups
ls -lh /mnt/backups/ | head -10
```

### Monthly Operations

```bash
# Deep dive health check
cd /opt/docker

# Check all containers
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

# Resource usage analysis
docker stats --no-stream

# Database optimization
docker exec nextcloud-database mysqlcheck -u nextcloud -p --all-databases

# Clean up unused images
docker image prune -a --force --filter "until=720h"

# Verify SSL certificates (if using Let's Encrypt)
ls -la /opt/docker/proxy/letsencrypt/live/
```

---

**For more details, see:**
- [Main README](./README.md) - Architecture and overview
- [SECURITY.md](./SECURITY.md) - Security best practices
- Per-service READMEs in each directory
