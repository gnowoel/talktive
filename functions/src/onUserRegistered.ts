import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import * as functions from 'firebase-functions/v1';
import { getDate, getMonth, getYear, isDebugMode } from './helpers';

if (!admin.apps.length) {
  admin.initializeApp();
}

interface User {
  uid: string
}

interface StatParams {
  users?: number | object
  rooms?: number | object
  messages?: number | object
}

const db = admin.database();

const onUserRegistered = functions.auth.user().onCreate(async (user) => {
  const now = new Date();

  try {
    await copyUser(user, now);
    await updateUserStats(now);
  } catch (error) {
    logger.error(error);
  }
});

const copyUser = async (user: User, now: Date) => {
  const userId = user.uid;
  const userRef = db.ref(`users/${userId}`);
  const createdAt = now.toJSON();
  const filter = `temp-${createdAt}`;

  try {
    await userRef.set({ filter });
  } catch (error) {
    logger.error(error);
  }
};

const updateUserStats = async (now: Date) => {
  const year = getYear(now);
  const month = getMonth(now);
  const date = getDate(now);
  const statRef = db.ref(`stats/${year}/${month}/${date}`);

  const snapshot = await statRef.get();

  if (!snapshot.exists()) return;

  const stat = snapshot.val();
  const params: StatParams = {};

  // `ServerValue` doesn't work with Emulators Suite
  if (isDebugMode()) {
    params.users = stat.users + 1;
  } else {
    params.users = admin.database.ServerValue.increment(1);
  }

  try {
    await statRef.update(params);
  } catch (error) {
    logger.error(error);
  }
};

export default onUserRegistered;
