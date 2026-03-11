// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_notifications_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserNotifications)
final userNotificationsProvider = UserNotificationsProvider._();

final class UserNotificationsProvider
    extends $AsyncNotifierProvider<UserNotifications, List<UserNotification>> {
  UserNotificationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userNotificationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userNotificationsHash();

  @$internal
  @override
  UserNotifications create() => UserNotifications();
}

String _$userNotificationsHash() => r'ec636def5c7c52f5059e36d488683d1db00af2ae';

abstract class _$UserNotifications
    extends $AsyncNotifier<List<UserNotification>> {
  FutureOr<List<UserNotification>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<List<UserNotification>>, List<UserNotification>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<UserNotification>>,
                List<UserNotification>
              >,
              AsyncValue<List<UserNotification>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
