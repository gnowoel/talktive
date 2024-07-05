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
      if (!snapshot.exists()) return;
      const rooms = snapshot.val();
      return Object.keys(rooms);
    })
    .then((roomIds) => {
      return roomIds.reduce((p, roomId) => {
        return p
          .then(() => {
            return saveStats(roomId);
          })
          .then(() => {
            return removeRecords(roomId);
          });
      }, Promise.resolve());
    });
};

const saveStats = (roomId) => {
  return Promise.resolve()
    .then(() => {
      return getMessageCount(roomId);
    })
    .then((messageCount) => {
      const deletedAt = new Date().getTime();
      const params = {
        messageCount,
        deletedAt,
      };
      return params;
    })
    .then((params) => {
      const statsRef = db.ref(`stats/${roomId}`);
      return statsRef.set(params);
    });
};

const removeRecords = (roomId) => {
  return Promise.resolve()
    .then(() => {
      const messagesRef = db.ref(`messages/${roomId}`);
      return messagesRef.remove();
    })
    .then(() => {
      const roomRef = db.ref(`rooms/${roomId}`);
      return roomRef.remove();
    });
};

const getMessageCount = (roomId) => {
  const messagesRef = db.ref(`messages/${roomId}`);

  return messagesRef.get().then((snapshot) => {
    if (!snapshot.exists()) return 0; // for empty rooms
    const messages = snapshot.val();
    return Object.keys(messages).length;
  });
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
