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

        const room = snapshot.val();
        const roomLanguageCode = room.languageCode;
        const params = {};

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

exports.markRoomExpired = onValueCreated("/expires/*", (event) => {
  const expire = event.data.val();
  const roomId = expire.roomId;

  const db = admin.database();
  const expireRef = db.ref(event.ref);
  const roomRef = db.ref(`rooms/${roomId}`);

  roomRef
    .get()
    .then((snapshot) => {
      if (!snapshot.exists()) return;

      const room = snapshot.val();
      const filter = `${room.languageCode}-zzzz`;
      const params = {};

      if (room.filter !== filter) {
        params.filter = filter;
      }

      roomRef.update(params);
    })
    .then(() => {
      expireRef.remove();
    })
    .catch((error) => {
      logger.error(error);
    });
});

exports.updateRoomFilter = onValueCreated("/accesses/*", (event) => {
  const access = event.data.val();
  const roomId = access.roomId;

  const db = admin.database();
  const accessRef = db.ref(event.ref);
  const roomRef = db.ref(`rooms/${roomId}`);

  roomRef
    .get()
    .then((snapshot) => {
      if (!snapshot.exists()) return;

      const room = snapshot.val();
      const now = new Date().getTime();
      const diff = now - room.createdAt;
      const timeElapsed =
        diff < 0 ? new Date(0).toJSON() : new Date(diff).toJSON();

      roomRef.update({
        filter: `${room.languageCode}-${timeElapsed}`,
      });
    })
    .then(() => {
      accessRef.remove();
    })
    .catch((error) => {
      logger.error(error);
    });
});

function isRoomNew(room) {
  return room.filter.endsWith("-aaaa");
}

function isRoomOld(room, message) {
  return room.filter.endsWith("-zzzz") || room.closedAt <= message.createdAt;
}
