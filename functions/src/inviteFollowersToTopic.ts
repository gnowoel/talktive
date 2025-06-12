import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

export const inviteFollowersToTopic = onCall(async (request) => {
  try {
    const { userId, topicId } = request.data;

    if (!userId || !topicId) {
      return {
        success: false,
        error: 'Missing required fields'
      };
    }

    // Verify user exists
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return {
        success: false,
        error: 'User not found'
      };
    }

    // Verify topic exists
    const topicDoc = await firestore.collection('topics').doc(topicId).get();
    if (!topicDoc.exists) {
      return {
        success: false,
        error: 'Topic not found'
      };
    }

    // Verify user is a participant (has sent at least one message)
    const messagesSnapshot = await firestore
      .collection('topics')
      .doc(topicId)
      .collection('messages')
      .where('userId', '==', userId)
      .limit(1)
      .get();

    if (messagesSnapshot.empty) {
      return {
        success: false,
        error: 'User is not a participant in this topic'
      };
    }

    // Get the user's followers first to avoid unnecessary work
    const followersSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('followers')
      .get();

    if (followersSnapshot.empty) {
      return {
        success: true,
        invitedCount: 0,
        message: 'No followers to invite'
      };
    }

    // Get topic data
    const topicData = topicDoc.data();
    const now = Timestamp.now();

    // Get existing topic followers to avoid duplicates
    const existingFollowersSnapshot = await firestore
      .collection('topics')
      .doc(topicId)
      .collection('followers')
      .get();

    const existingFollowerIds = new Set(
      existingFollowersSnapshot.docs.map(doc => doc.id)
    );

    // Filter out followers who are already following the topic
    const newFollowerIds = followersSnapshot.docs
      .map(doc => doc.id)
      .filter(followerId => !existingFollowerIds.has(followerId));

    if (newFollowerIds.length === 0) {
      return {
        success: true,
        invitedCount: 0,
        message: 'All followers are already following this topic'
      };
    }

    // Use batch operations for atomic writes
    const batch = firestore.batch();

    for (const followerId of newFollowerIds) {
      // Add follower to topic's followers collection
      const topicFollowerRef = firestore
        .collection('topics')
        .doc(topicId)
        .collection('followers')
        .doc(followerId);

      batch.set(topicFollowerRef, {
        muted: false,
      });

      // Add topic to follower's topics collection
      const followerTopicRef = firestore
        .collection('users')
        .doc(followerId)
        .collection('topics')
        .doc(topicId);

      batch.set(followerTopicRef, {
        title: topicData?.title || '',
        creator: topicData?.creator || {},
        createdAt: topicData?.createdAt || now,
        updatedAt: topicData?.updatedAt || now,
        messageCount: topicData?.messageCount || 0,
        readMessageCount: 0, // New follower hasn't read any messages yet
        lastMessageContent: topicData?.lastMessageContent || '',
        mute: false,
        tribeId: topicData?.tribeId || null,
        isPublic: topicData?.isPublic ?? true,
      });
    }

    // Commit all operations
    await batch.commit();

    return {
      success: true,
      invitedCount: newFollowerIds.length,
      message: `Successfully invited ${newFollowerIds.length} followers`
    };

  } catch (error) {
    logger.error('Error inviting followers to topic:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});