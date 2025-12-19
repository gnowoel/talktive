import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onRequest } from 'firebase-functions/v2/https';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

interface FixPartnerDataStats {
  chatsScanned: number;
  incompletePartnersFound: number;
  partnersFixed: number;
  partnersStillIncomplete: number;
  userLookupErrors: number;
  updateErrors: number;
  usersProcessed: number;
  totalUsers: number;
  startTime: number;
  endTime?: number;
}

interface ChatData {
  partner?: PartnerData;
  createdAt?: number;
  updatedAt?: number;
  messageCount?: number;
  readMessageCount?: number;
  firstUserId?: string | null;
  lastMessageContent?: string | null;
  mute?: boolean;
  [key: string]: unknown;
}

interface PartnerData {
  createdAt?: number;
  updatedAt?: number;
  languageCode?: string | null;
  photoURL?: string | null;
  displayName?: string | null;
  description?: string;
  gender?: string | null;
  revivedAt?: number | null;
  messageCount?: number | null;
  [key: string]: unknown;
}

interface UserData {
  createdAt: number;
  updatedAt: number;
  languageCode?: string | null;
  photoURL?: string | null;
  displayName?: string | null;
  description?: string;
  gender?: string | null;
  revivedAt?: number | null;
  messageCount?: number | null;
  [key: string]: unknown;
}

const fixPartnerData = onRequest(
  {
    timeoutSeconds: 540, // 9 minutes
    memory: '2GiB',
    cors: true,
  },
  async (request, response) => {
    const stats: FixPartnerDataStats = {
      chatsScanned: 0,
      incompletePartnersFound: 0,
      partnersFixed: 0,
      partnersStillIncomplete: 0,
      userLookupErrors: 0,
      updateErrors: 0,
      usersProcessed: 0,
      totalUsers: 0,
      startTime: Date.now(),
    };

    try {
      logger.info('Starting partner data fix...');

      // Process all chats to fix incomplete partner data
      await processAllChats(stats);

      stats.endTime = Date.now();
      const duration = ((stats.endTime - stats.startTime) / 1000).toFixed(2);

      logger.info('Partner data fix completed successfully', {
        stats,
        durationSeconds: duration,
      });

      response.status(200).json({
        success: true,
        message: 'Partner data fix completed successfully',
        stats,
        durationSeconds: duration,
      });
    } catch (error) {
      stats.endTime = Date.now();
      const duration = ((stats.endTime - stats.startTime) / 1000).toFixed(2);

      logger.error('Partner data fix failed', {
        error: error instanceof Error ? error.message : String(error),
        stats,
        durationSeconds: duration,
      });

      response.status(500).json({
        success: false,
        message: 'Partner data fix failed',
        error: error instanceof Error ? error.message : String(error),
        stats,
        durationSeconds: duration,
      });
    }
  }
);

async function processAllChats(stats: FixPartnerDataStats): Promise<void> {
  logger.info('Starting to process all chats...');

  const chatsRef = db.ref('chats');
  const snapshot = await chatsRef.get();

  if (!snapshot.exists()) {
    logger.info('No chats found to process');
    return;
  }

  const chats = snapshot.val() as Record<string, Record<string, ChatData>>;
  const userIds = Object.keys(chats);
  stats.totalUsers = userIds.length;

  logger.info(`Found ${userIds.length} users with chats to process`);

  // Process users in batches to avoid memory issues
  const batchSize = 10;
  for (let i = 0; i < userIds.length; i += batchSize) {
    const batch = userIds.slice(i, i + batchSize);
    await processUserBatch(batch, chats, stats);

    // Log progress every 10 batches
    if ((i / batchSize) % 10 === 0) {
      logger.info(`Progress: ${stats.usersProcessed}/${stats.totalUsers} users processed, ${stats.partnersFixed} partners fixed`);
    }
  }

  logger.info(`Partner data fix completed: ${stats.chatsScanned} chats scanned, ${stats.partnersFixed} partners fixed`);
}

async function processUserBatch(
  userIds: string[],
  allChats: Record<string, Record<string, ChatData>>,
  stats: FixPartnerDataStats
): Promise<void> {
  const updates: { [key: string]: PartnerData } = {};

  for (const userId of userIds) {
    try {
      const userChats = allChats[userId];
      if (!userChats) continue;

      const chatIds = Object.keys(userChats);
      for (const chatId of chatIds) {
        const chat = userChats[chatId];
        stats.chatsScanned++;

        if (!chat.partner) continue;

        const isIncomplete = isPartnerIncomplete(chat.partner);
        if (isIncomplete) {
          stats.incompletePartnersFound++;

          // Extract partner ID from chat ID
          const partnerId = chatId.replace(userId, '');

          try {
            // Get complete user data for the partner
            const completeUserData = await getUserData(partnerId);
            if (completeUserData) {
              // Create updated partner data
              const updatedPartner = createCompletePartnerData(completeUserData);

              // Check if the updated partner is now complete
              if (!isPartnerIncomplete(updatedPartner)) {
                updates[`chats/${userId}/${chatId}/partner`] = updatedPartner;
                stats.partnersFixed++;
              } else {
                stats.partnersStillIncomplete++;
                logger.warn(`Partner ${partnerId} still incomplete after lookup`, {
                  userId,
                  chatId,
                  partnerId,
                  partnerData: updatedPartner
                });
              }
            } else {
              stats.userLookupErrors++;
              logger.warn(`Could not find user data for partner ${partnerId}`, {
                userId,
                chatId,
                partnerId
              });
            }
          } catch (error) {
            stats.userLookupErrors++;
            logger.error(`Error looking up partner ${partnerId}:`, error);
          }
        }
      }

      stats.usersProcessed++;
    } catch (error) {
      stats.updateErrors++;
      logger.error(`Error processing user ${userId}:`, error);
    }
  }

  // Apply updates in batch
  if (Object.keys(updates).length > 0) {
    try {
      await db.ref().update(updates);
      logger.info(`Applied ${Object.keys(updates).length} partner updates`);
    } catch (error) {
      stats.updateErrors++;
      logger.error('Error applying partner updates:', error);
    }
  }
}

function isPartnerIncomplete(partner: PartnerData): boolean {
  // Check if any required fields are missing or null
  return !partner.displayName ||
    !partner.gender ||
    !partner.languageCode ||
    !partner.photoURL;
}

async function getUserData(userId: string): Promise<UserData | null> {
  try {
    const userRef = db.ref(`users/${userId}`);
    const snapshot = await userRef.get();

    if (!snapshot.exists()) {
      return null;
    }

    return snapshot.val() as UserData;
  } catch (error) {
    logger.error(`Error fetching user data for ${userId}:`, error);
    return null;
  }
}

function createCompletePartnerData(userData: UserData): PartnerData {
  return {
    createdAt: userData.createdAt,
    updatedAt: userData.updatedAt || 0,
    languageCode: userData.languageCode ?? null,
    photoURL: userData.photoURL ?? null,
    displayName: userData.displayName ?? null,
    description: userData.description || '', // To save space
    gender: userData.gender ?? null,
    revivedAt: userData.revivedAt ?? null,
    messageCount: userData.messageCount ?? null,
  };
}

export default fixPartnerData;
