// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for user streak data.

@ProviderFor(UserStreakNotifier)
final userStreakProvider = UserStreakNotifierProvider._();

/// Provider for user streak data.
final class UserStreakNotifierProvider
    extends $AsyncNotifierProvider<UserStreakNotifier, UserStreakData?> {
  /// Provider for user streak data.
  UserStreakNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userStreakProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userStreakNotifierHash();

  @$internal
  @override
  UserStreakNotifier create() => UserStreakNotifier();
}

String _$userStreakNotifierHash() =>
    r'e080f5866b4d23a631a27199e7615d01bae7a4a0';

/// Provider for user streak data.

abstract class _$UserStreakNotifier extends $AsyncNotifier<UserStreakData?> {
  FutureOr<UserStreakData?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<UserStreakData?>, UserStreakData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserStreakData?>, UserStreakData?>,
              AsyncValue<UserStreakData?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
