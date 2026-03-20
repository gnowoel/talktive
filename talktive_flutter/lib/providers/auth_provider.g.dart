// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Auth)
final authProvider = AuthProvider._();

final class AuthProvider
    extends $AsyncNotifierProvider<Auth, TalktiveAuthState> {
  AuthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authHash();

  @$internal
  @override
  Auth create() => Auth();
}

String _$authHash() => r'535e7d1bf04a84f7685dc5f8c0a3c9c5d1af7bff';

abstract class _$Auth extends $AsyncNotifier<TalktiveAuthState> {
  FutureOr<TalktiveAuthState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<TalktiveAuthState>, TalktiveAuthState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TalktiveAuthState>, TalktiveAuthState>,
              AsyncValue<TalktiveAuthState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
