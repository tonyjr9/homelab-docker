# Proxy Services (Nginx Proxy Manager, Pi-hole, DDNS, OpenVPN)

Back to [Main README](../README.md)

This stack provides reverse proxying with TLS termination, network-wide DNS resolution and ad-blocking, a self-hosted OpenVPN server, and automatic DuckDNS updates.

## Services Included

- **Nginx Proxy Manager (NPM)**: Reverse proxy with Let's Encrypt SSL/TLS.
- **Pi-hole**: DNS resolver with ad-blocking for LAN and VPN clients.
- **OpenVPN (optional)**: Self-hosted OpenVPN server for remote access if you do not have a hardware VPN gateway.
- **DDNS Updater**: Automatic DuckDNS updates for dynamic WAN IPs.

## Docker Compose Overview

`proxy/docker-compose.yml` defines four services and their networks:

- Binds HTTP/HTTPS and NPM admin to a dedicated IP (`NPM_IP`).
- Binds Pi-hole HTTP/DNS to a dedicated IP (`PIHOLE_IP`).
- Runs OpenVPN on UDP port 1194 with persistent configuration in `openvpn-data/`.
- Runs `ddns-updater` to keep a DuckDNS subdomain updated with the current WAN IP.

```yaml
services:
  npm:
    container_name: npm
    image: 'jc21/nginx-proxy-manager:latest'
    restart: unless-stopped
    ports:
      - '${NPM_IP:-192.168.0.197}:80:80'   # Public HTTP port
      - '${NPM_IP:-192.168.0.197}:443:443' # Public HTTPS port
      - '${NPM_IP:-192.168.0.197}:81:81'   # Admin web port
    volumes:
      - ${CONFIG_PATH:-/opt/docker}/proxy/data:/data
      - ${CONFIG_PATH:-/opt/docker}/proxy/letsencrypt:/etc/letsencrypt
    networks:
      - pihole
      - proxy_network
      - apptjc_proxy_network
      - radarr_network

  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "${PIHOLE_IP:-192.168.0.198}:80:80/tcp"
      - "${PIHOLE_IP:-192.168.0.198}:443:443/tcp"
      - "${PIHOLE_IP:-192.168.0.198}:53:53/tcp"
      - "${PIHOLE_IP:-192.168.0.198}:53:53/udp"
    environment:
      TZ: ${TZ:-Europe/Lisbon}
      WEBPASSWORD: ${PIHOLE_PASSWORD}
      FTLCONF_dns_listeningMode: 'all'
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    restart: unless-stopped

  openvpn:
    image: kylemanna/openvpn
    container_name: openvpn
    ports:
      - "1194:1194/udp"
    volumes:
      - ./openvpn-data:/etc/openvpn
    cap_add:
      - NET_ADMIN
    restart: unless-stopped

  ddns-updater:
    image: qmcgaw/ddns-updater:latest
    container_name: ddns-updater
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ:-Europe/Lisbon}
      - PERIOD=5m
      - UPDATE_COOLDOWN_PERIOD=5m
      - CONFIG={"settings":[{"provider":"duckdns","domain":"${DUCKDNS_DOMAIN}","token":"${DUCKDNS_TOKEN}","ip_version":"ipv4"}]}
    volumes:
      - ./ddns/data:/updater/data
    ports:
      - 8000:8000
    restart: unless-stopped
    networks:
      - proxy_network

networks:
  pihole:
  proxy_network:
    external: true
  apptjc_proxy_network:
    external: true
  radarr_network:
    external: true
```

## Directory Structure

```text
proxy/
├── docker-compose.yml
├── README.md
├── .env.example              # Environment variables for this stack
├── data/                     # NPM config and certificates (not tracked)
├── letsencrypt/              # Let's Encrypt certs (not tracked)
├── etc-pihole/               # Pi-hole config (not tracked)
├── etc-dnsmasq.d/            # Pi-hole DNS config (not tracked)
└── ddns/
    └── data/                 # DDNS updater data (not tracked)
```

