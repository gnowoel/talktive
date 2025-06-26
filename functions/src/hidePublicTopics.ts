import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onRequest } from 'firebase-functions/v2/https';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

const ALLOWED_CREATOR_ID = 'vyuqdT68ClZDuyWSC2YjvqtpNmC3';

export const hidePublicTopics = onRequest(async (_req, res) => {
  try {
    const now = Timestamp.now();
    let hiddenCount = 0;
    let skippedCount = 0;
    let processedBatches = 0;

    // Get all topics
    const topicsSnapshot = await firestore.collection('topics').get();

    if (topicsSnapshot.empty) {
      logger.info('No topics found in the collection');
      res.status(200).send({
        success: true,
        hidden: 0,
        skipped: 0,
        message: 'No topics found',
      });
      return;
    }

    // Process topics in batches (Firestore batch limit is 500 operations)
    const batchSize = 500;
    const topics = topicsSnapshot.docs;

    for (let i = 0; i < topics.length; i += batchSize) {
      const batch = firestore.batch();
      const batchTopics = topics.slice(i, i + batchSize);

      for (const topicDoc of batchTopics) {
        const topicData = topicDoc.data();
        const createdBy = topicData.createdBy;

        // Skip topics created by the allowed user
        if (createdBy === ALLOWED_CREATOR_ID) {
          skippedCount++;
          continue;
        }

        // Hide the topic by setting isPublic to false
        batch.update(topicDoc.ref, {
          isPublic: false,
          updatedAt: now,
        });
        hiddenCount++;
      }

      // Commit this batch if it has any updates
      if (hiddenCount > processedBatches * batchSize) {
        await batch.commit();
        processedBatches++;
        logger.info(`Processed batch ${processedBatches}, hidden ${hiddenCount} topics so far`);
      }
    }

    logger.info(`Hide public topics completed: hidden ${hiddenCount}, skipped ${skippedCount}`);
    res.status(200).send({
      success: true,
      hidden: hiddenCount,
      skipped: skippedCount,
      allowedCreatorId: ALLOWED_CREATOR_ID,
      totalProcessed: hiddenCount + skippedCount,
    });
  } catch (error) {
    logger.error('Error hiding public topics:', error);
    res.status(500).send({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});
