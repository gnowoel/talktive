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
  const userBefore: User = event.data.before.val();
  const user: User = event.data.after.val();

  try {
    await updateUserPriority(userId, user, userBefore);
    await updateUserCache(userId, user);
  } catch (error) {
    logger.error(error);
  }
});

// TODO: Just a fallback, as we no longer use priority of a user in newer versions
const updateUserPriority = async (userId: string, user: User, userBefore: User) => {
  if (isNew(user)) return;
  if (user.updatedAt === userBefore.updatedAt) return;

  const userRef = db.ref(`users/${userId}`);
  const priority = -1 * user.updatedAt;

  await userRef.setPriority(priority, (error) => {
    if (error) {
      logger.error(error);
    }
  });
};

// TODO: Cache timestamps and execute no more than once per minute for a user
const updateUserCache = async (userId: string, user: User) => {
  if (isNew(user)) return;

  try {
    // Exclude the unnecessary `fcmToken` to save some space
    const userData = {
      id: userId,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      languageCode: user.languageCode ?? null,
      photoURL: user.photoURL ?? null,
      displayName: user.displayName ?? null,
      description: user.description ?? null,
      gender: user.gender ?? null,
      revivedAt: user.revivedAt ?? 0, // For easy querying with Cloud Firestore
      messageCount: user.messageCount ?? 0,
    };

    const userRef = firestore.collection(USERS_COLLECTION).doc(userId);
    await userRef.set(userData, { merge: true });
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
