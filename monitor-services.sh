#!/usr/bin/env bash
# Service monitoring script

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

clear

while true; do
    echo -e "${BLUE}=== APITable Service Status ===${NC}"
    echo -e "$(date)"
    echo ""
    
    # Check Docker services
    echo -e "${YELLOW}Infrastructure Services:${NC}"
    for service in mysql redis rabbitmq minio; do
        if docker ps | grep -q "$service"; then
            STATUS=$(docker ps --filter "name=$service" --format "table {{.Status}}" | tail -n 1)
            echo -e "  $service: ${GREEN}✓ Running${NC} - $STATUS"
        else
            echo -e "  $service: ${RED}✗ Not running${NC}"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Application Services:${NC}"
    
    # Check backend
    if pgrep -f "application.jar" > /dev/null; then
        echo -e "  Backend Server: ${GREEN}✓ Running${NC} (PID: $(pgrep -f application.jar))"
    else
        echo -e "  Backend Server: ${RED}✗ Not running${NC}"
    fi
    
    # Check room server
    if pgrep -f "nest start" > /dev/null || pgrep -f "room-server" > /dev/null; then
        echo -e "  Room Server:    ${GREEN}✓ Running${NC} (PID: $(pgrep -f 'nest start' || pgrep -f 'room-server'))"
    else
        echo -e "  Room Server:    ${RED}✗ Not running${NC}"
    fi
    
    # Check frontend
    if pgrep -f "next dev" > /dev/null; then
        echo -e "  Frontend:       ${GREEN}✓ Running${NC} (PID: $(pgrep -f 'next dev'))"
    else
        echo -e "  Frontend:       ${RED}✗ Not running${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Port Status:${NC}"
    for port in 3000 3333 8081 6379 3306 5672 9000; do
        if ss -tuln | grep -q ":$port "; then
            case $port in
                3000) SERVICE="Frontend" ;;
                3333) SERVICE="Room Server" ;;
                8081) SERVICE="Backend API" ;;
                6379) SERVICE="Redis" ;;
                3306) SERVICE="MySQL" ;;
                5672) SERVICE="RabbitMQ" ;;
                9000) SERVICE="MinIO" ;;
            esac
            echo -e "  Port $port: ${GREEN}✓${NC} $SERVICE"
        else
            echo -e "  Port $port: ${RED}✗${NC} Not listening"
        fi
    done
    
    echo ""
    echo -e "${YELLOW}Recent Logs:${NC}"
    if [ -d logs ]; then
        for log in logs/*.log; do
            if [ -f "$log" ]; then
                echo -e "  $(basename "$log"):"
                tail -n 3 "$log" 2>/dev/null | sed 's/^/    /'
            fi
        done
    fi
    
    echo ""
    echo -e "${BLUE}Press Ctrl+C to exit | Refreshing in 5 seconds...${NC}"
    sleep 5
    clear
done