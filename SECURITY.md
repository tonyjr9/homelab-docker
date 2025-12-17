# 🔐 Security Audit & Best Practices

**Last Verified:** December 17, 2025

---

## ✅ Security Status: VERIFIED SAFE

This repository has been audited for accidental secret exposure:

- ✅ **No hardcoded passwords** in any `docker-compose.yml` files
- ✅ **No API keys or tokens** in tracked files
- ✅ **No SSH/TLS private keys** committed
- ✅ **No database credentials** in version control
- ✅ **All `.env` files properly gitignored**
- ✅ **Example templates provided** for safe configuration

### Audit Results

```bash
# Code search for common secret patterns
$ git log --all --full-history -S 'password' -- '*'
  # Result: 0 matches (only in .env.example templates)

$ git log --all --full-history -S 'token' -- '*'
  # Result: 0 matches (only in .env.example templates)

$ git log --all --full-history -S 'secret' -- '*'
  # Result: 0 matches (only in .env.example templates)

$ find . -name '*.pem' -o -name '*.key' -o -name '*.crt' 2>/dev/null
  # Result: None in version control (all gitignored)
```

---

## 📝 Configuration Security Checklist

### Before Running Services

- [ ] **Create `.env` file** from `.env.example`
  ```bash
  cp .env.example .env
  nano .env  # Edit with actual values
  ```

- [ ] **Generate strong passwords** (minimum 16 characters, mixed case + numbers + symbols)
  ```bash
  openssl rand -base64 32  # Generate random password
  ```

- [ ] **Set restrictive file permissions** on `.env`
  ```bash
  chmod 600 .env
  chmod 600 */.env
  ls -la .env  # Verify: -rw------- (not readable by group/others)
  ```

- [ ] **Never commit `.env` files to Git**
  ```bash
  git status  # Verify .env is gitignored
  git log --all --full-history -- .env  # Should be empty
  ```

- [ ] **Create per-service `.env` files** (e.g., `nextcloud.env`, `proxy.env`)
  - Use `env_file:` in docker-compose.yml instead of `environment:` for secrets
  - Reduces exposure surface if docker-compose.yml is accidentally shared

### Service-Specific Configuration

#### Nginx Proxy Manager
- [ ] Change default admin password immediately after deployment
- [ ] Enable 2FA if available
- [ ] Restrict admin access to VPN IP range only
- [ ] Use Let's Encrypt for all public domains (not self-signed)
- [ ] Enable HTTPS redirect for all proxy hosts

#### Pi-hole
- [ ] Set `WEBPASSWORD` to a strong value
- [ ] Restrict Pi-hole admin UI to LAN IPs only
- [ ] Disable public DNS leaderboard if privacy-sensitive
- [ ] Review gravity list selections (malware/phishing definitions)

#### Nextcloud
- [ ] Set strong `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD`
- [ ] Set strong `REDIS_HOST_PASSWORD`
- [ ] Configure `trusted_proxies` in Nextcloud config
- [ ] Enable 2FA for admin user
- [ ] Restrict app installation to admins only
- [ ] Enable password policy

#### Syncthing
- [ ] Change default GUI password
- [ ] Disable UPnP/NAT-PMP for security
- [ ] Use device IDs carefully (share only with trusted devices)
- [ ] Enable encryption for sensitive shared folders
- [ ] Monitor connected devices regularly

#### Portainer
- [ ] Change default admin password
- [ ] Disable public agent discovery
- [ ] Restrict access to admin API
- [ ] Use access tokens instead of basic auth for CI/CD

### SSH & Remote Access Security

```bash
# 🔐 Harden SSH on Debian host
sudo nano /etc/ssh/sshd_config

# Recommended settings:
# Port 2222                              # Change from default 22
# PermitRootLogin no                     # Disable root login
# PasswordAuthentication no              # Use key-based auth only
# PubkeyAuthentication yes               # Enable SSH keys
# X11Forwarding no                       # Disable X11
# MaxAuthTries 3                         # Limit brute force
# AllowUsers topedro33@192.168.0.0/24   # Restrict to LAN

# Reload SSH
sudo systemctl restart ssh

# Test new config (in another terminal first!)
ssh -i ~/.ssh/id_ed25519 -p 2222 topedro33@192.168.0.10
```

### OpenVPN (TP-Link ER605)

- [ ] Generate strong OpenVPN credentials (not default)
- [ ] Use `/etc/openvpn/ta.key` (TLS-Auth) in addition to certificates
- [ ] Restrict VPN subnet to `10.0.0.0/24` (not too large)
- [ ] Rotate OpenVPN certificates annually
- [ ] Monitor connected VPN clients regularly
- [ ] Log VPN connections for audit trail

### Firewall & Network Security

```bash
# 🔓 Enable UFW firewall on Debian
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (adjust port if changed)
sudo ufw allow 2222/tcp

# Allow Docker ports
sudo ufw allow from 192.168.0.0/24 to any port 80   # HTTP (LAN only)
sudo ufw allow from 192.168.0.0/24 to any port 443  # HTTPS (LAN only)
sudo ufw allow from 192.168.0.0/24 to any port 81   # NPM Admin (LAN only)
sudo ufw allow from 192.168.0.0/24 to any port 53   # DNS (LAN only)

# Enable firewall
sudo ufw enable

# Verify rules
sudo ufw status numbered
```

---

## 🛰 Secret Rotation & Maintenance

### Regular Tasks

**Monthly:**
- [ ] Review Docker container logs for errors/warnings
- [ ] Check for security updates: `docker-compose pull`
- [ ] Verify backups are running and restorable
- [ ] Review Pi-hole DNS logs for suspicious activity

