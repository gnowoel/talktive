import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueCreated } from 'firebase-functions/v2/database';
import { formatDate, isDebugMode } from './helpers';
import { ChatGPTService } from './services/chatgpt';
import { CHATGPT_CONFIG } from './config';
import { Chat, RoomMessage, Message, PairParams, StatParams } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

interface Room {
  closedAt: number
  filter: string
}

interface RoomParams {
  createdAt?: number
  updatedAt?: number
  closedAt?: number
  filter?: string
}

const db = admin.database();

const timeBeforeClosing = isDebugMode() ?
  1000 * 60 * 6 : // 6 minutes
  1000 * 60 * 60 * 24 * 3; // 3 days

const BOT_WAIT_TIME = 10 * 1000;

const BOT = {
  userId: 'bot',
  userName: 'assistant',
  userCode: '\u{1f916}', // Robot
};

const onMessageCreated = onValueCreated('/messages/{listId}/*', async (event) => {
  const now = new Date();
  const listId = event.params.listId;
  const message = event.data.val();
  const userId = message.userId;
  const messageCreatedAt = message.createdAt;

  const pairId = listId;
  const roomId = listId;
  const isPair = listId.length > 20; // Push ID is 20 characters long

  try {
    await updateUserUpdatedAt(userId, now);
    if (isPair) {
      await updatePair(pairId, message, now);
      await sendPushNotification(userId, pairId, message);
    } else {
      await updateRoomTimestamps(roomId, messageCreatedAt);
    }
    await updateMessageOrResponseStats(now, message);
    await sendBotResponse(roomId, message);
  } catch (error) {
    logger.error(error);
  }
});

const updateUserUpdatedAt = async (userId: string, now: Date) => {
  const userRef = db.ref(`users/${userId}`);
  const updatedAt = now.valueOf();

  try {
    await userRef.update({ updatedAt });
  } catch (error) {
    logger.error(error);
  }
};

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

    const chat = await getChat(userId, chatId);

    if (!chat) return;

    const isActive = isChatActive(chat);

    if (!isActive) return;

    const token = await getFcmToken(otherId);

    if (!token) return;

    const title = `${message.userPhotoURL} ${message.userDisplayName}`;
    const body = message.content;

    const pushMessage: admin.messaging.Message = {
      notification: { title, body },
      data: { userId, chatId },
      token
    };

    await admin.messaging().send(pushMessage);
  } catch (error) {
    logger.error(error);
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
  return !isChatNew(chat) && !isChatClosed(chat) && !isChatMuted(chat);
};

const isChatNew = (chat: Chat) => {
  return !chat.firstUserId;
};

const isChatClosed = (chat: Chat) => {
  const now = new Date().getTime();
  return chat.updatedAt + timeBeforeClosing <= now;
};

const isChatMuted = (chat: Chat) => {
  return !!chat.mute;
};

const getFcmToken = async (userId: string) => {
  try {
    const userRef = db.ref(`users/${userId}`);
    const snapshot = await userRef.get();

    if (!snapshot.exists()) return null;

    const user = snapshot.val();

    return user.fcmToken;
  } catch (error) {
    logger.error(error);
  }
};

const updateRoomTimestamps = async (roomId: string, messageCreatedAt: number) => {
  const ref = db.ref(`rooms/${roomId}`);

  const snapshot = await ref.get();

  if (!snapshot.exists()) return;

  const room = snapshot.val();
  const filter0 = `${room.languageCode}-1970-01-01T00:00:00.000Z`;
  const filterC = '-cccc';
  const params: RoomParams = {};

  params.updatedAt = messageCreatedAt;

  if (isRoomNew(room)) {
    params.createdAt = messageCreatedAt;
    params.filter = filter0;
  }

  if (!isRoomClosed(room, messageCreatedAt)) {
    params.closedAt = messageCreatedAt + timeBeforeClosing;
  } else {
    if (room.filter !== filterC) {
      params.filter = filterC;
    }
  }

  try {
    await ref.update(params);
  } catch (error) {
    logger.error(error);
  }
};

const updateMessageOrResponseStats = async (now: Date, message: Message) => {
  const statRef = db.ref(`stats/${formatDate(now)}`);
  const snapshot = await statRef.get();

  if (!snapshot.exists()) return;

  const stat = snapshot.val();
  const params: StatParams = {};

  if (message.userId === BOT.userId) {
    // Just in case that data has not migrated after upgrading
    if (!('responses' in stat)) return;

    // `ServerValue` doesn't work with Emulators Suite
    if (isDebugMode()) {
      params.responses = stat.responses + 1;
    } else {
      params.responses = admin.database.ServerValue.increment(1);
    }
  } else {
    // `ServerValue` doesn't work with Emulators Suite
    if (isDebugMode()) {
      params.messages = stat.messages + 1;
    } else {
      params.messages = admin.database.ServerValue.increment(1);
    }
  }

  try {
    await statRef.update(params);
  } catch (error) {
    logger.error(error);
  }
};

const isRoomNew = (room: Room) => {
  return room.filter.endsWith('-nnnn');
};

const isRoomClosed = (room: Room, timestamp: number) => {
  return room.filter === '-cccc' || room.closedAt <= timestamp;
};

const sendBotResponse = async (roomId: string, message: RoomMessage) => {
  if (roomId !== BOT.userId) return; // Disable chatbot for now

  if (message.userId === BOT.userId) return;

  try {
    await new Promise(resolve => setTimeout(resolve, BOT_WAIT_TIME));

    const roomSnapshot = await db.ref(`/rooms/${roomId}`).get();
    const room = roomSnapshot.val();

    if (!room || room.filter === '-dddd' || room.filter === '-cccc') {
      return; // Room is deleted or closed
    }

    if (room.updatedAt > message.createdAt) {
      return; // Someone else replied
    }

    const messagesRef = db.ref(`/messages/${roomId}`);
    const recentMessagesQuery = messagesRef
      .orderByChild('createdAt')
      .endAt(message.createdAt)
      .limitToLast(CHATGPT_CONFIG.maxContextMessages + 1);

    const recentMessagesSnapshot = await recentMessagesQuery.get();
    const recentMessages: RoomMessage[] = [];

    if (recentMessagesSnapshot.exists()) {
      recentMessagesSnapshot.forEach((childSnapshot) => {
        const msg = childSnapshot.val();
        recentMessages.push(msg);
      });
    }

    recentMessages.pop();

    const response = await ChatGPTService.generateResponse(
      message,
      recentMessages
    );

    if (!response) return;

    const botMessage = {
      userId: BOT.userId,
      userName: BOT.userName,
      userCode: BOT.userCode,
      content: response,
      createdAt: Date.now(),
    };

    await db.ref(`/messages/${roomId}`).push(botMessage);
  } catch (error) {
    logger.error(error);
  }
};

export default onMessageCreated;
