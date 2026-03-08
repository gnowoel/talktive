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

String _$currentResidentHash() => r'ad6a14a8be02b33ad033e4dc27affc2d57e291f8';

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

/// Provider to fetch a resident by their user ID.

@ProviderFor(residentById)
final residentByIdProvider = ResidentByIdFamily._();

/// Provider to fetch a resident by their user ID.

final class ResidentByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Resident?>,
          Resident?,
          FutureOr<Resident?>
        >
    with $FutureModifier<Resident?>, $FutureProvider<Resident?> {
  /// Provider to fetch a resident by their user ID.
  ResidentByIdProvider._({
    required ResidentByIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'residentByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$residentByIdHash();

  @override
  String toString() {
    return r'residentByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Resident?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Resident?> create(Ref ref) {
    final argument = this.argument as String;
    return residentById(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ResidentByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$residentByIdHash() => r'534cc053da81ecd3cf97e9c64eb479d5b1c4f17c';

/// Provider to fetch a resident by their user ID.

final class ResidentByIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Resident?>, String> {
  ResidentByIdFamily._()
    : super(
        retry: null,
        name: r'residentByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider to fetch a resident by their user ID.

  ResidentByIdProvider call(String userId) =>
      ResidentByIdProvider._(argument: userId, from: this);

  @override
  String toString() => r'residentByIdProvider';
}
