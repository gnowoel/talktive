const { onValueCreated } = require("firebase-functions/v2/database");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onRoomCreated = onValueCreated("/rooms/*", (event) => {
  const room = event.data.val();
  const userId = room.userId;
  const userRef = db.ref(`users/${userId}`);
  const updatedAt = new Date().toJSON();
  const params = {
    filter: `perm-${updatedAt}`,
  };

  return userRef.update(params).catch((error) => {
    logger.error(error);
  });
});

module.exports = onRoomCreated;
