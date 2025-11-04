# Network & Proxy Services

Reverse proxy, SSL termination, and DNS services. External remote access to the homelab is provided through a TP‑Link ER605 running an OpenVPN server.

## Services

### Nginx Proxy Manager
- Ports: 80 (HTTP), 443 (HTTPS), 81 (Admin)
- Access: http://server-ip:81

### Pi-hole
- Ports: 80 (Web), 53 (DNS)
- Access: http://server-ip/admin

## Environment
Create `.env`:
```
NPM_IP=192.168.0.10X
PIHOLE_IP=192.168.0.10X
PIHOLE_PASSWORD=your_secure_password
TZ=Europe/Lisbon
CONFIG_PATH=/opt/docker
```

## Notes
- Certificates (Let's Encrypt) are stored under `./letsencrypt`
- Pi-hole config persists under `./etc-pihole` and `./etc-dnsmasq.d`
- Both services attach to `proxy_network`
