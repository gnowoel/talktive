// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for user notifications.

@ProviderFor(UserNotifications)
final userNotificationsProvider = UserNotificationsProvider._();

/// Provider for user notifications.
final class UserNotificationsProvider
    extends $AsyncNotifierProvider<UserNotifications, List<UserNotification>> {
  /// Provider for user notifications.
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

String _$userNotificationsHash() => r'5c4f60b1ff32171e097b0e88492c6d55c90acef8';

/// Provider for user notifications.

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

/// Provider for unread notification count.

@ProviderFor(UnreadNotificationCount)
final unreadNotificationCountProvider = UnreadNotificationCountProvider._();

/// Provider for unread notification count.
final class UnreadNotificationCountProvider
    extends $AsyncNotifierProvider<UnreadNotificationCount, int> {
  /// Provider for unread notification count.
  UnreadNotificationCountProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'unreadNotificationCountProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$unreadNotificationCountHash();

  @$internal
  @override
  UnreadNotificationCount create() => UnreadNotificationCount();
}

String _$unreadNotificationCountHash() =>
    r'717a70c092cd58908d8e77df29d9d667c5a644e7';

/// Provider for unread notification count.

abstract class _$UnreadNotificationCount extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
