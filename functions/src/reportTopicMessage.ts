import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions'
import { onCall } from 'firebase-functions/v2/https';

import { getDateBasedDocId } from './helpers';
import { applyModerationPenalty } from './userModerationUtils';

interface TopicMessageData {
  userId: string;
  userDisplayName: string;
  userPhotoURL: string;
  content: string;
  createdAt: admin.firestore.Timestamp;
  type: string;
  reportCount?: number;
}

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

// Message Report Configuration (matches Dart MessageReportConfig)
const MESSAGE_REPORT_CONFIG = {
  flagThreshold: 1,
  hideThreshold: 5,
  severeThreshold: 13,
} as const;

// Topic becomes private using graduated threshold: max(1, 14 - messageCount)
// This aligns with MessageReportConfig.severeThreshold = 13

interface ReportTopicMessageRequest {
  topicId: string;
  messageId: string;
  reporterUserId: string;
}

interface FirestoreTopicMessageReport {
  topicId: string;
  messageId: string;
  messageAuthorId: string;
  reporterUserId: string;
  createdAt: admin.firestore.Timestamp;
  status: 'pending' | 'resolved';
}

export const reportTopicMessage = onCall(async (request) => {
  const requesterId = request.auth?.uid;

  try {
    // Get the authenticated user
    if (!requesterId) {
      throw new Error('Authentication required');
    }

    const { topicId, messageId, reporterUserId } = request.data as ReportTopicMessageRequest;

    logger.info('Topic message report request received', {
      messageId,
      topicId,
      reporterUserId,
      requesterId,
    });

    // Validate input
    if (!topicId || !messageId || !reporterUserId) {
      throw new Error('Missing required parameters: topicId, messageId, reporterUserId');
    }

    // Validate that the requester is the same as reporterUserId
    if (requesterId !== reporterUserId) {
      throw new Error('Unauthorized: can only report with your own user ID');
    }

    // Fetch the message from Firestore
    const messageRef = firestore.collection('topics').doc(topicId).collection('messages').doc(messageId);
    const messageSnapshot = await messageRef.get();

    if (!messageSnapshot.exists) {
      logger.error('Topic message not found', {
        messageId,
        topicId,
        firestorePath: `topics/${topicId}/messages/${messageId}`,
      });
      throw new Error('Topic message not found');
    }

    const messageData = messageSnapshot.data() as TopicMessageData;
    const messageAuthorId = messageData.userId;

    // Prevent self-reporting
    if (messageAuthorId === reporterUserId) {
      throw new Error('Cannot report your own message');
    }

    // Create the report in Firestore
    const now = Timestamp.now();
    const reportData: FirestoreTopicMessageReport = {
      topicId,
      messageId,
      messageAuthorId,
      reporterUserId,
      createdAt: now,
      status: 'pending',
    };

    // Calculate date-based parent document ID from creation time
    const parentDocId = getDateBasedDocId(now.toDate()); // e.g., "2025-01-06"

    const reportRef = await firestore
      .collection('reports')
      .doc(parentDocId)
      .collection('topicMessages')
      .add(reportData);

    // Auto-resolve the report using the same algorithm as chat reports
    await resolveTopicMessageReport(reportRef.id, reportData);

    logger.info('Topic message report successful', {
      messageId,
      topicId,
      reportedBy: requesterId,
      reportId: reportRef.id,
    });

    return {
      success: true,
      reportId: reportRef.id,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';

    logger.error('Topic message report failed', {
      messageId: request.data?.messageId,
      topicId: request.data?.topicId,
      requesterId,
      error: errorMessage,
    });

    // Return user-friendly error messages
    return {
      success: false,
      error: errorMessage,
    };
  }
});

const resolveTopicMessageReport = async (reportId: string, report: FirestoreTopicMessageReport) => {
  try {
    // Apply moderation penalty to the message author
    await applyModerationPenalty(report.messageAuthorId);

    logger.info(`Topic message report resolved for user ${report.messageAuthorId}, message ${report.messageId} in topic ${report.topicId}`);

    // Update the topic message's report count in both Firestore message and messageMeta
    await updateTopicMessageReportCount(report.topicId, report.messageId);

    // Update the topic's report count and check if it should be made private
    await updateTopicReportCountAndCheckPrivacy(report.topicId);

    // Calculate parentDocId from the report's creation time
    const parentDocId = getDateBasedDocId(report.createdAt.toDate());

    // Update the report status in Firestore
    await firestore
      .collection('reports')
      .doc(parentDocId)
      .collection('topicMessages')
      .doc(reportId)
      .update({
        status: 'resolved',
      });

  } catch (error) {
    logger.error('Error resolving topic message report:', error);
  }
};

const updateTopicMessageReportCount = async (topicId: string, messageId: string) => {
  try {
    let newReportCount = 0;

    // Update the topic message's report count in Firestore (for backward compatibility)
    const messageRef = firestore.collection('topics').doc(topicId).collection('messages').doc(messageId);

    await firestore.runTransaction(async (transaction) => {
      const messageDoc = await transaction.get(messageRef);

      if (!messageDoc.exists) {
        logger.error(`Topic message ${messageId} not found during report count update`);
        throw new Error('Topic message not found');
      }

      const messageData = messageDoc.data() as TopicMessageData;
      const currentCount = messageData.reportCount || 0;
      newReportCount = currentCount + 1;

      // Update the original message document
      transaction.update(messageRef, {
        reportCount: newReportCount
      });

      logger.info(`Topic message ${messageId} report count updated to ${newReportCount} in Firestore document`);
    });

    // Update/store the report count in messageMeta subcollection for live streams
    const metaCollectionPath = `topics/${topicId}/messageMeta`;
    const metaRef = firestore.collection(metaCollectionPath).doc(messageId);

    await firestore.runTransaction(async (transaction) => {
      const currentMeta = await transaction.get(metaRef);
      const currentMetaData = currentMeta.exists ? currentMeta.data() : null;

      logger.info('Updating topic message meta with report count', {
        messageId,
        topicId,
        metaCollectionPath,
        currentReportCount: currentMetaData?.reportCount || 0,
        newReportCount,
      });

      // Store/update report count metadata
      const metadataToStore = {
        reportCount: newReportCount,
        lastReportedAt: Timestamp.now(),
      };

      // Preserve existing metadata fields (like isRecalled)
      if (currentMeta.exists && currentMetaData) {
        Object.assign(metadataToStore, currentMetaData, {
          reportCount: newReportCount,
          lastReportedAt: Timestamp.now(),
        });
      }

      transaction.set(metaRef, metadataToStore, { merge: true });
    });

    logger.info(`Topic message ${messageId} report count updated to ${newReportCount} in both Firestore document and messageMeta`);

  } catch (error) {
    logger.error(`Error updating topic message ${messageId} report count:`, error);
  }
};

const updateTopicReportCountAndCheckPrivacy = async (topicId: string) => {
  try {
    const topicRef = firestore.collection('topics').doc(topicId);

    await firestore.runTransaction(async (transaction) => {
      const topicDoc = await transaction.get(topicRef);

      if (!topicDoc.exists) {
        logger.error(`Topic ${topicId} not found`);
        return;
      }

      const topicData = topicDoc.data();
      const currentReportCount = topicData?.reportCount || 0;
      const newReportCount = currentReportCount + 1;
      const messageCount = topicData?.messageCount || 0;
      const isCurrentlyPublic = topicData?.isPublic ?? true;

      // Always increment the report count
      const updateData: { reportCount: number; isPublic?: boolean } = { reportCount: newReportCount };

      // Calculate graduated threshold
      const threshold = Math.max(1, MESSAGE_REPORT_CONFIG.severeThreshold + 1 - messageCount) * messageCount;

      // If topic is public and reports exceed threshold, make it private
      if (isCurrentlyPublic && messageCount > 0 && newReportCount >= threshold) {
        updateData.isPublic = false;
        logger.info(`Topic ${topicId} converted to private: ${newReportCount} reports >= ${threshold} threshold (${messageCount} messages)`);
      }

      transaction.update(topicRef, updateData);
      logger.info(`Topic ${topicId} report count updated to ${newReportCount}`);
    });
  } catch (error) {
    logger.error(`Error updating topic ${topicId} report count:`, error);
  }
};

export default reportTopicMessage;
