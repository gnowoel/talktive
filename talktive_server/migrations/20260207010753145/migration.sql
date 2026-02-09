BEGIN;

--
-- ACTION DROP TABLE
--
DROP TABLE "moment" CASCADE;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "moment" (
    "id" bigserial PRIMARY KEY,
    "authorId" bigint NOT NULL,
    "imageUrl" text NOT NULL,
    "caption" text,
    "createdAt" timestamp without time zone NOT NULL,
    "likesCount" bigint NOT NULL,
    "commentsCount" bigint NOT NULL,
    "authorName" text NOT NULL,
    "authorAvatar" text NOT NULL,
    "authorFloor" bigint NOT NULL
);


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260207010753145', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260207010753145', "timestamp" = now();

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
