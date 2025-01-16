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
const cachedUsers: User[] = [];

export const onUserUpdated = onValueUpdated('/users/{userId}', async (event) => {
  const userId = event.params.userId;
  const userBefore = event.data.before.val();
  const user = event.data.after.val();

  if (userBefore.updatedAt === user.updatedAt) return;

  user.id = userId;

  try {
    await updateUserPriority(user);
    await updateCachedUsers(user);
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

const updateCachedUsers = async (user: User) => {
  if (cachedUsers.length === 0) {
    await fetchUsers();
    return;
  }

  const index = cachedUsers.findIndex((element) => element.id === user.id);

  if (index > -1) {
    cachedUsers.splice(index, 1);
  }

  cachedUsers.unshift({
    id: user.id,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
    languageCode: user.languageCode,
    photoURL: user.photoURL,
    displayName: user.displayName,
    description: user.description,
    gender: user.gender,
  });

  cachedUsers.splice(USER_LIMIT);
}

const fetchUsers = async () => {
  try {
    const usersRef = db.ref('users');
    const query = usersRef
      .orderByPriority()
      .endBefore(0)
      .limitToFirst(USER_LIMIT);

    const snapshot = await query.get();

    if (!snapshot.exists()) {
      return;
    }

    cachedUsers.splice(0);

    snapshot.forEach((child) => {
      const user = child.val();
      cachedUsers.push({
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
  } catch (error) {
    logger.error(error);
  }
};

// HTTP endpoint to get cached users
export const getCachedUsers = onCall(
  // { enforceAppCheck: false },
  async () => {
    if (cachedUsers.length === 0) {
      await fetchUsers();
    }
    return cachedUsers;
  }
);
