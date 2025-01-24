import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueUpdated } from 'firebase-functions/v2/database';
import { User } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();
const firestore = admin.firestore();
const USERS_COLLECTION = 'users';

const onUserUpdated = onValueUpdated('/users/{userId}', async (event) => {
  const userId = event.params.userId;
  const userBefore = event.data.before.val();
  const user = event.data.after.val();

  if (user.updatedAt == userBefore.updatedAt) return;

  try {
    await updateUserPriority(userId, user);
    await updateUserCache(userId, user);
  } catch (error) {
    logger.error(error);
  }
});

const updateUserPriority = async (userId: string, user: User) => {
  if (isNew(user)) return;

  const userRef = db.ref(`users/${userId}`);

  const priority = -1 * user.updatedAt;

  await userRef.setPriority(priority, (error) => {
    if (error) {
      logger.error(error);
    }
  });
};

const updateUserCache = async (userId: string, user: User) => {
  if (isNew(user)) return;

  try {
    const userRef = firestore.collection(USERS_COLLECTION).doc(userId);
    await userRef.set({
      id: userId,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      languageCode: user.languageCode,
      photoURL: user.photoURL,
      displayName: user.displayName,
      description: user.description,
      gender: user.gender,
      revivedAt: user.revivedAt,
    }, { merge: true });
  } catch (error) {
    logger.error('Error updating user cache:', error);
  }
}

const isNew = (user: User) => {
  return !user.languageCode ||
    !user.photoURL ||
    !user.displayName ||
    !user.description ||
    !user.gender;
};

export default onUserUpdated;
