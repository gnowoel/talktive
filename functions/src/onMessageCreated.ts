import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueCreated } from 'firebase-functions/v2/database';
import { formatDate, isDebugMode } from './helpers';
import { Chat, Message, UserParams, PairParams, StatParams } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

interface MessagingError extends Error {
  code: string;
  message: string;
}

const db = admin.database();

const timeBeforeClosing = isDebugMode() ?
  1000 * 60 * 6 : // 6 minutes
  1000 * 60 * 60 * 24 * 3; // 3 days

function isMessagingError(error: unknown): error is MessagingError {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    typeof (error as MessagingError).code === 'string'
  );
}

const onMessageCreated = onValueCreated('/messages/{listId}/*', async (event) => {
  const now = new Date();
  const listId = event.params.listId;
  const message = event.data.val();
  const userId = message.userId;
  const pairId = listId;

  try {
    await updateUserUpdatedAtAndMessageCount(userId, now);
    await updatePair(pairId, message, now);
    await sendPushNotification(userId, pairId, message);
    await updateMessageOrResponseStats(now);
  } catch (error) {
    logger.error(error);
  }
});

const updateUserUpdatedAtAndMessageCount = async (userId: string, now: Date) => {
  const userRef = db.ref(`users/${userId}`);
  const snapshot = await userRef.get();

  if (!snapshot.exists()) return;

  const user = snapshot.val();
  const params: UserParams = {};

  params.updatedAt = now.valueOf();

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

// TODO: Consider updating the `partner` field
const updatePair = async (pairId: string, message: Message, now: Date) => {
  const ref = db.ref(`pairs/${pairId}`);
  const snapshot = await ref.get();

  if (!snapshot.exists()) return;

  const pair = snapshot.val();
  const params: PairParams = {};

  params.updatedAt = now.valueOf();
  params.lastMessageContent = message.content;

  if (!pair.firstUserId) {
    params.firstUserId = message.userId;
  }

  if (isDebugMode()) {
    params.messageCount = pair.messageCount + 1;
  } else {
    params.messageCount = admin.database.ServerValue.increment(1);
  }

  try {
    await ref.update(params);
  } catch (error) {
    logger.error(error);
  }
};

const sendPushNotification = async (userId: string, pairId: string, message: Message) => {
  try {
    const otherId = pairId.replace(userId, '');
    const chatId = pairId;

    const chat: Chat = await getChat(otherId, chatId);
    if (!chat) return;
    const isActive = isChatActive(chat);
    if (!isActive) return;

    const token = await getUserFcmToken(otherId);
    if (!token) return;

    const title = `${message.userPhotoURL} ${message.userDisplayName}`;
    const body = message.content;
    const chatCreatedAt = chat.createdAt.toString();

    const pushMessage: admin.messaging.Message = {
      token,
      notification: {},
      data: {
        type: 'chat',
        title, body, chatId, chatCreatedAt,
        partnerDisplayName: '' // TODO: Remove later
      },
      android: {
        priority: 'high'
      }
    };


    try {
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
          await db.ref(`users/${otherId}/fcmToken`).remove();
          logger.info(`Removed invalid FCM token for user ${otherId}`);
        }
      }
      // Don't rethrow the error as it's not critical
      logger.warn('Push notification failed:', error);
    }
  } catch (error) {
    // Log other errors that might occur during the process
    logger.error('Error in sendPushNotification:', error);
  }
};

const getChat = async (userId: string, chatId: string) => {
  try {
    const chatRef = db.ref(`chats/${userId}/${chatId}`);
    const snapshot = await chatRef.get();

    if (!snapshot.exists()) return null;

    const chat = snapshot.val();

    return chat;
  } catch (error) {
    logger.error(error);
  }
};

const isChatActive = (chat: Chat) => {
  // return !isChatNew(chat) && !isChatClosed(chat) && !isChatMuted(chat);
  return !isChatClosed(chat) && !isChatMuted(chat);
};

// TODO: New chat should also be notified. It should be deleted after a certain time.
// const isChatNew = (chat: Chat) => {
//   return !chat.firstUserId;
// };

const isChatClosed = (chat: Chat) => {
  const now = new Date().getTime();
  return chat.updatedAt + timeBeforeClosing <= now;
};

const isChatMuted = (chat: Chat) => {
  return !!chat.mute;
};

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

const updateMessageOrResponseStats = async (now: Date) => {
  const statRef = db.ref(`stats/${formatDate(now)}`);
  const snapshot = await statRef.get();

  if (!snapshot.exists()) return;

  const stat = snapshot.val();
  const params: StatParams = {};

  // `ServerValue` doesn't work with Emulators Suite
  if (isDebugMode()) {
    params.chatMessages = stat.chatMessages + 1;
  } else {
    params.chatMessages = admin.database.ServerValue.increment(1);
  }

  try {
    await statRef.update(params);
  } catch (error) {
    logger.error(error);
  }
};

export default onMessageCreated;
