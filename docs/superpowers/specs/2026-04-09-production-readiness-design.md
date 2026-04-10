# Design Spec: Talktive Production Readiness (Serverpod)

**Date:** 2026-04-09
**Status:** Approved
**Topic:** Infrastructure Migration & Security Hardening for Production Release

## 1. Objective
Transition the Talktive application from a development/Firebase-reliant state to a professional, distributed production environment on Amazon Lightsail. This includes hardening security, ensuring data integrity, and optimizing infrastructure costs.

## 2. Infrastructure Architecture (Amazon Lightsail)

The backend will be distributed across three specialized instances in the `us-east-1` (N. Virginia) region.

### 2.1 Server Topology

| Instance | Role | Specs | Network Tier | Private Hostname |
| :--- | :--- | :--- | :--- | :--- |
| **App Server** | Serverpod Engine | 2GB RAM / 1 vCPU | Dual-stack | `app.talktive.internal` |
| **DB Server** | PostgreSQL 16 + pgvector | 2GB RAM / 1 vCPU | **IPv6-only** | `db.talktive.internal` |
| **Cache Server** | Redis 7 | 1GB RAM / 1 vCPU | **IPv6-only** | `redis.talktive.internal` |

### 2.2 Networking Strategy
*   **Cost Optimization:** DB and Cache servers use "IPv6-only" mode to eliminate the cost of public IPv4 addresses.
*   **Internal Communication:** The App Server will communicate with the DB and Cache servers using their **Private IPv4 addresses** over the Lightsail VPC.
*   **Security:** 
    *   DB/Cache firewalls will block all public traffic.
    *   Inbound traffic to port 5432 (DB) and 6379 (Redis) is restricted to the App Server's private IP.
    *   The App Server will expose 8080 (API), 8081 (Insights), and 8082 (Web) to the public via its Static IPv4.

## 3. Backend Hardening

### 3.1 SQL Injection Prevention
Refactor `ResidentService.getBatchUserCounts` to eliminate unsafe string interpolation in `unsafeQuery`.
*   **Old Pattern:** `WHERE "senderId" IN ($idList)`
*   **New Pattern:** Use Serverpod's typed database API where possible, or use parameterized queries (`$1, $2, ...`) if complex raw SQL is required.

### 3.2 Robust Channel Seeding
Decouple the "Plaza" (Lobby) from hardcoded `ID 1`.
*   **Logic:** The server initialization will query for a channel where `type == ChannelType.plaza`.
*   **Action:** If none exists, it will create one. This ensures the app functions correctly even if the database is restored with different primary keys.

### 3.3 Configuration Consolidation
Centralize all environment-specific settings in `config/production.yaml`.
*   Move Cloudflare R2 bucket name, endpoint, and public host into the `storage` section of the YAML.
*   Update `server.dart` to rely on the Serverpod `Config` object rather than `Platform.environment` or hardcoded fallback strings.

## 4. Frontend Resilience (Flutter)

### 4.1 Production URL Hardening
Update `AppConfig.initialize()` to enforce production safety:
*   In `kReleaseMode`, the app must **never** fall back to `localhost`.
*   If `assets/config.json` fails to load or the server is unreachable, the app will transition to a "Building Maintenance" screen (part of the `Duo` design system) instead of crashing or showing raw errors.

### 4.2 Error Handling
Ensure `TalktiveException` codes (e.g., `USER_MUTED`, `FLOOR_RESTRICTION`) are consistently caught and displayed using `DuoInfoBanner` or `DuoNotificationToast` components.

## 5. Data Integrity

### 5.1 Migration Verification
*   Perform a baseline check of the migration history to ensure schema consistency.
*   Ensure `SeedData.seedAchievements` is idempotent to prevent duplicate entries during server restarts.

## 6. Testing & Validation
1.  **Integration Tests:** Run `dart test test/integration` on the server after refactoring SQL queries.
2.  **Infrastructure Test:** Verify App -> DB/Redis connectivity using private IPv4 literals in a staging environment.
3.  **AppConfig Test:** Simulate a missing `config.json` in a release-mode build to verify the maintenance UI.
