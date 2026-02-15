BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "resident" DROP COLUMN "creditScore";
ALTER TABLE "resident" DROP COLUMN "isBanned";
ALTER TABLE "resident" DROP COLUMN "lastCreditIncrease";
ALTER TABLE "resident" ADD COLUMN "reputation" bigint NOT NULL DEFAULT 100;
ALTER TABLE "resident" ADD COLUMN "lastReputationIncrease" timestamp without time zone;
ALTER TABLE "resident" ADD COLUMN "mutedUntil" timestamp without time zone;
ALTER TABLE "resident" ADD COLUMN "suspended" boolean NOT NULL DEFAULT false;
ALTER TABLE "resident" ADD COLUMN "xp" bigint NOT NULL DEFAULT 0;
ALTER TABLE "resident" ADD COLUMN "level" bigint NOT NULL DEFAULT 0;
ALTER TABLE "resident" ADD COLUMN "currentStreak" bigint NOT NULL DEFAULT 0;
ALTER TABLE "resident" ADD COLUMN "longestStreak" bigint NOT NULL DEFAULT 0;
ALTER TABLE "resident" ADD COLUMN "lastLoginDate" timestamp without time zone;
ALTER TABLE "resident" ADD COLUMN "lastMessageDate" timestamp without time zone;
ALTER TABLE "resident" ALTER COLUMN "floor" SET DEFAULT 0;
ALTER TABLE "resident" ALTER COLUMN "experienceMessageCount" SET DEFAULT 0;

--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260215142531053', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260215142531053', "timestamp" = now();

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
-- MIGRATION VERSION FOR serverpod_auth
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth', '20250825102351908-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250825102351908-v3-0-0', "timestamp" = now();


COMMIT;
