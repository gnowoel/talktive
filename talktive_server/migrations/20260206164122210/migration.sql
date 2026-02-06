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
    "floor" bigint NOT NULL,
    "creditScore" bigint NOT NULL,
    "experienceMessageCount" bigint NOT NULL,
    "lastCreditIncrease" timestamp without time zone
);

-- Indexes
CREATE UNIQUE INDEX "resident_user_idx" ON "resident" USING btree ("userInfoId");


--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260206164122210', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260206164122210', "timestamp" = now();

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
