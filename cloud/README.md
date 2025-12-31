# Nextcloud Stack (Nextcloud, MariaDB, Redis)

Back to [Main README](../README.md)

Self-hosted cloud storage with collaborative editing, file sync, and backup support.

## Services Included

- **Nextcloud**: Cloud storage, file sync, contacts, calendar
- **MariaDB**: Relational database for Nextcloud
- **Redis**: In-memory cache for performance

## Directory Structure

```
nextcloud/
├── docker-compose.yml
├── nextcloud.env              # Credentials (not tracked)
├── README.md
├── config/                   # Nextcloud config (not tracked)
└── db/                      # MariaDB data (not tracked)
```

## Environment Variables

```bash
# nextcloud.env
MYSQL_ROOT_PASSWORD=root_password_here
MYSQL_PASSWORD=nextcloud_db_password_here
REDIS_PASSWORD=redis_password_here
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=admin_password_here
TZ=Europe/Lisbon
```

## Quick Start

```bash
cd nextcloud

# Create nextcloud.env with credentials
cat > nextcloud.env << 'EOF'
MYSQL_ROOT_PASSWORD=your_root_password
MYSQL_PASSWORD=your_nextcloud_password
REDIS_PASSWORD=your_redis_password
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=your_admin_password
TZ=Europe/Lisbon
EOF

# Start services
docker-compose up -d

# Wait for Nextcloud to initialize (2-3 min)
sleep 120

# Verify
docker-compose ps
```

## Access Points

### Nextcloud Web UI
- **URL**: http://192.168.0.10:8080
- **Default User**: admin (or configured in nextcloud.env)
- **Setup Wizard**: First launch

### MariaDB
- **Port**: 3306 (only accessible from within container network)
- **Root User**: root
- **Nextcloud User**: nextcloud

### Redis
- **Port**: 6379 (internal only)

## Configuration

### Initial Setup

1. Navigate to http://192.168.0.10:8080
2. Login with credentials from nextcloud.env
3. Configure:
   - Admin account
   - Default file storage location (/data)
   - Trusted domains (if accessing via different hostname)

### Database Setup

Database is automatically created on first launch:
- Database name: `nextcloud`
- User: `nextcloud`
- Password: From nextcloud.env

**Verify connection:**
```bash
# Check logs
docker-compose logs nextcloud | grep -i database

# Or from container
docker exec nextcloud-database mysql -u nextcloud -p -e "SHOW DATABASES;"
```

### Redis Cache

Redis improves Nextcloud performance for file operations and sessions.

**Verify Redis is enabled:**

Login to Nextcloud > Settings > Administration > System > Caching
- Should show: Redis is configured as memory cache

### Trusted Domains

If accessing Nextcloud from different hostnames (e.g., via NPM proxy):

**Add domain via web UI:**
1. Settings > Administration > Overview
2. Look for "Trusted domains" warning (if needed)
3. Edit `/opt/docker/nextcloud/config/config.php` directly:

```php
'trusted_domains' => [
  0 => 'localhost',
  1 => '192.168.0.10',
  2 => 'cloud.yourdomain.com',
],
```

Restart Nextcloud:
```bash
docker-compose restart nextcloud
```

## Usage

### Web Client

All features available via web UI:
- File upload/download
- Folder sharing
- Collaborative editing (with Collabora)
- Contacts and calendar
- Tasks
- Notes

### Desktop Client

