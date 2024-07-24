import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueCreated } from 'firebase-functions/v2/database';
import { formatDate, isDebugMode } from './helpers';

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

interface StatParams {
  users?: number | object
  rooms?: number | object
  messages?: number | object
}

const db = admin.database();
const timeBeforeClosing = isDebugMode() ?
  360 * 1000 : // 6 minutes
  3600 * 1000; // 1 hour

const onMessageCreated = onValueCreated('/messages/{roomId}/*', async (event) => {
  const now = new Date();
  const roomId = event.params.roomId;
  const message = event.data.val();
  const userId = message.userId;
  const messageCreatedAt = message.createdAt;

  try {
    await updateUserFilter(userId, now);
    await updateRoomTimestamps(roomId, messageCreatedAt);
    await updateMessageStats(now);
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
};

const updateRoomTimestamps = async (roomId: string, messageCreatedAt: number) => {
  const ref = db.ref(`rooms/${roomId}`);

  const snapshot = await ref.get();

  if (!snapshot.exists()) return;

  const room = snapshot.val();
  const filter0 = `${room.languageCode}-1970-01-01T00:00:00.000Z`;
  const filterZ = '-zzzz';
  const params: RoomParams = {};

  params.updatedAt = messageCreatedAt;

  if (isRoomNew(room)) {
    params.createdAt = messageCreatedAt;
    params.filter = filter0;
  }

  if (!isRoomClosed(room, messageCreatedAt)) {
    params.closedAt = messageCreatedAt + timeBeforeClosing;
  } else {
    if (room.filter !== filterZ) {
      params.filter = filterZ;
    }
  }

  try {
    await ref.update(params);
  } catch (error) {
    logger.error(error);
  }
};

const updateMessageStats = async (now: Date) => {
  const statRef = db.ref(`stats/${formatDate(now)}`);
  const snapshot = await statRef.get();

  if (!snapshot.exists()) return;

  const stat = snapshot.val();
  const params: StatParams = {};

  // `ServerValue` doesn't work with Emulators Suite
  if (isDebugMode()) {
    params.messages = stat.messages + 1;
  } else {
    params.messages = admin.database.ServerValue.increment(1);
  }

  try {
    await statRef.update(params);
  } catch (error) {
    logger.error(error);
  }
};

const isRoomNew = (room: Room) => {
  return room.filter.endsWith('-aaaa');
};

const isRoomClosed = (room: Room, timestamp: number) => {
  return room.filter === '-zzzz' || room.closedAt <= timestamp;
};

export default onMessageCreated;
