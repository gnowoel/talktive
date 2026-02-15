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

/// Provider to fetch a resident by their user ID

@ProviderFor(residentById)
final residentByIdProvider = ResidentByIdFamily._();

/// Provider to fetch a resident by their user ID

final class ResidentByIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Resident?>,
          Resident?,
          FutureOr<Resident?>
        >
    with $FutureModifier<Resident?>, $FutureProvider<Resident?> {
  /// Provider to fetch a resident by their user ID
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

String _$residentByIdHash() => r'f6822834ba639e01bc43a0c338559022079e6809';

/// Provider to fetch a resident by their user ID

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

  /// Provider to fetch a resident by their user ID

  ResidentByIdProvider call(String userId) =>
      ResidentByIdProvider._(argument: userId, from: this);

  @override
  String toString() => r'residentByIdProvider';
}
