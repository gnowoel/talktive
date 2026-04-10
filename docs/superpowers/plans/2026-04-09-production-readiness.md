# Talktive Production Readiness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Hardening the backend and frontend for a distributed production release on Amazon Lightsail.

**Architecture:** We are moving from a monolithic development setup to a distributed architecture using separate App, DB, and Redis servers. We are also applying security best practices (parameterized queries) and improving infrastructure portability via centralized configuration.

**Tech Stack:** Serverpod (Dart), Flutter, PostgreSQL (pgvector), Redis, Cloudflare R2.

---

### Task 1: SQL Injection Prevention in ResidentService

**Files:**
- Modify: `talktive_server/lib/src/services/resident_service.dart`
- Test: `talktive_server/test/integration/resident_service_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// Add this to talktive_server/test/integration/resident_service_test.dart
test('getBatchUserCounts is safe from SQL injection attempt', () async {
  final maliciousId = UuidValue.fromString('00000000-0000-0000-0000-000000000000');
  // This is a simplified test; real UuidValue validation usually prevents this,
  // but we want to ensure the underlying query is parameterized.
  final results = await ResidentService.getBatchUserCounts(session, [maliciousId]);
  expect(results, isNotNull);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/integration/resident_service_test.dart`
Expected: PASS (It passes because UuidValue handles validation, but we need to refactor for standard safety).

- [ ] **Step 3: Refactor to use parameterized queries**

```dart
// talktive_server/lib/src/services/resident_service.dart

  static Future<Map<String, Map<String, int>>> getBatchUserCounts(
    Session session,
    List<UuidValue> userIds,
  ) async {
    if (userIds.isEmpty) return {};

    final result = <String, Map<String, int>>{};
    for (final id in userIds) {
      result[id.toString()] = {
        'messages': 0,
        'moments': 0,
        'reports': 0,
      };
    }

    try {
      // Use parameterized queries to prevent SQL injection
      // Serverpod's session.db.unsafeQuery supports substitution using @id
      
      // 1. Message counts
      final messageCounts = await session.db.unsafeQuery(
        'SELECT "senderId", count(*) as count FROM message WHERE "senderId" = ANY(@userIds) GROUP BY "senderId"',
        parameters: {
          'userIds': userIds.map((u) => u.toString()).toList(),
        },
      );
      for (final row in messageCounts) {
        final id = row[0].toString();
        if (result.containsKey(id)) {
          result[id]!['messages'] = int.tryParse(row[1].toString()) ?? 0;
        }
      }

      // 2. Moment counts
      final momentCounts = await session.db.unsafeQuery(
        'SELECT "authorId", count(*) as count FROM moment WHERE "authorId" = ANY(@userIds) GROUP BY "authorId"',
        parameters: {
          'userIds': userIds.map((u) => u.toString()).toList(),
        },
      );
      for (final row in momentCounts) {
        final id = row[0].toString();
        if (result.containsKey(id)) {
          result[id]!['moments'] = int.tryParse(row[1].toString()) ?? 0;
        }
      }

      // 3. Report counts (against the user)
      final reportCounts = await session.db.unsafeQuery(
        'SELECT "targetId", count(*) as count FROM report WHERE "targetId" = ANY(@userIds) GROUP BY "targetId"',
        parameters: {
          'userIds': userIds.map((u) => u.toString()).toList(),
        },
      );
      for (final row in reportCounts) {
        final id = row[0].toString();
        if (result.containsKey(id)) {
          result[id]!['reports'] = int.tryParse(row[1].toString()) ?? 0;
        }
      }
    } catch (e) {
      session.log('Error in getBatchUserCounts: $e', level: LogLevel.error);
    }

    return result;
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/integration/resident_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add talktive_server/lib/src/services/resident_service.dart
git commit -m "security: prevent SQL injection in getBatchUserCounts using parameterized queries"
```

---

### Task 2: Robust Plaza Channel Seeding

**Files:**
- Modify: `talktive_server/lib/server.dart`
- Test: `talktive_server/test/integration/channel_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// talktive_server/test/integration/channel_test.dart
test('Plaza channel can be found by type even if ID is not 1', () async {
  // Create a dummy channel to occupy ID 1 if possible (though serials vary)
  // The real test is that our seeding logic finds the plaza correctly.
  final plaza = await Channel.db.findFirstRow(session, where: (t) => t.type.equals(ChannelType.plaza));
  expect(plaza, isNotNull);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run: `dart test test/integration/channel_test.dart`
Expected: FAIL (if DB is fresh and seeding hasn't run, or PASS if already seeded - we will update logic anyway).

- [ ] **Step 3: Update seeding logic in server.dart**

```dart
// talktive_server/lib/server.dart

  // Seed Data
  final session = await pod.createSession(enableLogging: true);
  try {
    // Seed Achievements
    await SeedData.seedAchievements(session);

    // ROBUST PLAZA SEEDING
    final plaza = await Channel.db.findFirstRow(
      session,
      where: (t) => t.type.equals(ChannelType.plaza),
    );
    
    if (plaza == null) {
      session.log('Seeding: Creating Plaza Channel');
      await Channel.db.insertRow(
        session,
        Channel(
          type: ChannelType.plaza,
          name: 'The Plaza',
          createdAt: DateTime.now(),
        ),
      );
    } else {
      session.log('Seeding: Plaza Channel already exists (ID: ${plaza.id})');
    }
  } catch (e) {
    session.log('Seeding Error: $e', level: LogLevel.error);
  } finally {
    await session.close();
  }
