# Production Release Guide: Talktive

> **Runbook** — Follow these phases in order for every fresh deployment. For architectural context and configuration reference, see **[DEPLOYMENT.md](../DEPLOYMENT.md)**.

---

## Phase 1 — Provision Infrastructure

### 1.1 Launch Lightsail Instances

In the [Amazon Lightsail console](https://lightsail.aws.amazon.com) (`us-east-1` region), launch **four Ubuntu 24.04 LTS** instances:

| # | Name | Blueprint | Plan |
|:--|:-----|:----------|:-----|
| 1 | `talktive-nginx` | Ubuntu 24.04 LTS | 512 MB / 1 vCPU |
| 2 | `talktive-app` | Ubuntu 24.04 LTS | 2 GB / 1 vCPU |
| 3 | `talktive-db` | Ubuntu 24.04 LTS | 2 GB / 1 vCPU |
| 4 | `talktive-cache` | Ubuntu 24.04 LTS | 1 GB / 1 vCPU |

### 1.2 Networking

1. **Private Network**: Enable Lightsail VPC private networking. Attach all four instances to the same private network.
2. **Static IP**: Attach a Static IP to `talktive-nginx` only.
3. **Record Private IPs**: Open the **Networking** tab for each instance and note the private IPv4:

   ```
   NGINX_PRIVATE_IP=172.26.?.?
   APP_PRIVATE_IP=172.26.?.?
   DB_PRIVATE_IP=172.26.?.?
   CACHE_PRIVATE_IP=172.26.?.?
   ```

4. **DNS**: In your domain registrar / Cloudflare, create:
   - `api.talktive.app` → `<NGINX_STATIC_IP>` (A record)

### 1.3 Firewall Rules

Configure in the Lightsail **Networking** tab for each instance. Remove any default-open rules that are not listed below.

**`talktive-nginx`**:
- SSH (22) — Your management IP
- HTTP (80) — Anywhere
- HTTPS (443) — Anywhere

**`talktive-app`**:
- SSH (22) — Your management IP
- TCP 8080-8082 — `<NGINX_PRIVATE_IP>` only

**`talktive-db`**:
- SSH (22) — Your management IP
- TCP 5432 — `<APP_PRIVATE_IP>` only

**`talktive-cache`**:
- SSH (22) — Your management IP
- TCP 6379 — `<APP_PRIVATE_IP>` only

---

## Phase 2 — Database Server Setup

SSH into `talktive-db`:

```bash
ssh ubuntu@<DB_PRIVATE_IP>
```

### 2.1 Install PostgreSQL 16 + pgvector

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y postgresql-16 postgresql-16-pgvector
```

### 2.2 Allow Remote Connections

Edit `/etc/postgresql/16/main/postgresql.conf`:

```bash
sudo nano /etc/postgresql/16/main/postgresql.conf
```

Find and set:

```conf
listen_addresses = '*'
```

Edit `/etc/postgresql/16/main/pg_hba.conf` — add one line at the bottom:

```bash
sudo nano /etc/postgresql/16/main/pg_hba.conf
```

```conf
# Allow App Server to connect using password auth
host    serverpod    postgres    <APP_PRIVATE_IP>/32    md5
```

### 2.3 Create Database, Extensions, and Set Password

```bash
sudo -u postgres psql
```

Inside the psql shell:

```sql
-- Create the application database
CREATE DATABASE serverpod;

-- Connect and enable extensions
\c serverpod

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- Used for full-text resident search

-- Set a strong password for the postgres user
ALTER USER postgres WITH PASSWORD '<POSTGRES_PASSWORD>';

\q
```

### 2.4 Restart PostgreSQL

```bash
sudo systemctl restart postgresql
sudo systemctl enable postgresql
```

**Verify** connectivity from the App Server (run after Phase 4.1):

```bash
psql -h <DB_PRIVATE_IP> -U postgres -d serverpod -c "SELECT version();"
```

---

## Phase 3 — Cache Server Setup

SSH into `talktive-cache`:

```bash
ssh ubuntu@<CACHE_PRIVATE_IP>
```

### 3.1 Install Redis 7

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y redis-server
```

### 3.2 Configure Redis

Edit `/etc/redis/redis.conf`:

```bash
sudo nano /etc/redis/redis.conf
```

Find and update these lines:

```conf
# Accept connections from any interface (firewall restricts actual access)
bind 0.0.0.0

# Require password authentication
requirepass <REDIS_PASSWORD>

# Enable append-only log for persistence
appendonly yes
```

### 3.3 Restart Redis

```bash
sudo systemctl restart redis-server
sudo systemctl enable redis-server
```

**Verify** from the Cache Server:

```bash
redis-cli -a <REDIS_PASSWORD> ping
# Expected: PONG
```

---

## Phase 4 — App Server Setup

SSH into `talktive-app`:

```bash
ssh ubuntu@<APP_PRIVATE_IP>
```

### 4.1 Install Docker

```bash
sudo apt update && sudo apt upgrade -y

# Install Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Allow the current user to run docker without sudo
sudo usermod -aG docker $USER

# Activate group change (or log out and back in)
newgrp docker

# Verify
docker --version
docker compose version
```

### 4.2 Clone the Repository

```bash
git clone https://github.com/YOUR_ORG/talktive.git
cd talktive/talktive_server
```

> Replace `YOUR_ORG/talktive` with your actual repository path.

### 4.3 Configure `production.yaml`

Open the file:

```bash
nano config/production.yaml
```

Make these changes:

```yaml
database:
  host: <DB_PRIVATE_IP>       # ← Replace with DB Server's private IP
  port: 5432
  name: serverpod
  user: postgres
  requireSsl: false            # Private VPC — no TLS overhead needed

redis:
  host: <CACHE_PRIVATE_IP>   # ← Replace with Cache Server's private IP
  port: 6379

storage:
  - id: public
    endpoint: https://<ACCOUNT_ID>.r2.cloudflarestorage.com  # ← Your R2 account ID
```

### 4.4 Create `passwords.yaml`

This file is **gitignored** and must be created manually:

```bash
nano config/passwords.yaml
```

```yaml
# PostgreSQL
database: <POSTGRES_PASSWORD>

# Redis
redis: <REDIS_PASSWORD>

# Cloudflare R2 (from R2 → Manage API Tokens)
storage-public-accessKey: <R2_ACCESS_KEY_ID>
storage-public-secretKey: <R2_SECRET_ACCESS_KEY>

# Serverpod internal secrets
# Generate with: openssl rand -hex 32
jwtSecret: <GENERATED_JWT_SECRET>
serviceSecret: <GENERATED_SERVICE_SECRET>
```

Generate secrets:

```bash
openssl rand -hex 32   # run twice — once for jwtSecret, once for serviceSecret
```

### 4.5 Add Firebase Service Account

Download the Firebase Admin SDK JSON from:
**Firebase Console → Project Settings → Service Accounts → Generate new private key**

Upload to the App Server:

```bash
# From your local machine
scp firebase_service_account_key.json ubuntu@<APP_PRIVATE_IP>:~/talktive/talktive_server/config/
```

The server expects this file at `config/firebase_service_account_key.json` at startup.

### 4.6 Apply Database Migrations

**Run this before starting the server container for the first time**, and before each update that includes schema changes.

```bash
# From talktive_server directory
dart bin/main.dart --apply-migrations
```

> If Dart SDK is not installed, install it first:
> ```bash
> sudo apt install -y apt-transport-https
> wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/dart.gpg
> echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | sudo tee /etc/apt/sources.list.d/dart_stable.list
> sudo apt update && sudo apt install -y dart
> dart pub get
> ```

### 4.7 Build the Docker Image

```bash
docker build -t talktive-server -f Dockerfile.production .
```

> The first build takes ~5–8 minutes (Dart AOT compilation). Subsequent builds are faster due to layer caching.

### 4.8 Run the Container

```bash
docker run -d --name talktive-server --restart unless-stopped \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8082:8082 \
  -v $(pwd)/config:/app/config \
  talktive-server
```

**Verify** the container started:

```bash
docker logs --tail=50 talktive-server
```

Look for:
```
Insights server started on port 8081
Serverpod server started on port 8080
```

### 4.9 Health Check

```bash
# Basic liveness
curl -s -X POST http://127.0.0.1:8080/health \
  -H 'Content-Type: application/json' \
  -d '{"method":"check"}' | jq

# Readiness (confirms DB + Redis connectivity)
curl -s -X POST http://127.0.0.1:8080/health \
  -H 'Content-Type: application/json' \
  -d '{"method":"ready"}' | jq
```

Both should return HTTP 200.

---

## Phase 5 — Nginx Server Setup

SSH into `talktive-nginx`:

```bash
ssh ubuntu@<NGINX_STATIC_IP>
```

### 5.1 Install Nginx + Certbot

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y nginx certbot python3-certbot-nginx
```

### 5.2 Configure the Site

Use `docs/nginx/talktive.conf` from this repository as the baseline. Copy it to the server:

```bash
sudo nano /etc/nginx/sites-available/talktive
```

Paste the contents of `docs/nginx/talktive.conf`, replacing both `<APP_SERVER_PRIVATE_IP>` placeholders with your actual App Server private IP:

```nginx
upstream talktive_api {
  server <APP_PRIVATE_IP>:8080;
  keepalive 32;
}

upstream talktive_web {
  server <APP_PRIVATE_IP>:8082;
  keepalive 8;
}
```

### 5.3 Enable the Site

```bash
# Disable the default site
sudo rm -f /etc/nginx/sites-enabled/default

# Enable talktive
sudo ln -s /etc/nginx/sites-available/talktive /etc/nginx/sites-enabled/

# Test config
sudo nginx -t

# Apply
sudo systemctl reload nginx
```

### 5.4 Issue SSL Certificate

```bash
sudo certbot --nginx -d api.talktive.app
```

When prompted:
- Enter your email address.
- Agree to Terms of Service.
- Choose **option 2** (Redirect HTTP → HTTPS).

Certbot auto-renews certificates via a systemd timer. Verify:

```bash
sudo systemctl status certbot.timer
sudo certbot renew --dry-run
```

### 5.5 Final Nginx Verification

```bash
# Config is valid
sudo nginx -t

# HTTPS handshake works
curl -I https://api.talktive.app/health

# WebSocket upgrade header is forwarded
curl -I -H "Upgrade: websocket" -H "Connection: Upgrade" https://api.talktive.app/websocket
```

---

## Phase 6 — Flutter Client Release

### 6.1 Update API URL

In `talktive_flutter/assets/config.json`:

```json
{
  "apiUrl": "https://api.talktive.app"
}
```

### 6.2 Build Release Binaries

```bash
cd talktive_flutter

# Android APK / AAB
flutter build apk --release
flutter build appbundle --release

# iOS (requires macOS with Xcode)
flutter build ios --release
```

### 6.3 Smoke-Test the Client

Before publishing to store:

1. Install the release APK on a test device.
2. Confirm the **"Building Maintenance"** splash screen does **not** appear.
3. Complete Google Sign-In end-to-end.
4. Send a Plaza message and confirm real-time delivery.
5. Upload an avatar and confirm it resolves from `media.talktive.app`.

---

## Phase 7 — Verification & Monitoring

### 7.1 Container Health

From the App Server:

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

From the public internet (after Nginx is up):

```bash
curl -s -X POST https://api.talktive.app/health \
  -H 'Content-Type: application/json' \
  -d '{"method":"check"}' | jq
```

### 7.2 Log Inspection

```bash
# Live tail
docker logs -f talktive-server

# Last 200 lines
docker logs --tail=200 talktive-server

# Nginx access log
sudo tail -f /var/log/nginx/access.log

# Nginx error log
sudo tail -f /var/log/nginx/error.log
```

### 7.3 Database Connectivity

From the App Server:

```bash
psql -h <DB_PRIVATE_IP> -U postgres -d serverpod -c "SELECT COUNT(*) FROM serverpod_session_log;"
```

### 7.4 Redis Connectivity

From the Cache Server:

```bash
redis-cli -a <REDIS_PASSWORD> info server | grep redis_version
```

---

## Ongoing Operations

### Updating the Application

```bash
# On App Server
cd talktive/talktive_server
git pull origin main

# If the release includes migrations, apply them first:
dart bin/main.dart --apply-migrations

# Rebuild and replace the container
docker build -t talktive-server -f Dockerfile.production .
docker stop talktive-server && docker rm talktive-server
docker run -d --name talktive-server --restart unless-stopped \
  -p 8080:8080 -p 8081:8081 -p 8082:8082 \
  -v $(pwd)/config:/app/config \
  talktive-server

# Verify
docker logs --tail=50 talktive-server
```

### Rollback

```bash
# Roll back to the previous image tag (if you tag images before deploying)
docker stop talktive-server && docker rm talktive-server
docker run -d --name talktive-server --restart unless-stopped \
  -p 8080:8080 -p 8081:8081 -p 8082:8082 \
  -v $(pwd)/config:/app/config \
  talktive-server:<PREVIOUS_TAG>
```

### SSL Certificate Renewal

Certbot handles this automatically. To force-renew manually:

```bash
sudo certbot renew --force-renewal
sudo systemctl reload nginx
```

### PostgreSQL Backups

```bash
# On DB Server — create a timestamped dump
sudo -u postgres pg_dump serverpod | gzip > /tmp/serverpod_$(date +%Y%m%d_%H%M%S).sql.gz

# Transfer to a safe location (e.g. R2 via rclone, or local machine via scp)
```

---

## Troubleshooting

| Symptom | Check |
|:--------|:------|
| Container won't start | `docker logs talktive-server` — look for DB or Redis connection errors |
| `ready` health check fails | Verify `passwords.yaml` DB/Redis credentials and that port rules allow traffic |
| 502 Bad Gateway from Nginx | Confirm App container is running: `docker ps` |
| WebSocket disconnects immediately | Verify `proxy_read_timeout 3600s` is set in `talktive.conf` |
| Sign-in fails | Check `firebase_service_account_key.json` path and that the service account has the right IAM roles |
| Media uploads fail | Verify R2 keys in `passwords.yaml` and the `endpoint` in `production.yaml` |
| Migrations fail | Ensure the target DB version matches what is expected; check `migrations/` directory |
