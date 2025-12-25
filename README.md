# Homelab Docker Stack

Production-ready personal homelab built with Docker Compose for media, networking, files, monitoring, and automation. Remote access via TP-Link ER605 OpenVPN; Home Assistant runs as a KVM/libvirt VM on the same Debian host.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)
![Docker: Compose](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)

## Table of Contents

- [Host Infrastructure](#host-infrastructure)
- [Architecture](#architecture)
- [Service Documentation](#service-documentation)
- [System Configuration](#system-configuration)
- [Storage Architecture](#storage-architecture)
- [Quick Start](#quick-start)
- [Directory Structure](#directory-structure)
- [Configuration](#configuration)
- [Networking & Security](#networking--security)
- [Useful Commands](#useful-commands)
- [Troubleshooting](#troubleshooting)

---

## Host Infrastructure

### Hardware

| Component | Model | Specifications |
|-----------|-------|---|
| **Host OS** | Debian 13 | I7-8700H, 40GB RAM, 1x 256GB NVMe, 1x 12TB HDD |
| **Hypervisor** | KVM/libvirt (virt-manager) | Hosts Home Assistant VM (2 vCPU, 4GB RAM) |
| **Router/Gateway** | TP-Link ER605 | OpenVPN server, DDNS, port forwarding, 4x Gigabit LAN + 1x WAN |

### System-Level Configuration

#### HDD Spindown & Power Management

File: `/etc/rc.local`

```bash
#!/bin/bash

# HDD Spindown after 10 minutes
hdparm -S 120 /dev/sda

# CPU Power Saving (scales dynamically based on load)
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "powersave" > $cpu 2>/dev/null
done

exit 0
```

**Behavior:**
- HDD automatically spins down after 10 minutes of inactivity
- CPU scales from 800 MHz (idle) to 4.6 GHz (under load)
- Reduces power consumption by 10-15W at idle
- No performance impact on loaded workloads (Minecraft, downloads, etc.)

**Note:** This setup assumes single HDD. Future upgrade to RAID 1 or higher recommended for data redundancy.

#### Service Spindown Optimization

Transmission seeding and Radarr/Sonarr constant polling were eliminated:

1. **Transmission** - Set to stop seeding at ratio 0.1 and pause if idle > 5 minutes
2. **Radarr/Sonarr** - Check for finished downloads every 60+ minutes (instead of 1 minute)
3. **RSS Polling** - Disabled (manual content addition preferred)
4. **Webhook Notifications** - Implemented to trigger scans only on download completion

Result: HDD sleeps ~90% of the time, system is virtually silent at idle.

#### System Monitoring

Monitor disk activity in real-time:

```bash
# Install if needed
sudo apt install iotop

# Run with aggregated options
sudo iotop -a
```

Monitor current HDD state:

```bash
sudo hdparm -C /dev/sda
# Expected output when idle: "drive state is: standby"
```

Check CPU scaling:

```bash
cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
# Expected: "powersave" on all cores
```

---

## Architecture

### Network Topology

```
INTERNET (Tor / Remote Access)
    |
    | OpenVPN (port 1194)
    |
TP-Link ER605 (192.168.0.1)
    | OpenVPN Server: 10.0.0.0/24
    | DDNS Gateway: vpn.duckdns.org
    |
192.168.0.0/24 LAN
    |
Debian Server (192.168.0.10)
    |
    +-- Docker Stack (proxy_network)
    |   ├── Nginx Proxy Manager (80/443/81)
    |   ├── Pi-hole (53/80)
    |   ├── Homarr Dashboard (7575)
    |   ├── Portainer (9000/8000)
    |   ├── Transmission (9091/51413)
    |   ├── Nextcloud + MariaDB + Redis
    |   ├── Syncthing (22000/21027)
    |   └── Media Services (expandable)
    |
    +-- KVM/libvirt VM
        └── Home Assistant (8123)
```

### Access Patterns

**Local LAN**
- Direct IP access: `http://192.168.0.10:7575` (Homarr)
- Docker internal: `http://homarr:7575` (via container DNS)
- Hostname if configured: `http://homelab.local:7575`

**Remote VPN**
- Connect to TP-Link ER605 OpenVPN (vpn.duckdns.org)
- Receive VPN IP in 10.0.0.0/24 range
- Access via VPN IP: `http://10.0.0.2:7575`

**Public Domains (Optional)**
- Via Nginx Proxy Manager reverse proxy
- Let's Encrypt TLS certificates
- Example: `https://dashboard.yourdomain.com`

---

## Service Documentation

Each Docker service has dedicated documentation:

### Core Networking
- **[Nginx Proxy Manager, Pi-hole, DDNS](./proxy/README.md)**
  - Reverse proxy with TLS termination
  - DNS resolution and ad-blocking
  - Dynamic DNS updates

### Dashboards & Monitoring
- **[Homarr Dashboard & Beszel](./dashboard/README.md)**
  - Unified service dashboard
  - System resource monitoring

### Cloud Storage
- **[Nextcloud Stack (Nextcloud + MariaDB + Redis)](./nextcloud/README.md)**
  - Self-hosted file sync and sharing
  - Database and caching layer
  - Backup and restore procedures

### Media & Downloads
- **[Media Services (Transmission + expandable)](./media/README.md)**
  - Torrent downloading with event-driven scanning
  - Ready for Sonarr, Radarr, Plex, Immich
  - Webhook integration for automatic imports

### File Synchronization
- **[Syncthing](./syncthing/README.md)**
  - Peer-to-peer file sync
  - Multi-device synchronization

---

## System Configuration

### Debian Host Setup

#### Required Packages

```bash
# Docker and container runtime
sudo apt install docker.io docker-compose

# System utilities
sudo apt install htop iotop curl wget git

# KVM/libvirt for Home Assistant
sudo apt install qemu-kvm libvirt-daemon-system virt-manager

# Power management (optional, for advanced scaling)
sudo apt install cpufrequtils

# Optional: OpenVPN client (to test VPN connectivity)
sudo apt install openvpn
```

#### User Permissions

```bash
# Add user to docker group (avoid sudo for docker commands)
sudo usermod -aG docker $USER
newgrp docker

# Add user to libvirt group (for virt-manager)
sudo usermod -aG libvirt $USER
```

#### Time Synchronization

```bash
# Check NTP status
timedatectl status

# Set timezone (if needed)
sudo timedatectl set-timezone Europe/Lisbon
```

### Home Assistant VM

Home Assistant runs on KVM/libvirt on the same Debian host.

**Setup via virt-manager:**

```bash
# Launch UI
virt-manager &

# Or via command line:
virsh list                    # List VMs
virsh start home-assistant    # Start VM
virsh shutdown home-assistant # Graceful shutdown
```

**Access:**
- Local: `http://192.168.0.10:8123`
- Via NPM reverse proxy: `https://home.yourdomain.com`

**Integration with Docker:**
- Home Assistant can discover Docker containers via socket access
- Configure in Home Assistant UI: Settings > Integrations > Docker

---

## Storage Architecture

### Recommended Layout

```
/opt/docker/                           # Docker Compose configurations
├── proxy/                             # Nginx, Pi-hole, DDNS
├── dashboard/                         # Homarr, Beszel
├── nextcloud/                         # Nextcloud, MariaDB, Redis
├── media/                             # Transmission, media services
├── syncthing/                         # File sync
├── minecraft/                         # Optional game server
├── docker-compose.yml                 # Orchestration (if centralized)
└── .env                              # Secrets (not tracked in git)

/mnt/media/                            # Media and large files
├── media/
│   ├── movies/                        # Movie library
│   ├── tvseries/                      # TV show library
│   └── transmission/
│       ├── downloads/
│       │   ├── complete/              # Seeded torrents
│       │   └── incomplete/            # In-progress downloads
│       └── watch/                     # Auto-import folder
├── nextcloud/
│   ├── config/                        # NC configuration
│   ├── data/                          # User files
│   └── db/                            # MariaDB data
└── backups/                           # Backup destination
```

### Storage Notes

Current single HDD setup (12TB) is suitable for:
- Media library (movies, TV series)
- Nextcloud user data
- Transmission downloads
- System backups

**Future Upgrade:** Deploy RAID 1 (mirrored) or RAID 5+ for redundancy and fault tolerance. No funds allocated currently.

Monitor disk usage:

```bash
du -sh /mnt/media/*                   # Per-folder usage
df -h /mnt/media                      # Overall free space
```

---

## Quick Start

### Prerequisites

- Debian 12+ with Docker & Docker Compose
- 2+ CPU cores, 4+ GB RAM minimum
- Network connectivity to TP-Link ER605 gateway
- Sufficient storage: 50GB+ for services, additional for media

### 1. Clone Repository

```bash
git clone https://github.com/tonyjr9/homelab-docker.git /opt/docker
cd /opt/docker
```

### 2. Configure Environment

```bash
# Copy template
cp .env.example .env

# Edit with your settings
nano .env
```

### 3. Create Networks (One-time)

```bash
docker network create proxy_network
```

### 4. Start Services (Recommended Order)

```bash
# 1. Networking (gateway for all services)
cd proxy && docker-compose up -d && cd ..

# 2. Dashboard and monitoring
cd dashboard && docker-compose up -d && cd ..

# 3. Core services
cd nextcloud && docker-compose up -d && cd ..
cd syncthing && docker-compose up -d && cd ..

# 4. Optional media services
cd media && docker-compose up -d && cd ..

# 5. Optional Minecraft
cd minecraft && docker-compose up -d && cd ..
```

### 5. Verify

```bash
# Check all containers running
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

# Check specific logs
docker-compose logs npm -f
```

---

## Directory Structure

```
/opt/docker/
├── .env                           # Configuration (not tracked)
├── .env.example                   # Template
├── .gitignore                     # Secrets protection
├── README.md                      # This file
│
├── proxy/                         # See proxy/README.md
│   ├── docker-compose.yml
│   ├── README.md
│   └── data/                      # (not tracked)
│
├── dashboard/                     # See dashboard/README.md
│   ├── docker-compose.yml
│   ├── README.md
│   └── configs/                   # (not tracked)
│
├── nextcloud/                     # See nextcloud/README.md
│   ├── docker-compose.yml
│   ├── nextcloud.env              # (not tracked)
│   ├── README.md
│   └── db/                        # (not tracked)
│
├── media/                         # See media/README.md
│   ├── docker-compose.yml
│   ├── README.md
│   └── transmission/              # (not tracked)
│
├── syncthing/                     # See syncthing/README.md
│   ├── docker-compose.yml
│   └── README.md
│
├── minecraft/                     # Optional
│   ├── docker-compose.yml
│   └── world/                     # (not tracked)
│
└── backups/                       # (not tracked)
```

---

## Configuration

### Global Environment Variables

Create `/opt/docker/.env`:

```bash
# Paths
CONFIG_PATH=/opt/docker
MEDIA_PATH=/mnt/media

# Networking
NPM_IP=192.168.0.197
PIHOLE_IP=192.168.0.198

# Timezone
TZ=Europe/Lisbon

# Credentials (change all defaults)
PIHOLE_PASSWORD=your_strong_password_here
DUCKDNS_DOMAIN=your-subdomain.duckdns.org
DUCKDNS_TOKEN=your_duckdns_token_here

MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_PASSWORD=your_nextcloud_db_password
REDIS_PASSWORD=your_redis_password

HOMARR_SECRET_KEY=your_homarr_secret_key
```

Each service may have a local `.env.example`. See individual READMEs for service-specific variables.

---

## Networking & Security

### Remote Access via OpenVPN (TP-Link ER605)

**Configuration on ER605:**
1. Login to ER605 web interface (192.168.0.1)
2. Navigate to VPN > OpenVPN Server
3. Enable OpenVPN, generate certificates
4. Forward port 1194 (UDP) to ER605 WAN
5. Create DuckDNS subdomain pointing to your WAN IP

**Connect from remote client:**
```bash
# Download .ovpn file from ER605
openvpn --config your-config.ovpn

# Once connected, access services:
# http://10.0.0.2:7575 (Homarr)
# http://10.0.0.2:8123 (Home Assistant)
# etc.
```

### Reverse Proxy (Nginx Proxy Manager)

NPM provides:
- TLS/SSL termination with Let's Encrypt
- Port 80/443 consolidation
- Access control and authentication
- Service routing

Setup via NPM UI (http://192.168.0.10:81):
1. Admin Panel > Proxy Hosts
2. Add new proxy host
3. Configure domain, SSL certificate, upstream service
4. Save and test

### Pi-hole DNS

Serves DNS to LAN and VPN clients:
- Blocks ads and malicious domains
- Logs DNS queries
- Custom DNS records for internal services

Access: `http://192.168.0.198/admin`

### Security Best Practices

**Do:**
- Keep `.env` files with secrets out of version control
- Use strong, unique passwords for each service
- Enable TLS/SSL for all public-facing services
- Restrict SSH access to authorized IPs
- Regularly update: `docker-compose pull && docker-compose up -d`
- Monitor logs for suspicious activity
- Use VPN for remote access (don't expose directly to internet)
- Review firewall rules: `sudo ufw status`

**Don't:**
- Hardcode secrets in docker-compose.yml
- Expose services without authentication
- Use default passwords
- Mount Docker socket without ACL consideration
- Keep sensitive backups in the repository
- Leave unnecessary ports open

### .gitignore Coverage

Protected items:
- All `.env` files (secrets)
- Database files (*.db, *.sql)
- SSL/TLS certificates (*.pem, *.key)
- SSH keys and fingerprints
- Runtime data directories (config, data, logs)
- Large media files

Allowed in Git:
- docker-compose.yml (uses env vars, no secrets)
- .env.example (template)
- READMEs and documentation
- Prometheus/monitoring configs

---

## Useful Commands

### Container Management

```bash
# List containers with details
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

# View logs
docker-compose logs -f [service]     # Follow logs
docker logs [container-name] -n 50   # Last 50 lines

# Control services
docker-compose restart [service]
docker-compose stop [service]
docker-compose up -d [service]

# Update all images
docker-compose pull && docker-compose up -d

# Prune unused resources
docker system prune -a --volumes
```

### Monitoring & Diagnostics

```bash
# Resource usage
docker stats

# Container details
docker inspect [container-name]

# Network connectivity
docker exec [container-1] ping [container-2]

# View environment
docker inspect [container-name] | grep -A 10 '"Env"'

# DNS resolution from container
docker exec [container] nslookup [hostname]
```

### Disk Monitoring

```bash
# HDD status
sudo hdparm -C /dev/sda              # Show spindown state

# Disk activity
sudo iotop -aoP                      # Aggregated, processes

# Disk usage
du -sh /mnt/media/*
df -h

# Monitor in real-time
watch -n 2 'du -sh /mnt/media/*'
```

### Backup & Restore

```bash
# Nextcloud database backup
docker exec nextcloud-database mysqldump -u nextcloud -p nextcloud > backup.sql

# Pi-hole gravity backup
docker cp pihole:/etc/pihole/gravity.db ./gravity_backup.db

# Full media sync to external drive
rsync -av --delete /mnt/media/ /mnt/external/media/
```

---

## Troubleshooting

### Services Can't Communicate

**Symptom:** Container A can't reach Container B

**Solution:**
```bash
# Verify both on proxy_network
docker network inspect proxy_network | grep -E '"Name"|"Containers"'

# Connect if missing
docker network connect proxy_network [container-name]

# Test DNS
docker exec [container-a] nslookup [container-b]

# Test connectivity
docker exec [container-a] ping [container-b]
```

### Port Already in Use

**Symptom:** `Error: bind: address already in use`

**Solution:**
```bash
# Find process
lsof -i :80
netstat -tlnp | grep :80

# Kill process or change docker-compose port mapping
docker-compose down && docker-compose up -d
```

### Out of Disk Space

**Symptom:** Services fail to write; containers exit

**Solution:**
```bash
# Check usage
df -h /opt/docker /mnt/media
du -sh /mnt/media/* | sort -h

# Clean Docker
docker system prune -a --volumes

# Remove old logs
docker exec [container] rm -f /var/log/*.log

# Move large files to external storage
```

### HDD Won't Spin Down

**Symptom:** `sudo hdparm -C /dev/sda` shows "active/idle" or "active"

**Solution:**
```bash
# Check what's accessing it
sudo iotop -aoP | head -20

# Common culprits:
# - Transmission still seeding (stop or reduce uploads)
# - Radarr/Sonarr scanning too frequently (check intervals)
# - System processes (journald, cron jobs)

# Force spindown for testing
sudo hdparm -y /dev/sda
sleep 5
sudo hdparm -C /dev/sda  # Should show standby
```

### Nextcloud Database Connection Fails

**Symptom:** Nextcloud container exits; "Cannot connect to database"

**Solution:**
```bash
# Check MariaDB
docker-compose logs nextcloud-database

# Verify credentials
cat nextcloud.env

# Restart stack properly
docker-compose down
sleep 2
docker-compose up -d
docker-compose logs -f nextcloud
```

### Nginx Proxy Manager Returns 502

**Symptom:** "Bad Gateway" error when accessing proxied service

**Solution:**
```bash
# Check NPM logs
docker-compose logs npm

# Verify upstream is running
docker ps | grep [service]

# Test from NPM container
docker exec npm ping [service]

# Check NPM proxy host configuration (UI, Admin Panel > Proxy Hosts)
# Use container name (not IP) for internal routing
```

### Home Assistant Can't Reach Docker

**Symptom:** HA VM can't communicate with host or Docker containers

**Solution:**
```bash
# From HA VM, test ping to host
ping 192.168.0.10

# Test DNS
nslookup docker.local  # (or hardcoded IP)

# Check firewall on Debian
sudo ufw status
sudo ufw allow from 192.168.0.0/24

# If using Docker socket:
ls -la /var/run/docker.sock
sudo chmod 666 /var/run/docker.sock  # Temporary fix
```

### General Debugging

1. Check logs: `docker-compose logs [service]`
2. Review .env configuration
3. Test container DNS: `docker exec [container] nslookup [host]`
4. Check firewall: `sudo ufw status`
5. Inspect network: `docker network inspect proxy_network`
6. Review service README for troubleshooting

---

## Resources

- Docker Compose: https://docs.docker.com/compose/
- Nginx Proxy Manager: https://nginxproxymanager.com/
- Pi-hole: https://docs.pi-hole.net/
- Nextcloud: https://docs.nextcloud.com/server/stable/admin_manual/
- Syncthing: https://docs.syncthing.net/
- Home Assistant: https://www.home-assistant.io/docs/
- TP-Link ER605: https://www.tp-link.com/us/support/download/er605/

---

**Last Updated:** December 2025 | **Status:** Active

For service-specific setup and configuration, see individual READMEs linked above.