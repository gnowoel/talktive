import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { Follow, FollowRequest, User } from './types';

if (!admin.app.length) {
  admin.initializeApp();
}

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
      id: followeeId,
      createdAt: now,
      updatedAt: now,
      user: {
        photoURL: followee.photoURL ?? null,
        displayName: followee.displayName ?? null,
        description: followee.description ?? null,
        languageCode: followee.languageCode ?? null,
        gender: followee.gender ?? null
      }
    };

    const newFollower: Follow = {
      id: followerId,
      createdAt: now,
      updatedAt: now,
      user: {
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
