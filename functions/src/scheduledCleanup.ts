import { onRequest } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";
import { getAuth } from "firebase-admin/auth";
import { isDebugMode } from "./helpers";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const priorUserDeleting = isDebugMode()
  ? 0 // now
  : 30 * 24 * 3600 * 1000; // 30 days
const priorRoomDeleting = isDebugMode()
  ? 0 // no wait for manual trigger
  : 48 * 3600 * 1000; // 48 hours

interface Params {
  [userId: string]: null
}

interface Room {
  id: string
  userId: string
  userName: string
  userCode: string
  languageCode: string
  createdAt: number
  updatedAt: number
  closedAt: number
  deletedAt: number
  filter: string
}

export const scheduledCleanup = onSchedule("every hour", async (_) => {
  cleanup().catch((error) => {
    logger.error(error);
  });
});

export const requestedCleanup = onRequest((req, res) => {
  cleanup()
    .catch((error) => {
      logger.error(error);
    })
    .then(() => {
      res.send("success");
    });
});

const cleanup = async () => {
  return Promise.resolve()
    .then(() => cleanupUsers())
    .then(() => cleanupRooms());
};

const cleanupUsers = () => {
  const ref = db.ref("users");
  const time = new Date((new Date().getTime() - priorUserDeleting)).toJSON();
  const query = ref
    .orderByChild("filter")
    .startAt("temp-0000")
    .endAt(`temp-${time}`)
    .limitToFirst(1000);

  return query
    .get()
    .then((snapshot) => {
      if (!snapshot.exists()) return [];
      return snapshot.val();
    })
    .then((users) => {
      const userIds = Object.keys(users);
      const params: Params = {};
      const usersRef = db.ref("users");

      userIds.forEach((userId) => {
        params[userId] = null;
      });

      return getAuth().deleteUsers(userIds).then(() => {
        usersRef.update(params);
      });
    });
};

const cleanupRooms = () => {
  const ref = db.ref("rooms");
  const time = new Date().getTime() - priorRoomDeleting;
  const query = ref.orderByChild("closedAt").endAt(time);

  return query
    .get()
    .then((snapshot) => {
      if (!snapshot.exists()) return []; // for empty results
      const rooms = snapshot.val();
      return Object.keys(rooms).map((roomId) => {
        return {
          id: roomId,
          ...rooms[roomId],
        };
      });
    })
    .then((rooms) => {
      return rooms.reduce((p, room) => {
        return p
          .then(() => {
            return markRoomDeleted(room);
          })
          .then(() => {
            return removeMessages(room);
          });
      }, Promise.resolve());
    });
};

const markRoomDeleted = (room: Room) => {
  const roomRef = db.ref(`rooms/${room.id}`);
  const filterZ = "-zzzz";
  return roomRef.update({
    filter: filterZ,
    deletedAt: new Date().getTime(),
  });
};

const removeMessages = (room: Room) => {
  const messagesRef = db.ref(`messages/${room.id}`);
  return messagesRef.remove();
};
