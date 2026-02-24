// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_likes_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserLikes)
final userLikesProvider = UserLikesProvider._();

final class UserLikesProvider
    extends $AsyncNotifierProvider<UserLikes, List<String>> {
  UserLikesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userLikesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userLikesHash();

  @$internal
  @override
  UserLikes create() => UserLikes();
}

String _$userLikesHash() => r'3b8319fd6364ffb6e0a03592fc1b4b543d984ba5';

abstract class _$UserLikes extends $AsyncNotifier<List<String>> {
  FutureOr<List<String>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<String>>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<String>>, List<String>>,
              AsyncValue<List<String>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
