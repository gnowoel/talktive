// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(NotificationNotifier)
final notificationProvider = NotificationNotifierProvider._();

final class NotificationNotifierProvider
    extends $NotifierProvider<NotificationNotifier, DuoNotification?> {
  NotificationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationNotifierHash();

  @$internal
  @override
  NotificationNotifier create() => NotificationNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DuoNotification? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DuoNotification?>(value),
    );
  }
}

String _$notificationNotifierHash() =>
    r'0218db970459b05f3a494d3dc3c76fd8efe3ee0d';

abstract class _$NotificationNotifier extends $Notifier<DuoNotification?> {
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