## Environment Variables

`proxy/.env.example` defines the key variables used by this stack:

```bash
# IPs bound on the host
NPM_IP=192.168.0.197
PIHOLE_IP=192.168.0.198

# Pi-hole
PIHOLE_PASSWORD=your_strong_password_here

# DuckDNS
DUCKDNS_DOMAIN=your-subdomain.duckdns.org
DUCKDNS_TOKEN=your_duckdns_token_here

# Timezone
TZ=Europe/Lisbon

# Paths (normally inherited from /opt/docker/.env)
CONFIG_PATH=/opt/docker
```

- `NPM_IP` and `PIHOLE_IP` must be additional IPs assigned to your Debian host.
- `PIHOLE_PASSWORD` sets the Pi-hole web UI admin password.
- `DUCKDNS_DOMAIN` is your DuckDNS subdomain (without `.duckdns.org`).
- `DUCKDNS_TOKEN` is the API token from your DuckDNS dashboard.

## Step-by-Step Deployment

### 1. Prepare IP Addresses on the Host

Assign additional IPs (for example `192.168.0.197` and `192.168.0.198`) to your Debian host using your preferred network tool (netplan, ifupdown, or systemd-networkd). These addresses must be reachable on your LAN and not used by other devices.

### 2. Create or Edit `.env`

From the repository root:

```bash
cp .env.example .env        # if not already created
vim .env                    # or nano .env
```

Ensure at least the following are set:

```bash
NPM_IP=192.168.0.197
PIHOLE_IP=192.168.0.198
PIHOLE_PASSWORD=change_me
DUCKDNS_DOMAIN=your-subdomain.duckdns.org
DUCKDNS_TOKEN=your_duckdns_token_here
TZ=Europe/Lisbon
CONFIG_PATH=/opt/docker
```

### 3. Start the Stack

```bash
cd proxy

# One-time: ensure external networks exist
# docker network create proxy_network

# Start services
docker compose up -d

# Verify
docker compose ps
```

You should now see `npm`, `pihole`, `openvpn`, and `ddns-updater` containers running.

## Access Points

### Nginx Proxy Manager

- **Admin Panel:** `http://192.168.0.197:81`
- **HTTP:** `http://192.168.0.197:80`
- **HTTPS:** `https://192.168.0.197:443`

Default credentials (change on first login): `admin@example.com` / `changeme`.

### Pi-hole

- **Dashboard:** `http://192.168.0.198/admin`
- **DNS:** `192.168.0.198:53` (UDP/TCP)

Configure your router or individual devices to use `192.168.0.198` as their DNS server.

### DDNS Updater

- **Web UI (optional):** `http://<host-ip>:8000` (if enabled in config; by default it is bound to the host).

Check logs:

```bash
cd proxy
docker compose logs ddns-updater
```

### OpenVPN (self-hosted)

The `openvpn` service exposes UDP port `1194` on the Docker host. To use it:

1. Initialize the OpenVPN PKI and server configuration in `vpn/openvpn-data` (see the `vpn` directory for detailed instructions).
2. Forward UDP port `1194` from your router to the Docker host IP.
3. Generate client profiles (`.ovpn` files) and distribute them to clients.

If you already use a hardware VPN gateway (for example ER605) or another VPN solution, this container can be left stopped.

## Nginx Proxy Manager Configuration

### Initial Setup

1. Open `http://192.168.0.197:81` in a browser.
2. Log in with default credentials and immediately change the admin email and password.
3. Optionally configure global settings (e.g., access lists, default certificates).

### Adding a Proxy Host

1. Go to **Proxy Hosts**.
2. Click **Add Proxy Host**.
3. Fill in:
   - **Domain Names:** e.g. `dashboard.yourdomain.com`.
   - **Scheme:** `http` or `https`.
   - **Forward Hostname/IP:** container name, e.g. `homarr`.
   - **Forward Port:** container port, e.g. `7575`.
   - Enable **Websockets Support** if the application needs it.
