import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Health endpoint', (sessionBuilder, endpoints) {
    test('check is available without authentication', () async {
      final payload = await endpoints.health.check(sessionBuilder);

      expect(payload['status'], 'healthy');
      expect(payload['timestamp'], isA<String>());
      expect(payload['version'], isA<String>());
    });

    test('ready returns a readiness status payload', () async {
      final payload = await endpoints.health.ready(sessionBuilder);

      expect(payload['status'], anyOf('ready', 'not_ready'));
      expect(payload['timestamp'], isA<String>());
    });

    test('detailed includes database and redis checks', () async {
      final payload = await endpoints.health.detailed(sessionBuilder);
      final checks = Map<Object?, Object?>.from(
        payload['checks'] as Map,
      );

      expect(payload['status'], anyOf('healthy', 'unhealthy'));
      expect(checks, contains('database'));
      expect(checks, contains('redis'));
    });
  });
}
