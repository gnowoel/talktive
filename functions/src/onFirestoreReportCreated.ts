import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { FirestoreTopicMessageReport } from './reportTopicMessage';
import { applyModerationPenalty } from './userModerationUtils';

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Triggered when a new report is created in Firestore.
 * Handles report resolution logic, such as applying moderation penalties.
 */
export const onFirestoreReportCreated = onDocumentCreated('reports/{date}/topicMessages/{reportId}', async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    logger.error('No data associated with the event');
    return;
  }

  const report = snapshot.data() as FirestoreTopicMessageReport;
  const reportId = event.params.reportId;

  logger.info(`New Firestore report created: ${reportId}`, report);

  try {
    // Check if we need to apply moderation (in case it wasn't done)
    if (report.status === 'pending') {
      await applyModerationPenalty(report.messageAuthorId);

      await snapshot.ref.update({
        status: 'resolved',
        resolvedAt: admin.firestore.Timestamp.now(),
      });

      logger.info(`Report ${reportId} resolved by trigger.`);
    }

  } catch (error) {
    logger.error(`Error processing Firestore report ${reportId}:`, error);
  }
});

export default onFirestoreReportCreated;
