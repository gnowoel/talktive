import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueCreated } from 'firebase-functions/v2/database';
import { Chat } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onChatCreated = onValueCreated('/chats/{chatId}', async (event) => {
  const chatId = event.params.chatId;
  const chat = event.data.val();
  const followers = chat.followers;

  try {
    for (const follower of followers) {
      await copyToFollower(follower, chatId, chat);
    }
  } catch (error) {
    logger.error(error);
  }
});

const copyToFollower = async (userId: string, chatId: string, chat: Chat) => {
  try {
    const ref = db.ref(`contacts/${userId}/${chatId}`);
    await ref.set({
      messageCount: chat.messageCount,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt,
    });
  } catch (error) {
    logger.error(error);
  }
};

export default onChatCreated;