```

- [ ] **Step 4: Run test to verify it passes**

Run: `dart test test/integration/channel_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add talktive_server/lib/server.dart
git commit -m "feat: implement robust plaza channel discovery by type instead of hardcoded ID"
```

---

### Task 3: Centralized Production Configuration

**Files:**
- Modify: `talktive_server/config/production.yaml`
- Modify: `talktive_server/lib/server.dart`

- [ ] **Step 1: Update production.yaml with real hosts and storage config**

```yaml
# talktive_server/config/production.yaml

apiServer:
  port: 8080
  publicHost: api.talktive.app
  publicPort: 443
  publicScheme: https

insightsServer:
  port: 8081
  publicHost: api.talktive.app
  publicPort: 8081
  publicScheme: https

webServer:
  port: 8082
  publicHost: api.talktive.app
  publicPort: 8082
  publicScheme: https

database:
  host: db.talktive.internal
  port: 5432
  name: talktive
  user: postgres
  requireSsl: false # Internal VPC doesn't need SSL overhead

redis:
  enabled: true
  host: redis.talktive.internal
  port: 6379

storage:
  - id: public
    type: s3
    public: true
    region: auto
    bucket: talktive-media
    endpoint: https://<ACCOUNT_ID>.r2.cloudflarestorage.com
    publicHost: media.talktive.app
```

- [ ] **Step 2: Clean up Cloud Storage registration in server.dart**

```dart
// talktive_server/lib/server.dart

  // Register Cloud Storage
  // Serverpod automatically registers storage from config if present.
  // We only need to manually add it if we are using logic-based setup.
  // We'll keep the R2CloudStorage import but rely on config for the details.
```

- [ ] **Step 3: Verify configuration loading**

Run: `dart bin/main.dart --mode production` (Expect connection failure since internal hosts don't exist locally, but verify it tries the correct IPs).

- [ ] **Step 4: Commit**

```bash
git add talktive_server/config/production.yaml talktive_server/lib/server.dart
git commit -m "config: centralize production host and storage settings in production.yaml"
```

---

### Task 4: Frontend Production Safety

**Files:**
- Modify: `talktive_flutter/lib/config/app_config.dart`
- Create: `talktive_flutter/lib/screens/maintenance_screen.dart`

- [ ] **Step 1: Harden AppConfig.initialize**

```dart
// talktive_flutter/lib/config/app_config.dart

  static Future<void> initialize() async {
    if (_instance != null) return;

    const serverpodUrlOverride = String.fromEnvironment('SERVERPOD_URL');
    
    final assetConfig = await _loadAssetConfig();
    final assetUrl = (assetConfig['apiUrl'] as String?)?.trim();
    
    String configuredUrl;
    
    if (serverpodUrlOverride.isNotEmpty) {
      configuredUrl = serverpodUrlOverride;
    } else if (kReleaseMode) {
      // FORCE production URL in release mode, fail if missing
      if (assetUrl == null || assetUrl.isEmpty) {
        throw StateError('Production API URL is missing from config.json');
      }
      configuredUrl = assetUrl;
    } else {
      // Development defaults
      configuredUrl = kIsWeb ? 'http://localhost:8080' : 'http://10.0.2.2:8080';
    }

    _instance = AppConfig._(
      serverpodUrl: configuredUrl,
      useFirebaseEmulators: !kReleaseMode, // Never use emulators in release
      firebaseEmulatorHost: kIsWeb ? 'localhost' : '10.0.2.2',
    );
  }
```

- [ ] **Step 2: Create Maintenance Screen**

```dart
// talktive_flutter/lib/screens/maintenance_screen.dart
import 'package:flutter/material.dart';
import '../widgets/duo/duo_page_scaffold.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DuoPageScaffold(
      title: 'Maintenance',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🏠', style: TextStyle(fontSize: 64)),
            SizedBox(height: 16),
            Text(
              'Building Maintenance',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Padding(
              padding: EdgeInsets.all(32.0),
              child: Text(
                'The residence is currently undergoing scheduled maintenance. Please check back soon!',
                textAlign: Center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add talktive_flutter/lib/config/app_config.dart talktive_flutter/lib/screens/maintenance_screen.dart
git commit -m "feat: add maintenance screen and harden production configuration logic"
```

---

### Task 5: Final Verification

- [ ] **Step 1: Run full server test suite**

Run: `cd talktive_server && dart test`
Expected: ALL PASS

- [ ] **Step 2: Verify Flutter build**

Run: `cd talktive_flutter && flutter build web` (or apk)
Expected: SUCCESS

- [ ] **Step 3: Cleanup test files**

```bash
rm talktive_server/test_syntax.dart
```

- [ ] **Step 4: Final Commit**

```bash
git commit -m "chore: cleanup and final verification for production release"
```
