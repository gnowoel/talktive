import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { Topic } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

export const joinTopic = onCall(async (request) => {
  try {
    const { userId, topicId } = request.data;

    if (!userId || !topicId) {
      return {
        success: false,
        error: 'Missing required fields'
      };
    }

    // Check if user exists
    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return {
        success: false,
        error: 'User not found'
      };
    }

    // Check if topic exists
    const topicRef = firestore.collection('topics').doc(topicId);
    const topicDoc = await topicRef.get();
    if (!topicDoc.exists) {
      return {
        success: false,
        error: 'Topic not found'
      };
    }

    // Access data after checking for existence and assert its type
    const topicData = topicDoc.data() as Topic;

    // Check if the user is already following this topic
    const followerRef = topicRef.collection('followers').doc(userId);
    const followerDoc = await followerRef.get();

    if (followerDoc.exists) {
      // User is already following this topic - just return success
      return {
        success: true,
        topicId
      };
    }

    // Use a batch write for atomic operations
    const batch = firestore.batch();

    // Add user to topic's followers collection
    batch.set(followerRef, {
      muted: false,
    });

    // Add topic to user's topics collection
    const userTopicRef = firestore
      .collection('users')
      .doc(userId)
      .collection('topics')
      .doc(topicId);

    batch.set(userTopicRef, {
      title: topicData.title,
      creator: topicData.creator,
      createdAt: topicData.createdAt,
      updatedAt: topicData.updatedAt,
      messageCount: topicData.messageCount,
      readMessageCount: 0, // New follower hasn't read any messages yet
      lastMessageContent: topicData.lastMessageContent, // It's actually the firstMessageContent
      mute: false,
    });

    // Commit all operations
    await batch.commit();

    return {
      success: true,
      topicId
    };
  } catch (error) {
    logger.error('Error joining topics:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});
