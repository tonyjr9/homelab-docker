# 🏠 Home Server Docker Configuration

A complete homelab setup using Docker Compose for self-hosting various essential services.

## 📋 Services Included

### 🖥️ Dashboard & Monitoring
- **Homarr** - Centralized dashboard for service management
- **DashDot** - Real-time system monitoring

### 🎬 Media Stack
- **Plex** - Media streaming server
- **Sonarr** - Automated TV series management  
- **Radarr** - Automated movie management
- **Overseerr** - Media request interface
- **Tautulli** - Plex analytics and monitoring
- **Immich** - Personal photo and video management

### 🌐 Networking & Proxy
- **Nginx Proxy Manager** - Reverse proxy with web interface
- **Pi-hole** - Network-level ad blocker

### 📁 File Management & Sync
- **Nextcloud** - Personal cloud platform
- **Syncthing** - Peer-to-peer file synchronization

### 🔧 Management Tools
- **Portainer** - Docker management interface
- **Transmission** - BitTorrent client

## 🚀 Quick Installation

### Prerequisites
- Docker and Docker Compose installed
- Approximately 4GB+ RAM
- Sufficient disk space for media and backups

### Initial Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/tonyjr9/serverdocker.git
   cd serverdocker
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env with your specific configuration
   nano .env
   ```

3. **Set up proxy network (run first):**
   ```bash
   cd proxy
   docker-compose up -d
   cd ..
   ```

4. **Start services by category:**
   ```bash
   # Dashboard
   cd dashboard && docker-compose up -d && cd ..
   
   # Media services
   cd media && docker-compose up -d && cd ..
   
   # Management tools
   cd portainer && docker-compose up -d && cd ..
   ```

## ⚙️ Configuration

### Environment Variables
Each service requires specific configuration:

- **PUID/PGID**: Set to your user ID (usually 1000)
- **Timezone**: Adjust to your location
- **Paths**: Adapt volume paths according to your system
- **Network IPs**: Update IP addresses in docker-compose files to match your network

### Access Ports
| Service | Port | Local URL |
|---------|------|-----------|
| Homarr | 7575 | http://localhost:7575 |
| DashDot | 3001 | http://192.168.0.10X:3001 |
| Nginx Proxy Manager | 81 | http://192.168.0.10X:81 |
| Pi-hole | 80 | http://192.168.0.10X:80 |
| Overseerr | 5055 | http://localhost:5055 |
| Radarr | 7878 | http://localhost:7878 |
| Sonarr | 8989 | http://localhost:8989 |

*Replace `192.168.0.10X` with your actual server IP address*

## 📂 Directory Structure

```
serverdocker/
├── dashboard/          # Homarr + DashDot
├── media/             # Complete media stack
│   ├── immich/        # Photo management
│   ├── overseer/      # Media requests  
│   ├── plex/          # Plex server
│   ├── radar/         # Radarr (movies)
│   ├── sonarr/        # Sonarr (TV series)
│   └── tautulli/      # Plex analytics
├── monitoring/        # Monitoring tools
├── nextcloud/         # Personal cloud
├── portainer/         # Docker management
├── proxy/             # Nginx PM + Pi-hole
├── syncthing/         # P2P synchronization
├── torrent/           # Additional torrent client
└── transmission/      # Main BitTorrent client
```

## 🔧 Maintenance

### Useful Commands

**Check container status:**
```bash
docker ps
```

**View service logs:**
```bash
docker-compose logs -f [service-name]
```

**Update images:**
```bash
cd [service-directory]
docker-compose pull
docker-compose up -d
```

**Backup configurations:**
```bash
# Create backup of important configs
tar -czf homelab-backup-$(date +%Y%m%d).tar.gz \
  dashboard/configs media/*/config proxy/data nextcloud/config
```

## 🔒 Security

- **Pi-hole** blocks ads and tracking at network level
- **Nginx Proxy Manager** enables automatic SSL/TLS
- All services are isolated in dedicated Docker networks
- Sensitive configurations should use local `.env` files

## ⚠️ Important Notes

- **Adapt IPs and paths** to your specific needs
- **Configure persistent volumes** before production use  
- **Use secure passwords** for all services
- **Set up regular backups** of important data
- **Remove sensitive information** from docker-compose files before making public

## 🔐 Security Configuration

Before production use, make sure to:

1. **Create local `.env` files** for passwords and tokens
2. **Change default passwords** in all services
3. **Configure SSL/TLS** in Nginx Proxy Manager
4. **Restrict network access** as needed
5. **Update IP addresses** in docker-compose files to match your network

### Environment Variables Example

Create a `.env` file in each service directory:

```env
# Pi-hole Configuration
PIHOLE_PASSWORD=your_secure_password_here

# Plex Configuration  
PLEX_CLAIM_TOKEN=your_plex_claim_token_here

# Homarr Configuration
HOMARR_SECRET_KEY=your_secret_encryption_key_here

# Network Configuration
SERVER_IP=192.168.0.10X
```

## 🤝 Contributing

Pull requests are welcome! For major changes:

1. Open an issue first to discuss the change
2. Fork the project  
3. Create a feature branch (`git checkout -b feature/AmazingFeature`)
4. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
5. Push to the branch (`git push origin feature/AmazingFeature`)
6. Open a Pull Request

## 📄 License

This project is under the MIT License. See the `LICENSE` file for details.

---

**💡 Tip:** Start with the proxy and dashboard, then gradually add other services as needed.