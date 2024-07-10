import { onValueCreated } from "firebase-functions/v2/database";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";
import { isDebugMode } from "./helpers";

if (!admin.apps.length) {
  admin.initializeApp();
}

interface Params {
  createdAt?: number
  updatedAt?: number
  closedAt?: number
  messageCount?: number | {}
  filter?: string
}

interface Room {
  closedAt: number
  filter: string
}

interface Message {
  createdAt: number
}

const db = admin.database();
const priorClosing = isDebugMode()
  ? 360 * 1000 // 6 minutes
  : 3600 * 1000; // 1 hour

const onMessageCreated = onValueCreated("/messages/{roomId}/*", (event) => {
  const roomId = event.params.roomId;
  const message = event.data.val();
  const userId = message.userId;

  return Promise.resolve()
    .then(() => updateUserTimestamp(userId))
    .then(() => updateRoomTimestamp(roomId, message));
});

const updateUserTimestamp = (userId: string) => {
  const userRef = db.ref(`users/${userId}`);
  const updatedAt = new Date().toJSON();
  const params = {
    filter: `perm-${updatedAt}`,
  };

  return userRef.update(params);
};

const updateRoomTimestamp = (roomId: string, message: Message) => {
  const ref = db.ref(`rooms/${roomId}`);

  return ref
    .get()
    .then((snapshot) => {
      if (!snapshot.exists()) return;

      const room = snapshot.val();
      const filter0 = `${room.languageCode}-1970-01-01T00:00:00.000Z`;
      const filterZ = "-zzzz";
      const params: Params = {};

      params.updatedAt = message.createdAt;

      if (isRoomNew(room)) {
        params.createdAt = message.createdAt;
        params.filter = filter0;
        params.messageCount = 1;
      } else {
        // `ServerValue` doesn't work on localhost
        if (isDebugMode()) {
          params.messageCount = room.messageCount + 1;
        } else {
          params.messageCount = admin.database.ServerValue.increment(1);
        }
      }

      if (!isRoomClosed(room, message)) {
        params.closedAt = message.createdAt + priorClosing;
      } else {
        if (room.filter !== filterZ) {
          params.filter = filterZ;
        }
      }

      return params;
    })
    .then((params) => {
      if (params) {
        ref.update(params);
      }
    })
    .catch((error) => {
      logger.error(error);
    });
};

const isRoomNew = (room: Room) => {
  return room.filter.endsWith("-aaaa");
};

const isRoomClosed = (room: Room, message: Message) => {
  return room.filter === "-zzzz" || room.closedAt <= message.createdAt;
};

export default onMessageCreated;
