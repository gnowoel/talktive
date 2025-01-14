import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueUpdated } from 'firebase-functions/v2/database';
import { Chat } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onChatUpdated = onValueUpdated('/chats/{userId}/{chatId}', async (event) => {
  const userId = event.params.userId;
  const chatId = event.params.chatId;
  const chat = event.data.after.val();

  try {
    await updateChatPriority(userId, chatId, chat);
  } catch (error) {
    logger.error(error);
  }
});

const updateChatPriority = async (userId: string, chatId: string, chat: Chat) => {
  const chatRef = db.ref(`chats/${userId}/${chatId}`);
  const priority = -1 * chat.updatedAt;

  await chatRef.setPriority(priority, (error) => {
    if (error) {
      logger.error(error);
    }
  });
}

export default onChatUpdated;
