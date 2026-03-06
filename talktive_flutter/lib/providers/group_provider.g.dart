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

String _$groupListHash() => r'055302966958ffc1d85580460ae10b5d8fb8e9f7';

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
