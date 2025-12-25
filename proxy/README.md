# Proxy Services (Nginx Proxy Manager, Pi-hole, DDNS)

Back to [Main README](../README.md)

This stack provides network-wide DNS resolution, ad-blocking, and reverse proxy functionality with TLS termination.

## Services Included

- **Nginx Proxy Manager (NPM)**: Reverse proxy with Let's Encrypt SSL/TLS
- **Pi-hole**: DNS resolver with ad-blocking
- **DDNS Updater**: Automatic DuckDNS updates for dynamic WAN IP

## Directory Structure

```
proxy/
├── docker-compose.yml
├── README.md
├── data/                    # NPM config and certificates (not tracked)
├── letsencrypt/             # Let's Encrypt certs (not tracked)
├── etc-pihole/              # Pi-hole config (not tracked)
├── etc-dnsmasq.d/           # Pi-hole DNS config (not tracked)
└── ddns/data/               # DDNS data (not tracked)
```

## Environment Variables

```bash
# .env
NPM_IP=192.168.0.197
PIHOLE_IP=192.168.0.198
PIHOLE_PASSWORD=your_strong_password
DUCKDNS_DOMAIN=your-subdomain.duckdns.org
DUCKDNS_TOKEN=your_duckdns_token_here
TZ=Europe/Lisbon
```

## Quick Start

```bash
cd proxy
docker-compose up -d

# Verify
docker-compose ps
```

## Access Points

### Nginx Proxy Manager
- **Admin Panel**: http://192.168.0.197:81
- **HTTP**: http://192.168.0.197:80 (forwards to HTTPS if configured)
- **HTTPS**: https://192.168.0.197:443

Default credentials: admin@example.com / changeme

### Pi-hole
- **Dashboard**: http://192.168.0.198/admin
- **DNS**: 192.168.0.198:53 (UDP/TCP)

## Configuration

### Nginx Proxy Manager Setup

1. Access Admin Panel (port 81)
2. Change default password
3. Create proxy hosts for each service:
   - Domain name
   - Upstream service (http://service-name:port)
   - SSL certificate (Let's Encrypt)
   - Custom headers/caching as needed

### Pi-hole Setup

1. Access Dashboard (port 80)
2. Change password: Settings > Change Password
3. Configure upstream DNS: Settings > DNS > Upstream DNS Servers
4. Add custom DNS records if needed
5. Set on router as default DNS: 192.168.0.198

### DDNS Updater

Automatically updates DuckDNS with current WAN IP.

**Configuration via environment:**
- `DUCKDNS_DOMAIN`: Your subdomain (without .duckdns.org)
- `DUCKDNS_TOKEN`: Token from DuckDNS dashboard

Verify updates:
```bash
# Check DDNS logs
docker-compose logs ddns

# Query DuckDNS
dig @8.8.8.8 your-subdomain.duckdns.org
```

## Usage

### Adding a Proxy Host (NPM UI)

1. **Proxy Hosts** tab
2. Click **Add Proxy Host**
3. Fill in:
   - Domain names (space-separated)
   - Scheme: http or https
   - Upstream hostname/IP: service-name (uses Docker DNS)
   - Upstream port: container's listening port
   - Cache assets: optional
   - Websockets support: if needed
4. **SSL tab**
   - Request new SSL certificate
   - Check "Force SSL"
   - Enable HSTS if desired
5. **Save**

### DNS Resolution

Pi-hole resolves:
- External domains: Forwards to upstream DNS
- Internal services: Returns container IP (if configured)
- Blocked domains: Returns null reply (ads, trackers)

**Test from host:**
```bash
nslookup homarr 192.168.0.198    # Should resolve to container IP
nslookup google.com 192.168.0.198
```

### Remote Access via OpenVPN

Clients connected to TP-Link ER605 OpenVPN can access services:

1. NPM forwards to internal services
2. Pi-hole resolves DNS for VPN clients
3. Configure ER605 to use Pi-hole as DNS (Settings > DNS)

**Example from VPN:**
```bash
# After connecting to ER605 VPN
nslookup dashboard.yourdomain.com  # Pi-hole resolves
curl https://dashboard.yourdomain.com:443  # Via NPM proxy
```

## Troubleshooting

### NPM returns 502 Bad Gateway

**Symptom:** Upstream service unreachable

**Solution:**
```bash
# Check if service is running
docker ps | grep [service-name]

# Test connectivity from NPM
docker exec npm ping [service-name]

# Verify upstream config in NPM UI
# Use container name (not IP) for Docker DNS resolution

# Check service logs
docker-compose logs [service-name]
```

### Pi-hole not resolving DNS

**Symptom:** nslookup returns no response or timeout

**Solution:**
```bash
# Verify Pi-hole is running
docker-compose ps pihole

# Check if listening on port 53
docker exec pihole netstat -tlnp | grep 53

# Test locally
nslookup google.com 192.168.0.198

# Set as default DNS on router (192.168.0.1)
# Or on specific devices
```

### DDNS not updating

**Symptom:** DuckDNS IP doesn't match current WAN IP

**Solution:**
```bash
# Check DDNS logs
docker-compose logs ddns | tail -20

# Verify token and domain in .env
cat .env | grep DUCKDNS

# Test manually
curl "https://www.duckdns.org/update?domains=your-domain&token=your-token&ip="

# Query result
dig your-domain.duckdns.org
```

### Let's Encrypt certificate renewal fails

**Symptom:** SSL error; certificate expired

**Solution:**
```bash
# Check NPM logs
docker-compose logs npm | grep -i ssl

# Verify DNS can resolve domain
nslookup your-domain.com

# Ensure port 80/443 accessible from internet
# Check ER605 port forwarding to NPM

# Manually renew via NPM UI:
# Proxy Hosts > [Host] > SSL tab > Renew
```

## Maintenance

### Update containers

```bash
cd proxy
docker-compose pull
docker-compose up -d
```

### Backup configurations

```bash
# NPM config
sudo tar -czf npm_backup.tar.gz data/ letsencrypt/

# Pi-hole
sudo tar -czf pihole_backup.tar.gz etc-pihole/ etc-dnsmasq.d/
```

### View logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f npm
docker-compose logs -f pihole
docker-compose logs -f ddns
```

## Advanced Configuration

### Custom DNS Records (Pi-hole)

Edit `etc-dnsmasq.d/custom.conf` (or via web UI):

```
address=/internal.local/192.168.0.10
address=/minecraft.local/192.168.0.10
```

Restart Pi-hole:
```bash
docker-compose restart pihole
```

### NPM Custom Headers

Add security headers to all proxied services:

**Custom Locations tab in Proxy Host:**
```
Location: /
Scheme: http
Forward hostname: upstream-service
Forward port: 3000
```

**Custom Headers:**
```
X-Frame-Options: SAMEORIGIN
X-Content-Type-Options: nosniff
X-XSS-Protection: 1; mode=block
Strict-Transport-Security: max-age=31536000; includeSubDomains
```

## Security Notes

- Change NPM default password immediately
- Change Pi-hole admin password
- Store DDNS token securely (.env is not committed)
- Enable firewall on Debian host: `sudo ufw enable`
- Restrict NPM admin access to local network if exposed
- Use strong certificates (Let's Encrypt is free and automatic)
- Review Pi-hole logs for blocked queries

---

For more info:
- [Nginx Proxy Manager Docs](https://nginxproxymanager.com/)
- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [DuckDNS](https://www.duckdns.org/)