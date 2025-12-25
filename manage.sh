#!/bin/bash
# Homelab Management Script
# Quick access to common Docker and system commands

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Service directories
PROXY_DIR="/opt/docker/proxy"
DASHBOARD_DIR="/opt/docker/dashboard"
NEXTCLOUD_DIR="/opt/docker/nextcloud"
MEDIA_DIR="/opt/docker/media"
SYNCTHING_DIR="/opt/docker/syncthing"
MINECRAFT_DIR="/opt/docker/minecraft"

# Main menu
show_menu() {
    clear
    print_header "Homelab Management Menu"
    echo ""
    echo -e "  ${GREEN}[Docker Services]${NC}"
    echo "  1)  Start all services"
    echo "  2)  Stop all services"
    echo "  3)  Restart all services"
    echo "  4)  Service status"
    echo "  5)  View logs (all services)"
    echo "  6)  Update all containers"
    echo ""
    echo -e "  ${YELLOW}[Individual Services]${NC}"
    echo "  10) Proxy (NPM, Pi-hole, DDNS)"
    echo "  11) Dashboard (Homarr, Beszel)"
    echo "  12) Nextcloud stack"
    echo "  13) Media services (Transmission, Radarr, Sonarr)"
    echo "  14) Syncthing"
    echo "  15) Minecraft"
    echo ""
    echo -e "  ${BLUE}[System Monitoring]${NC}"
    echo "  20) HDD status & spindown info"
    echo "  21) Disk I/O activity (iotop)"
    echo "  22) Container resource usage"
    echo "  23) Disk space usage"
    echo "  24) Network connections"
    echo "  25) System overview"
    echo ""
    echo -e "  ${RED}[Power Management]${NC}"
    echo "  30) Force HDD spindown now"
    echo "  31) Check CPU governor"
    echo "  32) Show power management config"
    echo ""
    echo -e "  ${GREEN}[Maintenance]${NC}"
    echo "  40) Clean Docker (prune unused)"
    echo "  41) Backup Nextcloud database"
    echo "  42) Backup Minecraft world"
    echo "  43) Check for updates"
    echo ""
    echo -e "  ${YELLOW}[Logs & Debugging]${NC}"
    echo "  50) Transmission webhook log"
    echo "  51) View service logs (choose)"
    echo "  52) Check network connectivity"
    echo ""
    echo "  0)  Exit"
    echo ""
    echo -n "  Enter choice: "
}

# Docker service functions
start_all() {
    print_header "Starting All Services"
    cd $PROXY_DIR && docker-compose up -d && cd - > /dev/null
    cd $DASHBOARD_DIR && docker-compose up -d && cd - > /dev/null
    cd $NEXTCLOUD_DIR && docker-compose up -d && cd - > /dev/null
    cd $MEDIA_DIR && docker-compose up -d && cd - > /dev/null
    cd $SYNCTHING_DIR && docker-compose up -d && cd - > /dev/null
    cd $MINECRAFT_DIR && docker-compose up -d && cd - > /dev/null
    print_success "All services started"
    echo ""
    echo "Press Enter to continue..."
    read
}

stop_all() {
    print_header "Stopping All Services"
    cd $PROXY_DIR && docker-compose down && cd - > /dev/null
    cd $DASHBOARD_DIR && docker-compose down && cd - > /dev/null
    cd $NEXTCLOUD_DIR && docker-compose down && cd - > /dev/null
    cd $MEDIA_DIR && docker-compose down && cd - > /dev/null
    cd $SYNCTHING_DIR && docker-compose down && cd - > /dev/null
    cd $MINECRAFT_DIR && docker-compose down && cd - > /dev/null
    print_success "All services stopped"
    echo ""
    echo "Press Enter to continue..."
    read
}

restart_all() {
    print_header "Restarting All Services"
    stop_all
    sleep 2
    start_all
}

service_status() {
    print_header "Service Status"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -v "NAMES" | sort
}

view_logs() {
    print_header "Recent Logs (All Services)"
    docker ps --format "{{.Names}}" | while read container; do
        echo ""
        echo -e "${YELLOW}=== $container ===${NC}"
        docker logs --tail 5 "$container" 2>&1
    done
}

