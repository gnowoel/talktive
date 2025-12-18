import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { User } from './types';
import { getRestrictionMultiplier } from './reputationUtils';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

const oneDay = 1 * 24 * 60 * 60 * 1000;
const twoWeeks = 14 * oneDay;

/**
 * Gets the restriction level based on revivedAt timestamp
 * Returns 'regular', 'alert', or 'warning'
 */
export const getRestrictionLevel = (revivedAt: number | null | undefined, now: number): string => {
  if (!revivedAt || revivedAt < now) return 'regular';
  if (revivedAt >= now + twoWeeks) return 'warning';
  return 'alert';
};

/**
 * Fetches a user from Firestore
 */
export const getUser = async (userId: string): Promise<User | null> => {
  try {
    const userRef = firestore.collection('users').doc(userId);
    const snapshot = await userRef.get();

    if (!snapshot.exists) return null;

    const user = snapshot.data() as User;
    return user;
  } catch (error) {
    logger.error(`Error fetching user ${userId}:`, error);
    return null;
  }
};

/**
 * Calculates the old revivedAt timestamp based on current time and user data
 */
export const getOldRevivedAt = (now: number, user: User) => {
  const start = now - 7 * oneDay;
  const oldRevivedAt = Math.max(user.revivedAt ?? 0, start);
  return oldRevivedAt;
};

/**
 * Calculates the new revivedAt timestamp based on reputation and restrictions
 */
export const getNewRevivedAt = async (now: number, oldRevivedAt: number, user: User) => {
  const start = now - 7 * oneDay;
  const penalty = Math.max(oldRevivedAt - start, oneDay);

  // Calculate restriction multiplier based on reputation score
  const restrictionMultiplier = getRestrictionMultiplier(user);
  const newRevivedAt = Math.max(oldRevivedAt, start) + penalty * restrictionMultiplier

  return Math.min(newRevivedAt, now + 21 * oneDay);
};

/**
 * Updates a user's revivedAt timestamp and increments their reportCount in Firestore
 */
export const updateUserRevivedAtAndReportCount = async (userId: string, revivedAt: number) => {
  try {
    const userRef = firestore.collection('users').doc(userId);

    await userRef.update({
      revivedAt,
      reportCount: admin.firestore.FieldValue.increment(1),
    });

    logger.info(`User ${userId} revivedAt and reportCount updated in Firestore`);
  } catch (error) {
    logger.error(`Error updating user ${userId} revivedAt and reportCount:`, error);
  }
};

/**
 * Applies moderation penalties to a user (updates revivedAt and reportCount)
 */
export const applyModerationPenalty = async (userId: string) => {
  try {
    const user = await getUser(userId);
    if (!user) {
      logger.error(`User not found: ${userId}`);
      return;
    }

    const now = new Date().getTime();
    const oldRevivedAt = getOldRevivedAt(now, user);
    const newRevivedAt = await getNewRevivedAt(now, oldRevivedAt, user);

    // Update the user's revivedAt and reportCount
    await updateUserRevivedAtAndReportCount(userId, newRevivedAt);

    const oldLevel = getRestrictionLevel(user.revivedAt, now);
    const newLevel = getRestrictionLevel(newRevivedAt, now);

    if (oldLevel !== newLevel) {
      logger.info(`Moderation penalty applied to user ${userId} - restriction level changed from ${oldLevel} to ${newLevel}`);
    } else {
      logger.info(`Moderation penalty applied to user ${userId} - restriction level unchanged (${oldLevel})`);
    }
  } catch (error) {
    logger.error(`Error applying moderation penalty to user ${userId}:`, error);
  }
};

