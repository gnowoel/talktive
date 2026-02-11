BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "device_tokens" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "token" text NOT NULL,
    "platform" text NOT NULL,
    "lastUsed" timestamp without time zone NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "user_token_unique" ON "device_tokens" USING btree ("userId", "token");
CREATE INDEX "token_idx" ON "device_tokens" USING btree ("token");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_notifications" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "type" text NOT NULL,
    "title" text NOT NULL,
    "body" text NOT NULL,
    "data" text,
    "read" boolean NOT NULL DEFAULT false,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "user_created_idx" ON "user_notifications" USING btree ("userId", "createdAt");
CREATE INDEX "user_read_idx" ON "user_notifications" USING btree ("userId", "read");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260211100938725', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260211100938725', "timestamp" = now();

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


COMMIT;