update_all() {
    print_header "Updating All Containers"
    cd $PROXY_DIR && docker-compose pull && docker-compose up -d && cd - > /dev/null
    cd $DASHBOARD_DIR && docker-compose pull && docker-compose up -d && cd - > /dev/null
    cd $NEXTCLOUD_DIR && docker-compose pull && docker-compose up -d && cd - > /dev/null
    cd $MEDIA_DIR && docker-compose pull && docker-compose up -d && cd - > /dev/null
    cd $SYNCTHING_DIR && docker-compose pull && docker-compose up -d && cd - > /dev/null
    cd $MINECRAFT_DIR && docker-compose pull && docker-compose up -d && cd - > /dev/null
    print_success "All containers updated"
    echo ""
    echo "Press Enter to continue..."
    read
}

# Individual service management
manage_service() {
    local service_name=$1
    local service_dir=$2
    
    clear
    print_header "$service_name Management"
    echo ""
    echo "  1) Start"
    echo "  2) Stop"
    echo "  3) Restart"
    echo "  4) Status"
    echo "  5) Logs (follow)"
    echo "  6) Logs (last 50 lines)"
    echo "  0) Back to main menu"
    echo ""
    echo -n "  Enter choice: "
    read choice
    
    case $choice in
        1) cd $service_dir && docker-compose up -d && cd - > /dev/null ;;
        2) cd $service_dir && docker-compose down && cd - > /dev/null ;;
        3) cd $service_dir && docker-compose restart && cd - > /dev/null ;;
        4) cd $service_dir && docker-compose ps && cd - > /dev/null ;;
        5) cd $service_dir && docker-compose logs -f ;;
        6) cd $service_dir && docker-compose logs --tail 50 && cd - > /dev/null ;;
        0) return ;;
    esac
    
    echo ""
    echo "Press Enter to continue..."
    read
}

# System monitoring
hdd_status() {
    print_header "HDD Status & Spindown Info"
    echo ""
    echo -e "${YELLOW}Current HDD State:${NC}"
    sudo hdparm -C /dev/sda
    echo ""
    echo -e "${YELLOW}Spindown Configuration:${NC}"
    grep hdparm /etc/rc.local 2>/dev/null || echo "No spindown configured in rc.local"
    echo ""
    echo -e "${YELLOW}HDD Information:${NC}"
    sudo hdparm -I /dev/sda | grep -E "Model|Serial|Capacity|Standby"
    echo ""
    echo -e "${BLUE}Note: Drive should show 'standby' when idle${NC}"
    echo ""
    echo "Press Enter to continue..."
    read
}

disk_io() {
    print_header "Disk I/O Activity (iotop)"
    echo ""
    echo -e "${YELLOW}Monitoring disk activity... (Press Ctrl+C to stop)${NC}"
    echo ""
    sleep 2
    sudo iotop -aoP
}

container_resources() {
    print_header "Container Resource Usage"
    docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    echo ""
    echo "Press Enter to continue..."
    read
}

