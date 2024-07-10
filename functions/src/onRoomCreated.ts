import { onValueCreated } from 'firebase-functions/v2/database';
import { logger } from 'firebase-functions';
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onRoomCreated = onValueCreated('/rooms/*', async (event) => {
  const room = event.data.val();
  const userId = room.userId;
  const userRef = db.ref(`users/${userId}`);
  const updatedAt = new Date().toJSON();
  const filter = `perm-${updatedAt}`;

  try {
    await userRef.update({ filter });
  } catch (error) {
    logger.error(error);
  }
});

export default onRoomCreated;
