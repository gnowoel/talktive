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
        const filter0 = `${room.languageCode}-1970-01-01T00:00:00.000Z`;
        const filterZ = `${room.languageCode}-zzzz`;
        const params = {};

        params.updatedAt = message.createdAt;

        if (isRoomNew(room)) {
          params.createdAt = message.createdAt;
          params.filter = filter0;
        }

        if (!isRoomOld(room, message)) {
          params.closedAt = message.createdAt + 360 * 1000; // TODO: 3600 * 1000
        } else {
          if (room.filter !== filterZ) {
            params.filter = filterZ;
          }
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
      const filterZ = `${room.languageCode}-zzzz`;
      const params = {};

      if (room.filter !== filterZ) {
        params.filter = filterZ;
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
      const timeElapsed = new Date(diff).toJSON();

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
