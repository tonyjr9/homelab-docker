# Syncthing

P2P file sync.

## Quick Start

```bash
cd syncthing
docker compose up -d
```

GUI: http://host:8384 | Pass: from logs.

## Config

./config/ (ignored): Devices/folders.

Add devices via GUI, share /mnt/media/cloud/syncthing.

Troubleshoot: Ports 22000/TCP, 21027/UDP.