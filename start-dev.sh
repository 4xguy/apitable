#!/usr/bin/env bash
# Development server starter with tmux/screen support for better process management

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
USE_TMUX=false
SESSION_NAME="apitable-dev"

# Check for tmux
if command -v tmux >/dev/null 2>&1; then
    USE_TMUX=true
    echo -e "${GREEN}Using tmux for session management${NC}"
else
    echo -e "${YELLOW}tmux not found. Install tmux for better experience: sudo apt install tmux${NC}"
fi

# Create necessary directories
mkdir -p logs

# Function to check if port is in use
check_port() {
    local port=$1
    if ss -tuln | grep -q ":$port "; then
        echo -e "${RED}Port $port is already in use!${NC}"
        return 1
    fi
    return 0
}

# Check critical ports
echo -e "${YELLOW}Checking ports...${NC}"
PORTS_OK=true
check_port 3000 || { echo "Frontend port 3000 in use"; PORTS_OK=false; }
check_port 3333 || { echo "Room server port 3333 in use"; PORTS_OK=false; }
check_port 8081 || { echo "Backend port 8081 in use"; PORTS_OK=false; }

if [ "$PORTS_OK" = false ]; then
    echo -e "${RED}Please free up the ports before starting${NC}"
    exit 1
fi

# Start infrastructure
echo -e "\n${YELLOW}Starting infrastructure...${NC}"
docker compose -f docker-compose.yaml -f docker-compose.dataenv.yaml up -d mysql redis rabbitmq minio

# Wait for services
echo "Waiting for infrastructure to be ready..."
for i in {1..30}; do
    if docker exec mysql mysqladmin ping -h localhost --silent 2>/dev/null; then
        echo -e "${GREEN}✓ MySQL is ready${NC}"
        break
    fi
    echo -n "."
    sleep 1
done

# Export environment variables
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi
if [ -f .env.devenv ]; then
    export $(grep -v '^#' .env.devenv | xargs)
fi

if [ "$USE_TMUX" = true ]; then
    # Kill existing session if it exists
    tmux kill-session -t "$SESSION_NAME" 2>/dev/null || true
    
    # Create new tmux session
    echo -e "\n${BLUE}Starting services in tmux session: $SESSION_NAME${NC}"
    
    # Create session with backend server
    tmux new-session -d -s "$SESSION_NAME" -n "backend" -c "$PWD/backend-server" \
        "echo 'Starting Backend Server...'; \
         export MYSQL_HOST=127.0.0.1; \
         export REDIS_HOST=127.0.0.1; \
         export RABBITMQ_HOST=127.0.0.1; \
         if [ ! -f application/build/libs/application.jar ]; then \
             ./gradlew build -x test; \
         fi; \
         java -jar application/build/libs/application.jar; \
         read -p 'Press enter to exit...'"
    
    # Create room server window
    tmux new-window -t "$SESSION_NAME:2" -n "room" -c "$PWD" \
        "echo 'Starting Room Server...'; \
         pnpm run start:room-server; \
         read -p 'Press enter to exit...'"
    
    # Create frontend window
    tmux new-window -t "$SESSION_NAME:3" -n "frontend" -c "$PWD" \
        "echo 'Starting Frontend Server...'; \
         pnpm run start:datasheet; \
         read -p 'Press enter to exit...'"
    
    # Create logs window
    tmux new-window -t "$SESSION_NAME:4" -n "logs" -c "$PWD" \
        "echo 'Log viewer - Press Ctrl+C to exit'; \
         tail -f logs/*.log 2>/dev/null || echo 'Waiting for logs...'; \
         bash"
    
    echo -e "${GREEN}All services started in tmux!${NC}"
    echo -e "\n${YELLOW}tmux commands:${NC}"
    echo "  Attach to session:  tmux attach -t $SESSION_NAME"
    echo "  List windows:       Ctrl+b w"
    echo "  Switch windows:     Ctrl+b [0-4]"
    echo "  Detach:            Ctrl+b d"
    echo "  Kill session:      tmux kill-session -t $SESSION_NAME"
    
else
    # Fallback to background processes
    echo -e "\n${YELLOW}Starting services in background...${NC}"
    
    # Backend
    (
        cd backend-server
        export MYSQL_HOST=127.0.0.1
        export REDIS_HOST=127.0.0.1
        export RABBITMQ_HOST=127.0.0.1
        if [ ! -f application/build/libs/application.jar ]; then
            ./gradlew build -x test
        fi
        nohup java -jar application/build/libs/application.jar > ../logs/backend-server.log 2>&1 &
        echo $! > ../backend-server.pid
    )
    
    # Room server
    nohup pnpm run start:room-server > logs/room-server.log 2>&1 &
    echo $! > room-server.pid
    
    # Frontend
    nohup pnpm run start:datasheet > logs/datasheet.log 2>&1 &
    echo $! > datasheet.pid
    
    echo -e "${GREEN}All services started!${NC}"
    echo -e "${YELLOW}View logs with:${NC} tail -f logs/*.log"
fi

echo -e "\n${GREEN}APITable Development Environment Ready!${NC}"
echo -e "\n${BLUE}Access points:${NC}"
echo "  Frontend:        http://localhost:3000"
echo "  Backend API:     http://localhost:8081/api/v1/"
echo "  Room Server:     http://localhost:3333"
echo "  RabbitMQ Admin:  http://localhost:15672 (guest/guest)"
echo "  MinIO Console:   http://localhost:9001"

if [ "$USE_TMUX" = false ]; then
    echo -e "\n${YELLOW}Stop all services with:${NC} ./stop-all.sh"
fi