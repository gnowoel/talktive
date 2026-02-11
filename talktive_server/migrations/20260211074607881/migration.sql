BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "daily_rewards" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "claimedDate" timestamp without time zone NOT NULL,
    "rewardType" text NOT NULL,
    "rewardAmount" bigint NOT NULL,
    "streakDay" bigint NOT NULL
);

-- Indexes
CREATE INDEX "user_date_idx" ON "daily_rewards" USING btree ("userId", "claimedDate");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_streaks" (
    "id" bigserial PRIMARY KEY,
    "userId" uuid NOT NULL,
    "currentStreak" bigint NOT NULL DEFAULT 0,
    "longestStreak" bigint NOT NULL DEFAULT 0,
    "lastActiveDate" timestamp without time zone,
    "totalActiveDays" bigint NOT NULL DEFAULT 0
);

-- Indexes
CREATE UNIQUE INDEX "user_unique" ON "user_streaks" USING btree ("userId");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260211074607881', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260211074607881', "timestamp" = now();

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
