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

    const user = userDoc.data() as User;
    const now = Date.now();

    const topicRef = await firestore.collection('topics').add({
      title,
      createdAt: now,
      updatedAt: now,
      user: {
        id: userId,
        createdAt: 0,
        updatedAt: 0,
        photoURL: user.photoURL,
        displayName: user.displayName,
        languageCode: user.languageCode,
        gender: user.gender,
      },
      messageCount: 1,
    });

    await firestore.collection('topics').doc(topicRef.id)
      .collection('messages').add({
        type: 'text',
        userId,
        userDisplayName: user.displayName ?? '',
        userPhotoURL: user.photoURL ?? '',
        content: message,
        createdAt: now,
      });

    return {
      success: true,
      topicId: topicRef.id,
    };
  } catch (error) {
    logger.error('Error creating topic:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});
