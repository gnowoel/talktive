const { onRequest } = require("firebase-functions/v2/https");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

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

const cleanup = () => {
  const ref = db.ref(`test/abc`);
  const promise = ref.set({ id: `${randomNumber(100, 999)}` });
  return promise;
};

const randomNumber = (min, max) => {
  return Math.floor(Math.random() * (max - min + 1) + min);
};

module.exports = {
  requestedCleanup,
  scheduledCleanup,
};
