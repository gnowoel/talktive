BEGIN;

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
    "mediaUrl" text,
    "mediaType" text,
    "isSystem" boolean NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "senderName" text NOT NULL,
    "senderAvatar" text,
    "senderMood" text,
    "senderFloor" bigint NOT NULL,
    "senderTrustScore" bigint NOT NULL
);

-- Indexes
CREATE INDEX "message_channel_idx" ON "message" USING btree ("channelId");
CREATE INDEX "message_sender_idx" ON "message" USING btree ("senderId");
CREATE INDEX "message_created_idx" ON "message" USING btree ("createdAt");
CREATE INDEX "message_channel_created_idx" ON "message" USING btree ("channelId", "createdAt");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260310154415111', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260310154415111', "timestamp" = now();

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
