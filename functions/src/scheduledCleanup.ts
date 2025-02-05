import * as admin from 'firebase-admin';
import { getAuth } from 'firebase-admin/auth';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';
import { onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { formatDate, isDebugMode } from './helpers';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();
const storage = getStorage();

const timeBeforeUserDeleting = isDebugMode()
  ? 0 // no wait
  : 30 * 24 * 3600 * 1000; // 30 days
const timeBeforeRoomDeleting = isDebugMode()
  ? 0 // no wait
  : 72 * 3600 * 1000; // 72 hours
const timeBeforePairDeleting = isDebugMode()
  ? 0 // no wait
  : 96 * 3600 * 1000; // 96 hours
const timeBeforeReportDeleting = isDebugMode()
  ? 0 // no wait
  : 7 * 24 * 3600 * 1000; // 7 days

interface Params {
  [id: string]: null;
}

export const scheduledCleanup = onSchedule('every hour', async (_event) => {
  try {
    await setup();
    await cleanup();
  } catch (error) {
    logger.error(error);
  }
});

export const requestedCleanup = onRequest(async (_req, res) => {
  try {
    await setup();
    await migrate();
    await cleanup();
  } catch (error) {
    logger.error(error);
  }

  res.send('success');
});

const setup = async () => {
  const today = new Date();
  const tomorrow = new Date(today.getTime() + 24 * 3600 * 1000);

  try {
    await setupDailyStats(today);
    await setupDailyStats(tomorrow);
  } catch (error) {
    logger.error(error);
  }
};

const setupDailyStats = async (timestamp: Date) => {
  const statRef = db.ref(`stats/${formatDate(timestamp)}`);
  const snapshot = await statRef.get();

  try {
    if (!snapshot.exists()) {
      await statRef.set({
        users: 0,
        chats: 0,
        rooms: 0,
        messages: 0,
        responses: 0,
      });
    }
  } catch (error) {
    logger.error(error);
  }
}

const migrate = async () => {
  try {
    await migrateUsers();
  } catch (error) {
    logger.error(error);
  }
}

const migrateUsers = async () => {
  const usersRef = db.ref('users');

  const query = usersRef
    .orderByChild('updatedAt')
    .endBefore(0)
    .limitToFirst(1000);

  try {
    const snapshot = await query.get();

    if (!snapshot.exists()) return;

    const users = snapshot.val();
    logger.info(users);
    const userIds = Object.keys(users);
    const params: Params = {};

    userIds.forEach((userId) => {
      const user = users[userId];
      if (!user['updatedAt']) {
        const timestamp = user.filter.slice(5);
        const then = new Date(timestamp).getTime();
        user['createdAt'] = then;
        user['updatedAt'] = then;
        params[userId] = user;
      }
    });

    await usersRef.update(params);
  } catch (error) {
    logger.error(error);
  }
}

const cleanup = async () => {
  try {
    await cleanupUsers();
    await cleanupRooms();
    await cleanupPairs();
    await cleanupReports();
  } catch (error) {
    logger.error(error);
  }
};

const cleanupUsers = async () => {
  try {
    await cleanupTempUsers();
    await cleanupPermUsers();
  } catch (error) {
    logger.error(error);
  }
}

const cleanupTempUsers = async () => {
  const usersRef = db.ref('users');
  const time = new Date(new Date().getTime() - timeBeforeUserDeleting).toJSON();

  const query = usersRef
    .orderByChild('filter')
    .startAt('temp-0000')
    .endAt(`temp-${time}`)
    .limitToFirst(1000);

  try {
    const snapshot = await query.get();

    if (!snapshot.exists()) return;

    const users = snapshot.val();
    const userIds = Object.keys(users);
    const params: Params = {};

    userIds.forEach((userId) => {
      params[userId] = null;
    });

    await getAuth().deleteUsers(userIds);
    await usersRef.update(params);
  } catch (error) {
    logger.error(error);
  }
};

// TODO: Remove this once we have fully upgraded to v2.
const cleanupPermUsers = async () => {
  const usersRef = db.ref('users');
  const time = new Date(new Date().getTime() - timeBeforeUserDeleting * 3).toJSON();

  const query = usersRef
    .orderByChild('filter')
    .startAt('perm-0000')
    .endAt(`perm-${time}`)
    .limitToFirst(1000);

  try {
    const snapshot = await query.get();

    if (!snapshot.exists()) return;

    const users = snapshot.val();
    const userIds = Object.keys(users);
    const params: Params = {};

    userIds.forEach((userId) => {
      params[userId] = null;
    });

    await getAuth().deleteUsers(userIds);
    await usersRef.update(params);
  } catch (error) {
    logger.error(error);
  }
};

// Rooms, messages & images
const cleanupRooms = async () => {
  const ref = db.ref('rooms');
  const time = new Date().getTime() - timeBeforeRoomDeleting;
  const query = ref.orderByChild('closedAt').endAt(time).limitToFirst(1000);

  const snapshot = await query.get();

  if (!snapshot.exists()) return;

  const rooms = snapshot.val();
  const roomIds = Object.keys(rooms);

  try {
    for (const roomId of roomIds) {
      await removeRoomImages(roomId);
      await removeRoomMessages(roomId);
      await removeRoom(roomId);
    }
  } catch (error) {
    logger.error(error);
  }
};

const removeRoomImages = async (roomId: string) => {
  try {
    const bucket = storage.bucket();
    const prefix = `rooms/${roomId}/`;

    const [files] = await bucket.getFiles({ prefix });

    const deletePromises = files.map(file => file.delete());
    await Promise.all(deletePromises);
  } catch (error) {
    logger.error(`Failed to remove images from room ${roomId}:`, error);
  }
};

const removeRoomMessages = async (roomId: string) => {
  const messagesRef = db.ref(`messages/${roomId}`);

  try {
    await messagesRef.remove();
  } catch (error) {
    logger.error(error);
  }
};

const removeRoom = async (roomId: string) => {
  const roomRef = db.ref(`rooms/${roomId}`);

  try {
    await roomRef.remove();
  } catch (error) {
    logger.error(error);
  }
};

// Pairs, chats, messages & images
const cleanupPairs = async () => {
  try {
    const ref = db.ref('pairs');
    const time = new Date().getTime() - timeBeforePairDeleting;
    const query = ref.orderByChild('updatedAt').endAt(time).limitToFirst(1000);

    const snapshot = await query.get();

    if (!snapshot.exists()) return;

    const pairs = snapshot.val();
    const pairIds = Object.keys(pairs);

    for (const pairId of pairIds) {
      const chatId = pairId;
      const userIds = pairs[pairId].followers;

      await removeChatImages(chatId);
      await removeChatMessages(chatId);

      for (const userId of userIds) {
        await removeChat(userId, chatId);
      }

      await removePair(pairId);
    }
  } catch (error) {
    logger.error(error);
  }
};

const removeChatImages = async (chatId: string) => {
  try {
    const bucket = storage.bucket();
    const prefix = `chats/${chatId}/`;

    const [files] = await bucket.getFiles({ prefix });

    const deletePromises = files.map(file => file.delete());
    await Promise.all(deletePromises);
  } catch (error) {
    logger.error(`Failed to remove images from chat ${chatId}:`, error);
  }
};

const removeChatMessages = async (chatId: string) => {
  try {
    const messagesRef = db.ref(`messages/${chatId}`);
    await messagesRef.remove();
  } catch (error) {
    logger.error(error);
  }
};

const removeChat = async (userId: string, chatId: string) => {
  try {
    const chatRef = db.ref(`chats/${userId}/${chatId}`);
    await chatRef.remove();
  } catch (error) {
    logger.error(error);
  }
};

const removePair = async (pairId: string) => {
  try {
    const pairRef = db.ref(`pairs/${pairId}`);
    await pairRef.remove();
  } catch (error) {
    logger.error(error);
  }
};

const cleanupReports = async () => {
  const reportsRef = db.ref('reports');

  const now = new Date().getTime();
  const then = now - timeBeforeReportDeleting;

  const query = reportsRef
    .orderByChild('createdAt')
    .endBefore(then)
    .limitToFirst(1000);

  try {
    const snapshot = await query.get();

    if (!snapshot.exists()) return;

    const reports = snapshot.val();
    const reportIds = Object.keys(reports);
    const params: Params = {};

    reportIds.forEach((reportId) => {
      params[reportId] = null;
    });

    await reportsRef.update(params);
  } catch (error) {
    logger.error(error);
  }
}
