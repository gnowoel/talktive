const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();
const span = 48 * 1000; // FIXME: `48 * 3600 * 1000` for production

const cleanup = async () => {
  const ref = db.ref("rooms");
  const time = new Date().getTime() - span;
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
            return saveStats(room);
          })
          .then(() => {
            return removeRecords(room);
          });
      }, Promise.resolve());
    });
};

const saveStats = (room) => {
  return Promise.resolve()
    .then(() => {
      return {
        messageCount: getMessageCount(room),
        deletedAt: new Date().getTime(),
      };
    })
    .then((params) => {
      const statsRef = db.ref(`stats/${room.id}`);
      return statsRef.set(params);
    });
};

const removeRecords = (room) => {
  return Promise.resolve()
    .then(() => {
      const messagesRef = db.ref(`messages/${room.id}`);
      return messagesRef.remove();
    })
    .then(() => {
      const roomRef = db.ref(`rooms/${room.id}`);
      return roomRef.remove();
    });
};

const getMessageCount = (room) => {
  return typeof room.messageCount === "undefined" ? 0 : room.messageCount;
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
