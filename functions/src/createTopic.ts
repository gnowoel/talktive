import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { User } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

export const createTopic = onCall(async (request) => {
  try {
    const { userId, title, message } = request.data;

    if (!userId || !title || !message) {
      return {
        success: false,
        error: 'Missing required fields'
      }
    }

    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return {
        success: false,
        error: 'User not found'
      };
    }

    const now = Date.now();
    const user = userDoc.data() as User;
    const creator = {
      id: userId,
      createdAt: 0,
      updatedAt: 0,
      photoURL: user.photoURL,
      displayName: user.displayName,
      languageCode: user.languageCode,
      gender: user.gender,
      revivedAt: user.revivedAt,
      messageCount: user.messageCount,
    };

    const topicRef = await firestore.collection('topics').add({
      title,
      creator,
      createdAt: now,
      updatedAt: now,
      messageCount: 1, // Copy to downstream
      lastMessageContent: message, // Copy to downstream
    });

    const topicId = topicRef.id;

    // Use a batch write for atomic operations
    const batch = firestore.batch();

    // Add first message
    const messageRef = firestore
      .collection('topics')
      .doc(topicId)
      .collection('messages')
      .doc();

    batch.set(messageRef, {
      type: 'text',
      userId,
      userDisplayName: user.displayName ?? '',
      userPhotoURL: user.photoURL ?? '',
      content: message,
      createdAt: now,
    });

    // Add creator to followers collection
    const followerRef = firestore
      .collection('topics')
      .doc(topicId)
      .collection('followers')
      .doc(userId)

    batch.set(followerRef, {
      muted: false,
    });

    // Add topic reference to user's topics collection
    const userTopicRef = firestore
      .collection('users')
      .doc(userId)
      .collection('topics')
      .doc(topicId);

    batch.set(userTopicRef, {
      title,
      creator,
      createdAt: now,
      updatedAt: now,
      messageCount: 1, // Copy from upstream
      readMessageCount: 1, // Creator has read their own message
      lastMessageContent: message, // Copy from upstream
      mute: false,
    });

    // Commit all operations
    await batch.commit();

    return {
      success: true,
      topicId,
      topicCreatedAt: now.toString(), // TODO: We don't actually need it for topics
    };
  } catch (error) {
    logger.error('Error creating topic:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});
