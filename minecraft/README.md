# Minecraft Server

Back to [Main README](../README.md)

Java Edition server with persistent world data and optimized performance for homelab.

## Services Included

- **Minecraft Java Server**: Latest or custom version

## Directory Structure

```
minecraft/
├── docker-compose.yml
├── .env.example
├── README.md
└── world/                    # Game data, world saves (not tracked)
```

## Environment Variables

```bash
# .env
PUID=1000
PGID=1000
TZ=Europe/Lisbon
MINECRAFT_EULA=true
MINECRAFT_VERSION=latest
MINECRAFT_MEMORY=2G
MINECRAFT_DIFFICULTY=2
```

## Quick Start

```bash
cd minecraft

# Create world directory
mkdir -p world

# Copy .env.example to .env and edit
cp .env.example .env
nano .env

# Start server
docker-compose up -d

# Wait for initialization (30-60 sec)
sleep 30

# Verify
docker-compose ps
docker-compose logs minecraft | tail -20
```

## Access

### Local Network
- **Address**: 192.168.0.102
- **Port**: 25565
- **Connect**: Add server with IP:port

### Via Proxy (Optional)
- Configure NPM reverse proxy for domain access
- Port forwarding for remote access

## Configuration

### Environment Options

```bash
# Memory allocation (adjust based on available RAM)
MINECRAFT_MEMORY=2G         # Default
MINECRAFT_MEMORY=4G         # More players/mods

# Difficulty (0-3)
MINECRAFT_DIFFICULTY=2      # Normal

# Mode (survival, creative, adventure, spectator)
MINECRAFT_MODE=survival     # Default

# View distance (3-32, lower = better performance)
MINECRAFT_VIEW_DISTANCE=10  # Default

# Server properties
MINECRAFT_MOTD=Welcome to Minecraft!    # Message of the day
MINECRAFT_SPAWN_PROTECTION=16           # Spawn area size
MINECRAFT_PVP=true                      # Enable PvP
```

### Advanced Configuration

**server.properties:**

Customize via mounted config file:

```bash
# docker-compose.yml volumes section
volumes:
  - ./server.properties:/data/server.properties
  - ./world:/data/world
```

Create `minecraft/server.properties`:

```
gamemode=survival
difficulty=2
pvp=true
spawn-protection=16
max-players=20
view-distance=10
whitelist=false
```

## Usage

### Connect from Client

1. Open Minecraft Java Edition
2. Multiplayer > Direct Connection
3. Enter: `192.168.0.102:25565`
4. Join world

### Server Commands

```bash
# Execute command in running server
docker exec minecraft rcon-cli "say Hello World"

# Save world
docker exec minecraft rcon-cli save-all

# Stop server gracefully
docker exec minecraft rcon-cli stop
```

### Whitelist Management

Enable whitelist for trusted players:

```bash
# Enable whitelist (edit server.properties or via command)
docker exec minecraft rcon-cli "whitelist on"

# Add player
docker exec minecraft rcon-cli "whitelist add PlayerName"

# Remove player
docker exec minecraft rcon-cli "whitelist remove PlayerName"

# List players
docker exec minecraft rcon-cli "whitelist list"
```

## Performance Tuning

### Memory Management

**For different player counts:**
- 1-5 players: 1-2GB
- 6-10 players: 2-3GB
- 11+ players: 4GB+

Edit `.env`:
```bash
MINECRAFT_MEMORY=2G
```

### World Optimization

```bash
# Regular world save
docker exec minecraft rcon-cli save-all

# Reduce mob spawn rate (if lagging)
docker exec minecraft rcon-cli "difficulty 1"

# Adjust view distance (lower = better performance)
# Edit server.properties: view-distance=8
```

## Backup & Restore

### Backup World

```bash
# Save and backup world
docker exec minecraft rcon-cli save-all
sudo tar -czf minecraft_world_backup_$(date +%Y%m%d).tar.gz world/

# Store backup
mv minecraft_world_backup_*.tar.gz /mnt/media/backups/
```

### Restore World

```bash
# Stop server
docker-compose stop minecraft

# Extract backup
sudo tar -xzf minecraft_world_backup_*.tar.gz -C minecraft/

# Restart
docker-compose up -d minecraft
```

## Troubleshooting

### Server won't start

```bash
# Check logs
docker-compose logs minecraft

# Common issues:
# - EULA not accepted (set MINECRAFT_EULA=true)
# - Port 25565 in use (check: lsof -i :25565)
# - Insufficient memory
```

### Clients can't connect

```bash
# Verify server is running
docker-compose ps minecraft

# Test from another container
docker exec [container] nc -zv 192.168.0.102 25565

# Check firewall
sudo ufw status
sudo ufw allow 25565
```

### Low FPS / Lag

```bash
# Increase memory
MINECRAFT_MEMORY=3G or 4G

# Reduce view distance
# server.properties: view-distance=8

# Check CPU/memory usage
docker stats minecraft
```

### World corrupted

```bash
# Restore from backup
# See "Backup & Restore" section above

# Or reset world
docker-compose down
rm -rf world/
docker-compose up -d minecraft
```

## Maintenance

### Update server

```bash
# Pull latest image
docker-compose pull minecraft

# Backup world first
sudo tar -czf minecraft_world_backup.tar.gz world/

# Update and restart
docker-compose up -d minecraft

# Verify world loaded
docker-compose logs minecraft | tail -20
```

### View logs

```bash
# Follow logs
docker-compose logs -f minecraft

# Last 50 lines
docker-compose logs --tail 50 minecraft
```

## Storage Notes

World files stored in `minecraft/world/` (not tracked in Git).

Typical world sizes:
- Empty world: <100MB
- Played world (1 month): 500MB-2GB
- Large world (1 year+): 5GB+

Regular backups recommended for large worlds.

## Power Management

Minecraft server respects HDD spindown:
- When idle (no players): HDD can sleep
- When active: HDD remains awake
- Automatic world saves don't prevent spindown with current settings

---

For more info:
- [Minecraft Server Docs](https://www.minecraft.net/en-us/download/server)
- [Minecraft Server Properties](https://minecraft.wiki/w/Server.properties)
- [itzg/minecraft-server Docker Image](https://github.com/itzg/docker-minecraft-server)