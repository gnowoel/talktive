# Talktive Deployment Guide

This document is the **architectural overview** for deploying the Talktive Serverpod backend. For the complete, step-by-step runbook, see **[docs/PRODUCTION_RELEASE_GUIDE.md](docs/PRODUCTION_RELEASE_GUIDE.md)**.

---

## Architecture

Talktive runs on a **distributed, private-network** topology hosted on **Amazon Lightsail (`us-east-1`)**. Only the Nginx reverse-proxy is exposed to the public internet. All other services communicate over a Lightsail private network, eliminating egress costs and attack surface.

```
Internet ──► Nginx (Public IP, ports 80/443)
                │
                │ Private VPC (172.26.0.0/16)
                ├──► App Server  :8080/:8081/:8082  (Serverpod Engine)
                ├──► DB Server   :5432               (PostgreSQL 16 + pgvector)
                └──► Cache Server :6379              (Redis 7)
```

### Instance Specifications

| Role | Lightsail Size | RAM | vCPU | Network | Private Hostname |
|:-----|:--------------|:----|:-----|:--------|:----------------|
| **Nginx** (Reverse Proxy / SSL) | nano_3_0 | 512 MB | 1 | Public + Private | `nginx.talktive.internal` |
| **App Server** (Serverpod Engine) | small_3_0 | 2 GB | 1 | Private only | `app.talktive.internal` |
| **DB Server** (PostgreSQL 16 + pgvector) | small_3_0 | 2 GB | 1 | Private only | `db.talktive.internal` |
| **Cache Server** (Redis 7) | micro_3_0 | 1 GB | 1 | Private only | `redis.talktive.internal` |

> **Why this layout?** The 2 vCPU / 4 GB RAM ceiling across App + DB comfortably serves ~10,000 concurrent residents while keeping monthly infrastructure costs minimal. WebSocket connections are long-lived and cheap; the bottleneck is DB I/O, which is isolated to its own instance.

---

## Firewall Rules

Configure these in the Lightsail **Networking** tab for each instance. Lock every rule to the minimum required source.

| Instance | Port(s) | Source | Protocol |
|:---------|:--------|:-------|:---------|
| Nginx | 80, 443 | Anywhere (0.0.0.0/0) | TCP |
| App | 8080-8082 | Nginx Private IP only | TCP |
| DB | 5432 | App Private IP only | TCP |
| Cache | 6379 | App Private IP only | TCP |

> All servers should also allow **22 (SSH)** from your management IP or via Lightsail's browser-based SSH.

---

## Ports

| Port | Service | Description |
|:-----|:--------|:------------|
| `8080` | Serverpod API | REST + WebSocket endpoint |
| `8081` | Serverpod Insights | Internal monitoring dashboard |
| `8082` | Web server | Flutter Web fallback |
| `5432` | PostgreSQL | Database |
| `6379` | Redis | Session cache / pub-sub |

---

## Configuration Files

The server reads two config files at startup. **Neither should ever be committed to the repository.**

### `talktive_server/config/production.yaml`

Controls server addresses, ports, database connection, Redis connection, and Cloudflare R2 storage.

```yaml
apiServer:
  port: 8080
  publicHost: api.talktive.app
  publicPort: 443
  publicScheme: https

insightsServer:
  port: 8081
  publicHost: api.talktive.app
  publicPort: 443
  publicScheme: https

webServer:
  port: 8082
  publicHost: api.talktive.app
  publicPort: 443
  publicScheme: https

database:
  host: <DB_PRIVATE_IP>       # DB Server's Private IPv4 from Lightsail console
  port: 5432
  name: serverpod
  user: postgres
  requireSsl: false            # Private VPC — SSL overhead not needed

redis:
  enabled: true
  host: <REDIS_PRIVATE_IP>    # Cache Server's Private IPv4
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

### `talktive_server/config/passwords.yaml`

Contains all secrets. Create this file directly on the App Server — it is gitignored.

```yaml
database: <POSTGRES_PASSWORD>

redis: <REDIS_PASSWORD>

storage-public-accessKey: <R2_ACCESS_KEY_ID>
storage-public-secretKey: <R2_SECRET_ACCESS_KEY>

jwtSecret: <GENERATED_JWT_SECRET>       # openssl rand -hex 32
serviceSecret: <GENERATED_SERVICE_SECRET> # openssl rand -hex 32
```

### `talktive_server/config/firebase_service_account_key.json`

The Firebase Admin SDK service account JSON. Download from the Firebase console under **Project Settings → Service Accounts**. Place it at this path on the App Server. The server loads it at startup for Google Sign-In verification and FCM push notifications.

---

## DNS Requirements

| Domain | Points To | Purpose |
|:-------|:----------|:--------|
| `api.talktive.app` | Nginx Static IP | API + WebSocket |
| `media.talktive.app` | Cloudflare R2 custom domain | Media CDN |

---

## Prerequisites

### Required Software (per server)

| Server | Software |
|:-------|:---------|
| Nginx | `nginx`, `certbot`, `python3-certbot-nginx` |
| App | `docker`, `docker compose` (v2), `git` |
| DB | `postgresql-16`, `postgresql-16-pgvector` |
| Cache | `redis-server` (Redis 7) |

### Required Third-Party Accounts

- **Amazon Lightsail** — Compute and private networking (`us-east-1`)
- **Cloudflare R2** — Zero-egress media storage (`talktive-media` bucket)
- **Firebase** — Google Sign-In identity provider + FCM push notifications
- **Domain registrar** — `talktive.app` with DNS management access

---

## Deployment Summary

Full instructions are in **[docs/PRODUCTION_RELEASE_GUIDE.md](docs/PRODUCTION_RELEASE_GUIDE.md)**.

| Phase | Where | What |
|:------|:------|:-----|
| 1 | Lightsail Console | Provision instances, assign Static IP, configure firewalls |
| 2 | DB Server | Install PostgreSQL 16 + pgvector, create database and extensions |
| 3 | Cache Server | Install and configure Redis 7 with a strong password |
| 4 | App Server | Clone repo, write config files, build Docker image, apply migrations, run container |
| 5 | Nginx Server | Install Nginx, deploy `docs/nginx/talktive.conf`, issue SSL cert via Certbot |
| 6 | Flutter clients | Set `apiUrl` in `assets/config.json`, build and publish release binaries |
| 7 | Verification | Health checks, log inspection, smoke-test sign-in and messaging |

### Quick Health Check (from App Server)

```bash
# Liveness
curl -s -X POST http://127.0.0.1:8080/health \
  -H 'Content-Type: application/json' \
  -d '{"method":"check"}' | jq

# Readiness
curl -s -X POST http://127.0.0.1:8080/health \
  -H 'Content-Type: application/json' \
  -d '{"method":"ready"}' | jq
```

---

## Updating the App

```bash
# On App Server — pull latest code, rebuild image, restart container
cd talktive/talktive_server
git pull origin main
docker build -t talktive-server -f Dockerfile.production .
docker stop talktive-server && docker rm talktive-server
docker run -d --name talktive-server --restart unless-stopped \
  -p 8080:8080 -p 8081:8081 -p 8082:8082 \
  -v $(pwd)/config:/app/config \
  talktive-server
```

> Run `dart bin/main.dart --apply-migrations` (or an equivalent one-off container) **before** replacing the running container whenever the release includes database schema changes.
