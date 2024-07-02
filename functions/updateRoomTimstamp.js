const { onValueCreated } = require("firebase-functions/v2/database");
const { logger } = require("firebase-functions");
const { db } = require("./admin");

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
});

function isRoomNew(room) {
  return room.filter.endsWith("-aaaa");
}

function isRoomOld(room, message) {
  return room.filter.endsWith("-zzzz") || room.closedAt <= message.createdAt;
}

module.exports = updateRoomTimestamp;
