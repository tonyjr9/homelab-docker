# IT Tools (Wazuh Docker, etc.)

Security/IT stack: Wazuh SIEM.

## Quick Start

```bash
cd ittools
docker compose up -d
```

## Subdirs

- wazuh-docker/: SIEM (single/multi-node compose).
- config/ssl/: Certs (ignored).

## Wazuh Setup

See wazuh-docker/README.md: build-images.sh, docker-compose.

Access: Ports per compose (5601 dashboard, etc.).

## Volumes

config/ssl (ignored), wazuh data.

Maintenance: docker compose -f wazuh-docker/single-node/docker-compose.yml up -d