# Network Stack

Back to [Main README](../README.md)

Core networking: reverse proxy with TLS, DNS/ad-blocking, dynamic DNS, and self-hosted OpenVPN.

[![Docker Compose](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://docs.docker.com/compose/)

## Services

| Service | Port | Purpose |
|---------|------|---------|
| **Nginx Proxy Manager** | 80 / 443 / 81 (admin) | Reverse proxy + Let's Encrypt TLS |
| **Pi-hole** | 53 / 80 | DNS resolution + ad-blocking |
| **DDNS Updater** | 8000 | Keeps DuckDNS in sync with WAN IP |
| **OpenVPN** | 1194/udp | Self-hosted VPN (optional if using ER605) |

## IP Assignment

Multiple IPs on the host are required because NPM, Pi-hole and any service binding to port 80 each need their own IP address.

| Service | IP |
|---------|----|
| Debian server / Docker | 192.168.0.102 |
| Nginx Proxy Manager | 192.168.0.197 |
| Pi-hole | 192.168.0.198 |

Configure extra IPs via NetworkManager on the primary interface.

## Quick Start

```bash
cp .env.example .env   # fill in NPM_IP, PIHOLE_IP, DUCKDNS_DOMAIN, DUCKDNS_TOKEN, etc.
docker compose up -d
```

## Environment (`.env.example`)

```
NPM_IP=192.168.0.197
PIHOLE_IP=192.168.0.198
PIHOLE_PASSWORD=strongpassword
DUCKDNS_DOMAIN=your-subdomain.duckdns.org
DUCKDNS_TOKEN=your-token
TZ=Europe/Lisbon
CONFIG_PATH=/opt/docker
```

## Access

- **NPM admin**: `http://192.168.0.197:81` — change default password immediately.
- **Pi-hole**: `http://192.168.0.198/admin`
- **DDNS UI**: `http://192.168.0.102:8000`

## NPM Setup

1. Log in and change the default admin password.
2. **Proxy Hosts → Add** — set domain, forward to `container-name:port`, enable Let's Encrypt.
3. Force SSL and test.

## Pi-hole Setup

Point your router's DNS (or individual clients) to `192.168.0.198`. Pi-hole logs all queries and blocks ads/malicious domains. It also pushes DNS to OpenVPN clients so they get ad-blocking while on VPN.

## OpenVPN (Docker — optional)

Use this if you do **not** have a hardware VPN gateway (e.g. TP-Link ER605). If you already use a hardware gateway, this service can be ignored.

### Initial setup

```bash
cd /opt/docker/network

# Generate config (replace with your DuckDNS domain)
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm \
  kylemanna/openvpn ovpn_genconfig -u udp://YOUR-DOMAIN.duckdns.org -n 192.168.0.198

# Init PKI (you will be prompted for a CA passphrase — store it safely)
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm -it \
  kylemanna/openvpn ovpn_initpki

docker compose up -d openvpn
```

### Add a client

```bash
# Create certificate (no password)
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm -it \
  kylemanna/openvpn easyrsa build-client-full CLIENTNAME nopass

# Export .ovpn file
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm \
  kylemanna/openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn
```

### Revoke a client

```bash
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm -it \
  kylemanna/openvpn easyrsa revoke CLIENTNAME
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm -it \
  kylemanna/openvpn easyrsa gen-crl
docker compose restart openvpn
```

### Client apps

- **Windows/macOS**: OpenVPN Connect or Tunnelblick
- **Linux**: `sudo openvpn --config CLIENTNAME.ovpn`
- **Android/iOS**: OpenVPN for Android / OpenVPN Connect

## Remote Access via TP-Link ER605

If using the router's built-in OpenVPN instead of the Docker container:

1. Router admin → **VPN → OpenVPN Server** → enable and generate certificates.
2. Forward UDP 1194 from upstream router to the ER605 if it's behind NAT.
3. Export `.ovpn` and set the `remote` line to your DDNS domain:
   ```
   remote your-subdomain.duckdns.org 1194
   ```
4. Connect: `openvpn --config your-config.ovpn`

## UFW Firewall

```bash
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 1194/udp    # OpenVPN
sudo ufw allow <port>      # per service as needed
sudo ufw enable
```

## Security Notes

- Keep `.env` out of version control.
- Use strong unique passwords for NPM and Pi-hole.
- Prefer VPN for remote access over direct port forwarding.
- Regularly update: `docker compose pull && docker compose up -d`.
- For public domains, the most secure option is a Cloudflare domain with Cloudflare Tunnels — no port forwarding needed and no NPM required.

## Backup

```bash
# Pi-hole gravity DB
docker cp pihole:/etc/pihole/gravity.db ./gravity_backup.db

# OpenVPN PKI (keep this safe — contains all certificates)
tar -czf openvpn-backup-$(date +%Y%m%d).tar.gz openvpn-data/
```

## Maintenance

```bash
docker compose pull && docker compose up -d
docker compose logs -f npm
docker compose logs -f pihole
```

## Troubleshooting

| Problem | Fix |
|---------|-----|
| NPM 502 | `docker exec npm ping <service>` — verify upstream is running and on `proxy_network` |
| No DNS resolution | `docker exec pihole netstat -tlnp` — check port 53 is listening |
| VPN connects but no internet | Verify Pi-hole is up; check `push "dhcp-option DNS"` in `openvpn.conf` |
| DuckDNS not updating | `docker compose logs ddns-updater` |

---
Updated March 2026.
