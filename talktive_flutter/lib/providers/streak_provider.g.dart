// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for user streak data.

@ProviderFor(UserStreak)
final userStreakProvider = UserStreakProvider._();

/// Provider for user streak data.
final class UserStreakProvider
    extends $AsyncNotifierProvider<UserStreak, UserStreakData?> {
  /// Provider for user streak data.
  UserStreakProvider._()
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
  String debugGetCreateSourceHash() => _$userStreakHash();

  @$internal
  @override
  UserStreak create() => UserStreak();
}

String _$userStreakHash() => r'3e1b508c1b968afedd27d41bab7f824ddee25f29';

/// Provider for user streak data.

abstract class _$UserStreak extends $AsyncNotifier<UserStreakData?> {
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
