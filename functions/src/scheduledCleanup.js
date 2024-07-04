const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();
const span = 120 * 1000; // TODO: '48 * 3600 * 1000' for production
const time = new Date().getTime() - span;

const cleanup = async () => {
  const ref = db.ref("rooms");
  const query = ref.orderByChild("closedAt").endAt(time);

  let promise = Promise.resolve();

  query.once("value", (snapshot) => {
    snapshot.forEach((childSnapshot) => {
      const roomId = childSnapshot.key;

      const messagesRef = db.ref(`messages/${roomId}`);
      const roomRef = db.ref(`rooms/${roomId}`);

      promise = promise.then(() => messagesRef.remove());
      promise = promise.then(() => roomRef.remove());

      return promise;
    });
  });
};

const requestedCleanup = onRequest((req, res) => {
  cleanup()
    .then(() => {
      res.send("success");
    })
    .catch((error) => {
      logger.error(error);
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
