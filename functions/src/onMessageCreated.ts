import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueCreated } from 'firebase-functions/v2/database';
import { getDate, getMonth, getYear, isDebugMode } from './helpers';

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
  messageCount?: number | object
  filter?: string
}

interface StatParams {
  users?: number | object
  rooms?: number | object
  messages?: number | object
}

const db = admin.database();
const priorClosing = isDebugMode() ?
  360 * 1000 : // 6 minutes
  3600 * 1000; // 1 hour

const onMessageCreated = onValueCreated('/messages/{roomId}/*', async (event) => {
  const now = new Date();
  const roomId = event.params.roomId;
  const message = event.data.val();
  const userId = message.userId;
  const messageCreatedAt = message.createdAt;

  try {
    await updateUserTimestamp(userId, now);
    await updateRoomTimestampAndMessageCount(roomId, messageCreatedAt);
    await updateMessageStats(now);
  } catch (error) {
    logger.error(error);
  }
});

const updateUserTimestamp = async (userId: string, now: Date) => {
  const userRef = db.ref(`users/${userId}`);
  const updatedAt = now.toJSON();
  const filter = `perm-${updatedAt}`;

  try {
    await userRef.update({ filter });
  } catch (error) {
    logger.error(error);
  }
};

const updateRoomTimestampAndMessageCount = async (roomId: string, messageCreatedAt: number) => {
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
    params.messageCount = 1;
  } else {
    // `ServerValue` doesn't work with Emulators Suite
    if (isDebugMode()) {
      params.messageCount = room.messageCount + 1;
    } else {
      params.messageCount = admin.database.ServerValue.increment(1);
    }
  }

  if (!isRoomClosed(room, messageCreatedAt)) {
    params.closedAt = messageCreatedAt + priorClosing;
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

const isRoomNew = (room: Room) => {
  return room.filter.endsWith('-aaaa');
};

const isRoomClosed = (room: Room, timestamp: number) => {
  return room.filter === '-zzzz' || room.closedAt <= timestamp;
};

const updateMessageStats = async (now: Date) => {
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

export default onMessageCreated;
