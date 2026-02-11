BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "groups" (
    "id" bigserial PRIMARY KEY,
    "channelId" bigint NOT NULL,
    "name" text NOT NULL,
    "description" text,
    "emoji" text,
    "creatorId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "memberCount" bigint NOT NULL DEFAULT 1,
    "isPublic" boolean NOT NULL DEFAULT false,
    "maxMembers" bigint NOT NULL DEFAULT 50
);

-- Indexes
CREATE UNIQUE INDEX "group_channel_idx" ON "groups" USING btree ("channelId");
CREATE INDEX "group_creator_idx" ON "groups" USING btree ("creatorId");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260211053322424', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260211053322424', "timestamp" = now();

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
