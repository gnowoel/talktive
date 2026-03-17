BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "groups" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "lounge" (
    "id" bigserial PRIMARY KEY,
    "channelId" bigint NOT NULL,
    "name" text NOT NULL,
    "description" text,
    "emoji" text,
    "creatorId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "memberCount" bigint NOT NULL DEFAULT 1,
    "isPublic" boolean NOT NULL DEFAULT false,
    "maxMembers" bigint NOT NULL DEFAULT 50,
    "lastMessageAt" timestamp without time zone,
    "lastMessage" text,
    "interests" json,
    "isStaffLocked" boolean NOT NULL DEFAULT false
);

-- Indexes
CREATE UNIQUE INDEX "lounge_channel_idx" ON "lounge" USING btree ("channelId");
CREATE INDEX "lounge_creator_idx" ON "lounge" USING btree ("creatorId");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260317154050728', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260317154050728', "timestamp" = now();

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
