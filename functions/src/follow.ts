import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { Follow, FollowRequest, User, StatParams } from './types';
import { formatDate, isDebugMode } from './helpers';

if (!admin.app.length) {
  admin.initializeApp();
}

const db = admin.database();
const firestore = admin.firestore();

export const follow = onCall<FollowRequest>(async (request) => {
  try {
    const { followerId, followeeId } = request.data;

    if (!followerId || !followeeId) {
      return {
        success: false,
        error: 'Missing required fields'
      }
    }

    if (followerId === followeeId) {
      return {
        success: false,
        error: "You can't follow yourself"
      };
    }

    const followeeDoc = await firestore.collection('users').doc(followeeId).get();
    const followerDoc = await firestore.collection('users').doc(followerId).get();
    if (!followeeDoc.exists || !followerDoc.exists) {
      return {
        success: false,
        error: 'User not found'
      };
    }

    const now = Date.now();
    const followee = followeeDoc.data() as User;
    const follower = followerDoc.data() as User;

    const newFollowee: Follow = {
      createdAt: now,
      updatedAt: now,
      user: {
        createdAt: followee.createdAt,
        updatedAt: followee.updatedAt,
        photoURL: followee.photoURL ?? null,
        displayName: followee.displayName ?? null,
        description: followee.description ?? null,
        languageCode: followee.languageCode ?? null,
        gender: followee.gender ?? null
      }
    };

    const newFollower: Follow = {
      createdAt: now,
      updatedAt: now,
      user: {
        createdAt: follower.createdAt,
        updatedAt: follower.updatedAt,
        photoURL: follower.photoURL ?? null,
        displayName: follower.displayName ?? null,
        description: follower.description ?? null,
        languageCode: follower.languageCode ?? null,
        gender: follower.gender ?? null
      }
    };

    await firestore.runTransaction(async (transaction) => {
      const followeeRef = firestore
        .collection('users')
        .doc(followerId)
        .collection('followees')
        .doc(followeeId);

      const followerRef = firestore
        .collection('users')
        .doc(followeeId)
        .collection('followers')
        .doc(followerId);

      const followeeDoc = await transaction.get(followeeRef);
      if (followeeDoc.exists) {
        throw new Error('Already following this user');
      }

      transaction.set(followeeRef, newFollowee);
      transaction.set(followerRef, newFollower);
    });

    await updateFollowStats();

    return {
      success: true
    };
  } catch (error) {
    logger.error('Error following user:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});

export const unfollow = onCall<FollowRequest>(async (request) => {
  try {
    const { followerId, followeeId } = request.data;

    if (!followerId || !followeeId) {
      return {
        success: false,
        error: 'Missing required fields'
      };
    }

    await firestore.runTransaction(async (transaction) => {
      const followeeRef = firestore
        .collection('users')
        .doc(followerId)
        .collection('followees')
        .doc(followeeId);

      const followerRef = firestore
        .collection('users')
        .doc(followeeId)
        .collection('followers')
        .doc(followerId);

      transaction.delete(followeeRef);
      transaction.delete(followerRef);
    });

    await updateUnfollowStats();

    return {
      success: true
    };
  } catch (error) {
    logger.error('Error unfollowing user:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});

const updateFollowStats = async () => {
  await updateFriendStats('follows');
}

const updateUnfollowStats = async () => {
  await updateFriendStats('unfollows');
}

const updateFriendStats = async (type: string) => {
  if (type !== 'follows' && type !== 'unfollows') {
    return;
  }

  const now = new Date();
  const statRef = db.ref(`stats/${formatDate(now)}`);
  const params: StatParams = {};

  // `ServerValue` doesn't work with Emulators Suite
  if (isDebugMode()) {
    const snapshot = await statRef.get();
    if (!snapshot.exists()) return;
    const stat = snapshot.val();
    params[type] = (stat[type] ?? 0) + 1;
  } else {
    params[type] = admin.database.ServerValue.increment(1);
  }

  try {
    await statRef.update(params);
  } catch (error) {
    logger.error(error);
  }
}
