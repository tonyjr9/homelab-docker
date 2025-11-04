# Dashboard Services

This directory contains the central dashboard for the homelab.

## Homarr
- Purpose: Centralized dashboard for all homelab services
- Port: 7575
- Access: http://server-ip:7575

### Configuration
Create a `.env` file:
```
HOMARR_SECRET_KEY=your_secret_encryption_key_here
```

### Volumes
- `./configs:/app/data/configs`
- `./icons:/app/public/icons`
- `./data:/data`
- `./imgs/backgrounds:/app/public/imgs/backgrounds`

### Notes
- Homarr reads Docker status via the Docker socket
- Attached to `proxy_network` for reverse proxying via NPM
