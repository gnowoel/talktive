import * as admin from 'firebase-admin';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { formatDate, isDebugMode } from './helpers';
import { StatParams, UserParams } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();
const firestore = admin.firestore();

interface TopicMessage {
  type: 'text' | 'image';
  userId: string;
  userDisplayName: string;
  userPhotoURL: string;
  content: string;
  createdAt: Timestamp;
}

interface MessagingError extends Error {
  code: string;
  message: string;
}


function isMessagingError(error: unknown): error is MessagingError {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    typeof (error as MessagingError).code === 'string'
  );
}

export const onTopicMessageCreated = onDocumentCreated(
  'topics/{topicId}/messages/{messageId}',
  async (event) => {
    const message = event.data?.data() as TopicMessage;
    const topicId = event.params.topicId;
    // const messageId = event.params.messageId;
    const now = Timestamp.now();

    try {
      // Start a batch write
      const batch = firestore.batch();

      // Update global topic metadata
      const topicRef = firestore.collection('topics').doc(topicId);
      batch.update(topicRef, {
        updatedAt: now,
        messageCount: FieldValue.increment(1),
        // Always show the first messages in the Topics tab
        // lastMessageContent: message.content,
      });

      // Get topic data to find followers
      const topicDoc = await topicRef.get();
      if (!topicDoc.exists) {
        logger.error(`Topic ${topicId} not found`);
        return;
      }

      const topic = topicDoc.data();

      // Get all followers
      const followersSnapshot = await topicRef
        .collection('followers')
        .where('muted', '==', false)
        .get();

      // A list of promises for sending notifications
      const notificationPromises = [];

      // Update each follower's personal topic copy
      followersSnapshot.docs.forEach((doc) => {
        const followerId = doc.id;

        // Don't send notification to message author
        const shouldNotify = followerId !== message.userId;

        const userTopicRef = firestore
          .collection('users')
          .doc(followerId)
          .collection('topics')
          .doc(topicId);

        batch.update(userTopicRef, {
          updatedAt: now,
          messageCount: FieldValue.increment(1),
          lastMessageContent: message.content,
        });

        // Add notification task for this follower
        if (shouldNotify) {
          notificationPromises.push(
            sendPushNotification(
              followerId,
              topicId,
              topic?.title ?? '',
              topic?.creator?.id ?? '',
              message,
              // messageId
            )
          );
        }
      });

      await batch.commit();

      await updateUserUpdatedAtAndMessageCount(message.userId, message.createdAt);
      await updateTopicMessagesStats();
    } catch (error) {
      logger.error('Error in onTopicMessageCreated:', error);
    }
  }
);

const getUserFcmToken = async (userId: string) => {
  try {
    const tokenRef = db.ref(`users/${userId}/fcmToken`);
    const snapshot = await tokenRef.get();

    if (!snapshot.exists()) return null;

    const token = snapshot.val();

    return token;
  } catch (error) {
    logger.error(error);
  }
};

/**
 * Send push notification to a user about a new topic message
 */
async function sendPushNotification(
  userId: string,
  topicId: string,
  topicTitle: string,
  topicCreatorId: string,
  message: TopicMessage,
  // messageId: string
): Promise<void> {
  try {
    // Get user's FCM token
    const userDoc = await firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      logger.warn(`User ${userId} not found for notification`);
      return;
    }

    const fcmToken = await getUserFcmToken(userId);

    if (!fcmToken) {
      // User doesn't have a token, skip notification
      return;
    }

    // Construct the notification
    const title = `${message.userDisplayName} in "${topicTitle}"`;
    const body = message.content;

    const pushMessage: admin.messaging.Message = {
      token: fcmToken,
      notification: {},
      data: {
        type: 'topic',
        title,
        body,
        topicId,
        topicCreatorId,
        // messageId,
        // senderId: message.userId,
        // senderName: message.userDisplayName,
        // createdAt: message.createdAt.toMillis().toString()
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'topic_messages'
        }
      },
      // apns: {
      //   payload: {
      //     aps: {
      //       contentAvailable: true
      //     }
      //   }
      // }
    };

    // Send the notification
    await admin.messaging().send(pushMessage);

  } catch (error) {
    if (isMessagingError(error)) {
      // Check if the error is due to an invalid token
      if (
        error.code === 'messaging/registration-token-not-registered' ||
        error.code === 'messaging/invalid-argument' ||
        error.code === 'messaging/invalid-registration-token'
      ) {
        // Remove the invalid token from the database
        await db.ref(`users/${userId}/fcmToken`).remove();
        logger.info(`Removed invalid FCM token for user ${userId}`);
      }
    }

    // Log but don't rethrow as it's not critical
    logger.warn('Push notification failed:', error);
  }
}

const updateUserUpdatedAtAndMessageCount = async (userId: string, now: Timestamp) => {
  const userRef = db.ref(`users/${userId}`);
  const snapshot = await userRef.get();

  if (!snapshot.exists()) return;

  const user = snapshot.val();
  const params: UserParams = {};

  params.updatedAt = now.toMillis();

  if (isDebugMode()) {
    params.messageCount = (user.messageCount ?? 0) + 1;
  } else {
    params.messageCount = admin.database.ServerValue.increment(1);
  }

  try {
    await userRef.update(params);
  } catch (error) {
    logger.error(error);
  }
};

const updateTopicMessagesStats = async () => {
  const now = new Date();
  const statRef = db.ref(`stats/${formatDate(now)}`);
  const snapshot = await statRef.get();

  if (!snapshot.exists()) return;

  const stat = snapshot.val();
  const params: StatParams = {};

  if (isDebugMode()) {
    params.topicMessages = (stat.topicMessages ?? 0) + 1;
  } else {
    params.topicMessages = admin.database.ServerValue.increment(1);
  }

  try {
    await statRef.update(params);
  } catch (error) {
    logger.error(error);
  }
};
