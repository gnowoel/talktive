// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'achievement_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for user achievements.

@ProviderFor(UserAchievements)
final userAchievementsProvider = UserAchievementsProvider._();

/// Provider for user achievements.
final class UserAchievementsProvider
    extends
        $AsyncNotifierProvider<UserAchievements, List<Map<String, dynamic>>> {
  /// Provider for user achievements.
  UserAchievementsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userAchievementsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userAchievementsHash();

  @$internal
  @override
  UserAchievements create() => UserAchievements();
}

String _$userAchievementsHash() => r'f18929d5b1f9ed60f425ef2f634699c11621cda0';

/// Provider for user achievements.

abstract class _$UserAchievements
    extends $AsyncNotifier<List<Map<String, dynamic>>> {
  FutureOr<List<Map<String, dynamic>>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<Map<String, dynamic>>>,
              List<Map<String, dynamic>>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<Map<String, dynamic>>>,
                List<Map<String, dynamic>>
              >,
              AsyncValue<List<Map<String, dynamic>>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
