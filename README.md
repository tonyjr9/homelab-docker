# Homelab Docker Stack

Production-ready personal homelab built with Docker Compose for media, networking, files, monitoring, and automation. Remote access via TP-Link ER605 OpenVPN; Home Assistant runs as a KVM/libvirt VM on the same Debian host.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)
![Docker: Compose](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)

## Table of Contents

- [Host Infrastructure](#host-infrastructure)
- [Network Configuration](#network-configuration)
- [Architecture](#architecture)
- [Service Documentation](#service-documentation)
- [System Configuration](#system-configuration)
- [Storage Architecture](#storage-architecture)
- [Quick Start](#quick-start)
- [Management Script](#management-script)
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
| **Host OS** | Debian 13 | Bare-metal or Debian VM on Proxmox/other hypervisor; i7-8700H, 40GB RAM, 1x 256GB NVMe SSD |
| **Storage** | HDD Array | Currently 1x 12TB (future: RAID 10 or RAID 5 with 4x HDDs) |
| **Hypervisor** | KVM/libvirt (virt-manager) | Hosts Home Assistant VM (2 vCPU, 4GB RAM) |
| **Router/Gateway** | TP-Link ER605 | OpenVPN server (fallback), DDNS, port forwarding, Gigabit LAN |

> The stack assumes a Debian server environment. This can be a bare-metal Debian install or a Debian VM (for example on Proxmox or another hypervisor). Home Assistant runs in a separate KVM/libvirt VM managed by virt-manager, but any VM host providing a Debian guest works.


**Storage Expansion Plan:**
Current single 12TB HDD will be replaced with RAID 10 (4x HDDs) for redundancy and performance. This provides fault tolerance with up to 2x disk failures.

### System-Level Configuration

#### HDD Spindown & Power Management

File: `/etc/rc.local`

```bash
#!/bin/bash

# HDD spindown after 10 minutes
hdparm -S 120 /dev/sda

# CPU power saving (scales dynamically based on load)
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "schedutil" > "$cpu" 2>/dev/null
done

exit 0
```

**Behavior:**
- HDD automatically spins down after 10 minutes of inactivity
- CPU scales from 800 MHz (idle) to 4.6 GHz (under load)
- Reduces power consumption by 10–15 W at idle
- No noticeable performance impact under load (Minecraft, downloads, etc.)

#### Service Spindown Optimization

Transmission seeding and Radarr/Sonarr constant polling were reduced:

1. **Transmission** – Stop seeding at ratio 0.1 and pause if idle > 5 minutes.
2. **Radarr/Sonarr** – Check for finished downloads every 120+ minutes (instead of 1 minute).
3. **RSS Polling** – Disabled (manual rss refresh preferred, when you add a film or series it rss polls once so this will only impact series that are not present in your indexer of choice, I preffer to do the recheck manually as for me there is no need of refrefreshing all the time).
4. **Webhook Notifications** – Trigger scans only on download completion, that garentees that the media is moved to plex directory asap.


Notes:
* Webhook is not working very well right now will update the repo as soon as I solve it 

Result: The HDD sleeps ~90% of the time, and the system is virtually silent at idle.
In my case the HDD I use is seagate enterprise level, like WD nas hdd's they are designed to be running 24/7 and most times they don't allow spindown. Sp the spindown only works for some types of hdd.

#### System Monitoring

Monitor disk activity in real time:

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

## Network Configuration

### IP Address Management

**Multiple IPs configured on the host for service isolation:**

| Service | IP Address | Purpose |
|---------|-----------|----------|
| **Debian Server** | 192.168.0.102 | Docker services, internal routing |
| **Nginx Proxy Manager** | 192.168.0.197 | Reverse proxy |
| **Pi-hole** | 192.168.0.198 | DNS resolution, ad-blocking |
| **Home Assistant VM** | 192.168.0.109 | KVM/libvirt managed, accessible via proxy |

**Network configuration (example):**
```bash
# Multiple IPs configured on the primary network interface as its needed because services like nextcloud, pihole and nginx need to use 80 as internal exposed port and to run all at once they need to be in different IP's
# Allows service-specific routing and isolation
# Managed via NetworkManager 
```

**TP-Link ER605 gateway:**
- LAN IP: 192.168.0.1
- OpenVPN server network: 192.168.X.0/24 (IP pool of connected devices)(remote access)
- DDNS: <duckdns-domain>.duckdns.org

---

## Architecture

### Network Topology

```
INTERNET (Tor / Remote Access)
    |
    | OpenVPN (port 1194)
    |
TP-Link ER605 (192.168.0.1)
    | OpenVPN server: 10.0.0.0/24
    | DDNS gateway: vpn.duckdns.org
    |
192.168.0.0/24 LAN
    |
Debian Server (192.168.0.102 primary, 192.168.0.197/198 for proxy/DNS)
    |
    +-- Docker Stack (proxy_network)
    |   ├── Nginx Proxy Manager (80/443/81)
    |   ├── Pi-hole (53/80)
    |   ├── Homarr Dashboard (7575)
    |   ├── Transmission (9091/51413)
    |   ├── Nextcloud + MariaDB + Redis
    |   ├── Syncthing (22000/21027)
    |   ├── Minecraft Server (25565)
    |   └── Media services (expandable)
    |
    +-- KVM/libvirt VM
    |   └── Home Assistant (8123)
    |
    +-- External CRUD application
        └── Cloudflared public site (via tunnel)
```

### Cloudflared Public Application

A public website or application is self-hosted via Cloudflare Tunnel (cloudflared):
- Located in a separate directory (not in `/opt/docker`).
- Uses Cloudflare tunnels for secure public access.
- No firewall port forwarding required.
- Accessible via a public domain.

Configuration and deployment are independent from the Docker stack.

### Access Patterns

**Local LAN**
- Using domain name, and nginx: `https://subdomain.domain.duckdns.org`
Example: `https://dashboard.domain.duckdns.org` (I use a free domain from duck dns, but I don't expose that to the open web with port forwarding)
- Direct IP: `http://192.168.0.102:7575` (Homarr).
- Docker internal: `http://homarr:7575` (via container DNS, doens't work on browser).
- Hostname (if configured): `http://homelab.local:7575`.

**Remote VPN (hardware gateway)**
- Connect to TP-Link ER605 OpenVPN (`vpn.duckdns.org`).
- Access via homelab IPs: `http://homelab-ip:7575` (Homarr), `https://subdomain.domain`

**Public domains (optional)**
- I recommend using a paid domain.
- Exposed via Nginx Proxy Manager reverse proxy.
- Secured with Let's Encrypt TLS certificates.
- Example: `https://dashboard.yourdomain.com`.
- The most secure way to do this is purchase a cloudflare domain and use cloudflare tunnels that don't need port forwarding and that way you don't even need nginx as cloudflare manages the proxy for you

---

## Service Documentation

Each Docker service has dedicated documentation:

### Core Networking
- **[Nginx Proxy Manager, Pi-hole, DDNS](./proxy/README.md)**
  - Reverse proxy with TLS termination.
  - DNS resolution and ad-blocking.
  - Dynamic DNS updates.

### Dashboards & Monitoring
- **[Homarr Dashboard & Beszel](./dashboard/README.md)**
  - Unified service dashboard.
  - System resource monitoring.

### Cloud Storage
- **[Nextcloud Stack (Nextcloud + MariaDB + Redis)](./nextcloud/README.md)**
  - Self-hosted file sync and sharing.
  - Database and caching layer.
  - Backup and restore procedures.

### Media & Downloads
- **[Media Services (Transmission + expandable)](./media/README.md)**
  - Torrent downloading with event-driven scanning.
  - Ready for arr stack, Plex and transmission.
  - Webhook integration for automatic imports (in progress).

### File Synchronization
- **[Syncthing](./syncthing/README.md)**
  - Peer-to-peer file sync.
  - Multi-device synchronization.

### Games & Recreation
- **[Minecraft Server](./minecraft/README.md)**
  - Java Edition server with a persistent world.
  - Performance tuning for homelab.
  - Backup and restore.

---

## System Configuration

### Debian Host Setup

#### Required Packages


[Install docker](https://docs.docker.com/engine/install/debian/#install-using-the-repository)

```bash

# System utilities
sudo apt install htop iotop curl wget git

# KVM/libvirt for Home Assistant
sudo apt install qemu-kvm libvirt-daemon-system virt-manager

# Power management (optional, for advanced scaling)
sudo apt install cpufrequtils

```

#### User Permissions

```bash
# Add user to docker group (avoid sudo for Docker commands)
sudo usermod -aG docker "$USER"
newgrp docker

# Add user to libvirt group (for virt-manager)
sudo usermod -aG libvirt "$USER"
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

You can also use a vnc server running on debian host and connect to the UI of the server via some VNC viewer, for that you need to install xfce for example in Debian host

**Access:**
- Local: `http://192.168.0.102:8123`.
- Via NPM reverse proxy: `https://home.yourdomain.com`.

**Integration with Docker:**
- Home Assistant can discover Docker containers via the Docker integration.
- Configure in Home Assistant UI: Settings > Integrations > Docker.

---

## Storage Architecture

### Current Layout

```
/opt/docker/                           # Docker Compose configurations
├── proxy/                             # Nginx, Pi-hole, DDNS, OpenVPN, DDNS updater
├── dashboard/                         # Homarr, Beszel
├── nextcloud/                         # Nextcloud, MariaDB, Redis
├── media/                             # Transmission, media services
├── syncthing/                         # File sync
├── minecraft/                         # Game server
├── docker-compose.yml                 # Optional root-level orchestration (if used)
└── .env                               # Global secrets/config (not tracked)

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
│   ├── config/                        # Nextcloud configuration
│   ├── data/                          # User files
│   └── db/                            # MariaDB data
└── backups/                           # Backup destination
```

### Storage Notes

**Current:** 1x 12TB HDD (suitable for development/testing).

**Future upgrade:** RAID array with 4x HDDs for:
- Redundancy: Survives certain 2-disk failure scenarios depending on raid config.
- Performance: Improved reads/writes.
- Capacity: Scales with a growing media library.


Monitor disk usage:

```bash
du -sh /mnt/media/*                   # Per-folder usage
df -h /mnt/media                      # Overall free space
```

---

## Quick Start

### Prerequisites

- Debian 12+ server (bare-metal or Debian VM on Proxmox/other hypervisor) with Docker and the Docker Compose plugin.
- 2+ CPU cores, 4+ GB RAM minimum.
- Network connectivity to your home router or gateway (TP-Link ER605 in this example).
- Sufficient storage: 50 GB+ for services, additional capacity for media.

**Performance note:** These minimum specs support core services (dashboards, file sync, light downloads). For demanding workloads such as real-time media transcoding (Plex/Jellyfin), heavy Minecraft multiplayer, or intensive automation, consider 4+ CPU cores and 8+ GB RAM to avoid performance bottlenecks.

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
vim .env
```

Each service directory also has `.env.example` for service-specific variables.

### 3. Create Networks (one time)

```bash
docker network create proxy_network
```

### 4. Start Services (recommended order)

```bash
# 1. Networking (gateway for all services)
cd proxy && docker compose up -d && cd ..

# 2. Dashboard and monitoring
cd dashboard && docker compose up -d && cd ..

# 3. Core services
cd nextcloud && docker compose up -d && cd ..
cd syncthing && docker compose up -d && cd ..

# 4. Optional media services
cd media && docker compose up -d && cd ..

# 5. Optional Minecraft
cd minecraft && docker compose up -d && cd ..
```

### 5. Verify

```bash
# Check all containers running
docker ps --format "table {{.Names}}	{{.Image}}	{{.Status}}	{{.Ports}}"

# Check specific logs
docker compose logs npm -f
```

---

## Management Script
(In development)
A comprehensive interactive management script is provided for easy homelab administration.

### Features

- **Docker services**: Start, stop, and restart all services or individual stacks.
- **System monitoring**: HDD status, disk I/O, container resources, network connections.
- **Power management**: Force HDD spindown, check CPU governor, view power configuration.
- **Maintenance**: Clean Docker, back up Nextcloud/Minecraft, check for image updates.
- **Logs and debugging**: View logs, test connectivity, check webhooks.

### Installation

```bash
# Copy script to system path
sudo cp /opt/docker/manage.sh /usr/local/bin/manage.sh

# Make executable
sudo chmod +x /usr/local/bin/manage.sh

# Create convenient alias
echo "alias manage='sudo /usr/local/bin/manage.sh'" >> ~/.bashrc
source ~/.bashrc # or ~/.zshrc
```

### Usage

```bash
# Launch interactive menu
manage
```

Refer to the menu description in this README for available options.

---

## Directory Structure

```
/opt/docker/
├── .env                           # Configuration (not tracked)
├── .env.example                   # Template
├── .gitignore                     # Secrets protection
├── README.md                      # This file
├── manage.sh                      # Management script
│
├── proxy/                         # See proxy/README.md
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── README.md
│   └── data/                      # (not tracked)
│
├── dashboard/                     # See dashboard/README.md
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── README.md
│   └── configs/                   # (not tracked)
│
├── ittools/                       # Self-hosted IT tools (if enabled)
│   ├── docker-compose.yml
│   ├── .env.example
│   └── README.md (optional)
│
├── nextcloud/                     # See nextcloud/README.md
│   ├── docker-compose.yml
│   ├── nextcloud.env              # (not tracked)
│   ├── .env.example
│   ├── README.md
│   └── db/                        # (not tracked)
│
├── media/                         # See media/README.md
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── README.md
│   └── transmission/              # (not tracked)
│
├── syncthing/                     # See syncthing/README.md
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── README.md
│   └── config/                    # (not tracked)
│
├── minecraft/                     # See minecraft/README.md
│   ├── docker-compose.yml
│   ├── .env.example
│   ├── README.md
│   └── world/                     # (not tracked)
├── vpn/                           # Optional self-hosted OpenVPN server
│   ├── docker-compose.yml
│   ├── openvpn-data/              # PKI and server configuration (not tracked)
│   └── README.md (recommended)
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
DOCKER_SERVER_IP=192.168.0.102
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

# Optional for media services
# RADARR_API_KEY=your_key_here
# SONARR_API_KEY=your_key_here
# PLEX_CLAIM=claim-token_here
```

Each service may have a local `.env.example`. See individual READMEs for service-specific variables.

---

## Networking & Security

### UFW (host firewall)

Use UFW to restrict which ports on the Debian host are reachable from your LAN and from the internet.

#### 1. Install and enable UFW

```bash
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

#### 2. Allow core management access

```bash
# SSH (adjust port if you changed it)
sudo ufw allow 22/tcp

# OpenVPN from the internet (if you use the host)
sudo ufw allow 1194/udp
```

#### 3. Allow LAN access to services

```bash
sudo ufw allow PORT # For each service port

```

### Self-Hosted OpenVPN Server (Optional)

The `./vpn` directory deploys a Docker-based OpenVPN server for remote LAN access. Use this if you do not have a dedicated VPN gateway device (such as a TP-Link ER605).

- **Deployment:** `cd vpn && docker compose up -d` (after one-time PKI initialization).
- **Port:** Forward UDP port 1194 on your router to the Docker host IP and port defined in `vpn/docker-compose.yml`. If you change the external port, update the OpenVPN client configuration to match.
- **Details:** See the `vpn` directory for server initialization commands and client configuration generation.

If you are already using a hardware VPN gateway or another VPN solution (for example Tailscale or WireGuard), this directory can be ignored.
 
### Remote Access via OpenVPN (TP-Link ER605 or other gateway/router)

**Configuration on ER605 (example):**
1. Log in to the router web interface (default: `http://192.168.0.1`).
2. Navigate to **VPN > OpenVPN Server**.
3. Enable OpenVPN and generate certificates.
4. Configure the OpenVPN server to listen on UDP port 1194 (or another port of your choice).
5. If the ER605 is behind another router or NAT, forward the chosen UDP port from the upstream router to the ER605.
6. Download the generated `.ovpn` client configuration file from the ER605.

**Client remote line:**
- If you use a static public IP, set the `remote` line in the `.ovpn` file to:
  - `remote your-public-ip 1194`
- If you use a dynamic public IP, configure DDNS (for example DuckDNS via the DDNS updater in the proxy stack) and set:
  - `remote your-subdomain.duckdns.org 1194`

The port number in the `remote` line must match the public UDP port you exposed on the router.

**Connect from a remote client:**
```bash
# Use the .ovpn file exported from the ER605
openvpn --config your-config.ovpn

# Once connected, access services using internal IPs:
# http://homelab-ip:7575   (Homarr)
# http://ha-vm-ip:8123     (Home Assistant)
# etc.
```

**DDNS note:**
Using a DDNS name (for example `your-subdomain.duckdns.org`) instead of a raw IP helps when your ISP assigns a dynamic address. The `ddns-updater` container in the proxy stack keeps the DDNS record in sync with your current WAN IP.

### Reverse Proxy (Nginx Proxy Manager)

Nginx Proxy Manager (NPM) provides:
- TLS/SSL termination with Let's Encrypt.
- Port 80/443 consolidation.
- Access control and authentication.
- HTTP(S) routing for internal services.

Setup via NPM UI (`http://192.168.0.197:81` by default):
1. Sign in with the default admin user and immediately change the password.
2. Go to **Proxy Hosts** and add a new proxy host.
3. Configure domain, SSL certificate (Let's Encrypt), and upstream service.
4. Save and test.

### Pi-hole DNS

Pi-hole serves DNS to LAN and VPN clients:
- Blocks ads and known malicious domains.
- Logs DNS queries.
- Can host custom DNS records for internal services.

Access: `http://192.168.0.198/admin`.

### Security Best Practices

**Do:**
- Keep `.env` files with secrets out of version control.
- Use strong, unique passwords for each service.
- Enable TLS/SSL for all public-facing services.
- Restrict SSH access to authorized IPs.
- Regularly update containers: `docker compose pull && docker compose up -d`.
- Monitor logs for suspicious activity.
- Prefer VPN for remote access instead of exposing services directly to the internet.
- Review firewall rules: `sudo ufw status`.

**Don't:**
- Hardcode secrets in `docker-compose.yml`.
- Expose services without authentication.
- Use default passwords.
- Mount the Docker socket without access control.
- Keep sensitive backups inside the repository.
- Leave unnecessary ports open on the router or host firewall.

### .gitignore Coverage

Protected items:
- All `.env` files (secrets).
- Database files (`*.db`, `*.sql`).
- SSL/TLS certificates (`*.pem`, `*.key`).
- SSH keys and fingerprints.
- Runtime data directories (config, data, logs).
- Large media files.
- World saves and game data.

Allowed in Git:
- `docker-compose.yml` files that use environment variables.
- `.env.example` templates.
- READMEs and documentation.
- Monitoring and metric configuration files.

---

## Useful Commands

### Container Management

```bash
# List containers with details
docker ps --format "table {{.Names}}	{{.Image}}	{{.Status}}	{{.Ports}}"

# View logs
docker compose logs -f [service]     # Follow logs
docker logs [container-name] -n 50   # Last 50 lines

# Control services
docker compose restart [service]
docker compose stop [service]
docker compose up -d [service]

# Update all images
docker compose pull && docker compose up -d

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

# Monitor in real time
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

### Services cannot communicate

If one container cannot reach another:
```bash
# Verify both are on the same network (for example proxy_network)
docker network inspect proxy_network | grep -E '"Name"|"Containers"'

# Test connectivity
docker exec [container-a] ping [container-b]
```

### Port already in use

```bash
# Find the process using the port
lsof -i :80

# Change the port mapping in docker-compose.yml or stop the conflicting process
```

### Out of disk space

```bash
# Check usage
df -h /mnt/media
du -sh /mnt/media/* | sort -h

# Clean Docker
docker system prune -a --volumes
```

### HDD will not spin down

```bash
# Check what is accessing the drive
sudo iotop -aoP | head -20

# Common culprits: Transmission seeding, frequent Radarr/Sonarr scans
# Verify settings: Transmission > Pause All, Radarr/Sonarr scan intervals
```

### Nextcloud database connection fails

```bash
# Check MariaDB
ocker compose ps nextcloud-database
docker compose logs nextcloud-database

# Restart stack
docker compose down && sleep 2 && docker compose up -d
```

### Nginx Proxy Manager returns 502

```bash
# Check NPM logs
docker compose logs npm

# Verify upstream is running and reachable
docker exec npm ping [service]
```

---

## Resources

- Docker Compose: https://docs.docker.com/compose/
- Nginx Proxy Manager: https://nginxproxymanager.com/
- Pi-hole: https://docs.pi-hole.net/
- Nextcloud: https://docs.nextcloud.com/server/stable/admin_manual/
- Syncthing: https://docs.syncthing.net/
- Home Assistant: https://www.home-assistant.io/docs/
- TP-Link ER605: https://www.tp-link.com/us/support/download/er605/
- Minecraft Server: https://www.minecraft.net/en-us/download/server

---

**Last Updated:** March 2026 | **Status:** Active

For service-specific setup and configuration, see the individual READMEs linked above.
