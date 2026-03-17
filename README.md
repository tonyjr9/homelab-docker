# Homelab Docker Stack

Personal homelab built with Docker Compose for media, networking, cloud storage, dashboards, and gaming. Remote access via TP-Link ER605 OpenVPN; Home Assistant runs as a KVM/libvirt VM on the same Debian host.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
![Platform: Linux](https://img.shields.io/badge/Platform-Linux-blue.svg)
![Docker: Compose](https://img.shields.io/badge/Docker-Compose-2496ED?logo=docker)

## Table of Contents

- [Hardware](#hardware)
- [Architecture](#architecture)
- [Services](#services)
- [Quick Start](#quick-start)
- [System Configuration](#system-configuration)
- [Storage Layout](#storage-layout)
- [Management Script](#management-script)
- [Useful Commands](#useful-commands)
- [Troubleshooting](#troubleshooting)

---

## Hardware

| Component | Details |
|-----------|--------|
| **Host OS** | Debian 13 — bare-metal or VM (e.g. Proxmox); i7-8700H, 40 GB RAM, 256 GB NVMe |
| **Storage** | 1× 12 TB HDD (planned: RAID 10/ RAID 5 with 4× HDDs) |
| **Hypervisor** | KVM/libvirt (virt-manager) — hosts Home Assistant VM (2 vCPU, 4 GB RAM) |
| **Router** | TP-Link ER605 — OpenVPN server, DDNS, port forwarding, Gigabit LAN |

---

## Architecture

```
INTERNET
    |
    | OpenVPN (UDP 1194)
    |
TP-Link ER605 (192.168.0.1)
    |
192.168.0.0/24 LAN
    |
Debian Server (192.168.0.102 · 192.168.0.197 NPM · 192.168.0.198 Pi-hole)
    |
    +-- Docker Stack (proxy_network)
    |   ├── Nginx Proxy Manager  :80/443/81  (192.168.0.197)
    |   ├── Pi-hole              :53/80      (192.168.0.198)
    |   ├── DDNS Updater         :8000
    |   ├── OpenVPN              :1194/udp
    |   ├── Homarr               :7575
    |   ├── Dashdot              :3001
    |   ├── Transmission         :9091
    |   ├── Plex                 (host network)
    |   ├── Jellyfin             :8096
    |   ├── Radarr / Sonarr / Prowlarr / Overseerr
    |   ├── Seafile + MariaDB + Memcached
    |   ├── Syncthing            :8384
    |   └── Minecraft            :25565
    |
    +-- KVM/libvirt VM
    |   └── Home Assistant       :8123
    |
    +-- Cloudflare Tunnel (external CRUD app, no port forwarding)
```

### Access patterns

| Method | Example |
|--------|---------|
| Local via NPM | `https://subdomain.domain.duckdns.org` |
| Local direct IP | `http://192.168.0.102:7575` |
| Remote VPN | Connect to ER605 → use internal IPs |
| Public (optional) | Domain via NPM + Let's Encrypt, or Cloudflare Tunnel |

---

## Services
Click on the directory to see the corresponding README

| Stack | Directory | Details |
|-------|-----------|--------|
| Reverse proxy, Pi-hole, DDNS, OpenVPN | [`network/`](./network/README.md) | Core networking |
| Homarr dashboard, Dashdot | [`dashboard/`](./dashboard/README.md) | Dashboards & monitoring |
| Seafile (+ MariaDB + Memcached) | [`cloud/`](./cloud/README.md) | Self-hosted cloud storage |
| Transmission, Plex, Jellyfin, Radarr, Sonarr, Prowlarr, Overseerr | [`media/`](./media/README.md) | Media & downloads |
| Syncthing | [`syncthing/`](./syncthing/README.md) | Peer-to-peer file sync |
| Minecraft | [`minecraft/`](./minecraft/README.md) | Game server |

> Home Assistant runs as a KVM/libvirt VM — not in Docker. See [System Configuration](#system-configuration).

---

## Quick Start

### Prerequisites

- Debian 12+ with Docker and the Compose plugin installed ([guide](https://docs.docker.com/engine/install/debian/#install-using-the-repository)).
- 2+ CPU cores, 4+ GB RAM minimum (8+ GB recommended for media transcoding).
- Sufficient storage: 50 GB+ for services, more for media.

### 1. Clone

```bash
git clone https://github.com/tonyjr9/homelab-docker.git /opt/docker
cd /opt/docker
```

### 2. Configure environment

```bash
cp .env.example .env
vim .env
```

Each service directory also has its own `.env.example`.

### 3. Create shared network (once)

```bash
docker network create proxy_network
```

### 4. Start services

```bash
# Recommended order
cd network   && docker compose up -d && cd ..
cd dashboard && docker compose up -d && cd ..
cd cloud     && docker compose up -d && cd ..
cd media     && docker compose up -d && cd ..
cd syncthing && docker compose up -d && cd ..
cd minecraft && docker compose up -d && cd ..
```

### 5. Verify

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
```

---

## System Configuration

### Required packages

```bash
sudo apt install htop iotop curl wget git
sudo apt install qemu-kvm libvirt-daemon-system virt-manager  # Home Assistant VM
sudo apt install cpufrequtils  # optional power management
```

### User permissions

```bash
sudo usermod -aG docker "$USER"
sudo usermod -aG libvirt "$USER"
```

### HDD spindown (`/etc/rc.local`)

```bash
#!/bin/bash
hdparm -S 120 /dev/sda  # spin down after 10 min
for cpu in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo "schedutil" > "$cpu" 2>/dev/null
done
exit 0
```

Result: HDD sleeps ~90% of the time at idle. Note: enterprise/NAS drives (Seagate, WD Red) may ignore spindown by design.

### Service polling optimisation

- **Transmission** — stop seeding at ratio 0.1; pause if idle > 5 min.
- **Radarr/Sonarr** — check for finished downloads every 120+ min.
- **RSS polling** — disabled; manual refresh preferred.
- **Webhooks** — trigger scans only on download completion (in test phase).

### Home Assistant VM

```bash
virt-manager &          # GUI
virsh list              # list VMs
virsh start home-assistant
```

Access: `http://192.168.0.109:8123` or via NPM reverse proxy.

---

## Storage Layout

```
/opt/docker/            # Compose configs (this repo)
├── network/
├── dashboard/
├── cloud/
├── media/
├── syncthing/
├── minecraft/
└── .env

/mnt/media/             # Large files (HDD)
├── media/
│   ├── movies/
│   ├── tvseries/
│   └── transmission/downloads/
├── cloud/seafile/
└── backups/
```

Monitor:

```bash
du -sh /mnt/media/*
df -h /mnt/media
```

---

## Management Script

> In development.

```bash
sudo cp /opt/docker/manage.sh /usr/local/bin/manage.sh
sudo chmod +x /usr/local/bin/manage.sh
echo "alias manage='sudo /usr/local/bin/manage.sh'" >> ~/.zshrc
```

Features: start/stop stacks, system monitoring, HDD spindown, Nextcloud/Minecraft backups, log viewer.

---

## Useful Commands

```bash
# Container overview
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Logs
docker compose logs -f [service]

# Update all images
docker compose pull && docker compose up -d

# Prune unused resources
docker system prune -a --volumes

# Disk monitoring
sudo hdparm -C /dev/sda
sudo iotop -aoP
```

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Containers can't communicate | `docker network inspect proxy_network` — verify both are on the same network |
| Port already in use | `lsof -i :<port>` — stop the conflicting process or change the mapping |
| Out of disk space | `docker system prune -a --volumes` then check `df -h /mnt/media` |
| HDD won't spin down | `sudo iotop -aoP` — common culprits: Transmission seeding, frequent arr scans |
| NPM 502 | `docker compose logs npm` — verify upstream container is running |

---

## Resources

- [Docker Compose docs](https://docs.docker.com/compose/)
- [Nginx Proxy Manager](https://nginxproxymanager.com/)
- [Pi-hole](https://docs.pi-hole.net/)
- [Seafile](https://manual.seafile.com/)
- [Syncthing](https://docs.syncthing.net/)
- [Home Assistant](https://www.home-assistant.io/docs/)
- [TP-Link ER605](https://www.tp-link.com/us/support/download/er605/)

---

**Last Updated:** March 2026 | **Status:** Active
