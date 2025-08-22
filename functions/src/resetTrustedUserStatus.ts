import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
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
export const resetTrustedUserStatus = functions.https.onRequest(async (req, res) => {
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

    logger.info('Starting trusted user status reset process...');

    const batchSize = parseInt(req.body.batchSize) || 100; // Default batch size
    const dryRun = req.body.dryRun === 'true' || req.body.dryRun === true;

    logger.info(`Configuration: batchSize=${batchSize}, dryRun=${dryRun}`);

    // Get all users from the database
    const usersRef = db.ref('users');
    const snapshot = await usersRef.once('value');

    if (!snapshot.exists()) {
      logger.info('No users found in database');
      res.status(200).json({
        success: true,
        message: 'No users found',
        processedCount: 0,
        resetCount: 0
      });
      return;
    }

    const allUsers = snapshot.val();
    const userIds = Object.keys(allUsers);

    logger.info(`Found ${userIds.length} total users`);

    let processedCount = 0;
    let resetCount = 0;
    const resetUsers: Array<{ userId: string, reputationLevel: string, reputationScore: number }> = [];
    const errors: Array<{ userId: string, error: string }> = [];

    // Process users in batches to avoid overwhelming the database
    for (let i = 0; i < userIds.length; i += batchSize) {
      const batch = userIds.slice(i, i + batchSize);
      const batchPromises: Promise<void>[] = [];

      for (const userId of batch) {
        batchPromises.push(
          (async () => {
            try {
              const user: User = allUsers[userId];
              if (!user) {
                processedCount++;
                return;
              }

              const reputationScore = calculateReputationScore(user);
              const reputationLevel = getReputationLevel(reputationScore);

              // Reset users with reputation level higher than 'fair'
              // This means 'good' and 'excellent' users will be reset
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
                    `Followers: ${user.followerCount || 0}, Following: ${user.followeeCount || 0}`
                  );
                }
              }

              processedCount++;

              // Log progress every 500 processed users
              if (processedCount % 500 === 0) {
                logger.info(`Progress: ${processedCount}/${userIds.length} users processed, ${resetCount} users reset`);
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

      const batchNumber = Math.floor(i / batchSize) + 1;
      const totalBatches = Math.ceil(userIds.length / batchSize);
      logger.info(`Completed batch ${batchNumber}/${totalBatches} (${resetCount} users reset so far)`);
    }

    const message = `${dryRun ? '[DRY RUN] ' : ''}Successfully processed ${processedCount} users, reset ${resetCount} trusted users with good reputation (score > ${REPUTATION_THRESHOLDS.FAIR})`;
    logger.info(message);

    const result = {
      success: true,
      message,
      processedCount,
      resetCount,
      dryRun,
      sampleResetUsers: resetUsers.slice(0, 10), // Return first 10 for reference
      totalResetUsers: resetCount,
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
});
