// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gamification_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GamificationNotifier)
final gamificationProvider = GamificationNotifierProvider._();

final class GamificationNotifierProvider
    extends $AsyncNotifierProvider<GamificationNotifier, GamificationData?> {
  GamificationNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gamificationProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gamificationNotifierHash();

  @$internal
  @override
  GamificationNotifier create() => GamificationNotifier();
}

String _$gamificationNotifierHash() =>
    r'6bb9842b3af03d77d259e0fc20b99d5330729d57';

abstract class _$GamificationNotifier
    extends $AsyncNotifier<GamificationData?> {
  FutureOr<GamificationData?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<GamificationData?>, GamificationData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GamificationData?>, GamificationData?>,
              AsyncValue<GamificationData?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
