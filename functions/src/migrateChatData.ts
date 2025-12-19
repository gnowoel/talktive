import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onRequest } from 'firebase-functions/v2/https';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

interface MigrationStats {
  pairsScanned: number;
  pairsFixed: number;
  chatsScanned: number;
  chatsFixed: number;
  errors: number;
  startTime: number;
  endTime?: number;
}

interface PairData {
  lastMessageContent?: string | null;
  followers?: [string, string];
  createdAt?: number;
  updatedAt?: number;
  messageCount?: number;
  firstUserId?: string | null;
  v2?: boolean;
  [key: string]: unknown;
}

interface ChatData {
  lastMessageContent?: string | null;
  partner?: Record<string, unknown>;
  createdAt?: number;
  updatedAt?: number;
  messageCount?: number;
  readMessageCount?: number;
  firstUserId?: string | null;
  mute?: boolean;
  reported?: boolean;
  [key: string]: unknown;
}

const migrateChatData = onRequest(
  {
    timeoutSeconds: 540, // 9 minutes
    memory: '1GiB',
    cors: true,
  },
  async (request, response) => {
    const stats: MigrationStats = {
      pairsScanned: 0,
      pairsFixed: 0,
      chatsScanned: 0,
      chatsFixed: 0,
      errors: 0,
      startTime: Date.now(),
    };

    try {
      logger.info('Starting chat data migration...');

      // Migrate pairs first
      await migratePairs(stats);

      // Then migrate chats
      await migrateChats(stats);

      stats.endTime = Date.now();
      const duration = ((stats.endTime - stats.startTime) / 1000).toFixed(2);

      logger.info('Migration completed successfully', {
        stats,
        durationSeconds: duration,
      });

      response.status(200).json({
        success: true,
        message: 'Migration completed successfully',
        stats,
        durationSeconds: duration,
      });
    } catch (error) {
      stats.endTime = Date.now();
      const duration = ((stats.endTime - stats.startTime) / 1000).toFixed(2);

      logger.error('Migration failed', {
        error: error instanceof Error ? error.message : String(error),
        stats,
        durationSeconds: duration,
      });

      response.status(500).json({
        success: false,
        message: 'Migration failed',
        error: error instanceof Error ? error.message : String(error),
        stats,
        durationSeconds: duration,
      });
    }
  }
);

async function migratePairs(stats: MigrationStats): Promise<void> {
  logger.info('Starting pairs migration...');

  const pairsRef = db.ref('pairs');
  const snapshot = await pairsRef.get();

  if (!snapshot.exists()) {
    logger.info('No pairs found to migrate');
    return;
  }

  const pairs = snapshot.val() as Record<string, PairData>;
  const pairIds = Object.keys(pairs);
  const batchSize = 50;

  for (let i = 0; i < pairIds.length; i += batchSize) {
    const batch = pairIds.slice(i, i + batchSize);
    await processPairBatch(batch, pairs, stats);

    // Log progress every 10 batches
    if ((i / batchSize) % 10 === 0) {
      logger.info(`Pairs progress: ${stats.pairsScanned}/${pairIds.length} scanned, ${stats.pairsFixed} fixed`);
    }
  }

  logger.info(`Pairs migration completed: ${stats.pairsScanned} scanned, ${stats.pairsFixed} fixed`);
}

async function processPairBatch(pairIds: string[], pairs: Record<string, PairData>, stats: MigrationStats): Promise<void> {
  const updates: { [key: string]: null } = {};

  for (const pairId of pairIds) {
    try {
      const pair: PairData = pairs[pairId];
      stats.pairsScanned++;

      // Check if lastMessageContent is undefined
      if (Object.prototype.hasOwnProperty.call(pair, 'lastMessageContent') && pair.lastMessageContent === undefined) {
        updates[`pairs/${pairId}/lastMessageContent`] = null;
        stats.pairsFixed++;
      }
    } catch (error) {
      stats.errors++;
      logger.error(`Error processing pair ${pairId}:`, error);
    }
  }

  // Apply updates in batch
  if (Object.keys(updates).length > 0) {
    try {
      await db.ref().update(updates);
      logger.info(`Applied ${Object.keys(updates).length} pair updates`);
    } catch (error) {
      stats.errors++;
      logger.error('Error applying pair updates:', error);
    }
  }
}

async function migrateChats(stats: MigrationStats): Promise<void> {
  logger.info('Starting chats migration...');

  const chatsRef = db.ref('chats');
  const snapshot = await chatsRef.get();

  if (!snapshot.exists()) {
    logger.info('No chats found to migrate');
    return;
  }

  const chats = snapshot.val() as Record<string, Record<string, ChatData>>;
  const userIds = Object.keys(chats);

  for (const userId of userIds) {
    try {
      await migrateUserChats(userId, chats[userId], stats);

      // Log progress every 100 users
      if (stats.chatsScanned % 1000 === 0) {
        logger.info(`Chats progress: ${stats.chatsScanned} scanned, ${stats.chatsFixed} fixed`);
      }
    } catch (error) {
      stats.errors++;
      logger.error(`Error migrating chats for user ${userId}:`, error);
    }
  }

  logger.info(`Chats migration completed: ${stats.chatsScanned} scanned, ${stats.chatsFixed} fixed`);
}

async function migrateUserChats(userId: string, userChats: Record<string, ChatData>, stats: MigrationStats): Promise<void> {
  const chatIds = Object.keys(userChats);
  const batchSize = 25;

  for (let i = 0; i < chatIds.length; i += batchSize) {
    const batch = chatIds.slice(i, i + batchSize);
    await processChatBatch(userId, batch, userChats, stats);
  }
}

async function processChatBatch(userId: string, chatIds: string[], userChats: Record<string, ChatData>, stats: MigrationStats): Promise<void> {
  const updates: { [key: string]: null } = {};

  for (const chatId of chatIds) {
    try {
      const chat: ChatData = userChats[chatId];
      stats.chatsScanned++;

      // Check if lastMessageContent is undefined
      if (Object.prototype.hasOwnProperty.call(chat, 'lastMessageContent') && chat.lastMessageContent === undefined) {
        updates[`chats/${userId}/${chatId}/lastMessageContent`] = null;
        stats.chatsFixed++;
      }
    } catch (error) {
      stats.errors++;
      logger.error(`Error processing chat ${userId}/${chatId}:`, error);
    }
  }

  // Apply updates in batch
  if (Object.keys(updates).length > 0) {
    try {
      await db.ref().update(updates);
      logger.info(`Applied ${Object.keys(updates).length} chat updates for user ${userId}`);
    } catch (error) {
      stats.errors++;
      logger.error(`Error applying chat updates for user ${userId}:`, error);
    }
  }
}

export default migrateChatData;
