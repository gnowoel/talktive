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
  ? 0 // now wait
  : 30 * 24 * 3600 * 1000; // 30 days

const timeBeforeRoomDeleting = isDebugMode()
  ? 0 // no wait
  : 72 * 3600 * 1000; // 72 hours

interface Params {
  [userId: string]: null
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
  const stat = snapshot.val();

  try {
    if (snapshot.exists()) {
      // TODO: For data migration when upgrading. Can be simplified after deployment.
      if ('responses' in stat) {
        return;
      } else {
        await statRef.update({
          responses: 0,
        });
      }
    } else {
      await statRef.set({
        users: 0,
        rooms: 0,
        messages: 0
      });
    }
  } catch (error) {
    logger.error(error);
  }
}

const cleanup = async () => {
  try {
    await cleanupUsers();
    await cleanupRooms();
  } catch (error) {
    logger.error(error);
  }
};

const cleanupUsers = async () => {
  const ref = db.ref('users');
  const time = new Date(new Date().getTime() - timeBeforeUserDeleting).toJSON();

  const query = ref
    .orderByChild('filter')
    .startAt('temp-0000')
    .endAt(`temp-${time}`)
    .limitToFirst(1000);

  const snapshot = await query.get();

  if (!snapshot.exists()) return;

  const users = snapshot.val();
  const userIds = Object.keys(users);
  const params: Params = {};
  const usersRef = db.ref('users');

  userIds.forEach((userId) => {
    params[userId] = null;
  });

  try {
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
