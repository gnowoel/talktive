// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'current_resident_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for the current logged-in resident's data.

@ProviderFor(CurrentResident)
final currentResidentProvider = CurrentResidentProvider._();

/// Provider for the current logged-in resident's data.
final class CurrentResidentProvider
    extends $AsyncNotifierProvider<CurrentResident, Resident?> {
  /// Provider for the current logged-in resident's data.
  CurrentResidentProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'currentResidentProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$currentResidentHash();

  @$internal
  @override
  CurrentResident create() => CurrentResident();
}

String _$currentResidentHash() => r'c686a17a4eff9e8f8464361f3419e1844bfb6a5b';

/// Provider for the current logged-in resident's data.

abstract class _$CurrentResident extends $AsyncNotifier<Resident?> {
  FutureOr<Resident?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Resident?>, Resident?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Resident?>, Resident?>,
              AsyncValue<Resident?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
