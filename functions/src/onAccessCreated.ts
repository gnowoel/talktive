import { onValueCreated } from 'firebase-functions/v2/database';
import { logger } from 'firebase-functions';
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onAccessCreated = onValueCreated('/accesses/*/{roomId}', (event) => {
  const roomId = event.params.roomId;
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

export default onAccessCreated;
