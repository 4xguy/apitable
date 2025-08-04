#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping APITable Services...${NC}"

# Function to stop a service
stop_service() {
    local name=$1
    local pidfile=$2
    
    if [ -f "$pidfile" ]; then
        PID=$(cat "$pidfile")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo -e "${YELLOW}Stopping $name (PID: $PID)...${NC}"
            kill "$PID" 2>/dev/null || true
            
            # Wait for process to stop (max 10 seconds)
            for i in {1..10}; do
                if ! ps -p "$PID" > /dev/null 2>&1; then
                    echo -e "${GREEN}✓ $name stopped${NC}"
                    rm -f "$pidfile"
                    return 0
                fi
                sleep 1
            done
            
            # Force kill if still running
            echo -e "${YELLOW}Force killing $name...${NC}"
            kill -9 "$PID" 2>/dev/null || true
            rm -f "$pidfile"
            echo -e "${GREEN}✓ $name force stopped${NC}"
        else
            echo -e "${YELLOW}$name not running (stale PID file)${NC}"
            rm -f "$pidfile"
        fi
    else
        echo -e "${YELLOW}$name not running (no PID file)${NC}"
    fi
}

# Stop application servers
echo -e "\n${YELLOW}Stopping application servers...${NC}"
stop_service "Frontend server" "datasheet.pid"
stop_service "Room server" "room-server.pid"
stop_service "Backend server" "backend-server.pid"

# Also try to stop any orphaned processes
echo -e "\n${YELLOW}Checking for orphaned processes...${NC}"

# Stop any running datasheet dev servers
if pgrep -f "next dev" > /dev/null; then
    echo "Stopping orphaned Next.js processes..."
    pkill -f "next dev" || true
fi

# Stop any running room servers
if pgrep -f "nest start" > /dev/null; then
    echo "Stopping orphaned NestJS processes..."
    pkill -f "nest start" || true
fi

# Stop any running Java backend
if pgrep -f "application.jar" > /dev/null; then
    echo "Stopping orphaned Java processes..."
    pkill -f "application.jar" || true
fi

# Ask about infrastructure
echo -e "\n${YELLOW}Infrastructure services (Docker containers)${NC}"
read -p "Do you want to stop infrastructure services too? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Stopping Docker containers...${NC}"
    docker compose -f docker-compose.yaml -f docker-compose.dataenv.yaml down
    echo -e "${GREEN}✓ Infrastructure services stopped${NC}"
else
    echo -e "${YELLOW}Infrastructure services left running${NC}"
    echo "To stop them manually: docker compose -f docker-compose.yaml -f docker-compose.dataenv.yaml down"
fi

echo -e "\n${GREEN}All application services stopped!${NC}"

# Clean up any leftover log files if they're too big
if [ -d "logs" ]; then
    echo -e "\n${YELLOW}Log files:${NC}"
    ls -lh logs/*.log 2>/dev/null || echo "No log files found"
    read -p "Do you want to clean up log files? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -f logs/*.log
        echo -e "${GREEN}✓ Log files cleaned${NC}"
    fi
fi