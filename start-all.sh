#!/usr/bin/env bash
set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting APITable Services...${NC}"

# Check if infrastructure is running
check_infra() {
    local service=$1
    if docker ps | grep -q "$service"; then
        echo -e "${GREEN}✓ $service is already running${NC}"
        return 0
    else
        echo -e "${RED}✗ $service is not running${NC}"
        return 1
    fi
}

# Start infrastructure if not running
echo -e "\n${YELLOW}Checking infrastructure services...${NC}"
INFRA_OK=true
check_infra "mysql" || INFRA_OK=false
check_infra "redis" || INFRA_OK=false
check_infra "rabbitmq" || INFRA_OK=false
check_infra "minio" || INFRA_OK=false

if [ "$INFRA_OK" = false ]; then
    echo -e "\n${YELLOW}Starting infrastructure services...${NC}"
    docker compose -f docker-compose.yaml -f docker-compose.dataenv.yaml up -d mysql redis rabbitmq minio
    echo "Waiting for services to be ready..."
    sleep 10
fi

# Start backend server in background
echo -e "\n${YELLOW}Starting Backend Server...${NC}"
(
    cd backend-server
    source ../scripts/export-env.sh ../.env 2>/dev/null || true
    source ../scripts/export-env.sh ../.env.devenv 2>/dev/null || true
    export MYSQL_HOST=127.0.0.1
    export REDIS_HOST=127.0.0.1
    export RABBITMQ_HOST=127.0.0.1
    if [ ! -f "application/build/libs/application.jar" ]; then
        echo "Building backend server first..."
        ./gradlew build -x test
    fi
    nohup java -jar application/build/libs/application.jar > ../logs/backend-server.log 2>&1 &
    echo $! > ../backend-server.pid
)
echo -e "${GREEN}✓ Backend server started (PID: $(cat backend-server.pid))${NC}"

# Start room server
echo -e "\n${YELLOW}Starting Room Server...${NC}"
source scripts/export-env.sh .env 2>/dev/null || true
source scripts/export-env.sh .env.devenv 2>/dev/null || true
nohup pnpm run start:room-server > logs/room-server.log 2>&1 &
ROOM_PID=$!
echo $ROOM_PID > room-server.pid
echo -e "${GREEN}✓ Room server started (PID: $ROOM_PID)${NC}"

# Start frontend/datasheet server
echo -e "\n${YELLOW}Starting Frontend Server...${NC}"
nohup pnpm run start:datasheet > logs/datasheet.log 2>&1 &
DATASHEET_PID=$!
echo $DATASHEET_PID > datasheet.pid
echo -e "${GREEN}✓ Frontend server started (PID: $DATASHEET_PID)${NC}"

# Create logs directory if it doesn't exist
mkdir -p logs

echo -e "\n${GREEN}All services started!${NC}"
echo -e "\n${YELLOW}Access points:${NC}"
echo "  Frontend:     http://localhost:3000"
echo "  Backend API:  http://localhost:8081"
echo "  RabbitMQ:     http://localhost:15672"
echo "  MinIO:        http://localhost:9001"
echo ""
echo -e "${YELLOW}Logs:${NC}"
echo "  Backend:  logs/backend-server.log"
echo "  Room:     logs/room-server.log"
echo "  Frontend: logs/datasheet.log"
echo ""
echo -e "${YELLOW}To stop all services, run:${NC} ./stop-all.sh"
echo -e "${YELLOW}To view logs:${NC} tail -f logs/*.log"