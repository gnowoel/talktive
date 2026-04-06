// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_relationships_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SocialRelationshipsState)
final socialRelationshipsStateProvider = SocialRelationshipsStateProvider._();

final class SocialRelationshipsStateProvider
    extends
        $AsyncNotifierProvider<SocialRelationshipsState, SocialRelationships> {
  SocialRelationshipsStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'socialRelationshipsStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$socialRelationshipsStateHash();

  @$internal
  @override
  SocialRelationshipsState create() => SocialRelationshipsState();
}

String _$socialRelationshipsStateHash() =>
    r'f30b2edb874c6a276fa36a2c36cf9a769e759a2f';

abstract class _$SocialRelationshipsState
    extends $AsyncNotifier<SocialRelationships> {
  FutureOr<SocialRelationships> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<SocialRelationships>, SocialRelationships>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<SocialRelationships>, SocialRelationships>,
              AsyncValue<SocialRelationships>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
