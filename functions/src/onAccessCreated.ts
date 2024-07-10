import { onValueCreated } from 'firebase-functions/v2/database';
import { logger } from 'firebase-functions';
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onAccessCreated = onValueCreated('/accesses/*/{roomId}', async (event) => {
  const roomId = event.params.roomId;
  const accessRef = db.ref(event.ref);
  const roomRef = db.ref(`rooms/${roomId}`);

  const snapshot = await roomRef.get();

  if (!snapshot.exists()) return;

  const room = snapshot.val();
  const now = new Date().getTime();
  const then = now - room.createdAt;
  const elapsed = new Date(then).toJSON();
  const filter = `${room.languageCode}-${elapsed}`;

  try {
    await roomRef.update({ filter });
    await accessRef.remove();
  } catch (error) {
    logger.error(error);
  }
});

export default onAccessCreated;
