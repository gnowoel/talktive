# Production Release Guide: Talktive

This guide provides step-by-step instructions for deploying Talktive to its distributed production environment on Amazon Lightsail.

## Phase 1: Provisioning Infrastructure

### 1. Launch Instances
In the Amazon Lightsail console (`us-east-1` region), launch three **Ubuntu 22.04 LTS** instances:

1.  **App Server**: 2GB RAM / 1 vCPU (Dual-stack).
2.  **DB Server**: 2GB RAM / 1 vCPU (**IPv6-only**).
3.  **Cache Server**: 1GB RAM / 1 vCPU (**IPv6-only**).

### 2. Networking Setup
1.  **Static IP**: Attach a Static IP to the **App Server**.
2.  **DNS**: Map `api.talktive.app` to the App Server's Static IP.
3.  **Private IPs**: Note the **Private IPv4** addresses for the DB and Cache servers from the "Networking" tab.

### 3. Firewall Configuration
Configure the firewall for each instance in the Lightsail console:

*   **App Server**:
    *   HTTP (80) - Custom (Anywhere)
    *   HTTPS (443) - Custom (Anywhere)
    *   8080-8082 - Custom (Anywhere)
*   **DB Server**:
    *   5432 - Custom (Only App Server Private IP)
*   **Cache Server**:
    *   6379 - Custom (Only App Server Private IP)

---

## Phase 2: Database Server Setup

Connect to the **DB Server** via SSH:

### 1. Install PostgreSQL & pgvector
```bash
sudo apt update
sudo apt install postgresql-16 postgresql-16-pgvector
```

### 2. Configure Remote Access
Edit `/etc/postgresql/16/main/postgresql.conf`:
```bash
# Change listen_addresses to '*' or the private IP
listen_addresses = '*'
```

Edit `/etc/postgresql/16/main/pg_hba.conf`:
```bash
# Add entry for the App Server's Private IP
host    talktive    postgres    <APP_SERVER_PRIVATE_IP>/32    md5
```

### 3. Create Database & Extensions
```bash
sudo -u postgres psql
CREATE DATABASE talktive;
\c talktive
CREATE EXTENSION IF NOT EXISTS vector;
ALTER USER postgres WITH PASSWORD 'your_strong_db_password';
\q
sudo systemctl restart postgresql
```

---

## Phase 3: Cache Server Setup

Connect to the **Cache Server** via SSH:

### 1. Install Redis
```bash
sudo apt update
sudo apt install redis-server
```

### 2. Configure Redis
Edit `/etc/redis/redis.conf`:
```bash
bind 0.0.0.0
requirepass your_strong_redis_password
```

### 3. Restart
```bash
sudo systemctl restart redis-server
```

---

## Phase 4: App Server Setup

Connect to the **App Server** via SSH:

### 1. Install Docker
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
# Logout and log back in
```

### 2. Deploy Application
1.  **Clone Repo**:
    ```bash
    git clone https://github.com/your-org/talktive.git
    cd talktive/talktive_server
    ```
2.  **Configure Environment**:
    *   Edit `config/production.yaml`: Set `database.host` and `redis.host` to their respective Private IPs.
    *   Create `config/passwords.yaml`: Add DB password, Redis password, and Cloudflare R2 keys.
3.  **Build & Run**:
    ```bash
    docker build -t talktive-server -f Dockerfile.production .
    docker run -d --name talktive-server --restart unless-stopped \
      -p 8080:8080 -p 8081:8081 -p 8082:8082 \
      -v $(pwd)/config:/app/config \
      talktive-server
    ```

---

## Phase 5: Nginx & SSL

### 1. Install Nginx
```bash
sudo apt install nginx certbot python3-certbot-nginx
```

### 2. Configure Site
Create `/etc/nginx/sites-available/talktive`:
*(Use the configuration provided in the DEPLOYMENT.md, ensuring `proxy_pass` points to `localhost:8080` for API and `localhost:8082` for Web).*

### 3. Enable & SSL
```bash
sudo ln -s /etc/nginx/sites-available/talktive /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d api.talktive.app
```

---

## Phase 6: Frontend Release

1.  **Update Config**: In `talktive_flutter/assets/config.json`, ensure `apiUrl` is set to `https://api.talktive.app`.
2.  **Build Flutter**:
    ```bash
    flutter build apk --release # For Android
    flutter build ios --release # For iOS
    ```
3.  **Verify**: Open the app and ensure the "Building Maintenance" screen does **not** appear and you can sign in.
