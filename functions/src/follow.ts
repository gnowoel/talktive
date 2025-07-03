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



      // ALL READS FIRST
      const followeeDoc = await transaction.get(followeeRef);
      if (followeeDoc.exists) {
        // Already following this user - return success (idempotent)
        return;
      }

      // ALL WRITES SECOND
      transaction.set(followeeRef, newFollowee);
      transaction.set(followerRef, newFollower);
    });

    // Update user counts in Realtime Database
    await updateUserFollowCounts(followerId, followeeId, 'follow');

    await updateFollowStats();

    return {
      success: true
    };
  } catch (error) {
    logger.error('Error following user:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to follow user'
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



      // ALL READS FIRST
      // Check if the relationship exists before attempting to delete
      const followeeDoc = await transaction.get(followeeRef);
      if (!followeeDoc.exists) {
        // Not following this user - return success (idempotent)
        return;
      }

      // ALL WRITES SECOND
      transaction.delete(followeeRef);
      transaction.delete(followerRef);
    });

    // Update user counts in Realtime Database
    await updateUserFollowCounts(followerId, followeeId, 'unfollow');

    await updateUnfollowStats();

    return {
      success: true
    };
  } catch (error) {
    logger.error('Error unfollowing user:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Failed to unfollow user'
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

const updateUserFollowCounts = async (followerId: string, followeeId: string, action: 'follow' | 'unfollow') => {
  try {
    const followerRef = db.ref(`users/${followerId}`);
    const followeeRef = db.ref(`users/${followeeId}`);

    // Get current user data to check if counts need initialization
    const [followerSnapshot, followeeSnapshot] = await Promise.all([
      followerRef.once('value'),
      followeeRef.once('value')
    ]);

    const followerData = followerSnapshot.val();
    const followeeData = followeeSnapshot.val();

    if (!followerData || !followeeData) {
      logger.error('User data not found for follow count update');
      return;
    }

    const updates: { [key: string]: number } = {};

    // Handle followeeCount for the follower
    if (followerData.followeeCount == null) {
      // Initialize followeeCount by counting existing followees
      const followeesSnapshot = await firestore
        .collection('users')
        .doc(followerId)
        .collection('followees')
        .count()
        .get();
      const currentCount = followeesSnapshot.data().count;
      updates[`users/${followerId}/followeeCount`] = action === 'follow' ? currentCount : Math.max(0, currentCount - 1);
    } else {
      // Increment/decrement existing count
      const currentCount = followerData.followeeCount || 0;
      updates[`users/${followerId}/followeeCount`] = action === 'follow' ? currentCount + 1 : Math.max(0, currentCount - 1);
    }

    // Handle followerCount for the followee
    if (followeeData.followerCount == null) {
      // Initialize followerCount by counting existing followers
      const followersSnapshot = await firestore
        .collection('users')
        .doc(followeeId)
        .collection('followers')
        .count()
        .get();
      const currentCount = followersSnapshot.data().count;
      updates[`users/${followeeId}/followerCount`] = action === 'follow' ? currentCount : Math.max(0, currentCount - 1);
    } else {
      // Increment/decrement existing count
      const currentCount = followeeData.followerCount || 0;
      updates[`users/${followeeId}/followerCount`] = action === 'follow' ? currentCount + 1 : Math.max(0, currentCount - 1);
    }

    // Apply all updates atomically
    await db.ref().update(updates);
  } catch (error) {
    logger.error('Error updating user follow counts:', error);
  }
}
