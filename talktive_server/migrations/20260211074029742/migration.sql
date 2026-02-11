BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "moment_comments" (
    "id" bigserial PRIMARY KEY,
    "momentId" bigint NOT NULL,
    "userId" uuid NOT NULL,
    "text" text NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "userName" text NOT NULL,
    "userAvatar" text NOT NULL,
    "userFloor" bigint NOT NULL
);

-- Indexes
CREATE INDEX "moment_created_idx" ON "moment_comments" USING btree ("momentId", "createdAt");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "moment_likes" (
    "id" bigserial PRIMARY KEY,
    "momentId" bigint NOT NULL,
    "userId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "userName" text NOT NULL,
    "userAvatar" text NOT NULL,
    "userFloor" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "moment_user_unique" ON "moment_likes" USING btree ("momentId", "userId");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260211074029742', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260211074029742', "timestamp" = now();

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
