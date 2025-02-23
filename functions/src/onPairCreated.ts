import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueCreated } from 'firebase-functions/v2/database';
import { Pair, User, StatParams } from './types';
import { formatDate, isDebugMode } from './helpers';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

interface Mapper {
  [id:string]: User;
}

const onPairCreated = onValueCreated('/pairs/{pairId}', async (event) => {
  const pairId = event.params.pairId;
  const pair = event.data.val();
  const followers = pair.followers;
  const now = new Date();

  try {
    await copyToFollowers(followers, pairId, pair);
    updateChatStats(now);
  } catch (error) {
    logger.error(error);
  }
});

const copyToFollowers = async (followers: [string], pairId: string, pair: Pair) => {
  try {
    const mapper: Mapper = {};

    for (const follower of followers) {
      const userRef = db.ref(`users/${follower}`);
      const snapshot = await userRef.get();
      mapper[follower] = snapshot.val();
    }

    for (const follower of followers) {
      // copyToFollower(follower, user, pairId, pair);
      const otherId = pairId.replace(follower, '');
      const other: User = mapper[otherId];
      const partner = {
        createdAt: other.createdAt, // For checking `newcomer` status
        updatedAt: 0,
        languageCode: other.languageCode ?? null,
        photoURL: other.photoURL ?? null,
        displayName: other.displayName ?? null,
        description: other.description ?? null,
        gender: other.gender ?? null,
        revivedAt: other.revivedAt ?? null,
        messageCount: other.messageCount ?? null,
        // fcmToken: ''
      };

      const userRef = db.ref(`chats/${follower}/${pairId}`);
      const now = new Date().getTime();
      const twoWeeks = 14 * 24 * 60 * 60 * 1000;
      const mute = (other.revivedAt ?? 0) >= now + twoWeeks;

      await userRef.set({
        partner: partner,
        firstUserId: null,
        lastMessageContent: null,
        messageCount: pair.messageCount, // 0
        readMessageCount: pair.messageCount, // 0
        mute,
        createdAt: pair.createdAt,
        updatedAt: pair.updatedAt,
      });
    }

  } catch (error) {
    logger.error(error);
  }
}

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
