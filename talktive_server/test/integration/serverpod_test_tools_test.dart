import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given withServerpod test tools',
    (sessionBuilder, endpoints) {
      test('forwards configOverride to the underlying Serverpod instance', () async {
        final session = sessionBuilder.build();

        expect(session.server.serverId, 'config-override-test');
      });
    },
    configOverride: (config) => config.copyWith(serverId: 'config-override-test'),
  );
}
