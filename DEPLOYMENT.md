# Talktive Deployment Guide

## Overview

This guide covers deploying the Talktive Serverpod backend to production. The application uses:
- **Backend**: Serverpod 3.4.2 (Dart)
- **Database**: PostgreSQL 16+
- **Cache**: Redis 7+
- **Authentication**: Firebase Auth + Serverpod Auth Core

---

## Prerequisites

### Required Software
- Docker & Docker Compose
- Git
- Dart SDK 3.8.0+
- PostgreSQL 16+ (or Docker)
- Redis 7+ (or Docker)

### Required Accounts
- Firebase project (for authentication)
- Domain name with DNS access
- SSL certificate (Let's Encrypt recommended)
- Optional: Sentry account (for error tracking)

---

## Environment Configuration

### 1. Environment Variables

Create a `.env` file in `talktive_server/`:

```bash
# Server Configuration
SERVERPOD_ENV=production
SERVER_PORT=8080
API_PORT=8081
INSIGHTS_PORT=8082

# Database Configuration
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=talktive_production
POSTGRES_USER=talktive_user
POSTGRES_PASSWORD=<strong-password-here>

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_PASSWORD=<redis-password-here>

# Firebase Configuration
FIREBASE_PROJECT_ID=<your-project-id>
FIREBASE_API_KEY=<your-api-key>

# Security
JWT_SECRET=<generate-strong-secret>
SESSION_SECRET=<generate-strong-secret>

# Monitoring (Optional)
SENTRY_DSN=<your-sentry-dsn>
LOG_LEVEL=info
```

### 2. Generate Secrets

```bash
# Generate strong secrets
openssl rand -base64 32  # For JWT_SECRET
openssl rand -base64 32  # For SESSION_SECRET
openssl rand -base64 32  # For POSTGRES_PASSWORD
openssl rand -base64 32  # For REDIS_PASSWORD
```

---

## Production Server Setup

### Option 1: Docker Compose (Recommended)

Create `docker-compose.production.yml`:

```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: talktive_postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    container_name: talktive_redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  serverpod:
    build:
      context: .
      dockerfile: Dockerfile.production
    container_name: talktive_server
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    environment:
      SERVERPOD_ENV: production
      POSTGRES_HOST: postgres
      POSTGRES_PORT: 5432
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      REDIS_HOST: redis
      REDIS_PORT: 6379
      REDIS_PASSWORD: ${REDIS_PASSWORD}
      JWT_SECRET: ${JWT_SECRET}
      SESSION_SECRET: ${SESSION_SECRET}
    ports:
      - "8080:8080"
      - "8081:8081"
      - "8082:8082"
    volumes:
      - ./uploads:/app/uploads
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  redis_data:
```

### Option 2: Manual Installation

#### 1. Install PostgreSQL

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql-16 postgresql-contrib

# Create database and user
sudo -u postgres psql
CREATE DATABASE talktive_production;
CREATE USER talktive_user WITH ENCRYPTED PASSWORD 'your-password';
GRANT ALL PRIVILEGES ON DATABASE talktive_production TO talktive_user;
\q
```

#### 2. Install Redis

```bash
# Ubuntu/Debian
sudo apt install redis-server

# Configure Redis password
sudo nano /etc/redis/redis.conf
# Add: requirepass your-redis-password

sudo systemctl restart redis
```

#### 3. Install Dart SDK

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install apt-transport-https
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list

sudo apt update
sudo apt install dart
```

---

## Deployment Steps

### 1. Clone Repository

```bash
git clone https://github.com/your-org/talktive.git
cd talktive/talktive_server
```

### 2. Install Dependencies

```bash
dart pub get
```

### 3. Generate Code

```bash
serverpod generate
```

### 4. Run Migrations

```bash
# Apply all migrations
dart run bin/main.dart --apply-migrations

# Or apply specific migration
dart run bin/main.dart --apply-migrations --migration=<migration-name>
```

### 5. Start Server

#### Using Docker Compose

```bash
docker-compose -f docker-compose.production.yml up -d
```

#### Using Systemd Service

Create `/etc/systemd/system/talktive.service`:

```ini
[Unit]
Description=Talktive Serverpod Server
After=network.target postgresql.service redis.service

[Service]
Type=simple
User=talktive
WorkingDirectory=/opt/talktive/talktive_server
Environment="PATH=/usr/lib/dart/bin:/usr/bin"
ExecStart=/usr/lib/dart/bin/dart run bin/main.dart
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Enable and start:

```bash
sudo systemctl daemon-reload
sudo systemctl enable talktive
sudo systemctl start talktive
sudo systemctl status talktive
```

---

## Nginx Reverse Proxy

### 1. Install Nginx

```bash
sudo apt install nginx
```

### 2. Configure Nginx

Create `/etc/nginx/sites-available/talktive`:

```nginx
upstream serverpod_api {
    server localhost:8080;
}

upstream serverpod_insights {
    server localhost:8082;
}

server {
    listen 80;
    server_name api.talktive.app;

    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.talktive.app;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/api.talktive.app/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.talktive.app/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # API Proxy
    location / {
        proxy_pass http://serverpod_api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # WebSocket Support
    location /ws {
        proxy_pass http://serverpod_api;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 86400;
    }

    # Static Files (Uploads)
    location /uploads {
        alias /opt/talktive/talktive_server/uploads;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Health Check
    location /health {
        proxy_pass http://serverpod_api/health;
        access_log off;
    }
}

# Insights Dashboard (Admin Only)
server {
    listen 443 ssl http2;
    server_name insights.talktive.app;

    ssl_certificate /etc/letsencrypt/live/insights.talktive.app/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/insights.talktive.app/privkey.pem;

    # Basic Auth for Security
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;

    location / {
        proxy_pass http://serverpod_insights;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable site:

```bash
sudo ln -s /etc/nginx/sites-available/talktive /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 3. SSL Certificate (Let's Encrypt)

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d api.talktive.app -d insights.talktive.app
```

---

## Monitoring & Logging

### 1. Application Logs

```bash
# View logs (systemd)
sudo journalctl -u talktive -f

# View logs (Docker)
docker logs -f talktive_server
```

### 2. Database Monitoring

```bash
# PostgreSQL connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"

# Database size
sudo -u postgres psql -d talktive_production -c "SELECT pg_size_pretty(pg_database_size('talktive_production'));"
```

### 3. Redis Monitoring

```bash
redis-cli -a your-password INFO stats
redis-cli -a your-password MONITOR
```

### 4. Sentry Integration (Optional)

Add to `config/production.yaml`:

```yaml
sentry:
  dsn: 'your-sentry-dsn'
  environment: 'production'
  tracesSampleRate: 0.1
```

---

## Backup & Recovery

### 1. Database Backup

Create backup script `/opt/talktive/backup.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/opt/talktive/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/talktive_$DATE.sql.gz"

mkdir -p $BACKUP_DIR

# Backup database
PGPASSWORD=your-password pg_dump -h localhost -U talktive_user talktive_production | gzip > $BACKUP_FILE

# Keep only last 7 days
find $BACKUP_DIR -name "talktive_*.sql.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_FILE"
```

Add to crontab:

```bash
# Daily backup at 2 AM
0 2 * * * /opt/talktive/backup.sh
```

### 2. Redis Backup

Redis automatically saves to `/var/lib/redis/dump.rdb`. Configure in `/etc/redis/redis.conf`:

```
save 900 1
save 300 10
save 60 10000
```

### 3. Restore Database

```bash
gunzip < backup_file.sql.gz | psql -h localhost -U talktive_user talktive_production
```

---

## Performance Tuning

### PostgreSQL

Edit `/etc/postgresql/16/main/postgresql.conf`:

```
# Memory
shared_buffers = 256MB
effective_cache_size = 1GB
work_mem = 16MB

# Connections
max_connections = 100

# Logging
log_min_duration_statement = 1000  # Log slow queries (>1s)
```

### Redis

Edit `/etc/redis/redis.conf`:

```
maxmemory 512mb
maxmemory-policy allkeys-lru
```

---

## Security Checklist

- [ ] Strong passwords for all services
- [ ] Firewall configured (UFW or iptables)
- [ ] SSL certificates installed and auto-renewing
- [ ] Database not exposed to public internet
- [ ] Redis password protected
- [ ] Regular security updates
- [ ] Backup system tested
- [ ] Monitoring and alerting configured
- [ ] Rate limiting enabled
- [ ] Content filtering active

---

## Troubleshooting

### Server Won't Start

```bash
# Check logs
sudo journalctl -u talktive -n 50

# Check ports
sudo netstat -tulpn | grep -E '8080|8081|8082'

# Check database connection
psql -h localhost -U talktive_user -d talktive_production
```

### High Memory Usage

```bash
# Check process memory
ps aux | grep dart

# Check Redis memory
redis-cli -a your-password INFO memory

# Check PostgreSQL connections
sudo -u postgres psql -c "SELECT count(*) FROM pg_stat_activity;"
```

### Slow Queries

```bash
# Enable slow query log in PostgreSQL
sudo -u postgres psql -d talktive_production
ALTER SYSTEM SET log_min_duration_statement = 1000;
SELECT pg_reload_conf();

# View slow queries
sudo tail -f /var/log/postgresql/postgresql-16-main.log
```

---

## Scaling Considerations

### Horizontal Scaling

- Use load balancer (Nginx, HAProxy, or cloud LB)
- Run multiple Serverpod instances
- Shared PostgreSQL and Redis
- Session affinity for WebSocket connections

### Vertical Scaling

- Increase server resources (CPU, RAM)
- Optimize database queries
- Increase Redis memory
- Use connection pooling

### Database Scaling

- Read replicas for read-heavy workloads
- Connection pooling (PgBouncer)
- Partitioning for large tables
- Regular VACUUM and ANALYZE

---

## Maintenance

### Regular Tasks

- **Daily**: Check logs for errors
- **Weekly**: Review performance metrics
- **Monthly**: Update dependencies
- **Quarterly**: Security audit

### Updates

```bash
# Update Dart packages
cd talktive_server
dart pub upgrade

# Regenerate code
serverpod generate

# Run tests
dart test

# Apply new migrations
dart run bin/main.dart --apply-migrations

# Restart server
sudo systemctl restart talktive
```

---

## Support

For issues or questions:
- GitHub Issues: https://github.com/your-org/talktive/issues
- Documentation: https://docs.talktive.app
- Email: support@talktive.app
