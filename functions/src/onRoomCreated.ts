import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueCreated } from 'firebase-functions/v2/database';
import { StatParams } from './types';
import { formatDate, isDebugMode } from './helpers';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onRoomCreated = onValueCreated('/rooms/*', async (event) => {
  const now = new Date();
  const room = event.data.val();
  const userId = room.userId;

  try {
    await updateUserFilter(userId, now);
    await updateRoomStats(now);
  } catch (error) {
    logger.error(error);
  }
});

const updateUserFilter = async (userId: string, now: Date) => {
  const userRef = db.ref(`users/${userId}`);
  const updatedAt = now.toJSON();
  const filter = `perm-${updatedAt}`;

  try {
    await userRef.update({ filter });
  } catch (error) {
    logger.error(error);
  }
}

const updateRoomStats = async (now: Date) => {
  const statRef = db.ref(`stats/${formatDate(now)}`);
  const snapshot = await statRef.get();

  if (!snapshot.exists()) return;

  const stat = snapshot.val();
  const params: StatParams = {};

  // `ServerValue` doesn't work with Emulators Suite
  if (isDebugMode()) {
    params.rooms = stat.rooms + 1;
  } else {
    params.rooms = admin.database.ServerValue.increment(1);
  }

  try {
    await statRef.update(params);
  } catch (error) {
    logger.error(error);
  }
};


export default onRoomCreated;
