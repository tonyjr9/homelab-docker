# 🏠 Homelab Docker Stack

> **Production-ready personal homelab** built with Docker Compose for media, networking, files, monitoring, and automation. Remote access via TP-Link ER605 OpenVPN; Home Assistant runs as a KVM/libvirt VM on the same Debian host.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)
![Docker: Compose](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)

---

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Hardware](#-hardware)
- [Services Overview](#-services-overview)
- [Quick Start](#-quick-start)
- [Directory Structure](#-directory-structure)
- [Configuration](#-configuration)
- [Networking & Security](#-networking--security)
- [Per-Service Documentation](#-per-service-documentation)
- [Storage Layout](#-storage-layout)
- [Useful Commands](#-useful-commands)
- [Troubleshooting](#-troubleshooting)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ INTERNET (via Tor / Remote Access)                          │
└──────────────┬──────────────────────────────────────────────┘
               │ OpenVPN
┌──────────────▼──────────────────────────────────────────────┐
│ TP-Link ER605 (Router + OpenVPN Gateway)                     │
│ • VPN Server: 10.0.0.0/24                                    │
│ • LAN Gateway: 192.168.0.1                                   │
└──────────────┬──────────────────────────────────────────────┘
               │
┌──────────────▼──────────────────────────────────────────────┐
│ Debian Server (192.168.0.10)                                 │
├─────────────────────────────────────────────────────────────┤
│ Docker Stack (proxy_network)                                 │
│  ├─ Nginx Proxy Manager (80/443/81) [TLS Termination]       │
│  ├─ Pi-hole (53/80) [DNS + Ad-blocking]                     │
│  ├─ Homarr (7575) [Central Dashboard]                       │
│  ├─ Portainer [Container Management]                        │
│  ├─ Transmission (9091/51413) [Torrent Client]              │
│  ├─ Nextcloud (8080) + MariaDB + Redis [Cloud Storage]      │
│  ├─ Syncthing [File Sync]                                   │
│  ├─ DDNS Updater [Dynamic DNS]                              │
│  └─ Minecraft Server [Optional]                             │
├─────────────────────────────────────────────────────────────┤
│ KVM/libvirt Virtual Machines                                 │
│  └─ Home Assistant VM (8123) [Automation Platform]          │
└─────────────────────────────────────────────────────────────┘
```

**Access Patterns:**
- **Local LAN**: Direct access via IP/hostname (e.g., `http://192.168.0.10:7575`)
- **Remote VPN**: Connect to TP-Link ER605 OpenVPN, then access via VPN IP (e.g., `http://10.0.0.2:7575`)
- **Public Domains**: Via NPM reverse proxy with Let's Encrypt TLS (if exposed)

---

## 💻 Hardware

| Component | Model | Notes |
|-----------|-------|-------|
| **Router/Gateway** | TP-Link ER605 | OpenVPN server, DDNS, port forwarding, 4x Gigabit LAN + 1x WAN |
| **Host Server** | Custom Debian 12 | Ryzen 5 5600X, 32GB RAM, 2x 2TB NVMe (RAID 1), 4x 6TB HDD |
| **Hypervisor** | KVM/libvirt/virt-manager | Hosts Home Assistant VM (4 vCPU, 4GB RAM) + other VMs |
| **Network Storage** | Synology NAS (optional) | For media backups and off-site sync |
| **UPS** | APC Smart-UPS | Ensures graceful shutdown on power loss |

---

## 📦 Services Overview

### 🌐 **Networking & Proxy**
- **[Nginx Proxy Manager](./proxy/README.md)**: Reverse proxy, SSL/TLS termination, Let's Encrypt integration
- **Pi-hole**: DNS resolver + ad-blocking for LAN (and optional VPN clients)
- **DDNS Updater**: Automatic DuckDNS updates for dynamic WAN IP

### 🎛️ **Management & Monitoring**
- **[Homarr Dashboard](./dashboard/README.md)**: Unified interface for service management and shortcuts
- **Portainer**: Docker container orchestration and management UI
- **Beszel**: System monitoring and resource usage tracking

### 📁 **Storage & Sync**
- **[Nextcloud Stack](./nextcloud/README.md)**: Self-hosted cloud storage with MariaDB + Redis
- **Syncthing**: Peer-to-peer file synchronization
- **Transmission**: Torrent client with watch-folder integration

### 🎬 **Media Services** *(Expandable)*
- **[Media Directory](./media/README.md)**: Ready for Sonarr, Radarr, Plex, Immich, etc.
- Structured storage: `/mnt/media/media/{movies,tvseries,transmission/downloads}`

### 🏠 **Home Automation**
- **Home Assistant VM** (KVM/libvirt): Runs on the same Debian host, accessible via `http://server-ip:8123`
- Optionally placed behind NPM for secure remote access

### 🎮 **Optional Services**
- **Minecraft Server**: Docker-based game server with persistent world data
- **IT Tools**: Debugging and utility containers (Wazuh, code editors, etc.)

---

## 🚀 Quick Start

### Prerequisites
- Debian 12+ with Docker & Docker Compose installed
- 2+ CPU cores, 4+ GB RAM recommended
- Network connectivity to TP-Link ER605 or other gateway
- Sufficient storage for service data (`/opt/docker`, `/mnt/media`)

### 1. Clone & Setup

```bash
git clone https://github.com/tonyjr9/homelab-docker.git /opt/docker
cd /opt/docker

# Create .env from template
cp .env.example .env
# Edit .env with your configuration
nano .env
```

### 2. Bring Up Core Services (Recommended Order)

```bash
# 1️⃣ Networking first (Nginx Proxy Manager + Pi-hole + DDNS)
cd proxy
docker-compose up -d
cd ..

# 2️⃣ Dashboard & monitoring
cd dashboard
docker-compose up -d
cd ..

# 3️⃣ Core services
cd nextcloud && docker-compose up -d && cd ..
cd syncthing && docker-compose up -d && cd ..

# 4️⃣ Optional media services
cd media && docker-compose up -d && cd ..

# Optional: Minecraft
cd minecraft && docker-compose up -d && cd ..
```

### 3. Verify Services

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

# Check logs
docker-compose logs -f npm
docker-compose logs -f pihole
```

### 4. Configure Home Assistant (if on same host)

```bash
# Via virt-manager or virsh
virt-manager &
# Create or boot Home Assistant VM
# Access: http://192.168.0.10:8123 (or via NPM)
```

---

## 📂 Directory Structure

```
/opt/docker/
├── .env                           # ⚠️ GITIGNORED: Local configuration (secrets)
├── .env.example                   # ✅ Template for .env
├── .gitignore                     # Protects secrets and data directories
├── README.md                       # This file
│
├── proxy/                          # Nginx Proxy Manager + Pi-hole + DDNS
│   ├── docker-compose.yml
│   ├── .env.example               # NPM_IP, PIHOLE_IP, PIHOLE_PASSWORD, etc.
│   ├── README.md
│   ├── data/                       # ⚠️ GITIGNORED: NPM config
│   ├── letsencrypt/               # ⚠️ GITIGNORED: Let's Encrypt certs
│   ├── etc-pihole/                # ⚠️ GITIGNORED: Pi-hole config
│   ├── etc-dnsmasq.d/             # ⚠️ GITIGNORED: DNS config
│   └── ddns/data/                 # ⚠️ GITIGNORED: DDNS updates
│
├── dashboard/                      # Homarr + Beszel
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── README.md
│   ├── configs/                   # ⚠️ GITIGNORED: Homarr config
│   ├── data/                      # ⚠️ GITIGNORED: Beszel data
│   ├── icons/                     # ⚠️ GITIGNORED: Custom icons
│   ├── imgs/                      # ⚠️ GITIGNORED: Backgrounds
│   └── beszel_data/               # ⚠️ GITIGNORED: Monitoring DB
│
├── nextcloud/                      # Nextcloud + MariaDB + Redis
│   ├── docker-compose.yml
│   ├── nextcloud.env              # ⚠️ GITIGNORED: Credentials
│   ├── .env.example
│   ├── README.md
│   ├── db/                        # ⚠️ GITIGNORED: MariaDB data
│   ├── config/                    # ⚠️ GITIGNORED: Nextcloud config
│   ├── data/                      # ⚠️ GITIGNORED: Nextcloud files
│   └── old/                       # ⚠️ GITIGNORED: Backups/migration
│
├── media/                          # Media downloads + optional services
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── README.md
│   └── transmission/              # ⚠️ GITIGNORED: Torrent data
│
├── syncthing/                      # File synchronization
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── README.md
│   └── config/                    # ⚠️ GITIGNORED: Config + node ID
│
├── minecraft/                      # Minecraft server (optional)
│   ├── docker-compose.yml
│   ├── .env.example
│   └── world/                     # ⚠️ GITIGNORED: Game data
│
├── monitoring/                     # Prometheus config
│   └── prometheus.yml
│
└── backups/                        # ⚠️ GITIGNORED: Manual/automated backups
```

---

## ⚙️ Configuration

### Environment Variables (.env)

Create a `.env` file in `/opt/docker/` with the following:

```bash
# ========== PATHS ==========
CONFIG_PATH=/opt/docker
MEDIA_PATH=/mnt/media

# ========== NETWORKING ==========
NPM_IP=192.168.0.197          # Nginx Proxy Manager IP
PIHOLE_IP=192.168.0.198       # Pi-hole IP

# ========== TIMEZONE ==========
TZ=Europe/Lisbon              # Set your timezone (TZ database format)

# ========== PIHOLE ==========
PIHOLE_PASSWORD=your_secure_password_here

# ========== DDNS (DuckDNS) ==========
DUCKDNS_DOMAIN=your-subdomain.duckdns.org
DUCKDNS_TOKEN=your_duckdns_token_here

# ========== NEXTCLOUD ==========
MYSQL_ROOT_PASSWORD=root_password_here
MYSQL_PASSWORD=nextcloud_db_password_here
REDIS_PASSWORD=redis_password_here

# ========== HOMARR ==========
HOMARR_SECRET_KEY=your_secret_key_here

# ========== OPTIONAL: MEDIA SERVICES ==========
# PLEX_CLAIM_TOKEN=claim-xxxxxxxxxxxx
# RADARR_API_KEY=your_radarr_api_key
# SONARR_API_KEY=your_sonarr_api_key
```

**Each service may have a local `.env.example` file. See individual READMEs for service-specific variables.**

### Per-Service Configuration

- **[Proxy Services](./proxy/README.md)**: Nginx Proxy Manager, Pi-hole, DDNS
- **[Dashboard](./dashboard/README.md)**: Homarr, Beszel  
- **[Nextcloud Stack](./nextcloud/README.md)**: MariaDB, Redis, Nextcloud
- **[Media Services](./media/README.md)**: Transmission, expandable with *arr services
- **[Syncthing](./syncthing/README.md)**: Peer-to-peer sync

---

## 🔐 Networking & Security

### Remote Access Strategy

1. **OpenVPN via TP-Link ER605**
   - Connect to `vpn.duckdns.org` (or your domain)
   - Receives IP in `10.0.0.0/24` range
   - Access internal services over encrypted VPN tunnel

2. **Reverse Proxy (NPM)**
   - Terminates TLS/SSL with Let's Encrypt certificates
   - Routes HTTPS traffic to backend services
   - Enforces access controls (IP whitelist, authentication)

3. **Pi-hole DNS**
   - Serves DNS to LAN and VPN clients
   - Blocks ads and trackers
   - Logs queries for monitoring

### Security Best Practices

✅ **Do:**
- Keep all passwords/tokens in `.env` files (never commit to Git)
- Use strong, unique passwords for each service
- Enable TLS/SSL in NPM for all public-facing services
- Restrict SSH access to authorized IPs only
- Regularly update containers: `docker-compose pull && docker-compose up -d`
- Monitor logs for suspicious activity
- Use VPN for remote access; avoid exposing services directly to the internet

❌ **Don't:**
- Hardcode secrets in `docker-compose.yml`
- Expose services directly to the internet without authentication
- Use default passwords (especially Pi-hole, Nextcloud, Portainer)
- Mount Docker socket without careful ACL consideration
- Keep sensitive backups in the repository

### .gitignore Coverage

The `.gitignore` protects:
- ✅ All `.env` files with secrets
- ✅ Database files (`*.db`, `*.sql`)
- ✅ SSL/TLS certificates and keys (`*.pem`, `*.key`, `letsencrypt/`)
- ✅ SSH keys and fingerprints
- ✅ Runtime data directories (configs, data, logs)
- ✅ Large media files

**Allowed in Git:**
- ✅ `docker-compose.yml` (no secrets, uses env vars)
- ✅ `.env.example` (template, no values)
- ✅ READMEs and documentation
- ✅ Prometheus/monitoring configs

---

## 📚 Per-Service Documentation

Each service has a dedicated README. Start with:

1. **[Network & Proxy Setup](./proxy/README.md)**
   - Nginx Proxy Manager, Pi-hole, DDNS configuration
   - Port mappings, volumes, environment variables

2. **[Dashboard Setup](./dashboard/README.md)**
   - Homarr dashboard and Beszel monitoring
   - Docker socket integration, service discovery

3. **[Nextcloud Stack](./nextcloud/README.md)**
   - Self-hosted cloud with MariaDB and Redis
   - Database setup, volumes, backup strategy

4. **[Media Services](./media/README.md)**
   - Transmission, directory structure
   - Ready for Sonarr, Radarr, Plex, Immich (placeholder configs)

5. **[Syncthing Setup](./syncthing/README.md)**
   - File sync across devices
   - Device pairing, folder sharing

---

## 💾 Storage Layout

Recommended structure for persistent data:

```
/opt/docker/
├── proxy/data/           # NPM config & certificates
├── proxy/letsencrypt/    # Let's Encrypt certs
├── proxy/etc-pihole/     # Pi-hole config
├── dashboard/configs/    # Homarr dashboard config
├── nextcloud.env         # Nextcloud credentials (not tracked)
└── ... (other service configs)

/mnt/media/
├── media/
│   ├── movies/           # Movie library
│   ├── tvseries/         # TV show library
│   └── transmission/
│       ├── downloads/
│       │   ├── complete/ # Seeded torrents
│       │   └── incomplete/
│       └── watch/        # Watch folder for automated imports
├── nextcloud/            # Nextcloud data (if on separate mount)
│   ├── config/
│   ├── data/
│   └── db/
└── backups/              # Local backups before off-site sync
```

**Tip:** Use `du -sh /mnt/media/*` to monitor disk usage.

---

## 🧰 Useful Commands

### Container Management

```bash
# List all running containers with status and ports
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"

# View logs for a specific service
docker-compose logs -f [service-name]

# Restart a service
docker-compose restart [service-name]

# Update all images and restart
docker-compose pull && docker-compose up -d

# Stop all services
docker-compose down

# Prune unused images, containers, volumes
docker system prune -a --volumes
```

### Monitoring & Diagnostics

```bash
# Check service health
docker ps --no-trunc

# View resource usage
docker stats

# Inspect container details
docker inspect [container-name]

# Check network connectivity between containers
docker exec [container-1] ping [container-2]

# View environment variables passed to container
docker inspect [container-name] | grep -A 20 '"Env"'
```

### Backup & Maintenance

```bash
# Backup Nextcloud (database + config)
docker exec nextcloud-database mysqldump -u nextcloud -p nextcloud > nextcloud_backup.sql

# Backup Pi-hole gravity database
docker cp pihole:/etc/pihole/gravity.db ./gravity_backup.db

# Sync media to external storage
rsync -av --delete /mnt/media/ /mnt/external-backup/media/
```

### Docker Network Troubleshooting

```bash
# List all Docker networks
docker network ls

# Inspect a specific network
docker network inspect proxy_network

# Test DNS from a container
docker exec [container-name] nslookup another-service

# Test connectivity to external host
docker exec [container-name] curl -I https://example.com
```

---

## 🛠️ Troubleshooting

### Common Issues

#### Services can't communicate

**Problem:** Container A cannot reach Container B on the same network.

**Solution:**
```bash
# Ensure both containers are on the same network
docker network inspect proxy_network | grep -E '"Name"|"Containers"'

# Add to network if missing
docker network connect proxy_network [container-name]

# Test DNS resolution
docker exec [container-a] ping [container-b-hostname]
```

#### Port already in use

**Problem:** `Error: bind: address already in use`

**Solution:**
```bash
# Find process using the port
lsof -i :80
# or
netstat -tlnp | grep :80

# Kill the process or change docker-compose port mapping
# Edit docker-compose.yml and restart
docker-compose down && docker-compose up -d
```

#### Out of disk space

**Problem:** Containers can't write data; deployments fail.

**Solution:**
```bash
# Check disk usage
df -h /opt/docker /mnt/media

# Identify large files
du -sh /mnt/media/* | sort -h

# Prune Docker
docker system prune -a --volumes

# Clean old logs
docker exec [container-name] rm -f /var/log/*.log

# Consider expanding storage or moving data to another disk
```

#### Nextcloud can't connect to database

**Problem:** Nextcloud container exits with database connection error.

**Solution:**
```bash
# Check MariaDB logs
docker-compose logs nextcloud-database

# Verify database credentials in nextcloud.env
cat nextcloud.env

# Ensure MariaDB is running and healthy
docker ps | grep mariadb

# Restart the stack in order
docker-compose down
docker-compose up -d --wait
```

#### Home Assistant can't see Docker or other services

**Problem:** Home Assistant VM can't communicate with Docker containers or host.

**Solution:**
```bash
# From Home Assistant VM, test connectivity to host
ping 192.168.0.10

# Test DNS resolution
nslookup docker.local  # or use IP

# Check firewall on Debian host
sudo ufw status
sudo ufw allow from 192.168.0.0/24  # Allow LAN

# If using Unix socket mount, check permissions
ls -la /var/run/docker.sock
# May need: sudo chmod 666 /var/run/docker.sock (not recommended long-term)
```

#### NPM returns "Service Unavailable"

**Problem:** 502 Bad Gateway from Nginx Proxy Manager.

**Solution:**
```bash
# Check NPM logs
docker-compose logs npm

# Verify upstream service is running
docker ps | grep [service-name]

# Check if service is listening on expected port
docker exec [service-name] ss -tlnp | grep LISTEN

# Check upstream configuration in NPM UI (Admin Panel → Proxy Hosts)
# Ensure hostname resolves (use container name for internal Docker DNS)
docker exec npm ping [container-name]
```

### Getting Help

1. **Check logs first:** `docker-compose logs -f [service]`
2. **Review per-service README** for troubleshooting tips
3. **Check .env configuration** for typos or missing variables
4. **Inspect containers:** `docker inspect [container-name]`
5. **Test connectivity:** `docker exec [container] ping [host/service]`
6. **Search GitHub issues** or post in Docker/Homelab communities

---

## 📖 Additional Resources

- **Docker Compose Documentation:** https://docs.docker.com/compose/
- **Nginx Proxy Manager Docs:** https://nginxproxymanager.com/
- **Pi-hole Documentation:** https://docs.pi-hole.net/
- **Nextcloud Admin Guide:** https://docs.nextcloud.com/server/stable/admin_manual/
- **Syncthing Setup Guide:** https://docs.syncthing.net/
- **Home Assistant Documentation:** https://www.home-assistant.io/docs/
- **TP-Link ER605 OpenVPN Setup:** https://www.tp-link.com/us/support/download/er605/

---

## 📝 License

This project is provided as-is for personal use. No warranty or support is guaranteed.

---

## 🤝 Contributing

This is a **personal homelab configuration**. Contributions are not expected, but if you find issues or have improvements:

1. Review the [.gitignore](./.gitignore) to ensure no secrets are committed
2. Test thoroughly in a non-production environment
3. Document changes clearly

---

**Last Updated:** December 2025 | **Status:** Active

For questions or feedback, refer to the individual service READMEs or review your Docker logs.
