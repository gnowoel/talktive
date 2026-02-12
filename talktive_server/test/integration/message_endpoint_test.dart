import 'package:test/test.dart';
import 'package:talktive_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Message endpoint', (sessionBuilder, endpoints) {
    group('listMessages', () {
      test('returns empty list when no messages exist', () async {
        final messages = await endpoints.message.listMessages(
          sessionBuilder,
          channelId: 1,
          limit: 20,
        );

        expect(messages, isEmpty);
      });

      test('respects limit parameter', () async {
        // Create test messages
        final session = await sessionBuilder.build();

        // Create a test user first
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000001',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Create multiple messages
        for (var i = 0; i < 15; i++) {
          final message = Message(
            channelId: 1,
            senderId: resident.userInfoId!,
            content: 'Test message $i',
            createdAt: DateTime.now(),
          );
          await Message.db.insertRow(session, message);
        }

        // Test with limit of 10
        final messages = await endpoints.message.listMessages(
          sessionBuilder,
          channelId: 1,
          limit: 10,
        );

        expect(messages.length, lessThanOrEqualTo(10));
      });

      test('returns messages in chronological order', () async {
        final session = await sessionBuilder.build();

        // Create test user
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000002',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Create messages with different timestamps
        final now = DateTime.now();
        for (var i = 0; i < 5; i++) {
          final message = Message(
            channelId: 1,
            senderId: resident.userInfoId!,
            content: 'Message $i',
            createdAt: now.add(Duration(seconds: i)),
          );
          await Message.db.insertRow(session, message);
        }

        final messages = await endpoints.message.listMessages(
          sessionBuilder,
          channelId: 1,
          limit: 20,
        );

        // Verify chronological order (newest first)
        for (var i = 0; i < messages.length - 1; i++) {
          expect(
            messages[i].createdAt!.isAfter(messages[i + 1].createdAt!),
            true,
            reason: 'Messages should be in reverse chronological order',
          );
        }
      });

      test('filters by channel ID', () async {
        final session = await sessionBuilder.build();

        // Create test user
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000003',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Create messages in different channels
        await Message.db.insertRow(
          session,
          Message(
            channelId: 1,
            senderId: resident.userInfoId!,
            content: 'Channel 1 message',
            createdAt: DateTime.now(),
          ),
        );
        await Message.db.insertRow(
          session,
          Message(
            channelId: 2,
            senderId: resident.userInfoId!,
            content: 'Channel 2 message',
            createdAt: DateTime.now(),
          ),
        );

        // Query channel 1
        final channel1Messages = await endpoints.message.listMessages(
          sessionBuilder,
          channelId: 1,
          limit: 20,
        );

        // All messages should be from channel 1
        for (final message in channel1Messages) {
          expect(message.channelId, 1);
        }
      });
    });

    group('sendMessage', () {
      test('throws error when user has insufficient credit score', () async {
        final session = await sessionBuilder.build();

        // Create user with low credit score
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000004',
          ),
          floor: 0,
          creditScore: -10, // Below threshold
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Attempt to send message should fail
        expect(
          () => endpoints.message.sendMessage(
            sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                resident.userInfoId!.uuid,
                {},
              ),
            ),
            channelId: 1,
            content: 'Test message',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('successfully creates message with valid user', () async {
        final session = await sessionBuilder.build();

        // Create user with good credit score
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000005',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Send message
        final message = await endpoints.message.sendMessage(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              resident.userInfoId!.uuid,
              {},
            ),
          ),
          channelId: 1,
          content: 'Test message',
        );

        expect(message, isNotNull);
        expect(message.content, 'Test message');
        expect(message.channelId, 1);
        expect(message.senderId, resident.userInfoId);
      });

      test('increments user message count', () async {
        final session = await sessionBuilder.build();

        // Create user
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000006',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        final initialCount = resident.totalMessages;

        // Send message
        await endpoints.message.sendMessage(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              resident.userInfoId!.uuid,
              {},
            ),
          ),
          channelId: 1,
          content: 'Test message',
        );

        // Verify count increased
        final updatedResident = await Resident.db.findById(
          session,
          resident.id!,
        );

        expect(updatedResident!.totalMessages, initialCount! + 1);
      });

      test('filters profanity in message content', () async {
        final session = await sessionBuilder.build();

        // Create user
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000007',
          ),
          floor: 2, // Higher floor for lenient filtering
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Send message with profanity
        final message = await endpoints.message.sendMessage(
          sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              resident.userInfoId!.uuid,
              {},
            ),
          ),
          channelId: 1,
          content: 'This has badword1 in it',
        );

        // Content should be filtered
        expect(message.content, isNot(contains('badword1')));
        expect(message.content, contains('*')); // Replaced with asterisks
      });

      test('blocks spam messages', () async {
        final session = await sessionBuilder.build();

        // Create user
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000008',
          ),
          floor: 1,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        // Attempt to send spam message
        expect(
          () => endpoints.message.sendMessage(
            sessionBuilder.copyWith(
              authentication: AuthenticationOverride.authenticationInfo(
                resident.userInfoId!.uuid,
                {},
              ),
            ),
            channelId: 1,
            content: 'Check out http://spam.com for free prizes!!!',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Rate Limiting', () {
      test('enforces rate limits for low floor users', () async {
        final session = await sessionBuilder.build();

        // Create floor 0 user (strict limits)
        final resident = Resident(
          userInfoId: UuidValue.fromString(
            '00000000-0000-0000-0000-000000000009',
          ),
          floor: 0,
          creditScore: 100,
          experience: 0,
          totalMessages: 0,
        );
        await Resident.db.insertRow(session, resident);

        final sessionWithAuth = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            resident.userInfoId!.uuid,
            {},
          ),
        );

        // Send multiple messages rapidly
        for (var i = 0; i < 3; i++) {
          await endpoints.message.sendMessage(
            sessionWithAuth,
            channelId: 1,
            content: 'Message $i',
          );
        }

        // Next message should be rate limited (floor 0 = 5 msg/min with 2 sec delay)
        // This test may need adjustment based on actual rate limit implementation
        await Future.delayed(Duration(milliseconds: 100));

        expect(
          () => endpoints.message.sendMessage(
            sessionWithAuth,
            channelId: 1,
            content: 'Too fast',
          ),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
