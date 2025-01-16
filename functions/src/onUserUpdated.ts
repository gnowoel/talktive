import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueUpdated } from 'firebase-functions/v2/database';
import { User } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onUserUpdated = onValueUpdated('/users/{userId}', async (event) => {
  const userId = event.params.userId;
  const user = event.data.after.val();

  user.id = userId;

  try {
    await updateUserPriority(user);
  } catch (error) {
    logger.error(error);
  }
});

const updateUserPriority = async (user: User) => {
  if (isNew(user)) return;

  const userRef = db.ref(`users/${user.id}`);

  const priority = -1 * user.updatedAt;

  await userRef.setPriority(priority, (error) => {
    if (error) {
      logger.error(error);
    }
  });
};

const isNew = (user: User) => {
  return !user.languageCode ||
    !user.photoURL ||
    !user.displayName ||
    !user.description ||
    !user.gender;
};

export default onUserUpdated;
