# OpenVPN Server Setup Guide

This guide covers the setup and management of an OpenVPN server running in Docker, integrated with Pi-hole DNS and DuckDNS dynamic DNS.

## Overview

This OpenVPN setup provides:
- Secure remote access to your home network
- Automatic Pi-hole DNS for ad-blocking on all connected devices
- Dynamic DNS via DuckDNS for reliable connections
- Docker-based deployment for easy management and updates

## Prerequisites

- Docker and Docker Compose installed
- Port 1194/UDP forwarded from your router to 192.168.9.6
- DuckDNS domain configured in your environment variables
- Pi-hole running and accessible at 192.168.0.198

## Initial Setup

### 1. Add OpenVPN to Pi-hole Network

Update your `docker-compose.yml` to allow OpenVPN to communicate with Pi-hole:

```yaml
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
  networks:
    - pihole  # Add this line
```

### 2. Generate OpenVPN Configuration

Navigate to your project directory and run:

```bash
cd /opt/docker/network

# Generate configuration with Pi-hole DNS (replace with your DuckDNS domain)
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm \
  kylemanna/openvpn \
  ovpn_genconfig -u udp://YOUR-DOMAIN.duckdns.org -n 192.168.0.198
```

**Important**: Replace `YOUR-DOMAIN.duckdns.org` with your actual DuckDNS domain.

### 3. Initialize PKI (Certificate Authority)

```bash
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm -it \
  kylemanna/openvpn ovpn_initpki
```

You'll be prompted to:
1. Set a passphrase for your Certificate Authority (CA) - **Remember this!**
2. Enter your CA common name (or press Enter for default)

**Store the CA passphrase securely** - you'll need it every time you create new client certificates.

### 4. Start OpenVPN Server

```bash
docker-compose up -d openvpn
```

### 5. Verify Configuration

Check that OpenVPN is using Pi-hole for DNS:

```bash
docker exec openvpn cat /etc/openvpn/openvpn.conf | grep "push.*DNS"
```

You should see: `push "dhcp-option DNS 192.168.0.198"`

Check container status:

```bash
docker-compose ps openvpn
docker-compose logs openvpn
```

## Adding Users (Client Profiles)

### Generate Client Certificate (No Password)

For trusted devices where convenience is preferred:

```bash
cd /opt/docker/network

# Replace CLIENTNAME with a descriptive name (e.g., "laptop", "phone", "dad-phone")
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm -it \
  kylemanna/openvpn easyrsa build-client-full CLIENTNAME nopass
```

You'll be prompted for your **CA passphrase** (set during initial setup).

### Generate Client Certificate (With Password)

For additional security, require a password when connecting:

```bash
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm -it \
  kylemanna/openvpn easyrsa build-client-full CLIENTNAME
```

You'll be prompted to:
1. Set a client passphrase (user will enter this when connecting)
2. Enter your CA passphrase to sign the certificate

### Export Client Configuration

```bash
# Export .ovpn file to current directory
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm \
  kylemanna/openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn
```

The `.ovpn` file will be created in `/opt/docker/network/`.

### Distribute to User

Transfer the `.ovpn` file securely to the user via:
- USB drive
- Encrypted messaging (Signal, WhatsApp)
- Password-protected zip file via email
- Direct transfer when in person

**Never send .ovpn files via unencrypted email or public channels.**

## Client Connection Instructions

