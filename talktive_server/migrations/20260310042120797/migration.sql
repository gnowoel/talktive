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
-- ACTION DROP TABLE
--
DROP TABLE "moment" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "moment" (
    "id" bigserial PRIMARY KEY,
    "authorId" uuid NOT NULL,
    "imageUrl" text NOT NULL,
    "caption" text,
    "mediaType" text NOT NULL DEFAULT 'image'::text,
    "createdAt" timestamp without time zone NOT NULL,
    "likesCount" bigint NOT NULL,
    "commentsCount" bigint NOT NULL,
    "authorName" text NOT NULL,
    "authorAvatar" text,
    "authorMood" text,
    "authorFloor" bigint NOT NULL,
    "authorTrustScore" bigint NOT NULL
);

-- Indexes
CREATE INDEX "moment_author_idx" ON "moment" USING btree ("authorId");
CREATE INDEX "moment_created_idx" ON "moment" USING btree ("createdAt");
CREATE INDEX "moment_likes_idx" ON "moment" USING btree ("likesCount");
CREATE INDEX "moment_created_likes_idx" ON "moment" USING btree ("createdAt", "likesCount");

--
-- ACTION DROP TABLE
--
DROP TABLE "moment_comments" CASCADE;

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
    "userAvatar" text,
    "userMood" text,
    "userFloor" bigint NOT NULL,
    "userTrustScore" bigint NOT NULL
);

-- Indexes
CREATE INDEX "moment_comment_created_idx" ON "moment_comments" USING btree ("momentId", "createdAt");

--
-- ACTION DROP TABLE
--
DROP TABLE "moment_likes" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "moment_likes" (
    "id" bigserial PRIMARY KEY,
    "momentId" bigint NOT NULL,
    "userId" uuid NOT NULL,
    "createdAt" timestamp without time zone NOT NULL,
    "userName" text NOT NULL,
    "userAvatar" text,
    "userMood" text,
    "userFloor" bigint NOT NULL,
    "userTrustScore" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "moment_user_unique" ON "moment_likes" USING btree ("momentId", "userId");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260310042120797', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260310042120797', "timestamp" = now();

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
    VALUES ('serverpod_auth_idp', '20260129181124635', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181124635', "timestamp" = now();

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
