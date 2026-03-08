// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'moments_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the moments feed

@ProviderFor(Moments)
final momentsProvider = MomentsProvider._();

/// Provider for the moments feed
final class MomentsProvider
    extends $AsyncNotifierProvider<Moments, List<Moment>> {
  /// Provider for the moments feed
  MomentsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'momentsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$momentsHash();

  @$internal
  @override
  Moments create() => Moments();
}

String _$momentsHash() => r'6793fb975bae4fced66a47cc17957e1598d551c4';

/// Provider for the moments feed

abstract class _$Moments extends $AsyncNotifier<List<Moment>> {
  FutureOr<List<Moment>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Moment>>, List<Moment>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Moment>>, List<Moment>>,
              AsyncValue<List<Moment>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for tracking which moments are liked by the current user

@ProviderFor(MomentLikes)
final momentLikesProvider = MomentLikesProvider._();

/// Provider for tracking which moments are liked by the current user
final class MomentLikesProvider
    extends $AsyncNotifierProvider<MomentLikes, Set<int>> {
  /// Provider for tracking which moments are liked by the current user
  MomentLikesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'momentLikesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$momentLikesHash();

  @$internal
  @override
  MomentLikes create() => MomentLikes();
}

String _$momentLikesHash() => r'6f0e9bd4de15cfc4f4992210ea7c88a5a0b24733';

/// Provider for tracking which moments are liked by the current user

abstract class _$MomentLikes extends $AsyncNotifier<Set<int>> {
  FutureOr<Set<int>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Set<int>>, Set<int>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Set<int>>, Set<int>>,
              AsyncValue<Set<int>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for comments on a specific moment

@ProviderFor(MomentComments)
final momentCommentsProvider = MomentCommentsFamily._();

/// Provider for comments on a specific moment
final class MomentCommentsProvider
    extends $AsyncNotifierProvider<MomentComments, List<MomentComment>> {
  /// Provider for comments on a specific moment
  MomentCommentsProvider._({
    required MomentCommentsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'momentCommentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$momentCommentsHash();

  @override
  String toString() {
    return r'momentCommentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  MomentComments create() => MomentComments();

  @override
  bool operator ==(Object other) {
    return other is MomentCommentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$momentCommentsHash() => r'8db05d52d7faf0df24aeeaf04062d54f686290db';

/// Provider for comments on a specific moment

final class MomentCommentsFamily extends $Family
    with
        $ClassFamilyOverride<
          MomentComments,
          AsyncValue<List<MomentComment>>,
          List<MomentComment>,
          FutureOr<List<MomentComment>>,
          int
        > {
  MomentCommentsFamily._()
    : super(
        retry: null,
        name: r'momentCommentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for comments on a specific moment

  MomentCommentsProvider call(int momentId) =>
      MomentCommentsProvider._(argument: momentId, from: this);

  @override
  String toString() => r'momentCommentsProvider';
}

/// Provider for comments on a specific moment

abstract class _$MomentComments extends $AsyncNotifier<List<MomentComment>> {
  late final _$args = ref.$arg as int;
  int get momentId => _$args;

  FutureOr<List<MomentComment>> build(int momentId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<MomentComment>>, List<MomentComment>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<MomentComment>>, List<MomentComment>>,
              AsyncValue<List<MomentComment>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

/// Provider for a specific user's moments

@ProviderFor(UserMoments)
final userMomentsProvider = UserMomentsFamily._();

/// Provider for a specific user's moments
final class UserMomentsProvider
    extends $AsyncNotifierProvider<UserMoments, List<Moment>> {
  /// Provider for a specific user's moments
  UserMomentsProvider._({
    required UserMomentsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'userMomentsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$userMomentsHash();

  @override
  String toString() {
    return r'userMomentsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  UserMoments create() => UserMoments();

  @override
  bool operator ==(Object other) {
    return other is UserMomentsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$userMomentsHash() => r'89f4ef058a9476abd772d15c3d245bd7b8c1fca9';

/// Provider for a specific user's moments

final class UserMomentsFamily extends $Family
    with
        $ClassFamilyOverride<
          UserMoments,
          AsyncValue<List<Moment>>,
          List<Moment>,
          FutureOr<List<Moment>>,
          String
        > {
  UserMomentsFamily._()
    : super(
        retry: null,
        name: r'userMomentsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for a specific user's moments

  UserMomentsProvider call(String userId) =>
      UserMomentsProvider._(argument: userId, from: this);

  @override
  String toString() => r'userMomentsProvider';
}

/// Provider for a specific user's moments

abstract class _$UserMoments extends $AsyncNotifier<List<Moment>> {
  late final _$args = ref.$arg as String;
  String get userId => _$args;

  FutureOr<List<Moment>> build(String userId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Moment>>, List<Moment>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Moment>>, List<Moment>>,
              AsyncValue<List<Moment>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
