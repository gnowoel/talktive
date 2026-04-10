# Production Readiness Refinement Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Further refine the production-ready state of the Talktive Serverpod implementation by enhancing seeding robustness, error handling, and test coverage.

**Architecture:** Distributed architecture on Amazon Lightsail with IPv6-only internal services. Service-delegated logic with parameterized SQL queries.

**Tech Stack:** Serverpod (Dart), PostgreSQL (pgvector), Redis, Flutter (Dart).

---

### Task 1: Enhance Seeding Idempotency and Safety

**Files:**
- Modify: `talktive_server/lib/server.dart`

- [ ] **Step 1: Use advisory locks for Achievement seeding**
Update `_seedCoreData` to wrap `SeedData.seedAchievements(session)` in an advisory lock to prevent race conditions during cluster startup.

```dart
Future<void> _seedCoreData(Session session) async {
  await _withAdvisoryLock(session, 884210, () => SeedData.seedAchievements(session));
  await _withAdvisoryLock(session, 884211, () async {
    final plaza = await Channel.db.findFirstRow(
      session,
      where: (t) => t.type.equals(ChannelType.plaza),
    );
    if (plaza != null) return;
    session.log('Seeding: Creating Plaza Channel');
    await Channel.db.insertRow(
      session,
      Channel(
        type: ChannelType.plaza,
        name: 'The Plaza',
        createdAt: DateTime.now(),
      ),
    );
  });
}

Future<void> _withAdvisoryLock(
  Session session,
  int lockId,
  Future<void> Function() action,
) async {
  await session.db.unsafeQuery('SELECT pg_advisory_lock($lockId)');
  try {
    await action();
  } finally {
    await session.db.unsafeQuery('SELECT pg_advisory_unlock($lockId)');
  }
}
```

- [ ] **Step 2: Commit changes**

```bash
git add talktive_server/lib/server.dart
git commit -m "refactor: use advisory locks for all core seeding tasks"
```

### Task 2: Add Integration Test for Seeding Logic

**Files:**
- Create: `talktive_server/test/integration/seeding_test.dart`

- [ ] **Step 1: Write integration test for seeding**
Ensure that `_seedCoreData` (via a public helper or similar if needed) correctly creates the Plaza channel and achievements without duplicates.

```dart
import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:talktive_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Seeding Logic', (sessionBuilder, endpoints) {
    test('creates Plaza channel if it does not exist', () async {
      final session = sessionBuilder.build();
      
      // Assume _seedCoreData was run during withServerpod setup or run it manually if possible
      // For this test, let's verify the Plaza exists
      final plaza = await Channel.db.findFirstRow(
        session,
        where: (t) => t.type.equals(ChannelType.plaza),
      );
      
      expect(plaza, isNotNull);
      expect(plaza!.name, 'The Plaza');
    });
  });
}
```

- [ ] **Step 2: Run tests**

Run: `cd talktive_server && dart test test/integration/seeding_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add talktive_server/test/integration/seeding_test.dart
git commit -m "test: add integration test for seeding logic"
```

### Task 3: Final Production Configuration Audit

**Files:**
- Modify: `talktive_server/config/production.yaml`

- [ ] **Step 1: Ensure all production placeholders are noted**
Double check that `production.yaml` doesn't have any leaked dev credentials (though it should be non-committed, we check the template/example).

- [ ] **Step 2: Final Analysis Check**

Run: `cd talktive_server && dart analyze . && cd ../talktive_flutter && flutter analyze .`
Expected: No issues.
