BEGIN;

--
-- ACTION ALTER TABLE
--
CREATE INDEX "channel_member_user_idx" ON "channel_member" USING btree ("userInfoId");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "lounge_active_idx" ON "lounge" USING btree ("isPublic", "isStaffLocked", "lastMessageAt");
CREATE INDEX "lounge_member_idx" ON "lounge" USING btree ("memberCount");
CREATE INDEX "lounge_lastmsg_idx" ON "lounge" USING btree ("lastMessageAt");
--
-- ACTION ALTER TABLE
--
CREATE INDEX "resident_search_idx" ON "resident" USING btree ("allowDiscovery", "lastSeen");
CREATE INDEX "resident_geo_idx" ON "resident" USING btree ("country", "gender", "ageRange");
CREATE INDEX "resident_xp_idx" ON "resident" USING btree ("xp");
CREATE INDEX "resident_level_idx" ON "resident" USING btree ("level");
CREATE INDEX "resident_role_idx" ON "resident" USING btree ("role");
CREATE INDEX "resident_lastseen_idx" ON "resident" USING btree ("lastSeen");

--
-- MIGRATION VERSION FOR talktive
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('talktive', '20260326035736919', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260326035736919', "timestamp" = now();

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
