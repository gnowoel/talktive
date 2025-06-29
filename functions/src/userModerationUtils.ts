import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { User } from './types';
import { isDebugMode } from './helpers';
import { getRestrictionMultiplier } from './reputationUtils';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const oneDay = 1 * 24 * 60 * 60 * 1000;

/**
 * Fetches a user from the Realtime Database
 */
export const getUser = async (userId: string): Promise<User | null> => {
  const userRef = db.ref(`users/${userId}`);
  const snapshot = await userRef.get();

  if (!snapshot.exists()) return null;

  const user: User = snapshot.val();
  return user;
};

/**
 * Calculates the old revivedAt timestamp based on current time and user data
 */
export const getOldRevivedAt = (now: number, user: User) => {
  const then = now - 7 * oneDay;
  const oldRevivedAt = Math.max(user.revivedAt ?? 0, then);
  return oldRevivedAt;
};

/**
 * Calculates the new revivedAt timestamp based on reputation and restrictions
 */
export const getNewRevivedAt = async (now: number, oldRevivedAt: number, user: User) => {
  const then = now - 7 * oneDay;
  const remaining = oldRevivedAt - then;

  let days = Math.ceil(remaining / oneDay);
  if (days < 1) days = 1;

  // Calculate restriction multiplier based on reputation score
  const restrictionMultiplier = getRestrictionMultiplier(user);
  days = Math.max(Math.ceil(days * restrictionMultiplier), 1);

  const newRevivedAt = oldRevivedAt + days * oneDay;
  return Math.min(newRevivedAt, now + 21 * oneDay);
};

/**
 * Updates a user's revivedAt timestamp and increments their reportCount
 */
export const updateUserRevivedAtAndReportCount = async (userId: string, revivedAt: number) => {
  try {
    const userRef = db.ref(`users/${userId}`);

    // `ServerValue` doesn't work with Emulators Suite
    if (isDebugMode()) {
      // Get current user data to manually increment reportCount
      const userSnapshot = await userRef.get();
      const currentUser = userSnapshot.val();
      const currentReportCount = currentUser?.reportCount || 0;

      await userRef.update({
        revivedAt,
        reportCount: currentReportCount + 1,
      });
    } else {
      // Update revivedAt and increment reportCount atomically
      await userRef.update({
        revivedAt,
        reportCount: admin.database.ServerValue.increment(1),
      });
    }

    logger.info(`User ${userId} revivedAt and reportCount updated`);
  } catch (error) {
    logger.error(`Error updating user ${userId} revivedAt and reportCount:`, error);
  }
};

/**
 * Updates all partner chats with the new revivedAt timestamp
 */
export const updatePartnerChatsRevivedAt = async (userId: string, revivedAt: number) => {
  try {
    // Get all chat IDs where this user is a partner
    const userChatsRef = db.ref(`chats/${userId}`);
    const snapshot = await userChatsRef.get();

    if (!snapshot.exists()) return;

    const chatIds = Object.keys(snapshot.val());

    // Update each chat's partner revivedAt for all other users
    const updatePromises = chatIds.map(async (chatId) => {
      const partnerId = chatId.replace(userId, '');
      await updateChatPartnerRevivedAt(partnerId, chatId, revivedAt);
    });

    await Promise.all(updatePromises);
  } catch (error) {
    logger.error('Error updating partner chats revivedAt:', error);
  }
};

/**
 * Updates a specific chat's partner revivedAt timestamp
 */
export const updateChatPartnerRevivedAt = async (
  userId: string,
  chatId: string,
  revivedAt: number
): Promise<void> => {
  const chatRef = db.ref(`chats/${userId}/${chatId}`);

  try {
    const snapshot = await chatRef.get();
    if (!snapshot.exists()) return;

    await chatRef.child('partner').update({ revivedAt });
  } catch (error) {
    logger.error(`Error updating chat ${chatId} for user ${userId}:`, error);
  }
};

/**
 * Applies moderation penalties to a user (updates revivedAt and reportCount, updates partner chats)
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

    // Update all chats where this user is a partner
    await updatePartnerChatsRevivedAt(userId, newRevivedAt);

    logger.info(`Moderation penalty applied to user ${userId}`);
  } catch (error) {
    logger.error(`Error applying moderation penalty to user ${userId}:`, error);
  }
};
