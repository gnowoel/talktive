import 'package:test/test.dart';
import 'package:talktive_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Group endpoint', (sessionBuilder, endpoints) {
    group('createGroup', () {
      test('successfully creates a public group', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000201',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Create group
        final group = await endpoints.group.createGroup(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              creator.userInfoId!.uuid,
              {},
            ),
          ),
          name: 'Test Group',
          description: 'A test group',
          emoji: '🎉',
          isPublic: true,
          maxMembers: 50,
        );

        expect(group, isNotNull);
        expect(group.name, 'Test Group');
        expect(group.description, 'A test group');
        expect(group.emoji, '🎉');
        expect(group.isPublic, true);
        expect(group.maxMembers, 50);
        expect(group.creatorId, creator.userInfoId);
        expect(group.memberCount, 1); // Creator is automatically a member
      });

      test('successfully creates a private group', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000202',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Create private group
        final group = await endpoints.group.createGroup(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              creator.userInfoId!.uuid,
              {},
            ),
          ),
          name: 'Private Group',
          description: 'A private group',
          emoji: '🔒',
          isPublic: false,
          maxMembers: 10,
        );

        expect(group.isPublic, false);
        expect(group.name, 'Private Group');
      });

      test('throws error for invalid max members', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000203',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Try to create group with invalid max members
        expect(
          () => endpoints.group.createGroup(
            sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                creator.userInfoId!.uuid,
                {},
              ),
            ),
            name: 'Test Group',
            description: 'Test',
            emoji: '🎉',
            isPublic: true,
            maxMembers: 1, // Too low (minimum is 2)
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('throws error for empty group name', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000204',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Try to create group with empty name
        expect(
          () => endpoints.group.createGroup(
            sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                creator.userInfoId!.uuid,
                {},
              ),
            ),
            name: '',
            description: 'Test',
            emoji: '🎉',
            isPublic: true,
            maxMembers: 50,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('listGroups', () {
      test('returns empty list when no groups exist', () async {
        final groups = await endpoints.group.listGroups(
          sessionBuilder,
          limit: 20,
        );

        expect(groups, isEmpty);
      });

      test('only returns public groups for unauthenticated users', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000205',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Create public group
        final publicGroup = Group(
          name: 'Public Group',
          description: 'Public',
          emoji: '🌍',
          isPublic: true,
          maxMembers: 50,
          memberCount: 1,
          creatorId: creator.userInfoId!,
          createdAt: DateTime.now(),
        );
        await Group.db.insertRow(session, publicGroup);

        // Create private group
        final privateGroup = Group(
          name: 'Private Group',
          description: 'Private',
          emoji: '🔒',
          isPublic: false,
          maxMembers: 10,
          memberCount: 1,
          creatorId: creator.userInfoId!,
          createdAt: DateTime.now(),
        );
        await Group.db.insertRow(session, privateGroup);

        // List groups without authentication
        final groups = await endpoints.group.listGroups(
          sessionBuilder,
          limit: 20,
        );

        // Should only see public group
        expect(groups.length, 1);
        expect(groups.first.isPublic, true);
      });

      test('respects limit parameter', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000206',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Create multiple groups
        for (var i = 0; i < 15; i++) {
          final group = Group(
            name: 'Group $i',
            description: 'Test group $i',
            emoji: '🎉',
            isPublic: true,
            maxMembers: 50,
            memberCount: 1,
            creatorId: creator.userInfoId!,
            createdAt: DateTime.now(),
          );
          await Group.db.insertRow(session, group);
        }

        // Test with limit of 10
        final groups = await endpoints.group.listGroups(
          sessionBuilder,
          limit: 10,
        );

        expect(groups.length, lessThanOrEqualTo(10));
      });
    });

    group('joinGroup', () {
      test('successfully joins a public group', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000207',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Create group
        final group = Group(
          name: 'Test Group',
          description: 'Test',
          emoji: '🎉',
          isPublic: true,
          maxMembers: 50,
          memberCount: 1,
          creatorId: creator.userInfoId!,
          createdAt: DateTime.now(),
        );
        await Group.db.insertRow(session, group);

        // Create joiner
        final joiner = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000208',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, joiner);

        // Join group
        await endpoints.group.joinGroup(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              joiner.userInfoId!.uuid,
              {},
            ),
          ),
          groupId: group.id!,
        );

        // Verify member count increased
        final updatedGroup = await Group.db.findById(session, group.id!);
        expect(updatedGroup!.memberCount, 2);
      });

      test('throws error when group is full', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000209',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Create group with max 2 members
        final group = Group(
          name: 'Small Group',
          description: 'Test',
          emoji: '🎉',
          isPublic: true,
          maxMembers: 2,
          memberCount: 2, // Already full
          creatorId: creator.userInfoId!,
          createdAt: DateTime.now(),
        );
        await Group.db.insertRow(session, group);

        // Create joiner
        final joiner = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000210',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, joiner);

        // Try to join full group
        expect(
          () => endpoints.group.joinGroup(
            sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                joiner.userInfoId!.uuid,
                {},
              ),
            ),
            groupId: group.id!,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('prevents duplicate joins', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000211',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Create group
        final group = Group(
          name: 'Test Group',
          description: 'Test',
          emoji: '🎉',
          isPublic: true,
          maxMembers: 50,
          memberCount: 1,
          creatorId: creator.userInfoId!,
          createdAt: DateTime.now(),
        );
        await Group.db.insertRow(session, group);

        // Create joiner
        final joiner = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000212',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, joiner);

        final sessionWithAuth = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            joiner.userInfoId!.uuid,
            {},
          ),
        );

        // Join group
        await endpoints.group.joinGroup(sessionWithAuth, groupId: group.id!);

        // Try to join again
        expect(
          () => endpoints.group.joinGroup(sessionWithAuth, groupId: group.id!),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('leaveGroup', () {
      test('successfully leaves a group', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000213',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Create group
        final group = Group(
          name: 'Test Group',
          description: 'Test',
          emoji: '🎉',
          isPublic: true,
          maxMembers: 50,
          memberCount: 2,
          creatorId: creator.userInfoId!,
          createdAt: DateTime.now(),
        );
        await Group.db.insertRow(session, group);

        // Create member
        final member = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000214',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, member);

        // Leave group
        await endpoints.group.leaveGroup(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              member.userInfoId!.uuid,
              {},
            ),
          ),
          groupId: group.id!,
        );

        // Verify member count decreased
        final updatedGroup = await Group.db.findById(session, group.id!);
        expect(updatedGroup!.memberCount, 1);
      });

      test('throws error when not a member', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000215',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Create group
        final group = Group(
          name: 'Test Group',
          description: 'Test',
          emoji: '🎉',
          isPublic: true,
          maxMembers: 50,
          memberCount: 1,
          creatorId: creator.userInfoId!,
          createdAt: DateTime.now(),
        );
        await Group.db.insertRow(session, group);

        // Create non-member
        final nonMember = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000216',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, nonMember);

        // Try to leave group without being a member
        expect(
          () => endpoints.group.leaveGroup(
            sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                nonMember.userInfoId!.uuid,
                {},
              ),
            ),
            groupId: group.id!,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('deleteGroup', () {
      test('creator can delete their group', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000217',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Create group
        final group = Group(
          name: 'Test Group',
          description: 'Test',
          emoji: '🎉',
          isPublic: true,
          maxMembers: 50,
          memberCount: 1,
          creatorId: creator.userInfoId!,
          createdAt: DateTime.now(),
        );
        await Group.db.insertRow(session, group);

        // Delete group
        await endpoints.group.deleteGroup(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              creator.userInfoId!.uuid,
              {},
            ),
          ),
          groupId: group.id!,
        );

        // Verify group is deleted
        final deletedGroup = await Group.db.findById(session, group.id!);
        expect(deletedGroup, isNull);
      });

      test('non-creator cannot delete group', () async {
        final session = await sessionBuilder.build();

        // Create creator
        final creator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000218',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, creator);

        // Create group
        final group = Group(
          name: 'Test Group',
          description: 'Test',
          emoji: '🎉',
          isPublic: true,
          maxMembers: 50,
          memberCount: 1,
          creatorId: creator.userInfoId!,
          createdAt: DateTime.now(),
        );
        await Group.db.insertRow(session, group);

        // Create non-creator
        final nonCreator = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000219',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, nonCreator);

        // Try to delete group as non-creator
        expect(
          () => endpoints.group.deleteGroup(
            sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                nonCreator.userInfoId!.uuid,
                {},
              ),
            ),
            groupId: group.id!,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
