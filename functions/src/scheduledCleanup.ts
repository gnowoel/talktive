const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();
const priorDeleting =
  process.env.FUNCTIONS_EMULATOR === "true"
    ? 0 // no wait for manual trigger
    : 48 * 3600 * 1000; // 48 hours

const cleanup = async () => {
  const ref = db.ref("rooms");
  const time = new Date().getTime() - priorDeleting;
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
            return markDeleted(room);
          })
          .then(() => {
            return removeMessages(room);
          });
      }, Promise.resolve());
    });
};

const markDeleted = (room) => {
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

const requestedCleanup = onRequest((req, res) => {
  cleanup()
    .catch((error) => {
      logger.error(error);
    })
    .then(() => {
      res.send("success");
    });
});

const scheduledCleanup = onSchedule("every hour", async (event) => {
  cleanup().catch((error) => {
    logger.error(error);
  });
});

module.exports = {
  requestedCleanup,
  scheduledCleanup,
};