4. In the **SSL** tab:
   - Select **Request a new SSL certificate**.
   - Enable **Force SSL**.
   - Optionally enable **HSTS**.
5. Save and test.

## Pi-hole Configuration

1. Open `http://192.168.0.198/admin`.
2. Log in using the password defined in `PIHOLE_PASSWORD`.
3. Configure upstream DNS servers in **Settings > DNS**.
4. Enable or disable blocklists as desired.
5. Optionally add custom DNS records (local overrides) for internal services.

Test resolution from a host:

```bash
nslookup homarr 192.168.0.198
nslookup google.com 192.168.0.198
```

## DuckDNS / DDNS Updater

The `ddns-updater` container keeps your DuckDNS domain pointed at your current WAN IP.

- It reads configuration from the `CONFIG` environment variable in `docker-compose.yml`.
- It periodically calls the DuckDNS API using `DUCKDNS_DOMAIN` and `DUCKDNS_TOKEN`.

To verify it is working:

```bash
cd proxy
docker compose logs ddns-updater | tail -20

# Query DNS from outside your network (or using a public resolver)
dig your-subdomain.duckdns.org @8.8.8.8
```

If you use this DDNS name for OpenVPN or for public proxy hosts, make sure the DNS record matches your current public IP.

## Maintenance

### Update Containers

```bash
cd proxy
docker compose pull
docker compose up -d
```

### Backup Configurations

```bash
# NPM config and certificates
sudo tar -czf npm_backup.tar.gz data/ letsencrypt/

# Pi-hole configuration
sudo tar -czf pihole_backup.tar.gz etc-pihole/ etc-dnsmasq.d/
```

### View Logs

```bash
cd proxy

# All services
docker compose logs -f

# Specific service
docker compose logs -f npm
docker compose logs -f pihole
docker compose logs -f ddns-updater
```

## Troubleshooting

### NPM returns 502 Bad Gateway

**Symptom:** Upstream service is unreachable.

```bash
# Check if the service container is running
docker ps | grep [service-name]

# Test connectivity from NPM
docker exec npm ping [service-name]

# Inspect NPM logs
cd proxy
docker compose logs npm
```

Ensure you are using the container name (not the host IP) in the NPM upstream configuration when using Docker networking.

### Pi-hole not resolving DNS

```bash
cd proxy

# Verify Pi-hole is running
docker compose ps pihole

# Check if it is listening on port 53
docker exec pihole netstat -tlnp | grep 53

# Test from a client
nslookup google.com 192.168.0.198
```

### DDNS not updating

```bash
cd proxy

# Check DDNS logs
docker compose logs ddns-updater | tail -20

# Verify DUCKDNS_* values in the environment
cat ../.env | grep DUCKDNS
```

You can also test the DuckDNS API manually:

```bash
curl "https://www.duckdns.org/update?domains=your-subdomain&token=your-token&ip="
```

## Security Notes

- Change NPM default credentials immediately after first login.
- Use a strong `PIHOLE_PASSWORD` and rotate it periodically.
- Store DDNS tokens only in `.env` files (which are not committed).
- Restrict NPM admin access to your LAN or VPN where possible.
- Use HTTPS with Let's Encrypt for all internet-facing hosts.
- Consider enabling a host firewall such as UFW on the Debian server and only allowing the ports you actually need (for example 22/tcp for SSH, 80/443/81 for NPM from LAN, 53 for Pi-hole DNS, and 1194/udp for OpenVPN). See the UFW section in the main README for example rules.


---

For more information:
- [Nginx Proxy Manager Documentation](https://nginxproxymanager.com/)
- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [DuckDNS](https://www.duckdns.org/)
- [DDNS-Updater Documentation](https://github.com/qdm12/ddns-updater)
