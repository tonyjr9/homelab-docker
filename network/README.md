# Network Stack

Back to [Main README](../README.md)

The network stack provides the reverse proxy, Pi-hole DNS/ad blocking, DuckDNS updates, and an optional server-side WireGuard fallback. The Ubiquiti gateway (small UGM) is the primary VPN, routing, and firewall device.

## Services

| Service | Port | Purpose |
|---------|------|---------|
| **Nginx Proxy Manager** | 80 / 443 / 81 | Reverse proxy and Let's Encrypt TLS |
| **Pi-hole** | 53 / 80 / 443 | DNS resolution and ad blocking |
| **DDNS Updater** | 8000 | Keeps DuckDNS in sync with the WAN IP |
| **WireGuard (wg-easy)** | 51820/udp, 51821/tcp | Server-side VPN fallback |

The old Docker OpenVPN definition is preserved in [`docker-compose.yml.unused`](./docker-compose.yml.unused), but is not part of the active stack.

## IP assignment

| Variable | Purpose | Example |
|----------|---------|---------|
| `MAIN_IP` | Main server address | `192.168.2.102` |
| `NPM_IP` | Nginx Proxy Manager address | `192.168.2.197` |
| `PIHOLE_IP` | Pi-hole address | `192.168.2.198` |

These addresses require the corresponding host addresses to be configured on the server's primary interface.

## Quick start

```bash
cp .env.example .env
# Set MAIN_IP, NPM_IP, PIHOLE_IP, DUCKDNS_DOMAIN, DUCKDNS_TOKEN, and passwords.
docker compose up -d
```

## Access

- NPM admin: `http://${NPM_IP}:81` — change the default password immediately.
- Pi-hole: `http://${PIHOLE_IP}/admin`
- DDNS UI: `http://${MAIN_IP}:8000`

## DNS and VPN

Point the Ubiquiti gateway's LAN DNS (or individual clients) to `${PIHOLE_IP}`. Pi-hole remains the preferred DNS service; Ubiquiti DNS features are the fallback.

The Ubiquiti gateway owns the primary VPN endpoint. Keep `wg-easy` stopped unless the router VPN is unavailable or a server-terminated tunnel is specifically required. WireGuard clients should use `${PIHOLE_IP}` as their DNS server.

## NPM setup

1. Log in and change the default admin password.
2. Add proxy hosts that forward to container names on `proxy_network`.
3. Enable Let's Encrypt, force SSL, and test each host.

## Firewall

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 51820/udp
sudo ufw enable
```

## Backup and maintenance

```bash
docker compose pull && docker compose up -d
docker compose logs -f npm
docker compose logs -f pihole
tar -czf wireguard-backup-$(date +%Y%m%d).tar.gz wireguard-data/
```

Keep `.env`, VPN keys, Pi-hole data, and NPM certificates out of version control. See the repository root [`.gitignore`](../.gitignore).

---
Updated October 2026.
