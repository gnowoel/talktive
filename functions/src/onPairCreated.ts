import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueCreated } from 'firebase-functions/v2/database';
import { Pair, User } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onPairCreated = onValueCreated('/pairs/{pairId}', async (event) => {
  const pairId = event.params.pairId;
  const pair = event.data.val();
  const followers = pair.followers;

  try {
    for (const follower of followers) {
      await copyToFollower(follower, pairId, pair);
    }
  } catch (error) {
    logger.error(error);
  }
});

const copyToFollower = async (userId: string, pairId: string, pair: Pair) => {
  try {
    const otherId = pairId.replace(userId, '');

    const userRef = db.ref(`users/${otherId}`);
    const snapshot = await userRef.get();
    const other: User = snapshot.val();

    const ref = db.ref(`chats/${userId}/pairs/${pairId}`);
    await ref.set({
      partner: other,
      firstUserId: null,
      lastMessageContent: null,
      messageCount: pair.messageCount,
      createdAt: pair.createdAt,
      updatedAt: pair.updatedAt,
    });
  } catch (error) {
    logger.error(error);
  }
};

export default onPairCreated;
