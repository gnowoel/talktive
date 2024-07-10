import * as functions from 'firebase-functions/v1';
import { logger } from 'firebase-functions';
import * as admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onUserRegistered = functions.auth.user().onCreate(async (user) => {
  const userId = user.uid;
  const userRef = db.ref(`users/${userId}`);
  const createdAt = new Date().toJSON();
  const filter = `temp-${createdAt}`;

  try {
    await userRef.set({ filter });
  } catch (error) {
    logger.error(error);
  }
});

export default onUserRegistered;
