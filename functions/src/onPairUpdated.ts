import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueUpdated } from 'firebase-functions/v2/database';
import { Pair } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onPairUpdated = onValueUpdated('/pairs/{pairId}', async (event) => {
  const pairId = event.params.pairId;
  const pair = event.data.after.val();
  const followers = pair.followers;

  try {
    for (const follower of followers) {
      await updateFollower(follower, pairId, pair);
    }
  } catch (error) {
    logger.error(error);
  }
});

const updateFollower = async (userId: string, pairId: string, pair: Pair) => {
  try {
    const ref = db.ref(`chats/${userId}/${pairId}`);
    await ref.update({
      updatedAt: pair.updatedAt,
      messageCount: pair.messageCount,
      // Quick fix of the `undefined` error that might be caused by older versions of the app
      firstUserId: pair.firstUserId ?? null,
      lastMessageContent: pair.lastMessageContent,
    });
  } catch (error) {
    logger.error(error);
  }
};

export default onPairUpdated;
