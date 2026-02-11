BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "achievements" (
    "id" bigserial PRIMARY KEY,
    "key" text NOT NULL,
    "name" text NOT NULL,
    "description" text NOT NULL,
    "emoji" text NOT NULL,
    "category" text NOT NULL,
    "targetValue" bigint NOT NULL DEFAULT 1,
    "points" bigint NOT NULL DEFAULT 10,
    "isSecret" boolean NOT NULL DEFAULT false
);

-- Indexes
CREATE UNIQUE INDEX "achievement_key_idx" ON "achievements" USING btree ("key");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_achievements" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "achievementId" bigint NOT NULL,
    "progress" bigint NOT NULL DEFAULT 0,
    "unlockedAt" timestamp without time zone,
    "notified" boolean NOT NULL DEFAULT false
);

-- Indexes
CREATE UNIQUE INDEX "user_achievement_idx" ON "user_achievements" USING btree ("userId", "achievementId");
CREATE INDEX "user_unlocked_idx" ON "user_achievements" USING btree ("userId", "unlockedAt");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260211072710249', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260211072710249', "timestamp" = now();

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
