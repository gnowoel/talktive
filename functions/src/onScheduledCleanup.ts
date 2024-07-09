const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");
const { getAuth } = require("firebase-admin/auth");
const { isDebugMode } = require('./helpers');

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const priorUserDeleting = isDebugMode
    ? 0 // now
    : 30 * 24 * 3600 * 1000 // 30 days
const priorRoomDeleting = isDebugMode()
    ? 0 // no wait for manual trigger
    : 48 * 3600 * 1000; // 48 hours

const onScheduledCleanup = onSchedule("every hour", async (event) => {
  cleanup().catch((error) => {
    logger.error(error);
  });
});

const onRequestedCleanup = onRequest((req, res) => {
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
  const time = (new Date().getTime() - priorUserDeleting).toJSON();
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
      const params = {};
      const usersRef = db.ref('users');

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

const markRoomDeleted = (room) => {
  const roomRef = db.ref(`rooms/${room.id}`);
  const filterZ = "-zzzz";
  return roomRef.update({
    filter: filterZ,
    deletedAt: new Date().getTime(),
  });
};

const removeMessages = (room) => {
  const messagesRef = db.ref(`messages/${room.id}`);
  return messagesRef.remove();
};

module.exports = {
  onScheduledCleanup,
  onRequestedCleanup
};