disk_space() {
    print_header "Disk Space Usage"
    echo ""
    echo -e "${YELLOW}Overall Disk Usage:${NC}"
    df -h | grep -E "Filesystem|/dev/sd|/dev/nvme|/mnt"
    echo ""
    echo -e "${YELLOW}Docker Directory Usage:${NC}"
    sudo du -sh /opt/docker/* 2>/dev/null | sort -h
    echo ""
    echo -e "${YELLOW}Media Directory Usage:${NC}"
    sudo du -sh /mnt/media/* 2>/dev/null | sort -h
    echo ""
    echo "Press Enter to continue..."
    read
}

network_connections() {
    print_header "Network Connections"
    echo ""
    echo -e "${YELLOW}Docker Networks:${NC}"
    docker network ls
    echo ""
    echo -e "${YELLOW}Active Listening Ports:${NC}"
    sudo ss -tlnp | grep -E "LISTEN" | awk '{print $4, $6}' | column -t
    echo ""
    echo "Press Enter to continue..."
    read
}

system_overview() {
    print_header "System Overview"
    echo ""
    echo -e "${YELLOW}Uptime:${NC}"
    uptime
    echo ""
    echo -e "${YELLOW}CPU Info:${NC}"
    lscpu | grep -E "Model name|CPU\(s\):|Thread|Core"
    echo ""
    echo -e "${YELLOW}Memory Usage:${NC}"
    free -h
    echo ""
    echo -e "${YELLOW}Load Average:${NC}"
    cat /proc/loadavg
    echo ""
    echo -e "${YELLOW}CPU Frequency:${NC}"
    grep MHz /proc/cpuinfo | head -n 1
    echo ""
    echo "Press Enter to continue..."
    read
}

# Power management
force_spindown() {
    print_header "Force HDD Spindown"
    echo ""
    echo -e "${YELLOW}Current state:${NC}"
    sudo hdparm -C /dev/sda
    echo ""
    echo -n "Force spindown now? (y/n): "
    read confirm
    if [ "$confirm" = "y" ]; then
        sudo hdparm -y /dev/sda
        sleep 2
        echo ""
        echo -e "${YELLOW}New state:${NC}"
        sudo hdparm -C /dev/sda
        print_success "HDD spindown forced"
    fi
    echo ""
    echo "Press Enter to continue..."
    read
}

cpu_governor() {
    print_header "CPU Governor Status"
    echo ""
    echo -e "${YELLOW}Current CPU Governor:${NC}"
    cat /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null | sort | uniq -c
    echo ""
    echo -e "${YELLOW}Current CPU Frequencies:${NC}"
    grep MHz /proc/cpuinfo | awk '{print $4}' | sort -n | uniq -c
    echo ""
    echo -e "${YELLOW}Available Governors:${NC}"
    cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null
    echo ""
    echo "Press Enter to continue..."
    read
}

power_config() {
    print_header "Power Management Configuration"
    echo ""
    echo -e "${YELLOW}rc.local content:${NC}"
    cat /etc/rc.local 2>/dev/null || echo "rc.local not found"
    echo ""
    echo -e "${YELLOW}Current settings:${NC}"
    SPINDOWN=$(grep 'hdparm -S' /etc/rc.local 2>/dev/null | awk '{print $3}')
    if [ -n "$SPINDOWN" ]; then
        MINUTES=$((SPINDOWN * 5 / 60))
        echo "  - HDD spindown: $SPINDOWN (${MINUTES} minutes)"
    else
        echo "  - HDD spindown: Not configured"
    fi
    GOVERNOR=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
    echo "  - CPU governor: $GOVERNOR"
    echo ""
    echo "Press Enter to continue..."
    read
}

# Maintenance functions
clean_docker() {
    print_header "Clean Docker (Prune)"
    echo ""
    echo -e "${YELLOW}This will remove:${NC}"
    echo "  - Stopped containers"
    echo "  - Unused networks"
    echo "  - Dangling images"
    echo "  - Build cache"
    echo ""
    echo -n "Continue? (y/n): "
    read confirm
    if [ "$confirm" = "y" ]; then
        docker system prune -a --volumes
        print_success "Docker cleaned"
    fi
    echo ""
    echo "Press Enter to continue..."
    read
}

backup_nextcloud() {
    print_header "Backup Nextcloud Database"
    BACKUP_DIR="/mnt/media/backups"
    BACKUP_FILE="$BACKUP_DIR/nextcloud_db_$(date +%Y%m%d_%H%M%S).sql.gz"
    
    mkdir -p $BACKUP_DIR
    echo ""
    echo "Backing up to: $BACKUP_FILE"
    docker exec nextcloud-database mysqldump -u nextcloud -p nextcloud | gzip > $BACKUP_FILE
    print_success "Backup completed: $BACKUP_FILE"
    echo ""
    echo "Press Enter to continue..."
    read
}

backup_minecraft() {
    print_header "Backup Minecraft World"
    BACKUP_DIR="/mnt/media/backups"
    BACKUP_FILE="$BACKUP_DIR/minecraft_world_$(date +%Y%m%d_%H%M%S).tar.gz"
    
    mkdir -p $BACKUP_DIR
    echo ""
    echo "Saving world..."
    docker exec minecraft rcon-cli save-all 2>/dev/null || echo "Minecraft not running"
    sleep 2
    echo "Creating backup: $BACKUP_FILE"
    sudo tar -czf $BACKUP_FILE -C /opt/docker/minecraft world/ 2>/dev/null
    print_success "Backup completed: $BACKUP_FILE"
    echo ""
    echo "Press Enter to continue..."
    read
}

check_updates() {
    print_header "Check for Updates"
    echo ""
    echo -e "${YELLOW}Checking for new container images...${NC}"
    echo ""
    
    for dir in "$PROXY_DIR" "$DASHBOARD_DIR" "$NEXTCLOUD_DIR" "$MEDIA_DIR" "$SYNCTHING_DIR" "$MINECRAFT_DIR"; do
        echo -e "${BLUE}Checking $(basename $dir)...${NC}"
        cd $dir && docker-compose pull 2>&1 | grep -i "up to date\|downloaded" && cd - > /dev/null
    done
    
    echo ""
    echo "Press Enter to continue..."
    read
}

# Logs & debugging
transmission_webhook_log() {
    print_header "Transmission Webhook Log"
    echo ""
    if [ -f /tmp/transmission-notify.log ]; then
        tail -n 50 /tmp/transmission-notify.log
    else
        print_warning "No webhook log found at /tmp/transmission-notify.log"
    fi
    echo ""
    echo "Press Enter to continue..."
    read
}

choose_service_logs() {
    clear
    print_header "View Service Logs"
    echo ""
    docker ps --format "{{.Names}}" | nl
    echo ""
    echo -n "Enter service number (0 to cancel): "
    read choice
    
    if [ "$choice" != "0" ]; then
        container=$(docker ps --format "{{.Names}}" | sed -n "${choice}p")
        if [ -n "$container" ]; then
            echo ""
            echo -e "${YELLOW}Following logs for: $container (Ctrl+C to stop)${NC}"
            sleep 2
            docker logs -f "$container"
        fi
    fi
}

network_connectivity() {
    print_header "Network Connectivity Test"
    echo ""
    echo -e "${YELLOW}Testing external connectivity...${NC}"
    ping -c 3 8.8.8.8
    echo ""
    echo -e "${YELLOW}Testing DNS resolution...${NC}"
    nslookup google.com 192.168.0.198 2>/dev/null || nslookup google.com
    echo ""
    echo -e "${YELLOW}Testing container connectivity...${NC}"
    docker exec npm ping -c 2 pihole 2>/dev/null || echo "NPM or pihole not running"
    echo ""
    echo "Press Enter to continue..."
    read
}

# Main loop
while true; do
    show_menu
    read choice
    
    case $choice in
        1) start_all ;;
        2) stop_all ;;
        3) restart_all ;;
        4) service_status ; echo "" ; echo "Press Enter to continue..." ; read ;;
        5) view_logs ; echo "" ; echo "Press Enter to continue..." ; read ;;
        6) update_all ;;
        
        10) manage_service "Proxy Services" "$PROXY_DIR" ;;
        11) manage_service "Dashboard" "$DASHBOARD_DIR" ;;
        12) manage_service "Nextcloud Stack" "$NEXTCLOUD_DIR" ;;
        13) manage_service "Media Services" "$MEDIA_DIR" ;;
        14) manage_service "Syncthing" "$SYNCTHING_DIR" ;;
        15) manage_service "Minecraft" "$MINECRAFT_DIR" ;;
        
        20) hdd_status ;;
        21) disk_io ;;
        22) container_resources ;;
        23) disk_space ;;
        24) network_connections ;;
        25) system_overview ;;
        
        30) force_spindown ;;
        31) cpu_governor ;;
        32) power_config ;;
        
        40) clean_docker ;;
        41) backup_nextcloud ;;
        42) backup_minecraft ;;
        43) check_updates ;;
        
        50) transmission_webhook_log ;;
        51) choose_service_logs ;;
        52) network_connectivity ;;
        
        0) 
            clear
            print_success "Goodbye!"
            exit 0
            ;;
        *)
            print_error "Invalid choice"
            sleep 1
            ;;
    esac
done
