const { onValueCreated } = require("firebase-functions/v2/database");
const { logger } = require("firebase-functions");
const { db } = require("./admin");

const markRoomExpired = onValueCreated("/expires/*", (event) => {
  const collection = event.data.val();
  const expireRef = db.ref(event.ref);

  let promise = Promise.resolve();

  Object.keys(collection).forEach((roomId) => {
    promise = promise.then(() => {
      const roomRef = db.ref(`rooms/${roomId}`);

      return roomRef.get().then((snapshot) => {
        if (!snapshot.exists()) return;

        const room = snapshot.val();
        const filterZ = `${room.languageCode}-zzzz`;
        const params = {};

        if (room.filter !== filterZ) {
          params.filter = filterZ;
        }

        roomRef.update(params);
      });
    });
  });

  promise = promise.then(() => {
    expireRef.remove();
  });

  promise = promise.catch((error) => {
    logger.error(error);
  });
});

module.exports = markRoomExpired;
