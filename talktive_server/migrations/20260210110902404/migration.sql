BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_user_info" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_user_image" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_google_refresh_token" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_email_reset" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_email_failed_sign_in" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_email_create_request" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_email_auth" CASCADE;

--
-- ACTION DROP TABLE
--
DROP TABLE "serverpod_auth_key" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "rate_limit" (
    "id" bigserial PRIMARY KEY,
    "userInfoId" uuid NOT NULL,
    "channelId" bigint NOT NULL,
    "messageCount" bigint NOT NULL,
    "windowStart" timestamp without time zone NOT NULL,
    "lastMessageAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "rate_limit_user_channel_idx" ON "rate_limit" USING btree ("userInfoId", "channelId");

--
-- ACTION DROP TABLE
--
DROP TABLE "report" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "report" (
    "id" bigserial PRIMARY KEY,
    "reporterId" uuid NOT NULL,
    "targetId" uuid NOT NULL,
    "reason" text NOT NULL,
    "channelId" bigint,
    "messageId" bigint,
    "createdAt" timestamp without time zone NOT NULL,
    "resolved" boolean NOT NULL
);

-- Indexes
CREATE INDEX "report_target_idx" ON "report" USING btree ("targetId", "createdAt");
CREATE INDEX "report_reporter_idx" ON "report" USING btree ("reporterId", "createdAt");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260210110902404', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260210110902404', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260109031533194', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260109031533194', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20251208110412389-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110412389-v3-0-0', "timestamp" = now();


--
-- MIGRATION VERSION FOR 'serverpod_auth'
--
DELETE FROM "serverpod_migrations"WHERE "module" IN ('serverpod_auth');

COMMIT;
