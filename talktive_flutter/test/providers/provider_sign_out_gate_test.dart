import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:serverpod_auth_core_flutter/serverpod_auth_core_flutter.dart';
import 'package:talktive/providers/auth_provider.dart';
import 'package:talktive/providers/client_provider.dart';
import 'package:talktive/providers/private_chat_provider.dart';
import 'package:talktive/providers/user_profile_provider.dart';
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

class _CountingPrivateChatEndpoint extends EndpointPrivateChat {
  _CountingPrivateChatEndpoint(super.caller);

  int listCalls = 0;

  @override
  Future<List<PrivateChatWithProfile>> listPrivateChats() async {
    listCalls++;
    return const [];
  }
}

class _CountingResidentEndpoint extends EndpointResident {
  _CountingResidentEndpoint(super.caller);

  int profileCalls = 0;
  int likedCalls = 0;
  int blockedCalls = 0;

  @override
  Future<UserProfileView?> getUserProfile(String userId) async {
    profileCalls++;
    return null;
  }

  @override
  Future<List<String>> getMyLikedResidentIds() async {
    likedCalls++;
    return const [];
  }

  @override
  Future<List<String>> getBlockedResidentIds() async {
    blockedCalls++;
    return const [];
  }
}

class _TestClient extends Client {
  _TestClient() : super('http://localhost:0/') {
    _privateChatEndpoint = _CountingPrivateChatEndpoint(this);
    _residentEndpoint = _CountingResidentEndpoint(this);
  }

  late final _CountingPrivateChatEndpoint _privateChatEndpoint;

  late final _CountingResidentEndpoint _residentEndpoint;

  @override
  EndpointPrivateChat get privateChat => _privateChatEndpoint;

  @override
  EndpointResident get resident => _residentEndpoint;
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

  group('provider sign-out gate', () {
    test(
      'private chat list fetches while authenticated and gate open',
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
        final chatSubscription = container.listen(
          privateChatListProvider,
          (_, _) {},
          fireImmediately: true,
        );
        addTearDown(() {
          chatSubscription.close();
          container.dispose();
        });

        final chats = await container.read(privateChatListProvider.future);

        expect(chats, isEmpty);
        expect(client._privateChatEndpoint.listCalls, 1);
      },
    );

    test('sign-out gate blocks provider endpoint calls', () async {
      authenticatedCallGate.beginSignOut();

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
      final chatSubscription = container.listen(
        privateChatListProvider,
        (_, _) {},
        fireImmediately: true,
      );
      final profileSubscription = container.listen(
        userProfileProvider('resident-1'),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(() {
        profileSubscription.close();
        chatSubscription.close();
        container.dispose();
      });

      final chats = await container.read(privateChatListProvider.future);
      final profile = await container.read(
        userProfileProvider('resident-1').future,
      );
      await container.read(privateChatListProvider.notifier).refresh();
      await container
          .read(userProfileProvider('resident-1').notifier)
          .refresh();

      expect(chats, isEmpty);
      expect(profile, isNull);
      expect(client._privateChatEndpoint.listCalls, 0);
      expect(client._residentEndpoint.profileCalls, 0);
      expect(client._residentEndpoint.likedCalls, 0);
      expect(client._residentEndpoint.blockedCalls, 0);
    });
  });
}
