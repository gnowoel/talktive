// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lounge_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for listing all lounges.

@ProviderFor(LoungeList)
final loungeListProvider = LoungeListProvider._();

/// Provider for listing all lounges.
final class LoungeListProvider
    extends $AsyncNotifierProvider<LoungeList, List<LoungeWithMembership>> {
  /// Provider for listing all lounges.
  LoungeListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'loungeListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$loungeListHash();

  @$internal
  @override
  LoungeList create() => LoungeList();
}

String _$loungeListHash() => r'3a0b96b174ce00d7f9c6dd467cd6d21aec552946';

/// Provider for listing all lounges.

abstract class _$LoungeList extends $AsyncNotifier<List<LoungeWithMembership>> {
  FutureOr<List<LoungeWithMembership>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<LoungeWithMembership>>,
              List<LoungeWithMembership>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<LoungeWithMembership>>,
                List<LoungeWithMembership>
              >,
              AsyncValue<List<LoungeWithMembership>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for getting details about a specific lounge.

@ProviderFor(loungeDetails)
final loungeDetailsProvider = LoungeDetailsFamily._();

/// Provider for getting details about a specific lounge.

final class LoungeDetailsProvider
    extends $FunctionalProvider<AsyncValue<Lounge>, Lounge, FutureOr<Lounge>>
    with $FutureModifier<Lounge>, $FutureProvider<Lounge> {
  /// Provider for getting details about a specific lounge.
  LoungeDetailsProvider._({
    required LoungeDetailsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'loungeDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$loungeDetailsHash();

  @override
  String toString() {
    return r'loungeDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Lounge> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Lounge> create(Ref ref) {
    final argument = this.argument as int;
    return loungeDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LoungeDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$loungeDetailsHash() => r'7d2966cf5a93309aa3a3b2b4f129ea409651b54a';

/// Provider for getting details about a specific lounge.

final class LoungeDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Lounge>, int> {
  LoungeDetailsFamily._()
    : super(
        retry: null,
        name: r'loungeDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting details about a specific lounge.

  LoungeDetailsProvider call(int loungeId) =>
      LoungeDetailsProvider._(argument: loungeId, from: this);

  @override
  String toString() => r'loungeDetailsProvider';
}

/// Provider for getting members of a lounge with their profiles.

@ProviderFor(loungeMembersWithProfiles)
final loungeMembersWithProfilesProvider = LoungeMembersWithProfilesFamily._();

/// Provider for getting members of a lounge with their profiles.

final class LoungeMembersWithProfilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LoungeMemberWithProfile>>,
          List<LoungeMemberWithProfile>,
          FutureOr<List<LoungeMemberWithProfile>>
        >
    with
        $FutureModifier<List<LoungeMemberWithProfile>>,
        $FutureProvider<List<LoungeMemberWithProfile>> {
  /// Provider for getting members of a lounge with their profiles.
  LoungeMembersWithProfilesProvider._({
    required LoungeMembersWithProfilesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'loungeMembersWithProfilesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$loungeMembersWithProfilesHash();

  @override
  String toString() {
    return r'loungeMembersWithProfilesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<LoungeMemberWithProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LoungeMemberWithProfile>> create(Ref ref) {
    final argument = this.argument as int;
    return loungeMembersWithProfiles(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LoungeMembersWithProfilesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$loungeMembersWithProfilesHash() =>
    r'97a5c64a831d509e76aade2010b02397646ca8bd';

/// Provider for getting members of a lounge with their profiles.

final class LoungeMembersWithProfilesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<LoungeMemberWithProfile>>,
          int
        > {
  LoungeMembersWithProfilesFamily._()
    : super(
        retry: null,
        name: r'loungeMembersWithProfilesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting members of a lounge with their profiles.

  LoungeMembersWithProfilesProvider call(int loungeId) =>
      LoungeMembersWithProfilesProvider._(argument: loungeId, from: this);

  @override
  String toString() => r'loungeMembersWithProfilesProvider';
}

/// Provider for getting pending applications of a lounge.

@ProviderFor(pendingApplications)
final pendingApplicationsProvider = PendingApplicationsFamily._();

/// Provider for getting pending applications of a lounge.

final class PendingApplicationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<LoungeMemberWithProfile>>,
          List<LoungeMemberWithProfile>,
          FutureOr<List<LoungeMemberWithProfile>>
        >
    with
        $FutureModifier<List<LoungeMemberWithProfile>>,
        $FutureProvider<List<LoungeMemberWithProfile>> {
  /// Provider for getting pending applications of a lounge.
  PendingApplicationsProvider._({
    required PendingApplicationsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'pendingApplicationsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pendingApplicationsHash();

  @override
  String toString() {
    return r'pendingApplicationsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<LoungeMemberWithProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<LoungeMemberWithProfile>> create(Ref ref) {
    final argument = this.argument as int;
    return pendingApplications(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PendingApplicationsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pendingApplicationsHash() =>
    r'93099558a6622cf264000b6ea10b1e90c7f4308f';

/// Provider for getting pending applications of a lounge.

final class PendingApplicationsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<LoungeMemberWithProfile>>,
          int
        > {
  PendingApplicationsFamily._()
    : super(
        retry: null,
        name: r'pendingApplicationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting pending applications of a lounge.

  PendingApplicationsProvider call(int loungeId) =>
      PendingApplicationsProvider._(argument: loungeId, from: this);

  @override
  String toString() => r'pendingApplicationsProvider';
}

/// Provider for getting members of a lounge.

@ProviderFor(loungeMembers)
final loungeMembersProvider = LoungeMembersFamily._();

/// Provider for getting members of a lounge.

final class LoungeMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Resident>>,
          List<Resident>,
          FutureOr<List<Resident>>
        >
    with $FutureModifier<List<Resident>>, $FutureProvider<List<Resident>> {
  /// Provider for getting members of a lounge.
  LoungeMembersProvider._({
    required LoungeMembersFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'loungeMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$loungeMembersHash();

  @override
  String toString() {
    return r'loungeMembersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Resident>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Resident>> create(Ref ref) {
    final argument = this.argument as int;
    return loungeMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LoungeMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$loungeMembersHash() => r'590b72afca1415d6c9722bfc22704a0e25986026';

/// Provider for getting members of a lounge.

final class LoungeMembersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Resident>>, int> {
  LoungeMembersFamily._()
    : super(
        retry: null,
        name: r'loungeMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting members of a lounge.

  LoungeMembersProvider call(int loungeId) =>
      LoungeMembersProvider._(argument: loungeId, from: this);

  @override
  String toString() => r'loungeMembersProvider';
}

/// Provider for getting a single lounge with membership from the current user.

@ProviderFor(loungeWithMembership)
final loungeWithMembershipProvider = LoungeWithMembershipFamily._();

/// Provider for getting a single lounge with membership from the current user.

final class LoungeWithMembershipProvider
    extends
        $FunctionalProvider<
          AsyncValue<LoungeWithMembership?>,
          LoungeWithMembership?,
          FutureOr<LoungeWithMembership?>
        >
    with
        $FutureModifier<LoungeWithMembership?>,
        $FutureProvider<LoungeWithMembership?> {
  /// Provider for getting a single lounge with membership from the current user.
  LoungeWithMembershipProvider._({
    required LoungeWithMembershipFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'loungeWithMembershipProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$loungeWithMembershipHash();

  @override
  String toString() {
    return r'loungeWithMembershipProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LoungeWithMembership?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LoungeWithMembership?> create(Ref ref) {
    final argument = this.argument as int;
    return loungeWithMembership(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LoungeWithMembershipProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$loungeWithMembershipHash() =>
    r'f051796277376adb28a766e947b5ecbe6ea04308';

/// Provider for getting a single lounge with membership from the current user.

final class LoungeWithMembershipFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LoungeWithMembership?>, int> {
  LoungeWithMembershipFamily._()
    : super(
        retry: null,
        name: r'loungeWithMembershipProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting a single lounge with membership from the current user.

  LoungeWithMembershipProvider call(int loungeId) =>
      LoungeWithMembershipProvider._(argument: loungeId, from: this);

  @override
  String toString() => r'loungeWithMembershipProvider';
}
