import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import * as functions from 'firebase-functions/v1';
import { StatParams } from './types';
import { formatDate, isDebugMode } from './helpers';

if (!admin.apps.length) {
  admin.initializeApp();
}

interface User {
  uid: string
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
  const statRef = db.ref(`stats/${formatDate(now)}`);
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
