const { onValueCreated } = require("firebase-functions/v2/database");
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();
const priorClosing =
  process.env.FUNCTIONS_EMULATOR === "true"
    ? 360 * 1000 // 6 minutes
    : 3600 * 1000; // 1 hour

const updateRoomTimestamp = onValueCreated("/messages/{roomId}/*", (event) => {
  const roomId = event.params.roomId;
  const message = event.data.val();
  const ref = db.ref(`rooms/${roomId}`);

  ref
    .get()
    .then((snapshot) => {
      if (!snapshot.exists()) return;

      const room = snapshot.val();
      const filter0 = `${room.languageCode}-1970-01-01T00:00:00.000Z`;
      const filterZ = `${room.languageCode}-zzzz`;
      const params = {};

      params.updatedAt = message.createdAt;

      if (isRoomNew(room)) {
        params.createdAt = message.createdAt;
        params.filter = filter0;
        params.messageCount = 1;
      } else {
        // `ServerValue` doesn't work on localhost
        if (process.env.FUNCTIONS_EMULATOR === "true") {
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
});

const isRoomNew = (room) => {
  return room.filter.endsWith("-aaaa");
};

const isRoomClosed = (room, message) => {
  return room.filter.endsWith("-zzzz") || room.closedAt <= message.createdAt;
};

module.exports = updateRoomTimestamp;