Download from [nextcloud.com](https://nextcloud.com/install/#install-clients)

**Setup:**
1. Connect to: http://192.168.0.10:8080 (or via proxy URL)
2. Login with Nextcloud credentials
3. Select folders to sync locally
4. Two-way sync automatically

### Mobile Apps

Available on App Store and Google Play:
- Nextcloud
- Nextcloud Notes
- Nextcloud Contacts

## Backup & Restore

### Backup (Before Major Updates)

```bash
# Backup database
docker exec nextcloud-database mysqldump -u nextcloud -p nextcloud > nextcloud_backup.sql

# Backup Nextcloud config and data
sudo tar -czf nextcloud_config_backup.tar.gz /opt/docker/nextcloud/config/
sudo tar -czf nextcloud_data_backup.tar.gz /mnt/media/nextcloud/
```

### Restore

```bash
# Stop services
docker-compose down

# Restore database
cat nextcloud_backup.sql | docker exec -i nextcloud-database mysql -u nextcloud -p

# Restore config
sudo tar -xzf nextcloud_config_backup.tar.gz -C /

# Restore data (if separate)
sudo tar -xzf nextcloud_data_backup.tar.gz -C /

# Start services
docker-compose up -d
```

## Troubleshooting

### Nextcloud can't connect to database

**Symptom:** "Error connecting to database" on first launch or after restart

**Solution:**
```bash
# Check MariaDB is running
docker-compose ps nextcloud-database

# Check logs
docker-compose logs nextcloud-database

# Verify credentials in nextcloud.env
cat nextcloud.env

# Test connection manually
docker exec nextcloud-database mysql -u nextcloud -p nextcloud -e "SELECT 1;"

# If fails, check database initialization:
docker-compose logs | grep -i mysql

# Restart in order
docker-compose down
sleep 3
docker-compose up -d
```

### File sync is slow

**Symptom:** Desktop client takes a long time to sync files

**Solution:**
```bash
# Verify Redis is working
docker exec nextcloud-redis redis-cli -a [password] PING
# Should return: PONG

# Check Nextcloud logs for errors
docker-compose logs nextcloud | tail -20

# Increase MariaDB buffer pool size (advanced)
# Edit docker-compose.yml and add:
# command: --innodb-buffer-pool-size=2G
```

### Disk space full

**Symptom:** Users can't upload files; errors about disk space

**Solution:**
```bash
# Check disk usage
du -sh /mnt/media/nextcloud/
df -h /mnt/media

# Identify large files
find /mnt/media/nextcloud -type f -size +1G

# Clean old versions (can be configured in Nextcloud settings)
# Settings > Administration > Files > File retention
```

### Can't upload large files

**Symptom:** Upload fails; "413 Request Entity Too Large"

**Solution:**

Update nginx/upload limits in NPM if using reverse proxy:

```bash
# Via NPM UI:
# Proxy Hosts > [NC Host] > Advanced > Client Max Body Size
# Set to: 2048 (for 2GB limit)

# Or increase in Nextcloud config:
docker exec nextcloud occ config:app:set files max_upload_size 2147483648  # 2GB
```

## Maintenance

### Update containers

```bash
# Check for updates
docker-compose pull

# Backup before updating
sudo tar -czf nextcloud_pre_update.tar.gz /opt/docker/nextcloud/config/

# Update
docker-compose up -d

# Verify
docker-compose logs nextcloud | tail -10
```

### Regular backups

```bash
# Daily backup script
sudo bash << 'EOF'
#!/bin/bash
BACKUP_DIR=/mnt/media/backups
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Database backup
docker exec nextcloud-database mysqldump -u nextcloud -p nextcloud | gzip > $BACKUP_DIR/nextcloud_db_$DATE.sql.gz

# Keep only last 7 backups
find $BACKUP_DIR -name "nextcloud_db_*" -mtime +7 -delete
EOF

# Add to crontab for daily 3 AM backup
(crontab -l 2>/dev/null; echo "0 3 * * * /path/to/backup_script.sh") | crontab -
```

## Advanced Configuration

### Collabora Online Integration

Enable collaborative document editing:

1. Install Collabora Online (separate Docker service)
2. In Nextcloud: Settings > Apps > Enable "Collabora Online"
3. Add Collabora URL: http://collabora:9980

### S3 External Storage

Mountexternal S3 bucket as Nextcloud folder:

1. Install "External storage support" app
2. Settings > Administration > External storages
3. Add S3 configuration (key, secret, bucket)

### LDAP User Management

Sync users from LDAP directory:

1. Install LDAP Integration app
2. Configure LDAP server details
3. Test connection and sync

---

For more info:
- [Nextcloud Admin Guide](https://docs.nextcloud.com/server/stable/admin_manual/)
- [Nextcloud Desktop Client](https://nextcloud.com/install/#install-clients)
- [MariaDB Documentation](https://mariadb.org/documentation/)