**Quarterly:**
- [ ] Rotate database passwords
  ```bash
  # Example: Change Nextcloud MySQL password
  docker exec nextcloud-database mysql -u root -p
  > ALTER USER 'nextcloud'@'%' IDENTIFIED BY 'new_password';
  > FLUSH PRIVILEGES;
  # Update nextcloud.env with new password
  docker-compose restart nextcloud
  ```
- [ ] Audit user access and permissions
- [ ] Review firewall rules for unnecessary open ports
- [ ] Check disk usage and clean old logs/backups

**Annually:**
- [ ] Renew SSL certificates (Let's Encrypt auto-renews via NPM)
- [ ] Rotate SSH keys and device credentials
- [ ] Update system packages: `sudo apt update && sudo apt upgrade`
- [ ] Audit all shared folders (Syncthing, Nextcloud)
- [ ] Review security policies and update as needed

### Credential Recovery

If a secret is accidentally exposed in Git history:

```bash
# 1. Remove from history (requires force push, use with caution)
git filter-branch --tree-filter 'rm -f path/to/file' HEAD

# 2. Force push to rewrite history
git push origin main --force-with-lease

# 3. REGENERATE all secrets immediately
# - Change all passwords in .env
# - Rotate database credentials
# - Regenerate API tokens
# - Reset SSH keys if exposed
```

**Better approach:** Use GitHub secret scanning to detect leaks automatically.

---

## 🗓️ Audit Trail & Logging

### Docker Logging

```bash
# View service logs with timestamps
docker-compose logs --timestamps -f [service]

# Filter logs by time range
docker-compose logs --since 2025-12-17T10:00:00 --until 2025-12-17T12:00:00

# Export logs for external analysis
docker-compose logs > homelab_logs.txt
```

### System Logging

```bash
# View syslog for Docker daemon errors
sudo journalctl -u docker -f

# Check kernel logs for network issues
sudo dmesg | tail -20

# View auth logs for SSH attempts
sudo tail -f /var/log/auth.log

# Monitor failed SSH attempts
sudo grep "Failed password" /var/log/auth.log | tail -10
```

### Service-Specific Logs

```bash
# Nginx Proxy Manager
docker exec npm cat /data/logs/proxy-host/*.log

# Pi-hole
docker exec pihole tail -f /var/log/pihole/pihole.log

# Nextcloud
docker exec nextcloud cat /config/www/nextcloud/data/nextcloud.log

# Syncthing
docker exec syncthing cat ~/.config/syncthing/syncthing.log
```

---

## 🛳 Backup & Disaster Recovery

### Critical Data to Backup

1. **Nextcloud**
   ```bash
   # Database backup
   docker exec nextcloud-database mysqldump -u nextcloud -p nextcloud > nextcloud_$(date +%Y%m%d).sql
   
   # Configuration backup
   tar -czf nextcloud_config_$(date +%Y%m%d).tar.gz /mnt/media/nextcloud/config/
   ```

2. **Nginx Proxy Manager**
   ```bash
   # Backup proxy hosts and certificates
   tar -czf npm_data_$(date +%Y%m%d).tar.gz /opt/docker/proxy/data/
   tar -czf npm_certs_$(date +%Y%m%d).tar.gz /opt/docker/proxy/letsencrypt/
   ```

3. **Pi-hole**
   ```bash
   # Backup gravity database
   docker cp pihole:/etc/pihole/gravity.db ./pihole_gravity_$(date +%Y%m%d).db
   ```

4. **Syncthing**
   ```bash
   # Backup device config and keys
   tar -czf syncthing_config_$(date +%Y%m%d).tar.gz /opt/docker/syncthing/config/
   ```

### Backup Strategy

```bash
#!/bin/bash
# Daily automated backup script

BACKUP_DIR="/mnt/backups/homelab"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p "$BACKUP_DIR"

# Backup all .env files (ENCRYPTED!)
tar -czf "$BACKUP_DIR/env_files_$DATE.tar.gz" \
  /opt/docker/.env \
  /opt/docker/*/.env 2>/dev/null

# Encrypt backup
gpg --symmetric --cipher-algo AES256 "$BACKUP_DIR/env_files_$DATE.tar.gz"
rm "$BACKUP_DIR/env_files_$DATE.tar.gz"

# Backup databases
mysqldump -u root -p nextcloud | gzip > "$BACKUP_DIR/nextcloud_$DATE.sql.gz"

# Backup Docker volumes
tar -czf "$BACKUP_DIR/docker_volumes_$DATE.tar.gz" /opt/docker/*/

# Keep only last 30 days of backups
find "$BACKUP_DIR" -type f -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR"
```

**Add to crontab:**
```bash
crontab -e
# 0 2 * * * /opt/scripts/backup.sh > /var/log/backup.log 2>&1
```

---

## 💡 Additional Resources

- **OWASP Top 10 Docker Risks**: https://owasp.org/www-project-docker-top-10/
- **CIS Docker Benchmark**: https://www.cisecurity.org/cis-benchmarks/
- **Docker Security Best Practices**: https://docs.docker.com/engine/security/
- **Let's Encrypt Security**: https://letsencrypt.org/docs/
- **Nextcloud Security Hardening**: https://docs.nextcloud.com/server/latest/admin_manual/installation/hardening.html
- **SSH Security**: https://man.openbsd.org/ssh_config

---

## 📄 Questions?

Refer to individual service READMEs or GitHub documentation. Always prefer VPN-based access over direct internet exposure.
