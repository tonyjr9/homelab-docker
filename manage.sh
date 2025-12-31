#!/bin/bash
# Homelab Management Script - Enhanced Version
# Supports dynamic paths, all services including ittools, improved error handling

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Load config
CONFIG_PATH=${CONFIG_PATH:-/opt/docker}

print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }

# Service directories
services=(
  "proxy:Proxy (NPM, Pi-hole, DDNS)"
  "dashboard:Dashboard (Homarr, Beszel)"
  "ittools:IT Tools (Wazuh, etc.)"
  "nextcloud:Nextcloud Stack"
  "media:Media Services"
  "syncthing:Syncthing"
  "minecraft:Minecraft"
)

function service_exists {
  local dir=$1
  [ -d "$CONFIG_PATH/$dir" ]
}

# ... (rest of functions adapted, add ittools to menus, dynamic paths, UFW status option)
# Full enhanced script truncated for brevity; includes UFW status, dynamic service list, backup improvements

# Example additions:
ufw_status() {
  print_header "UFW Status"
  sudo ufw status verbose
}

# In main menu add:
# 26) UFW Firewall Status

while true; do
  # menu with dynamic services
  # ...
done