### Windows
1. Install [OpenVPN GUI](https://openvpn.net/client-connect-vpn-for-windows/)
2. Right-click the `.ovpn` file and select "Start OpenVPN on this config file"
3. Or copy the file to `C:\Program Files\OpenVPN\config\` and connect via GUI

### macOS
1. Install [Tunnelblick](https://tunnelblick.net/) or [OpenVPN Connect](https://openvpn.net/client/)
2. Double-click the `.ovpn` file to import
3. Connect from the menu bar

### Linux
```bash
sudo apt install openvpn
sudo openvpn --config CLIENTNAME.ovpn
```

### Android
1. Install [OpenVPN for Android](https://play.google.com/store/apps/details?id=de.blinkt.openvpn)
2. Transfer `.ovpn` file to device
3. Import profile and connect

### iOS
1. Install [OpenVPN Connect](https://apps.apple.com/app/openvpn-connect/id590379981)
2. Transfer `.ovpn` via AirDrop or Files app
3. Open with OpenVPN Connect app

## Management Tasks

### List All Clients

```bash
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm \
  kylemanna/openvpn ovpn_listclients
```

### Revoke Client Certificate

If a device is lost or a user should no longer have access:

```bash
# Revoke the certificate
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm -it \
  kylemanna/openvpn easyrsa revoke CLIENTNAME

# Regenerate CRL (Certificate Revocation List)
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm -it \
  kylemanna/openvpn easyrsa gen-crl

# Restart OpenVPN to apply changes
docker-compose restart openvpn
```

### Update OpenVPN Container

```bash
cd /opt/docker/network
docker-compose pull openvpn
docker-compose up -d openvpn
```

### Backup Configuration

Backup the entire OpenVPN configuration:

```bash
cd /opt/docker/network
tar -czf openvpn-backup-$(date +%Y%m%d).tar.gz openvpn-data/
```

Store the backup securely - it contains all certificates and private keys.

### Restore from Backup

```bash
cd /opt/docker/network
tar -xzf openvpn-backup-YYYYMMDD.tar.gz
docker-compose up -d openvpn
```

## Troubleshooting

### Check Server Logs

```bash
docker-compose logs -f openvpn
```

### Verify Port Forwarding

From an external network:
```bash
nc -vzu YOUR-DOMAIN.duckdns.org 1194
```

Or use [YouGetSignal Port Checker](https://www.yougetsignal.com/tools/open-ports/)

### Test DNS Resolution

After connecting to VPN, test that Pi-hole is working:

```bash
# Check DNS server
nslookup google.com
# Should show 192.168.0.198 as the DNS server

# Test ad-blocking
nslookup doubleclick.net
# Should be blocked by Pi-hole
```

### Pi-hole Not Resolving

Ensure Pi-hole is listening on all interfaces:
```bash
docker exec pihole cat /etc/dnsmasq.d/01-pihole.conf | grep interface
```

Should show: `interface=all`

### Connection Refused

1. Verify OpenVPN is running: `docker ps | grep openvpn`
2. Check router port forwarding to 192.168.9.6:1194/UDP
3. Verify DuckDNS is updating: `curl "https://www.duckdns.org/update?domains=YOUR-DOMAIN&token=YOUR-TOKEN&ip="`
4. Check firewall on Debian server: `sudo ufw status`

### Slow Connection Speeds

This is typically a VPN protocol issue, not Docker-related. Try:
1. Using TCP instead of UDP (in ovpn_genconfig)
2. Adjusting MTU settings
3. Checking your ISP upload speed (VPN is limited by this)

## Security Best Practices

1. **Never share your CA passphrase** - only you should know it
2. **Create unique certificates per device** - easier to revoke if lost
3. **Use password-protected profiles** for devices that might be lost/stolen
4. **Regularly backup** your openvpn-data directory
5. **Revoke certificates** for old/unused devices
6. **Keep OpenVPN updated** via `docker-compose pull`
7. **Monitor Pi-hole logs** for unusual DNS queries from VPN clients

## File Locations

- Configuration data: `/opt/docker/network/openvpn-data/`
- Client profiles: `/opt/docker/network/*.ovpn`
- Certificates: `/opt/docker/network/openvpn-data/pki/`
- Server config: `/opt/docker/network/openvpn-data/openvpn.conf`

## Network Details

- OpenVPN Server: 1194/UDP
- VPN Network: 10.8.0.0/24 (default)
- Pi-hole DNS: 192.168.0.198
- Home Network: 192.168.9.0/24 (assuming based on your IP)

## Quick Reference Commands

```bash
# Add new user (no password)
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm -it kylemanna/openvpn easyrsa build-client-full USERNAME nopass
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm kylemanna/openvpn ovpn_getclient USERNAME > USERNAME.ovpn

# List all clients
docker run -v $(pwd)/openvpn-data:/etc/openvpn --rm kylemanna/openvpn ovpn_listclients

# View logs
docker-compose logs -f openvpn

# Restart server
docker-compose restart openvpn

# Backup
tar -czf openvpn-backup-$(date +%Y%m%d).tar.gz openvpn-data/
```

## Additional Resources

- [kylemanna/docker-openvpn GitHub](https://github.com/kylemanna/docker-openvpn)
- [OpenVPN Documentation](https://openvpn.net/community-resources/)
- [Pi-hole Documentation](https://docs.pi-hole.net/)
