import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onValueUpdated } from 'firebase-functions/v2/database';
import { onCall } from 'firebase-functions/v2/https';
import { User } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const USER_LIMIT = 32;

let cachedUsers: User[];

export const onUserUpdated = onValueUpdated('/users/{userId}', async (event) => {
  const userId = event.params.userId;
  const user = event.data.after.val();

  try {
    await updateUserPriority(userId, user);
    await fetchUsers();
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

const isNew = (user: User) => {
  return !user.languageCode ||
    !user.photoURL ||
    !user.displayName ||
    !user.description ||
    !user.gender;
};

const fetchUsers = async () => {
  try {
    const now = Date.now();
    const tomorrow = now + 24 * 60 * 60 * 1000;
    const startAfter = -1 * tomorrow;

    // Fetch recent users
    const usersRef = db.ref('users');
    const query = usersRef
      .orderByPriority()
      .startAfter(startAfter)
      .endBefore(0)
      .limitToFirst(USER_LIMIT);

    const snapshot = await query.get();

    if (!snapshot.exists()) {
      return;
    }

    const users: User[] = [];
    snapshot.forEach((child) => {
      const user = child.val();
      users.push({
        id: child.key,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
        languageCode: user.languageCode,
        photoURL: user.photoURL,
        displayName: user.displayName,
        description: user.description,
        gender: user.gender,
      });
    });

    cachedUsers = users;
  } catch (error) {
    logger.error(error);
  }
};

// HTTP endpoint to get cached users
export const getCachedUsers = onCall(async () => {
  if (!cachedUsers) {
    await fetchUsers();
  }
  return cachedUsers;
});
