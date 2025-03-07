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
  const chatBefore = event.data.before.val();
  const chat = event.data.after.val();

  try {
    await updateChatPriority(userId, chatId, chat, chatBefore);
  } catch (error) {
    logger.error(error);
  }
});

// TODO: We've never used chat priority.
const updateChatPriority = async (userId: string, chatId: string, chat: Chat, chatBefore: Chat) => {
  if (chat.updatedAt === chatBefore.updatedAt) return;

  const chatRef = db.ref(`chats/${userId}/${chatId}`);
  const priority = -1 * chat.updatedAt;

  await chatRef.setPriority(priority, (error) => {
    if (error) {
      logger.error(error);
    }
  });
}

export default onChatUpdated;
