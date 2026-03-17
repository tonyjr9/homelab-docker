# Network Services (Nginx Proxy Manager, Pi-hole, DDNS, OpenVPN)

Back to [Main README](../README.md)

Production networking stack: reverse proxy/TLS, DNS/adblock, dynamic DNS, optional VPN.

[![Docker Compose](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://docs.docker.com/compose/)

## Services

- **Nginx Proxy Manager**: Proxy/TLS (Let's Encrypt).
- **Pi-hole**: DNS/ad-blocking.
- **DDNS Updater**: DuckDNS sync.
- **OpenVPN** (opt): Remote access.

## Quick Start

```bash
cp .env.example .env  # Edit NPM_IP, PIHOLE_IP, etc.
docker compose up -d
```

## Environment (.env.example)

```
NPM_IP=192.168.0.197
PIHOLE_IP=192.168.0.198
PIHOLE_PASSWORD=strongpass
DUCKDNS_DOMAIN=your.duckdns.org
DUCKDNS_TOKEN=token
TZ=Europe/Lisbon
```

## Access

- NPM Admin: http://NPM_IP:81 (default changeme → reset).
- Pi-hole: http://PIHOLE_IP/admin.
- DDNS UI: http://host:8000.

## Deployment Details

See docker-compose.yml: Dedicated IPs, proxy_network.

### NPM Setup
1. Login default.
2. Proxy Hosts → Add → Domain/Forward (container:port).
3. SSL: Let's Encrypt/Force SSL.

### Pi-hole
DNS to PIHOLE_IP LAN-wide.

## Maintenance

```
docker compose pull && docker compose up -d
docker compose logs -f npm
```

## Troubleshooting

502: Upstream ping from npm.
No DNS: netstat pihole:53.

---
Updated Jan 2026.
