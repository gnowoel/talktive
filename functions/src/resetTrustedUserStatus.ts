import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onRequest } from 'firebase-functions/v2/https';
import { User } from './types';
import { calculateReputationScore, getReputationLevel, REPUTATION_THRESHOLDS } from './reputationUtils';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

/**
 * Reset status for trusted users who have good reputation
 * This function can be triggered via HTTP requests (curl) and processes users in batches
 */
export const resetTrustedUserStatus = onRequest(
  // { memory: '1GiB', timeoutSeconds: 540 },
  async (req, res) => {
    try {
      // Only allow POST requests
      if (req.method !== 'POST') {
        res.status(405).json({ error: 'Method not allowed. Use POST.' });
        return;
      }

      // Simple authentication check - set ADMIN_TOKEN in your environment
      const authToken = req.headers.authorization?.replace('Bearer ', '') || req.body.authToken;
      if (!authToken || authToken !== process.env.ADMIN_TOKEN) {
        res.status(401).json({ error: 'Unauthorized. Invalid or missing auth token.' });
        return;
      }

      logger.info('Starting trusted user status reset process for active users with completed profiles...');

      const batchSize = parseInt(req.body.batchSize) || 100; // Default batch size
      const dryRun = req.body.dryRun === 'true' || req.body.dryRun === true;

      // Calculate cutoff for recent activity (3 weeks = 21 days)
      const threeWeeksAgo = Date.now() - (21 * 24 * 60 * 60 * 1000);

      logger.info(`Configuration: batchSize=${batchSize}, dryRun=${dryRun}, activityCutoff=${new Date(threeWeeksAgo).toISOString()}`);

      const usersRef = db.ref('users');

      let processedCount = 0;
      let resetCount = 0;
      const resetUsers: Array<{ userId: string, reputationLevel: string, reputationScore: number }> = [];
      const errors: Array<{ userId: string, error: string }> = [];

      // Process users in database-level batches to prevent memory overflow
      // Query by updatedAt first (recent activity), then filter by completed profiles in code
      let lastKey: string | null = null;
      let lastUpdatedAt: number | null = null;
      let hasMoreUsers = true;
      let batchNumber = 0;
      let totalFetched = 0;
      let skippedIncomplete = 0;

      logger.info('Starting database-level batch processing for recently active users...');

      while (hasMoreUsers) {
        batchNumber++;
        logger.info(`Processing database batch ${batchNumber} (batch size: ${batchSize}), lastKey: ${lastKey}`);

        // Create query for users active within last 3 weeks, ordered by updatedAt
        let query = usersRef.orderByChild('updatedAt').startAt(threeWeeksAgo).limitToFirst(batchSize + 1); // Get one extra to check if there are more
        if (lastUpdatedAt !== null && lastKey) {
          query = query.startAt(threeWeeksAgo, lastKey);
        }

        const snapshot = await query.once('value');

        if (!snapshot.exists()) {
          logger.info(`No more users found in batch ${batchNumber}`);
          hasMoreUsers = false;
          break;
        }

        const allBatchUsers = snapshot.val();
        let batchUsers = allBatchUsers;
        let batchUserIds = Object.keys(allBatchUsers);

        // If this is not the first batch, skip the first user (as it's the lastKey from previous batch)
        if (lastKey && batchUserIds.length > 0 && batchUserIds[0] === lastKey) {
          batchUserIds.shift(); // Remove first element
          const { [lastKey]: _removed, ...remainingUsers } = batchUsers;
          batchUsers = remainingUsers;
        }

        // Check if we have more users after this batch
        if (batchUserIds.length > batchSize) {
          // We have more users, so we'll continue after this batch
          hasMoreUsers = true;
          // Remove the extra user from processing but keep it as indicator
          const extraUserId = batchUserIds.pop();
          if (extraUserId) {
            const { [extraUserId]: _removed, ...limitedUsers } = batchUsers;
            batchUsers = limitedUsers;
          }
        } else if (batchUserIds.length === 0) {
          // No users to process in this batch
          logger.info(`No new users in batch ${batchNumber}, ending pagination`);
          hasMoreUsers = false;
          break;
        } else {
          // This is the last batch
          hasMoreUsers = false;
        }

        batchUserIds = Object.keys(batchUsers);
        totalFetched += batchUserIds.length;

        logger.info(`Fetched ${batchUserIds.length} users in batch ${batchNumber} (total so far: ${totalFetched})`);

        // Update lastKey and lastUpdatedAt for next iteration
        if (batchUserIds.length > 0) {
          lastKey = batchUserIds[batchUserIds.length - 1];
          lastUpdatedAt = batchUsers[lastKey]?.updatedAt || null;
          logger.info(`Updated lastKey to: ${lastKey}, lastUpdatedAt: ${lastUpdatedAt}`);
        }

        // Process current batch
        const batchPromises: Promise<void>[] = [];

        for (const userId of batchUserIds) {
          batchPromises.push(
            (async () => {
              try {
                const user: User = batchUsers[userId];
                if (!user) {
                  processedCount++;
                  return;
                }

                // Check if user has completed profile (filter should be null)
                const hasCompletedProfile = user.filter === null;
                if (!hasCompletedProfile) {
                  skippedIncomplete++;
                  processedCount++;
                  return;
                }

                const reputationScore = calculateReputationScore(user);
                const reputationLevel = getReputationLevel(reputationScore);

                // Reset users with reputation level higher than 'fair' who are recently active
                // This means 'good' and 'excellent' users with recent activity will be reset
                const shouldReset = reputationScore > REPUTATION_THRESHOLDS.FAIR;

                if (shouldReset) {
                  resetUsers.push({
                    userId,
                    reputationLevel,
                    reputationScore: Math.round(reputationScore * 1000) / 1000
                  });

                  if (!dryRun) {
                    // Reset reportCount and revivedAt to 0
                    await usersRef.child(userId).update({
                      reportCount: 0,
                      revivedAt: 0,
                    });
                  }

                  resetCount++;

                  if (resetCount <= 10) { // Log details for first 10 users
                    logger.info(
                      `${dryRun ? '[DRY RUN] ' : ''}Reset user ${userId} - ` +
                      `Reputation: ${reputationLevel} (${reputationScore.toFixed(3)}) - ` +
                      `Followers: ${user.followerCount || 0}, Following: ${user.followeeCount || 0} - ` +
                      `Last active: ${new Date(user.updatedAt || 0).toISOString()} - Filter: ${user.filter}`
                    );
                  }
                }

                processedCount++;

                // Log progress every 500 processed users
                if (processedCount % 500 === 0) {
                  logger.info(`Progress: ${processedCount} users processed, ${resetCount} users reset, ${skippedIncomplete} incomplete profiles skipped`);
                }

              } catch (error) {
                logger.error(`Error processing user ${userId}:`, error);
                errors.push({
                  userId,
                  error: error instanceof Error ? error.message : String(error)
                });
                processedCount++;
              }
            })()
          );
        }

        // Wait for current batch to complete before processing next batch
        await Promise.all(batchPromises);

        logger.info(`Completed database batch ${batchNumber} (${resetCount} users reset so far, ${processedCount} users processed, ${skippedIncomplete} incomplete profiles skipped)`);

        // Clear batch data from memory to prevent accumulation
        Object.keys(batchUsers).forEach(key => delete batchUsers[key]);
      }

      logger.info(`Database-level batch processing completed. Total batches: ${batchNumber}, Total users fetched: ${totalFetched}, Incomplete profiles skipped: ${skippedIncomplete}`);

      const message = `${dryRun ? '[DRY RUN] ' : ''}Successfully processed ${processedCount} recently active users, reset ${resetCount} trusted users with completed profiles and good reputation (score > ${REPUTATION_THRESHOLDS.FAIR})`;
      logger.info(message);

      const result = {
        success: true,
        message,
        processedCount,
        resetCount,
        dryRun,
        sampleResetUsers: resetUsers.slice(0, 10), // Return first 10 for reference
        totalResetUsers: resetCount,
        skippedIncompleteUsers: skippedIncomplete,
        activityCutoffDate: new Date(threeWeeksAgo).toISOString(),
        errors: errors.length > 0 ? errors.slice(0, 5) : undefined, // Return first 5 errors if any
        errorCount: errors.length,
        reputationThreshold: REPUTATION_THRESHOLDS.FAIR,
      };

      res.status(200).json(result);

    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : String(error);
      logger.error('Error in resetTrustedUserStatus:', error);

      res.status(500).json({
        success: false,
        error: errorMessage,
        processedCount: 0,
        resetCount: 0,
      });
    }
  }
);
