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
    await updatePartnerDataInChats(userId, user, userBefore);
    await handleUserAutoRelisting(userId, user, userBefore);
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
      reportCount: user.reportCount ?? 0,
      role: user.role ?? null,
      followeeCount: user.followeeCount ?? null,
      followerCount: user.followerCount ?? null,
      isPublic: user.isPublic ?? true, // Default to public for backward compatibility
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

const updatePartnerDataInChats = async (userId: string, user: User, userBefore: User) => {
  // Only update if partner-relevant fields have changed
  if (!hasPartnerRelevantFieldsChanged(user, userBefore)) {
    return;
  }

  // Skip if user is still incomplete
  if (isNew(user)) {
    logger.info(`Skipping partner data update for incomplete user ${userId}`);
    return;
  }

  try {
    // Get all chat IDs where this user is a partner
    const chatIds = await getUserChatIds(userId);

    if (chatIds.length === 0) {
      logger.info(`No chats found for user ${userId} to update partner data`);
      return;
    }

    // Create updated partner data
    const updatedPartnerData = createPartnerData(user);

    // Create batch updates for all chats where this user is a partner
    const updates: { [key: string]: ReturnType<typeof createPartnerData> } = {};

    for (const chatId of chatIds) {
      // Extract the other user's ID from the chat ID
      const otherUserId = chatId.replace(userId, '');

      // Update the partner data in the other user's chat
      updates[`chats/${otherUserId}/${chatId}/partner`] = updatedPartnerData;
    }

    // Apply all updates
    if (Object.keys(updates).length > 0) {
      await db.ref().update(updates);
      logger.info(`Updated partner data for user ${userId} in ${Object.keys(updates).length} chats`);
    }
  } catch (error) {
    logger.error(`Error updating partner data for user ${userId}:`, error);
  }
};

const hasPartnerRelevantFieldsChanged = (user: User, userBefore: User): boolean => {
  return user.displayName !== userBefore.displayName ||
    user.photoURL !== userBefore.photoURL ||
    user.gender !== userBefore.gender ||
    user.languageCode !== userBefore.languageCode ||
    user.description !== userBefore.description ||
    user.messageCount !== userBefore.messageCount ||
    user.revivedAt !== userBefore.revivedAt;
};

const getUserChatIds = async (userId: string): Promise<string[]> => {
  try {
    const userChatsRef = db.ref(`chats/${userId}`);
    const snapshot = await userChatsRef.get();

    if (!snapshot.exists()) {
      return [];
    }

    const chatIds = Object.keys(snapshot.val());
    return chatIds;
  } catch (error) {
    logger.error(`Error fetching chat IDs for user ${userId}:`, error);
    return [];
  }
};

const createPartnerData = (user: User) => {
  return {
    createdAt: user.createdAt,
    updatedAt: user.updatedAt || 0,
    languageCode: user.languageCode ?? null,
    photoURL: user.photoURL ?? null,
    displayName: user.displayName ?? null,
    description: user.description || '', // To save space
    gender: user.gender ?? null,
    revivedAt: user.revivedAt ?? null,
    messageCount: user.messageCount ?? null,
  };
};

const handleUserAutoRelisting = async (userId: string, user: User, userBefore: User) => {
  // Skip if user is still incomplete
  if (isNew(user)) {
    return;
  }

  // Check if the only change was isPublic (to prevent infinite loops)
  const isPublicChanged = user.isPublic !== userBefore.isPublic;
  const descriptionChanged = user.description !== userBefore.description;

  // Skip if only isPublic changed (this happens during auto-relisting)
  if (isPublicChanged && !descriptionChanged) {
    return;
  }

  // Check if description has changed and user was previously unlisted
  const wasUnlisted = userBefore.isPublic === false;
  const isCurrentlyUnlisted = user.isPublic === false;

  if (descriptionChanged && (wasUnlisted || isCurrentlyUnlisted)) {
    try {
      // Auto-relist the user by setting isPublic to true
      const userRef = db.ref(`users/${userId}`);
      await userRef.update({ isPublic: true });

      logger.info(`Auto-relisted user ${userId} after description change`);
    } catch (error) {
      logger.error(`Error auto-relisting user ${userId}:`, error);
    }
  }
};

export default onUserUpdated;
