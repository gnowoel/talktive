import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_core_flutter/serverpod_auth_core_flutter.dart';
import 'package:talktive/providers/auth_provider.dart';
import 'package:talktive/providers/client_provider.dart';
import 'package:talktive/providers/private_chat_provider.dart';
import 'package:talktive/serverpod_client.dart';
import 'package:talktive_client/talktive_client.dart';

class _InMemoryAuthStorage implements ClientAuthSuccessStorage {
  AuthSuccess? _data;

  @override
  Future<AuthSuccess?> get() async => _data;

  @override
  Future<void> set(AuthSuccess? data) async {
    _data = data;
  }
}

class _TestAuthNotifier extends Auth {
  _TestAuthNotifier(this.initialState);

  final TalktiveAuthState initialState;

  @override
  FutureOr<TalktiveAuthState> build() => initialState;
}

class _RecordingPrivateChatEndpoint extends EndpointPrivateChat {
  _RecordingPrivateChatEndpoint(super.caller);

  int createCalls = 0;

  @override
  Future<PrivateChat> getOrCreatePrivateChat(
    String otherUserId, {
    String? initialMessage,
  }) async {
    createCalls++;
    return PrivateChat(
      channelId: 42,
      participant1Id: UuidValue.fromString(
        '019d6272-8048-7f9a-9166-ed584a2bd93d',
      ),
      participant2Id: UuidValue.fromString(
        '019d6272-8048-7f9a-9166-ed584a2bd93e',
      ),
      createdAt: DateTime(2026),
    );
  }
}

class _TestClient extends Client {
  _TestClient() : super('http://localhost:0/') {
    _privateChatEndpoint = _RecordingPrivateChatEndpoint(this);
  }

  late final _RecordingPrivateChatEndpoint _privateChatEndpoint;

  @override
  EndpointPrivateChat get privateChat => _privateChatEndpoint;
}

AuthSuccess _fakeAuthSuccess() {
  return AuthSuccess(
    authStrategy: 'test',
    token: 'test-token',
    authUserId: UuidValue.fromString('019d6272-8048-7f9a-9166-ed584a2bd93d'),
    scopeNames: const {},
  );
}

void main() {
  late _TestClient client;

  setUpAll(() async {
    final bootstrapClient = Client('http://localhost:0/');
    final manager = FlutterAuthSessionManager(storage: _InMemoryAuthStorage());
    FlutterAuthSessionManagerExtension(bootstrapClient).authSessionManager =
        manager;
    sessionManager = manager;
  });

  setUp(() async {
    client = _TestClient();
    authenticatedCallGate.endSignOut();
    await sessionManager.updateSignedInUser(_fakeAuthSuccess());
  });

  tearDown(() async {
    authenticatedCallGate.endSignOut();
    await sessionManager.updateSignedInUser(null);
  });

  test(
    'getOrCreateChat rejects self chat before hitting the endpoint',
    () async {
      final container = ProviderContainer(
        overrides: [
          clientProvider.overrideWithValue(client),
          authProvider.overrideWith(
            () => _TestAuthNotifier(
              const Authenticated(userId: 'resident-1', userName: 'Resident'),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container
            .read(privateChatListProvider.notifier)
            .getOrCreateChat('resident-1'),
        throwsA(
          isA<TalktiveException>().having(
            (error) => error.code,
            'code',
            'SELF_CHAT_NOT_ALLOWED',
          ),
        ),
      );
      expect(client._privateChatEndpoint.createCalls, 0);
    },
  );
}
