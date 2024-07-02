const { onValueCreated } = require("firebase-functions/v2/database");
const { logger } = require("firebase-functions");
const { db } = require("./admin");

const markRoomExpired = onValueCreated("/expires/*", (event) => {
  const expire = event.data.val();
  const roomId = expire.roomId;
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

module.exports = markRoomExpired;
