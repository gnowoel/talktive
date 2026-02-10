// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resident_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CurrentResident)
final currentResidentProvider = CurrentResidentProvider._();

final class CurrentResidentProvider
    extends $AsyncNotifierProvider<CurrentResident, Resident?> {
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

String _$currentResidentHash() => r'e82a5fa796e279ebf0bce81e2c435801d1ed18c2';

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
