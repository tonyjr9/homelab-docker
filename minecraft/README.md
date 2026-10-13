# Minecraft Server

Java Edition.

## Quick Start

```bash
cp .env.example .env  # EULA=true
cd minecraft
docker compose up -d
```

Connect: host:25565

## World

./world/ (ignored): Persistent.
Backup: manage.sh or tar.

Stop: /save-all

## Minecraft backups

This Minecraft server uses an automated snapshot backup script with `rsync` and hard links to avoid recopying unchanged files on every run. The backup is made safer by briefly pausing server writes with `rcon-cli` (`save-off`, `save-all flush`, then `save-on`) so the world is copied in a consistent state. [web:72][web:3]

### Backup layout

Backups are stored as timestamped snapshots under:

```text
/mnt/media/minecraft/backups/snapshots/YYYY-MM/YYYY-MM-DD_HHMMSS/
```

The script also keeps a `latest` symlink so it can quickly compare against the previous snapshot and hard-link unchanged files instead of duplicating them. [web:3]

### How it works

1. The script pauses Minecraft saving through RCON.
2. It forces a flush to disk with `save-all flush`.
3. It runs `rsync -aH --delete --link-dest=...` to create the new snapshot.
4. It re-enables saving with `save-on`.
5. It removes old snapshots after the retention period.

`--delete` only removes files from the new snapshot that no longer exist in the source, so the backup stays an accurate mirror of the current server state. [web:6][web:14]

### Cron job

The backup runs from root’s crontab so it can read the Minecraft data directory and write snapshots reliably. Cron output is appended to a log file using `>> ... 2>&1`, which captures both stdout and stderr. [web:79][web:69]

Example cron entry:

```cron
0 4 * * * /usr/local/bin/backup_minecraft.sh >> /var/log/minecraft_backup.log 2>&1
```

### Restore

To restore the latest snapshot, sync it back into the live data directory:

```bash
sudo rsync -aH --delete /mnt/media/minecraft/backups/snapshots/latest/ /opt/docker/minecraft/data/
```

### Notes

- The backup script uses `/tmp` for its lock file so it can be tested manually without root permission issues.
- If the server is busy during backup, `save-all flush` may briefly freeze the game while chunks are written to disk. [web:72]
