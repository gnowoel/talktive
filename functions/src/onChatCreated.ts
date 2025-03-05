import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueCreated } from 'firebase-functions/v2/database';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

interface Chat {
  partner: any;
  createdAt: number;
  updatedAt: number;
  messageCount: number;
}

const onChatCreated = onValueCreated('/chats/{userId}/{chatId}', async (event) => {
  const userId = event.params.userId;
  const chatId = event.params.chatId;
  const chat: Chat = event.data.val();

  try {
    await createPair(userId, chatId, chat);
  } catch (error) {
    logger.error(error);
  }
});

const createPair = async (userId: string, chatId: string, chat: Chat) => {
  const pairRef = db.ref(`pairs/${chatId}`);
  const partnerId = chatId.replace(userId, '');

  await pairRef.transaction((current) => {
    if (current) return; // Don't overwrite existing pair

    return {
      followers: [userId, partnerId],
      firstUserId: null,
      lastMessageContent: null,
      messageCount: 0,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt,
    }
  });
}

export default onChatCreated;
