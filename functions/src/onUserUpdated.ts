import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueUpdated } from 'firebase-functions/v2/database';
import { User } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}


const firestore = admin.firestore();
const USERS_COLLECTION = 'users';

const onUserUpdated = onValueUpdated('/users/{userId}', async (event) => {
  const userId = event.params.userId;

  const user: User = event.data.after.val();

  try {

    await updateUserCache(userId, user);

  } catch (error) {
    logger.error(error);
  }
});



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
      reportCount: user.reportCount ?? 0,
      role: user.role ?? null,
      followeeCount: user.followeeCount ?? null,
      followerCount: user.followerCount ?? null,
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
