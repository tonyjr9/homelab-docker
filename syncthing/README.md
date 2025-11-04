# Syncthing

Peer-to-peer file synchronization across devices.

## Access
- Web UI: http://server-ip:8384 (if exposed)

## Volumes
- `/mnt/media/sync:/var/syncthing` (example; see compose for actual mapping)

## Notes
- Configure device pairing via web UI
- Use folder IDs for selective sync
- Consider reverse proxy for secure remote access
