#!/bin/bash
# Deploy APITable to Railway

set -e

echo "🚂 APITable Railway Deployment Script"
echo "===================================="

# Check if Railway CLI is installed
if ! command -v railway &> /dev/null; then
    echo "❌ Railway CLI not found. Please install it first:"
    echo "   npm install -g @railway/cli"
    exit 1
fi

# Check if logged in to Railway
if ! railway whoami &> /dev/null; then
    echo "❌ Not logged in to Railway. Please run:"
    echo "   railway login"
    exit 1
fi

echo "✅ Railway CLI is installed and authenticated"

# Get project ID
read -p "Enter your Railway project ID (or press Enter to create new): " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "Creating new Railway project..."
    railway init
    PROJECT_ID=$(railway status --json | jq -r '.projectId')
    echo "✅ Created project: $PROJECT_ID"
else
    echo "Using existing project: $PROJECT_ID"
fi

echo ""
echo "📦 Deploying Infrastructure Services..."
echo "======================================="

# Deploy MySQL (using Railway plugin)
echo "1. MySQL - Please add via Railway dashboard (Cmd/Ctrl+K → MySQL)"
read -p "Press Enter when MySQL is added..."

# Deploy Redis (using Railway plugin)
echo "2. Redis - Please add via Railway dashboard (Cmd/Ctrl+K → Redis)"
read -p "Press Enter when Redis is added..."

# Deploy RabbitMQ
echo "3. Deploying RabbitMQ..."
cd infrastructure
railway link $PROJECT_ID
railway service create rabbitmq
railway up -d rabbitmq.Dockerfile
cd ..

# Deploy MinIO
echo "4. Deploying MinIO..."
cd infrastructure
railway service create minio
railway up -d minio.Dockerfile
cd ..

echo ""
echo "⏳ Waiting for infrastructure to be ready (30s)..."
sleep 30

echo ""
echo "🚀 Deploying Application Services..."
echo "===================================="

# Deploy services in order
services=(
    "backend-server"
    "room-server"
    "web-server"
    "databus-server"
    "imageproxy-server"
)

for service in "${services[@]}"; do
    echo "Deploying $service..."
    cd $service
    railway link $PROJECT_ID
    railway service create $service
    railway up
    cd ..
    echo "✅ $service deployed"
    sleep 5
done

echo ""
echo "🔧 Running Database Initialization..."
echo "===================================="

# Run init-db
echo "Running database initialization..."
cd init-scripts
railway link $PROJECT_ID
railway run --service init-db "docker build -f init-db.Dockerfile . && docker run --rm init-db"
echo "✅ Database initialized"

# Run init-appdata
echo "Running application data initialization..."
railway run --service init-appdata "docker build -f init-appdata.Dockerfile . && docker run --rm init-appdata"
echo "✅ Application data initialized"
cd ..

echo ""
echo "🌐 Deploying Gateway (Nginx)..."
echo "==============================="

cd gateway
railway link $PROJECT_ID
railway service create gateway
railway up
cd ..

echo ""
echo "✅ Deployment Complete!"
echo "======================"
echo ""
echo "Next steps:"
echo "1. Set environment variables in Railway dashboard"
echo "2. Configure custom domain for the gateway service"
echo "3. Update PUBLIC_URL in environment variables"
echo ""
echo "Access your Railway project at:"
echo "https://railway.app/project/$PROJECT_ID"