// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provider for listing all groups.

@ProviderFor(GroupList)
final groupListProvider = GroupListProvider._();

/// Provider for listing all groups.
final class GroupListProvider
    extends $AsyncNotifierProvider<GroupList, List<GroupWithMembership>> {
  /// Provider for listing all groups.
  GroupListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupListHash();

  @$internal
  @override
  GroupList create() => GroupList();
}

String _$groupListHash() => r'c665c7d2b634b813e86cdcb985d32fd32998e6a2';

/// Provider for listing all groups.

abstract class _$GroupList extends $AsyncNotifier<List<GroupWithMembership>> {
  FutureOr<List<GroupWithMembership>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<
              AsyncValue<List<GroupWithMembership>>,
              List<GroupWithMembership>
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<List<GroupWithMembership>>,
                List<GroupWithMembership>
              >,
              AsyncValue<List<GroupWithMembership>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

/// Provider for getting details about a specific group.

@ProviderFor(groupDetails)
final groupDetailsProvider = GroupDetailsFamily._();

/// Provider for getting details about a specific group.

final class GroupDetailsProvider
    extends $FunctionalProvider<AsyncValue<Group>, Group, FutureOr<Group>>
    with $FutureModifier<Group>, $FutureProvider<Group> {
  /// Provider for getting details about a specific group.
  GroupDetailsProvider._({
    required GroupDetailsFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'groupDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupDetailsHash();

  @override
  String toString() {
    return r'groupDetailsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Group> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Group> create(Ref ref) {
    final argument = this.argument as int;
    return groupDetails(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupDetailsHash() => r'4b8923b7cabdfdfd7cc163aa2e6b8f59fd7d275e';

/// Provider for getting details about a specific group.

final class GroupDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Group>, int> {
  GroupDetailsFamily._()
    : super(
        retry: null,
        name: r'groupDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting details about a specific group.

  GroupDetailsProvider call(int groupId) =>
      GroupDetailsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'groupDetailsProvider';
}

/// Provider for getting members of a group with their profiles.

@ProviderFor(groupMembersWithProfiles)
final groupMembersWithProfilesProvider = GroupMembersWithProfilesFamily._();

/// Provider for getting members of a group with their profiles.

final class GroupMembersWithProfilesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupMemberWithProfile>>,
          List<GroupMemberWithProfile>,
          FutureOr<List<GroupMemberWithProfile>>
        >
    with
        $FutureModifier<List<GroupMemberWithProfile>>,
        $FutureProvider<List<GroupMemberWithProfile>> {
  /// Provider for getting members of a group with their profiles.
  GroupMembersWithProfilesProvider._({
    required GroupMembersWithProfilesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'groupMembersWithProfilesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupMembersWithProfilesHash();

  @override
  String toString() {
    return r'groupMembersWithProfilesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<GroupMemberWithProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupMemberWithProfile>> create(Ref ref) {
    final argument = this.argument as int;
    return groupMembersWithProfiles(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMembersWithProfilesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupMembersWithProfilesHash() =>
    r'eb070059c8e90343fd4139f87678a8aee276c81e';

/// Provider for getting members of a group with their profiles.

final class GroupMembersWithProfilesFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<GroupMemberWithProfile>>, int> {
  GroupMembersWithProfilesFamily._()
    : super(
        retry: null,
        name: r'groupMembersWithProfilesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting members of a group with their profiles.

  GroupMembersWithProfilesProvider call(int groupId) =>
      GroupMembersWithProfilesProvider._(argument: groupId, from: this);

  @override
  String toString() => r'groupMembersWithProfilesProvider';
}

/// Provider for getting pending applications of a group.

@ProviderFor(pendingApplications)
final pendingApplicationsProvider = PendingApplicationsFamily._();

/// Provider for getting pending applications of a group.

final class PendingApplicationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupMemberWithProfile>>,
          List<GroupMemberWithProfile>,
          FutureOr<List<GroupMemberWithProfile>>
        >
    with
        $FutureModifier<List<GroupMemberWithProfile>>,
        $FutureProvider<List<GroupMemberWithProfile>> {
  /// Provider for getting pending applications of a group.
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
  $FutureProviderElement<List<GroupMemberWithProfile>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GroupMemberWithProfile>> create(Ref ref) {
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
    r'784fe25dea9c11745a83c986cc82445c8c4ff12a';

/// Provider for getting pending applications of a group.

final class PendingApplicationsFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<GroupMemberWithProfile>>, int> {
  PendingApplicationsFamily._()
    : super(
        retry: null,
        name: r'pendingApplicationsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting pending applications of a group.

  PendingApplicationsProvider call(int groupId) =>
      PendingApplicationsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'pendingApplicationsProvider';
}

/// Provider for getting members of a group.

@ProviderFor(groupMembers)
final groupMembersProvider = GroupMembersFamily._();

/// Provider for getting members of a group.

final class GroupMembersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Resident>>,
          List<Resident>,
          FutureOr<List<Resident>>
        >
    with $FutureModifier<List<Resident>>, $FutureProvider<List<Resident>> {
  /// Provider for getting members of a group.
  GroupMembersProvider._({
    required GroupMembersFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'groupMembersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupMembersHash();

  @override
  String toString() {
    return r'groupMembersProvider'
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
    return groupMembers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupMembersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupMembersHash() => r'e07771ed19c988f9034427ccdd4fa548a600e309';

/// Provider for getting members of a group.

final class GroupMembersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Resident>>, int> {
  GroupMembersFamily._()
    : super(
        retry: null,
        name: r'groupMembersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting members of a group.

  GroupMembersProvider call(int groupId) =>
      GroupMembersProvider._(argument: groupId, from: this);

  @override
  String toString() => r'groupMembersProvider';
}

/// Provider for getting a single group with membership from the current user.

@ProviderFor(groupWithMembership)
final groupWithMembershipProvider = GroupWithMembershipFamily._();

/// Provider for getting a single group with membership from the current user.

final class GroupWithMembershipProvider
    extends
        $FunctionalProvider<
          AsyncValue<GroupWithMembership?>,
          GroupWithMembership?,
          FutureOr<GroupWithMembership?>
        >
    with
        $FutureModifier<GroupWithMembership?>,
        $FutureProvider<GroupWithMembership?> {
  /// Provider for getting a single group with membership from the current user.
  GroupWithMembershipProvider._({
    required GroupWithMembershipFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'groupWithMembershipProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupWithMembershipHash();

  @override
  String toString() {
    return r'groupWithMembershipProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GroupWithMembership?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<GroupWithMembership?> create(Ref ref) {
    final argument = this.argument as int;
    return groupWithMembership(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupWithMembershipProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupWithMembershipHash() =>
    r'33efe5c04594862d3f46bc3551f50a5eb2056e01';

/// Provider for getting a single group with membership from the current user.

final class GroupWithMembershipFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GroupWithMembership?>, int> {
  GroupWithMembershipFamily._()
    : super(
        retry: null,
        name: r'groupWithMembershipProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Provider for getting a single group with membership from the current user.

  GroupWithMembershipProvider call(int groupId) =>
      GroupWithMembershipProvider._(argument: groupId, from: this);

  @override
  String toString() => r'groupWithMembershipProvider';
}
