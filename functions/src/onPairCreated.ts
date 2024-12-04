import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueCreated } from 'firebase-functions/v2/database';
import { Pair, User, StatParams } from './types';
import { formatDate, isDebugMode } from './helpers';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onPairCreated = onValueCreated('/pairs/{pairId}', async (event) => {
  const pairId = event.params.pairId;
  const pair = event.data.val();
  const followers = pair.followers;
  const now = new Date();

  try {
    for (const follower of followers) {
      await copyToFollower(follower, pairId, pair);
    }
    updateChatStats(now);
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

    const ref = db.ref(`chats/${userId}/${pairId}`);
    await ref.set({
      partner: other,
      firstUserId: null,
      lastMessageContent: null,
      messageCount: pair.messageCount, // 0
      readMessageCount: pair.messageCount, // 0
      mute: false,
      createdAt: pair.createdAt,
      updatedAt: pair.updatedAt,
    });
  } catch (error) {
    logger.error(error);
  }
};

const updateChatStats = async (now: Date) => {
  const statRef = db.ref(`stats/${formatDate(now)}`);
  const snapshot = await statRef.get();

  if (!snapshot.exists()) return;

  const stat = snapshot.val();
  const params: StatParams = {};

  // `ServerValue` doesn't work with Emulators Suite
  if (isDebugMode()) {
    params.chats = stat.chats + 1;
  } else {
    params.chats = admin.database.ServerValue.increment(1);
  }

  try {
    await statRef.update(params);
  } catch (error) {
    logger.error(error);
  }
};

export default onPairCreated;
