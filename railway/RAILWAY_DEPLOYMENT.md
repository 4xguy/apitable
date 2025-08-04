# APITable Railway Deployment Guide

This guide explains how to deploy APITable to Railway.com using the prepared Dockerfile configuration.

## Prerequisites

1. **Railway Account**: Sign up at [railway.app](https://railway.app)
2. **Railway CLI**: Install with `npm install -g @railway/cli`
3. **GitHub Repository**: Your forked APITable repository

## Architecture Overview

APITable consists of 11 services that will be deployed as separate Railway services:

### Infrastructure Services
- **MySQL** - Database (Railway Plugin)
- **Redis** - Cache & Queue (Railway Plugin)
- **RabbitMQ** - Message Queue (Custom Docker)
- **MinIO** - S3-compatible Object Storage (Custom Docker)

### Application Services
- **gateway** - Nginx reverse proxy (port 80/443)
- **web-server** - Next.js frontend (port 8080)
- **backend-server** - Java Spring Boot API (port 8081)
- **room-server** - Node.js real-time collaboration (ports 3333, 3002, 3005, 3006)
- **databus-server** - Data synchronization service (port 8625)
- **imageproxy-server** - Image processing proxy (port 8080)

### Init Jobs (One-time)
- **init-db** - Database schema initialization
- **init-appdata** - Initial data seeding

## Step-by-Step Deployment

### 1. Create Railway Project

```bash
# Login to Railway
railway login

# Create new project
railway init
# Or link to existing project
railway link [project-id]
```

### 2. Deploy Infrastructure Services

#### MySQL & Redis (via Railway Dashboard)
1. Open Railway dashboard
2. Press `Cmd/Ctrl + K` 
3. Search and add "MySQL"
4. Search and add "Redis"

#### RabbitMQ & MinIO (Custom Services)
```bash
cd railway/infrastructure

# Deploy RabbitMQ
railway service create rabbitmq
railway up -d rabbitmq.Dockerfile --service rabbitmq

# Deploy MinIO
railway service create minio
railway up -d minio.Dockerfile --service minio
```

### 3. Configure Environment Variables

1. Copy `railway-env-template.env` as reference
2. In Railway dashboard, go to each service
3. Click "Variables" tab
4. Add required environment variables

**Important Variables to Set:**
- Database credentials (auto-generated for MySQL/Redis)
- Service internal URLs (use `.railway.internal` domains)
- Public gateway URL (after deployment)

### 4. Deploy Application Services

Deploy services in this order:

```bash
cd railway

# 1. Backend Server (depends on MySQL)
cd backend-server
railway service create backend-server
railway up --service backend-server
cd ..

# 2. Room Server (depends on MySQL/Redis)
cd room-server
railway service create room-server
railway up --service room-server
cd ..

# 3. Web Server
cd web-server
railway service create web-server
railway up --service web-server
cd ..

# 4. Databus Server
cd databus-server
railway service create databus-server
railway up --service databus-server
cd ..

# 5. Imageproxy Server
cd imageproxy-server
railway service create imageproxy-server
railway up --service imageproxy-server
cd ..
```

### 5. Initialize Database

Run one-time initialization jobs:

```bash
cd railway/init-scripts

# Initialize database schema
railway run --service backend-server "cd /app && java -jar init-db.jar"

# Initialize application data
railway run --service backend-server "cd /app && java -jar init-appdata.jar"
```

### 6. Deploy Gateway (Last)

```bash
cd railway/gateway
railway service create gateway
railway up --service gateway
```

### 7. Configure Public Access

1. In Railway dashboard, go to gateway service
2. Settings → Networking → Generate Domain
3. Copy the public URL
4. Update environment variables with public URL

## Environment Variables Reference

### Shared Variables (Project Level)
```env
# Database (from Railway MySQL)
DATABASE_URL=${{MySQL.DATABASE_URL}}
MYSQL_HOST=${{MySQL.RAILWAY_PRIVATE_DOMAIN}}
MYSQL_DATABASE=${{MySQL.MYSQL_DATABASE}}
MYSQL_PASSWORD=${{MySQL.MYSQL_ROOT_PASSWORD}}

# Redis (from Railway Redis)
REDIS_URL=${{Redis.REDIS_URL}}
REDIS_HOST=${{Redis.RAILWAY_PRIVATE_DOMAIN}}
REDIS_PASSWORD=${{Redis.REDIS_PASSWORD}}

# RabbitMQ
RABBITMQ_HOST=rabbitmq.railway.internal
RABBITMQ_USERNAME=apitable
RABBITMQ_PASSWORD=apitable@com

# MinIO
MINIO_HOST=minio.railway.internal
MINIO_ACCESS_KEY=apitable
MINIO_SECRET_KEY=apitable@com
```

### Service-Specific Variables

Each service needs specific environment variables. See `railway-env-template.env` for complete list.

## Networking

Railway provides automatic internal networking between services:

- Internal domain format: `[service-name].railway.internal`
- All services can communicate internally without public exposure
- Only the gateway service needs public domain

### Internal Service URLs
- Backend: `http://backend-server.railway.internal:8081`
- Room Server: `http://room-server.railway.internal:3333`
- Web Server: `http://web-server.railway.internal:8080`
- MinIO: `http://minio.railway.internal:9000`

## Troubleshooting

### Service Won't Start
1. Check logs: `railway logs --service [service-name]`
2. Verify environment variables are set
3. Check health check endpoints

### Database Connection Issues
1. Ensure MySQL is fully deployed
2. Verify DATABASE_URL format
3. Check if init-db ran successfully

### Gateway 502 Errors
1. Verify all backend services are running
2. Check nginx upstream configuration
3. Confirm internal domains are correct

### Memory/Performance Issues
1. Scale services individually in Railway dashboard
2. Adjust memory limits in environment variables
3. Enable autoscaling for high-traffic services

## Automated Deployment

Use the provided scripts:

```bash
# Full deployment
./railway/deploy-to-railway.sh

# Deploy individual service
./railway/deploy-services.sh [service-name]
```

## Cost Estimation

Railway pricing (as of 2024):
- $5/month credit included
- Pay for resources used:
  - CPU: $0.000463/vCPU minute
  - Memory: $0.000231/GB minute
  - Network: $0.10/GB egress

Estimated monthly cost for APITable:
- Development: ~$20-40/month
- Production: ~$50-150/month (depending on traffic)

## Security Considerations

1. **Change default passwords** in production
2. **Use Railway's secret management** for sensitive values
3. **Enable SSL** on custom domains
4. **Restrict internal services** from public access
5. **Regular backups** for MySQL and MinIO data

## Next Steps

1. Configure custom domain
2. Set up monitoring/alerts
3. Configure backups
4. Implement CI/CD with GitHub Actions
5. Set up staging environment

## Support

- Railway Documentation: https://docs.railway.app
- Railway Discord: https://discord.gg/railway
- APITable Issues: https://github.com/apitable/apitable/issues