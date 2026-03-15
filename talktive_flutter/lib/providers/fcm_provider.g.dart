// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fcm_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for Firebase Cloud Messaging for the Serverpod version.
/// Background messages are handled centrally in background_messaging_handler.dart.

@ProviderFor(FCMManager)
final fCMManagerProvider = FCMManagerProvider._();

/// Provider for Firebase Cloud Messaging for the Serverpod version.
/// Background messages are handled centrally in background_messaging_handler.dart.
final class FCMManagerProvider
    extends $AsyncNotifierProvider<FCMManager, String?> {
  /// Provider for Firebase Cloud Messaging for the Serverpod version.
  /// Background messages are handled centrally in background_messaging_handler.dart.
  FCMManagerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'fCMManagerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$fCMManagerHash();

  @$internal
  @override
  FCMManager create() => FCMManager();
}

String _$fCMManagerHash() => r'9a43c579d4482ed483c5c8ea28d2ad313460e1e2';

/// Provider for Firebase Cloud Messaging for the Serverpod version.
/// Background messages are handled centrally in background_messaging_handler.dart.

abstract class _$FCMManager extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
