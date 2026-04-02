import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/services/messaging_service.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('MessagingService recall testing', (sessionBuilder, endpoints) {
    late protocol.Resident testUser;
    late protocol.Channel plazaChannel;

    setUp(() async {
      final session = sessionBuilder.build();
      final resident = protocol.Resident(
        userInfoId: UuidValue.fromString(
          'a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d',
        ),
        level: 1,
        trustScore: 100,
        role: protocol.ResidentRole.user,
      );
      testUser = await protocol.Resident.db.insertRow(session, resident);
      final channel = protocol.Channel(
        type: protocol.ChannelType.plaza,
        name: 'Test Plaza',
        createdAt: DateTime.now(),
      );
      plazaChannel = await protocol.Channel.db.insertRow(session, channel);
    });

    test('recallMessage clears message content', () async {
      final session = sessionBuilder.build();
      final message = protocol.Message(
        channelId: plazaChannel.id!,
        senderId: testUser.userInfoId,
        content: 'To be recalled',
        createdAt: DateTime.now(),
        isSystem: false,
        senderName: 'Test User',
        senderFloor: 1,
        senderTrustScore: 100,
      );
      final savedMessage = await protocol.Message.db.insertRow(
        session,
        message,
      );

      final recalledMessage = await MessagingService.recallMessage(
        session,
        messageId: savedMessage.id!,
        resident: testUser,
      );

      expect(recalledMessage.isRecalled, isTrue);
      expect(recalledMessage.content, isNull);
    });
  });
}
