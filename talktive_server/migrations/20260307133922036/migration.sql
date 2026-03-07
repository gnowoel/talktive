BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "message" ADD COLUMN "mediaUrl" text;
ALTER TABLE "message" ADD COLUMN "mediaType" text;
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
    "authorAvatar" text NOT NULL,
    "authorMood" text,
    "authorFloor" bigint NOT NULL
);

-- Indexes
CREATE INDEX "moment_author_idx" ON "moment" USING btree ("authorId");
CREATE INDEX "moment_created_idx" ON "moment" USING btree ("createdAt");
CREATE INDEX "moment_likes_idx" ON "moment" USING btree ("likesCount");
CREATE INDEX "moment_created_likes_idx" ON "moment" USING btree ("createdAt", "likesCount");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260307133922036', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260307133922036', "timestamp" = now();

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
