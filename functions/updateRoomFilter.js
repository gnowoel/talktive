const { onValueCreated } = require("firebase-functions/v2/database");
const { logger } = require("firebase-functions");
const { db } = require("./admin");

const updateRoomFilter = onValueCreated("/accesses/*", (event) => {
  const access = event.data.val();
  const roomId = access.roomId;
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

module.exports = updateRoomFilter;
