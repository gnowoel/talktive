BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "channel_member" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "channel_member" (
    "id" bigserial PRIMARY KEY,
    "channelId" bigint NOT NULL,
    "userInfoId" uuid NOT NULL,
    "joinedAt" timestamp without time zone NOT NULL,
    "role" text,
    "status" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "channel_user_idx" ON "channel_member" USING btree ("channelId", "userInfoId");

--
-- ACTION DROP TABLE
--
DROP TABLE "message" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "message" (
    "id" bigserial PRIMARY KEY,
    "channelId" bigint NOT NULL,
    "senderId" uuid NOT NULL,
    "content" text,
    "imageUrl" text,
    "createdAt" timestamp without time zone NOT NULL
);

--
-- ACTION ALTER TABLE
--
ALTER TABLE "resident" ADD COLUMN "gender" text;
ALTER TABLE "resident" ADD COLUMN "country" text;
ALTER TABLE "resident" ADD COLUMN "bio" text;
ALTER TABLE "resident" ADD COLUMN "avatar" text;
ALTER TABLE "resident" ADD COLUMN "role" text;
--
-- ACTION DROP TABLE
--
DROP TABLE "user_block" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "user_block" (
    "id" bigserial PRIMARY KEY,
    "blockerId" uuid NOT NULL,
    "blockedId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "block_idx" ON "user_block" USING btree ("blockerId", "blockedId");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "channel_member"
    ADD CONSTRAINT "channel_member_fk_0"
    FOREIGN KEY("channelId")
    REFERENCES "channel"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "message"
    ADD CONSTRAINT "message_fk_0"
    FOREIGN KEY("channelId")
    REFERENCES "channel"("id")
    ON DELETE NO ACTION
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260209101620062', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260209101620062', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20251208110333922-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20251208110333922-v3-0-0', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth', '20250825102351908-v3-0-0', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20250825102351908-v3-0-0', "timestamp" = now();

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
