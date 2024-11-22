import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueUpdated } from 'firebase-functions/v2/database';

if (!admin.apps.length) {
  admin.initializeApp();
}

const onUserUpdated = onValueUpdated('/users/{userId}', async (event) => {
  const userId = event.params.userId;
  logger.info(userId);
});

export default onUserUpdated;
