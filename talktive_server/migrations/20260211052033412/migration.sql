BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "private_chat" (
    "id" bigserial PRIMARY KEY,
    "channelId" bigint NOT NULL,
    "participant1Id" uuid NOT NULL,
    "participant2Id" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "lastMessageAt" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "private_chat_channel_idx" ON "private_chat" USING btree ("channelId");
CREATE UNIQUE INDEX "private_chat_participants_idx" ON "private_chat" USING btree ("participant1Id", "participant2Id");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260211052033412', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260211052033412', "timestamp" = now();

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
