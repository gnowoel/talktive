import { onValueCreated } from 'firebase-functions/v2/database';
import { logger } from 'firebase-functions';
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onRoomCreated = onValueCreated('/rooms/*', (event) => {
  const room = event.data.val();
  const userId = room.userId;
  const userRef = db.ref(`users/${userId}`);
  const updatedAt = new Date().toJSON();
  const params = {
    filter: `perm-${updatedAt}`,
  };

  return userRef.update(params).catch((error) => {
    logger.error(error);
  });
});

export default onRoomCreated;
