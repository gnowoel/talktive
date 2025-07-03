import * as admin from 'firebase-admin';
import { FieldValue } from 'firebase-admin/firestore';
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

      const followerUserRef = firestore
        .collection('users')
        .doc(followerId);

      const followeeUserRef = firestore
        .collection('users')
        .doc(followeeId);

      // ALL READS FIRST
      const followeeDoc = await transaction.get(followeeRef);
      if (followeeDoc.exists) {
        // Already following this user - return success (idempotent)
        return;
      }

      const followerUserDoc = await transaction.get(followerUserRef);
      const followeeUserDoc = await transaction.get(followeeUserRef);

      const followerData = followerUserDoc.data();
      const followeeData = followeeUserDoc.data();

      // Get counts if needed for initialization (outside transaction)
      let followeeCount = 0;
      let followerCount = 0;

      if (followerData && followerData.followeeCount == null) {
        const followeesSnapshot = await firestore
          .collection('users')
          .doc(followerId)
          .collection('followees')
          .count()
          .get();
        followeeCount = followeesSnapshot.data().count;
      }

      if (followeeData && followeeData.followerCount == null) {
        const followersSnapshot = await firestore
          .collection('users')
          .doc(followeeId)
          .collection('followers')
          .count()
          .get();
        followerCount = followersSnapshot.data().count;
      }

      // ALL WRITES SECOND
      transaction.set(followeeRef, newFollowee);
      transaction.set(followerRef, newFollower);

      // Handle followeeCount for the follower
      if (followerData && followerData.followeeCount == null) {
        transaction.update(followerUserRef, {
          followeeCount: followeeCount
        });
      } else {
        transaction.update(followerUserRef, {
          followeeCount: FieldValue.increment(1)
        });
      }

      // Handle followerCount for the followee
      if (followeeData && followeeData.followerCount == null) {
        transaction.update(followeeUserRef, {
          followerCount: followerCount
        });
      } else {
        transaction.update(followeeUserRef, {
          followerCount: FieldValue.increment(1)
        });
      }
    });

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

      const followerUserRef = firestore
        .collection('users')
        .doc(followerId);

      const followeeUserRef = firestore
        .collection('users')
        .doc(followeeId);

      // ALL READS FIRST
      // Check if the relationship exists before attempting to delete
      const followeeDoc = await transaction.get(followeeRef);
      if (!followeeDoc.exists) {
        // Not following this user - return success (idempotent)
        return;
      }

      const followerUserDoc = await transaction.get(followerUserRef);
      const followeeUserDoc = await transaction.get(followeeUserRef);

      const followerData = followerUserDoc.data();
      const followeeData = followeeUserDoc.data();

      // Get counts if needed for initialization (outside transaction)
      let followeeCount = 0;
      let followerCount = 0;

      if (followerData && followerData.followeeCount == null) {
        const followeesSnapshot = await firestore
          .collection('users')
          .doc(followerId)
          .collection('followees')
          .count()
          .get();
        followeeCount = Math.max(0, followeesSnapshot.data().count - 1); // Subtract 1 for the deletion
      }

      if (followeeData && followeeData.followerCount == null) {
        const followersSnapshot = await firestore
          .collection('users')
          .doc(followeeId)
          .collection('followers')
          .count()
          .get();
        followerCount = Math.max(0, followersSnapshot.data().count - 1); // Subtract 1 for the deletion
      }

      // ALL WRITES SECOND
      transaction.delete(followeeRef);
      transaction.delete(followerRef);

      // Handle followeeCount for the follower
      if (followerData && followerData.followeeCount == null) {
        transaction.update(followerUserRef, {
          followeeCount: followeeCount
        });
      } else {
        transaction.update(followerUserRef, {
          followeeCount: FieldValue.increment(-1)
        });
      }

      // Handle followerCount for the followee
      if (followeeData && followeeData.followerCount == null) {
        transaction.update(followeeUserRef, {
          followerCount: followerCount
        });
      } else {
        transaction.update(followeeUserRef, {
          followerCount: FieldValue.increment(-1)
        });
      }
    });

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
