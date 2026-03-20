// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for user profile data (cached and reactive)

@ProviderFor(UserProfile)
final userProfileProvider = UserProfileFamily._();

/// Provider for user profile data (cached and reactive)
final class UserProfileProvider
    extends $AsyncNotifierProvider<UserProfile, UserProfileView?> {
  /// Provider for user profile data (cached and reactive)
  UserProfileProvider._({
    required UserProfileFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userProfileProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userProfileHash();

  @override
  String toString() {
    return r'userProfileProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserProfile create() => UserProfile();

  @override
  bool operator ==(Object other) {
    return other is UserProfileProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userProfileHash() => r'64992f76d9136892a6368a034e2da987ce670c84';

/// Provider for user profile data (cached and reactive)

final class UserProfileFamily extends $Family
    with
        $ClassFamilyOverride<
          UserProfile,
          AsyncValue<UserProfileView?>,
          UserProfileView?,
          FutureOr<UserProfileView?>,
          String
        > {
  UserProfileFamily._()
    : super(
        retry: null,
        name: r'userProfileProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for user profile data (cached and reactive)

  UserProfileProvider call(String userId) =>
      UserProfileProvider._(argument: userId, from: this);

  @override
  String toString() => r'userProfileProvider';
}

/// Provider for user profile data (cached and reactive)

abstract class _$UserProfile extends $AsyncNotifier<UserProfileView?> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  FutureOr<UserProfileView?> build(String userId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<UserProfileView?>, UserProfileView?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserProfileView?>, UserProfileView?>,
              AsyncValue<UserProfileView?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
