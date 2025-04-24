import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

interface TopicMessage {
  type: 'text' | 'image';
  userId: string;
  userDisplayName: string;
  userPhotoURL: string;
  content: string;
  createdAt: Timestamp;
}

export const onTopicMessageCreated = onDocumentCreated(
  'topics/{topicId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data() as TopicMessage;
    const topicId = event.params.topicId;
    const now = Timestamp.now();

    try {
      // Start a batch write
      const batch = firestore.batch();

      // Update global topic metadata
      const topicRef = firestore.collection('topics').doc(topicId);
      batch.update(topicRef, {
        updatedAt: now,
        messageCount: admin.firestore.FieldValue.increment(1),
        lastMessageContent: message.content,
      });

      // Get topic data to find followers
      const topicDoc = await topicRef.get();
      if (!topicDoc.exists) {
        logger.error(`Topic ${topicId} not found`);
        return;
      }

      // const topic = topicDoc.data()!;

      // Get all followers
      const followersSnapshot = await topicRef
        .collection('followers')
        .where('muted', '==', false)
        .get();

      // Update each follower's personal topic copy
      followersSnapshot.docs.forEach((doc) => {
        const userTopicRef = firestore
          .collection('users')
          .doc(doc.id)
          .collection('topics')
          .doc(topicId);

        batch.update(userTopicRef, {
          updatedAt: now,
          messageCount: admin.firestore.FieldValue.increment(1),
          lastMessageContent: message.content,
        });
      });

      // TODO: Send push notifications to followers

      await batch.commit();
    } catch (error) {
      logger.error('Error in onTopicMessageCreated:', error);
    }
  }
);
