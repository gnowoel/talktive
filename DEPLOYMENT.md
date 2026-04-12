# Talktive Deployment Guide

## Overview

This guide covers deploying the Talktive Serverpod backend to a distributed production environment on **Amazon Lightsail**.

### Architecture (Distributed Setup)

| Server | Role | Specs | Network Tier | Private Hostname |
| :--- | :--- | :--- | :--- | :--- |
| **Nginx Server** | Reverse Proxy / SSL | 512MB RAM / 1 vCPU | Public + private networking | `nginx.talktive.internal` |
| **App Server** | Serverpod Engine | 2GB RAM / 1 vCPU | Private networking | `app.talktive.internal` |
| **DB Server** | PostgreSQL 16 + pgvector | 2GB RAM / 1 vCPU | Private networking | `db.talktive.internal` |
| **Cache Server** | Redis 7 | 1GB RAM / 1 vCPU | Private networking | `redis.talktive.internal` |

**Key Benefits:**
- **Security:** Only the Nginx server is exposed to the public internet. All other servers (App, DB, Cache) stay off the public internet and accept traffic only over the residence's private network.
- **Cost Efficiency:** Only one public IPv4 address is required for the Nginx server.
- **Scalability:** High-energy WebSocket traffic can be easily load-balanced across multiple App servers in the future.

---

## Prerequisites

### Required Software
- **Nginx Server**: Nginx, Certbot
- **App Server**: Docker & Docker Compose, Git, Dart SDK 3.11.0+ (compatible with modern Serverpod)
- **DB/Cache Servers**: Native PostgreSQL and Redis

### Required Accounts
- **Amazon Lightsail**: In the `us-east-1` (N. Virginia) region.
- **Cloudflare R2**: For media storage.
- **Firebase project**: For authentication and push notifications.
- **Domain name**: `api.talktive.app` mapped to the **Nginx Server's** Static IP.

---

## Infrastructure Configuration

### 1. Networking (Lightsail VPC)
1. **Private networking**: Place all four instances in the same Lightsail private network.
2. **Static IP**: Attach a Static IP to the **Nginx Server** only.
3. **Internal Routing**: Identify the private IP addresses of all servers.
   - Example: Nginx Private IP `172.26.n.n`, App Private IP `172.26.a.a`, DB Private IP `172.26.d.d`, Redis Private IP `172.26.r.r`.

### 2. Firewall Rules
- **Nginx Server**: Allow 80 (HTTP) and 443 (HTTPS) publicly.
- **App Server**: Allow 8080-8082 **only** from the Nginx Server's Private IP.
- **DB Server**: Allow 5432 **only** from the App Server's Private IP.
- **Cache Server**: Allow 6379 **only** from the App Server's Private IP.

---

## Environment Configuration

### 1. Production Config (production.yaml)

The `talktive_server/config/production.yaml` is the source of truth for environment-specific settings.

```yaml
apiServer:
  port: 8080
  publicHost: api.talktive.app
  publicPort: 443
  publicScheme: https

database:
  host: <DB_PRIVATE_IP> # Use the DB server's Private IPv4
  port: 5432
  name: serverpod
  user: postgres
  requireSsl: false # Private VPC doesn't need SSL overhead

redis:
  enabled: true
  host: <REDIS_PRIVATE_IP> # Use the Redis server's Private IPv4
  port: 6379

storage:
  - id: public
    type: s3
    public: true
    region: auto
    bucket: talktive-media
    endpoint: https://<ACCOUNT_ID>.r2.cloudflarestorage.com
    publicHost: media.talktive.app
```

### 2. Password Configuration (passwords.yaml)

Create `talktive_server/config/passwords.yaml` on the **App Server** (this file should never be committed):

```yaml
# Database
database: <POSTGRES_PASSWORD>

# Redis
redis: <REDIS_PASSWORD>

# Cloudflare R2
storage-public-accessKey: <ACCESS_KEY>
storage-public-secretKey: <SECRET_KEY>

# Serverpod Secrets
jwtSecret: <GENERATED_JWT_SECRET>
sessionSecret: <GENERATED_SESSION_SECRET>
```

Also place your Firebase Admin credentials at `talktive_server/config/firebase_service_account_key.json`, because the server reads that file during startup in both development and production modes.

---

## Deployment Steps

Detailed step-by-step instructions can be found in **[docs/PRODUCTION_RELEASE_GUIDE.md](docs/PRODUCTION_RELEASE_GUIDE.md)**.

### Summary:
1. **Provision Servers**: Launch the 3 specialized Lightsail instances.
2. **Configure DB/Cache**: Set up native PostgreSQL and Redis on their respective servers.
3. **Deploy App**: Build and run the Serverpod Docker container on the App Server.
4. **Setup Nginx**: Configure SSL termination and WebSocket proxying.
5. **Verify**: Run the Serverpod health endpoint with `curl -X POST http://127.0.0.1:8080/health -H 'Content-Type: application/json' -d '{\"method\":\"check\"}'` and monitor logs.
