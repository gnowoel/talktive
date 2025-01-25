import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';

if (!admin.apps.length) {
  admin.initializeApp();
}

const onFirestoreUserCreated = onDocumentCreated('users/{userId}', async (event) => {
  const snapshot = event.data;

  if (!snapshot) {
    logger.warn('No data associated with the event');
    return;
  }

  const userData = snapshot.data();

  if (!userData?.createdAt) {
    try {
      await snapshot.ref.delete();
      logger.info(`Deleted user document ${snapshot.id} because it was missing createdAt field`);
    } catch (error) {
      logger.error('Error deleting user document:', error);
    }
  }
});

export default onFirestoreUserCreated;
