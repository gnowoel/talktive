import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart';
import '../generated/protocol.dart';

class MomentEndpoint extends Endpoint {
  /// Posts a new moment to the feed.
  Future<Moment> postMoment(
    Session session, {
    required String imageUrl,
    String caption = '',
  }) async {
    final authenticationInfo = session.authenticated;
    final senderIdentifier = authenticationInfo?.userIdentifier;

    if (senderIdentifier == null) {
      throw Exception('Not authenticated');
    }

    final senderUuid = UuidValue.fromString(senderIdentifier);

    // 1. Fetch Resident (for ID and Floor)
    final resident = await Resident.db.findFirstRow(
      session,
      where: (t) => t.userInfoId.equals(senderUuid),
    );

    if (resident == null) {
      throw Exception('Resident not found');
    }

    // 2. Fetch User Profile
    // 2. Fetch User Profile
    final userProfile = await AuthServices.instance.userProfiles
        .findUserProfileByUserId(
          session,
          senderUuid,
        );

    // 3. Create Moment
    final moment = Moment(
      authorId: resident.id!,
      imageUrl: imageUrl,
      caption: caption,
      createdAt: DateTime.now(),
      likesCount: 0,
      commentsCount: 0,
      authorName: userProfile.userName ?? 'Anonymous',
      authorAvatar: userProfile.imageUrl?.toString() ?? '',
      authorFloor: resident.floor,
    );

    return await Moment.db.insertRow(session, moment);
  }

  /// Lists the latest moments.
  Future<List<Moment>> listMoments(
    Session session, {
    int limit = 20,
    int? lastId,
  }) async {
    return await Moment.db.find(
      session,
      limit: limit,
      orderBy: (t) => t.id,
      orderDescending: true,
      where: lastId != null ? (t) => t.id < lastId : null,
    );
  }
}
