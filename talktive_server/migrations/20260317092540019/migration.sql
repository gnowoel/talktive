BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "resident" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "resident" (
    "id" bigserial PRIMARY KEY,
    "userInfoId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "trustScore" bigint NOT NULL DEFAULT 100,
    "lastReputationIncrease" timestamp without time zone,
    "mutedUntil" timestamp without time zone,
    "suspended" boolean NOT NULL DEFAULT false,
    "xp" bigint NOT NULL DEFAULT 0,
    "level" bigint NOT NULL DEFAULT 0,
    "currentStreak" bigint NOT NULL DEFAULT 0,
    "longestStreak" bigint NOT NULL DEFAULT 0,
    "lastLoginDate" timestamp without time zone,
    "lastMessageDate" timestamp without time zone,
    "experienceMessageCount" bigint NOT NULL DEFAULT 0,
    "userName" text,
    "gender" text,
    "country" text,
    "bio" text,
    "mood" text,
    "avatar" text,
    "interests" json,
    "languages" json,
    "role" text NOT NULL DEFAULT 'user'::text,
    "lastSeen" timestamp without time zone,
    "isPremium" boolean NOT NULL DEFAULT false,
    "showOnlineStatus" boolean NOT NULL DEFAULT true
);

-- Indexes
CREATE UNIQUE INDEX "resident_user_idx" ON "resident" USING btree ("userInfoId");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260317092540019', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260317092540019', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth', '20260129181059877', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181059877', "timestamp" = now();


COMMIT;
