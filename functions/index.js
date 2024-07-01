const { onRequest } = require("firebase-functions/v2/https");
const { onValueCreated } = require("firebase-functions/v2/database");
const { logger } = require("firebase-functions");

const admin = require("firebase-admin");
admin.initializeApp();

exports.updateRoomUpdatedAt = onValueCreated(
  "/messages/{roomId}/*",
  (event) => {
    const roomId = event.params.roomId;
    const message = event.data.val();

    const db = admin.database();
    const ref = db.ref(`rooms/${roomId}`);

    ref
      .get()
      .then((snapshot) => {
        if (!snapshot.exists()) return;

        var room = snapshot.val();
        var roomLanguageCode = room.languageCode;
        var params = {};

        params.updatedAt = message.createdAt;

        if (isRoomNew(room)) {
          params.createdAt = message.createdAt;
          params.filter = `${roomLanguageCode}-1970-01-01T00:00:00.000Z`;
        }

        if (!isRoomOld(room, message)) {
          params.closedAt = message.createdAt + 360 * 1000; // TODO: 3600 * 1000
        }

        return params;
      })
      .then((params) => {
        ref.update(params);
      })
      .catch((error) => {
        logger.error(error);
      });
  },
);

function isRoomNew(room) {
  return room.updatedAt == 0;
}

function isRoomOld(room, message) {
  return room.closedAt > 0 && room.closedAt < message.createdAt;
}
