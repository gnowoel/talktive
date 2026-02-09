import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'apartment_service.dart';

class ChatService {
  /// Initiates a private chat between two residents.
  /// Checks floor rules and block status.
  static Future<Channel?> createPrivateChat(
    Session session, {
    required UuidValue senderId,
    required UuidValue receiverId,
  }) async {
    // 1. Fetch Residents details
    final sender = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(senderId),
    );
    final receiver = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(receiverId),
    );

    if (sender == null || receiver == null) {
      throw Exception('Resident not found');
    }

    // 2. Check Apartment Rules (Floor logic)
    if (!ApartmentService.canInvite(sender: sender, receiver: receiver)) {
      throw Exception('You cannot invite this user (Floor rules).');
    }

    // 3. Check Block Status
    final isBlocked = await Block.db.findFirstRow(
      session,
      where: (t) =>
          t.blockerId.equals(receiverId) & t.blockedId.equals(senderId),
    );
    if (isBlocked != null) {
      throw Exception('You are blocked by this user.');
    }

    // Check if sender blocked receiver? (Usually prevents interaction too)
    final hasBlocked = await Block.db.findFirstRow(
      session,
      where: (t) =>
          t.blockerId.equals(senderId) & t.blockedId.equals(receiverId),
    );
    if (hasBlocked != null) {
      throw Exception('You have blocked this user.');
    }

    // 4. Create Channel
    // Simplified: Create new channel
    final channel = Channel(
      type: ChannelType.private,
      createdAt: DateTime.now(),
      name: null, // Private 1on1 often has no name
    );
    final validChannel = await Channel.db.insertRow(session, channel);

    // 5. Add Members
    await ChannelMember.db.insertRow(
      session,
      ChannelMember(
        channelId: validChannel.id!,
        userInfoId: senderId,
        joinedAt: DateTime.now(),
        status: ChannelMemberStatus.joined, // Sender joins immediately
        role: 'owner',
      ),
    );

    await ChannelMember.db.insertRow(
      session,
      ChannelMember(
        channelId: validChannel.id!,
        userInfoId: receiverId,
        joinedAt: DateTime.now(),
        status: ChannelMemberStatus.invited, // Receiver is invited
        role: 'member',
      ),
    );

    return validChannel;
  }

  static Future<void> blockUser(
    Session session,
    UuidValue blockerId,
    UuidValue blockedId,
  ) async {
    await Block.db.insertRow(
      session,
      Block(
        blockerId: blockerId,
        blockedId: blockedId,
        createdAt: DateTime.now(),
      ),
    );
  }
}
