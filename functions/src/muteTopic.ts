import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

export const muteTopic = onCall(async (request) => {
  try {
    const { userId, topicId } = request.data;

    if (!userId || !topicId) {
      return {
        success: false,
        error: 'Missing required fields'
      };
    }

    const batch = firestore.batch();

    const userTopicRef = firestore
      .collection('users')
      .doc(userId)
      .collection('topics')
      .doc(topicId);

    batch.update(userTopicRef, {
      mute: true
    });

    const topicFollowerRef = firestore
      .collection('topics')
      .doc(topicId)
      .collection('followers')
      .doc(userId);

    batch.update(topicFollowerRef, {
      muted: true
    });

    await batch.commit();

    return {
      success: true
    };
  } catch (error) {
    logger.error('Error muting topic:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});
