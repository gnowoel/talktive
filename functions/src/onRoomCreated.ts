import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueCreated } from 'firebase-functions/v2/database';
import { getDate, getMonth, getYear, isDebugMode } from './helpers';

if (!admin.apps.length) {
  admin.initializeApp();
}

interface StatParams {
  users?: number | object
  rooms?: number | object
  messages?: number | object
}

const db = admin.database();

const onRoomCreated = onValueCreated('/rooms/*', async (event) => {
  const now = new Date();
  const room = event.data.val();
  const userId = room.userId;

  try {
    await markUserPermanent(userId, now);
    await updateRoomStats(now);
  } catch (error) {
    logger.error(error);
  }
});

const markUserPermanent = async (userId: string, now: Date) => {
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
  const year = getYear(now);
  const month = getMonth(now);
  const date = getDate(now);
  const statRef = db.ref(`stats/${year}/${month}/${date}`);

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
