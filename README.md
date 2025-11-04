# 🏠 Homelab Docker Stack

A production-ready personal homelab built with Docker Compose: media, networking, files, monitoring, and security. External access via TP‑Link ER605 OpenVPN; Home Assistant runs as a VM on the same Debian host.

- Keep all secrets in local `.env` files (never commit)
- Use `server-ip` or `192.168.0.10X` in examples

## 📦 Services Overview

- Management: Portainer, Homarr
- Networking: Nginx Proxy Manager, Pi‑hole (DNS/ad‑block)
- Media/Downloads: Transmission (integrates with *arr if/when added)
- Files/Sync: Nextcloud (MariaDB + Redis), Syncthing
- Automation: Home Assistant VM (outside Docker)

## 🗺️ Architecture

```
Internet → TP‑Link ER605 (OpenVPN) → Debian Server
                                 ├── Home Assistant VM (8123)
                                 └── Docker (proxy_network)
                                     ├── Nginx Proxy Manager (80/443/81)
                                     ├── Pi‑hole (53/80)
                                     ├── Homarr (7575)
                                     ├── Transmission (9091/51413)
                                     ├── Nextcloud stack (8080 + DB/Redis)
                                     └── Syncthing (if exposed)
```

## 🚀 Quick Start

1) Bring up networking first
```bash
cd proxy && docker-compose up -d && cd ..
```
2) Dashboard and management
```bash
cd dashboard && docker-compose up -d && cd ..
```
3) Core services
```bash
cd transmission && docker-compose up -d && cd ..
cd nextcloud && docker-compose up -d && cd ..
cd syncthing && docker-compose up -d && cd ..
```

## 🌐 Networking
- Connect via OpenVPN on TP‑Link ER605 for secure remote access
- Terminate TLS in Nginx Proxy Manager; forward to services on `proxy_network`
- Pi‑hole serves local DNS (and optionally VPN clients)

## 🏠 Home Assistant VM
- Runs alongside Docker on the Debian host
- Typical access: http://server-ip:8123
- Optionally place behind NPM (prefer VPN for remote access)

## 🔐 Security
- Move all passwords/tokens to `.env` files; never commit secrets
- Restrict public exposure; prefer VPN + NPM access lists + TLS
- Regularly update containers and OS; monitor with your preferred tools

## 💾 Storage Layout (example)
```
/opt/docker/               # per‑service configs
/mnt/media/nextcloud/      # Nextcloud config/data/db
/mnt/media/media/          # downloads, movies, tvseries, etc.
```

## 🧰 Useful Commands
```bash
docker-compose up -d
docker-compose logs -f [service]
docker-compose pull && docker-compose up -d
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

## 📚 Per‑Service Docs
See README.md files inside each service directory for env, volumes, and setup.

— Personal configuration — no contributions section.