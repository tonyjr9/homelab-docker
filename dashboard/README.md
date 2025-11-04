# Dashboard Services

This directory contains the main dashboard and monitoring interfaces for the homelab.

## Services

### Homarr
- Purpose: Centralized dashboard for all homelab services
- Port: 7575
- Access: http://server-ip:7575

### DashDot
- Purpose: Real-time system monitoring
- Port: 3001
- Access: http://192.168.0.10X:3001

## Configuration

Create a `.env` file:
```
HOMARR_SECRET_KEY=your_secret_encryption_key_here
DASHBOT_IP=192.168.0.10X
```

## Notes
- Homarr reads Docker status via the Docker socket
- Both services are attached to the proxy network for reverse proxying
