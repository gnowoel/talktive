// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the single current in-app popup notification.

@ProviderFor(InAppNotification)
final inAppNotificationProvider = InAppNotificationProvider._();

/// Provider for the single current in-app popup notification.
final class InAppNotificationProvider
    extends $NotifierProvider<InAppNotification, DuoNotification?> {
  /// Provider for the single current in-app popup notification.
  InAppNotificationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inAppNotificationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inAppNotificationHash();

  @$internal
  @override
  InAppNotification create() => InAppNotification();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DuoNotification? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DuoNotification?>(value),
    );
  }
}

String _$inAppNotificationHash() => r'058b0df13e3e316de8962baedb2551811a7829fa';

/// Provider for the single current in-app popup notification.

abstract class _$InAppNotification extends $Notifier<DuoNotification?> {
  DuoNotification? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DuoNotification?, DuoNotification?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DuoNotification?, DuoNotification?>,
              DuoNotification?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for fetching and managing the persistent activity history (notifications).

@ProviderFor(ActivityHistory)
final activityHistoryProvider = ActivityHistoryProvider._();

/// Provider for fetching and managing the persistent activity history (notifications).
final class ActivityHistoryProvider
    extends $AsyncNotifierProvider<ActivityHistory, List<UserNotification>> {
  /// Provider for fetching and managing the persistent activity history (notifications).
  ActivityHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activityHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$activityHistoryHash();

  @$internal
  @override
  ActivityHistory create() => ActivityHistory();
}

String _$activityHistoryHash() => r'7909049ba363ebd5d583df2157b9b3eaa9d1d51c';

/// Provider for fetching and managing the persistent activity history (notifications).

abstract class _$ActivityHistory
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
