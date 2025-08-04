#!/bin/bash
# Deploy individual services to Railway
# Run this from the railway directory

set -e

SERVICE=$1

if [ -z "$SERVICE" ]; then
    echo "Usage: ./deploy-services.sh <service-name>"
    echo ""
    echo "Available services:"
    echo "  - backend-server"
    echo "  - room-server"
    echo "  - web-server"
    echo "  - databus-server"
    echo "  - imageproxy-server"
    echo "  - gateway"
    echo "  - rabbitmq"
    echo "  - minio"
    exit 1
fi

# Special handling for infrastructure services
if [ "$SERVICE" == "rabbitmq" ] || [ "$SERVICE" == "minio" ]; then
    cd infrastructure
    railway up -d ${SERVICE}.Dockerfile --service $SERVICE
    cd ..
else
    cd $SERVICE
    railway up --service $SERVICE
    cd ..
fi

echo "✅ $SERVICE deployed successfully"