import { onValueCreated } from 'firebase-functions/v2/database';
import { logger } from 'firebase-functions';
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

interface Params {
  filter?: string
}

const onExpireCreated = onValueCreated('/expires/*', async (event) => {
  const expires = event.data.val();
  const expireRef = db.ref(event.ref);
  const roomIds = Object.keys(expires);

  for (const roomId in roomIds) {
    await markOneRoom(roomId);
  }

  try {
    return await expireRef.remove();
  } catch (error) {
    logger.error(error);
  }
});

const markOneRoom = async (roomId: string) => {
  const roomRef = db.ref(`rooms/${roomId}`);
  const snapshot = await roomRef.get();

  if (!snapshot.exists()) return;

  const room = snapshot.val();
  const filterZ = '-zzzz';
  const params: Params = {};

  if (room.filter !== filterZ) {
    params.filter = filterZ;
  }

  try {
    await roomRef.update(params);
  } catch (error) {
    logger.error(error);
  }
};

export default onExpireCreated;
