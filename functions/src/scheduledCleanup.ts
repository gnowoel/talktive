import { onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';
import * as admin from 'firebase-admin';
import { getAuth } from 'firebase-admin/auth';
import { isDebugMode } from './helpers';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const priorUserDeleting = isDebugMode() ?
  0 : // now
  30 * 24 * 3600 * 1000; // 30 days
const priorRoomDeleting = isDebugMode() ?
  0 : // no wait for manual trigger
  48 * 3600 * 1000; // 48 hours

interface Params {
  [userId: string]: null
}

export const scheduledCleanup = onSchedule('every hour', async (_) => {
  try {
    await cleanup();
  } catch (error) {
    logger.error(error);
  }
});

export const requestedCleanup = onRequest(async (req, res) => {
  try {
    await cleanup();
  } catch (error) {
    logger.error(error);
  }

  res.send('success');
});

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
  const time = new Date((new Date().getTime() - priorUserDeleting)).toJSON();

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

const cleanupRooms = async () => {
  const ref = db.ref('rooms');
  const time = new Date().getTime() - priorRoomDeleting;
  const query = ref.orderByChild('closedAt').endAt(time);

  const snapshot = await query.get();

  if (!snapshot.exists()) return;

  const rooms = snapshot.val();
  const roomIds = Object.keys(rooms);

  try {
    for (const roomId in roomIds) {
      await markRoomDeleted(roomId);
      await removeMessages(roomId);
    }
  } catch (error) {
    logger.error(error);
  }
};

const markRoomDeleted = async (roomId: string) => {
  const roomRef = db.ref(`rooms/${roomId}`);
  const filterZ = '-zzzz';

  try {
    await roomRef.update({
      filter: filterZ,
      deletedAt: new Date().getTime(),
    });
  } catch (error) {
    logger.error(error);
  }
};

const removeMessages = async (roomId: string) => {
  const messagesRef = db.ref(`messages/${roomId}`);

  try {
    await messagesRef.remove();
  } catch (error) {
    logger.error(error);
  }
};
