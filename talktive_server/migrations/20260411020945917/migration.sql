BEGIN;

--
-- ACTION ALTER TABLE
--
--
-- ACTION ALTER TABLE
--
CREATE INDEX "lounge_search_idx" ON "lounge" USING gin ("name" gin_trgm_ops);
ALTER TABLE "lounge" ALTER COLUMN "interests" SET DATA TYPE jsonb;
ALTER TABLE "lounge" ALTER COLUMN "languages" SET DATA TYPE jsonb;
CREATE INDEX "lounge_interests_idx" ON "lounge" USING gin ("interests");
CREATE INDEX "lounge_languages_idx" ON "lounge" USING gin ("languages");
--
-- ACTION ALTER TABLE
--
ALTER TABLE "resident" ADD COLUMN "allowPushNotifications" boolean NOT NULL DEFAULT true;
ALTER TABLE "resident" ALTER COLUMN "interests" SET DATA TYPE jsonb;
ALTER TABLE "resident" ALTER COLUMN "languages" SET DATA TYPE jsonb;
CREATE INDEX "resident_interests_idx" ON "resident" USING gin ("interests");
CREATE INDEX "resident_languages_idx" ON "resident" USING gin ("languages");

--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260411020945917', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260411020945917', "timestamp" = now();

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
