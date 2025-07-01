import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions'
import { onCall } from 'firebase-functions/v2/https';

import { getDateBasedDocId } from './helpers';
import { applyModerationPenalty } from './userModerationUtils';

interface MessageData {
  userId: string;
  userDisplayName: string;
  userPhotoURL: string;
  content: string;
  createdAt: number;
  type: string;
  reportCount?: number;
}

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();
const firestore = admin.firestore();

interface ReportMessageRequest {
  chatId: string;
  messageId: string;
  reporterUserId: string;
}

interface FirestoreMessageReport {
  chatId: string;
  messageId: string;
  messageAuthorId: string;
  reporterUserId: string;
  createdAt: admin.firestore.Timestamp;
  status: 'pending' | 'resolved';
}

export const reportMessage = onCall(async (request) => {
  const requesterId = request.auth?.uid;

  try {
    // Get the authenticated user
    if (!requesterId) {
      throw new Error('Authentication required');
    }

    const { chatId, messageId, reporterUserId } = request.data as ReportMessageRequest;

    logger.info('Message report request received', {
      messageId,
      chatId,
      reporterUserId,
      requesterId,
    });

    // Validate input
    if (!chatId || !messageId || !reporterUserId) {
      throw new Error('Missing required parameters: chatId, messageId, reporterUserId');
    }

    // Validate that the requester is the same as reporterUserId
    if (requesterId !== reporterUserId) {
      throw new Error('Unauthorized: can only report with your own user ID');
    }

    // Fetch the message from Realtime Database
    const messageRef = db.ref(`messages/${chatId}/${messageId}`);
    const messageSnapshot = await messageRef.get();

    if (!messageSnapshot.exists()) {
      logger.error('Chat message not found', {
        messageId,
        chatId,
        databasePath: `messages/${chatId}/${messageId}`,
      });
      throw new Error('Message not found');
    }

    const messageData = messageSnapshot.val() as MessageData;
    const messageAuthorId = messageData.userId;

    // Prevent self-reporting
    if (messageAuthorId === reporterUserId) {
      throw new Error('Cannot report your own message');
    }

    // Create the report in Firestore
    const now = Timestamp.now();
    const reportData: FirestoreMessageReport = {
      chatId,
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
      .collection('chatMessages')
      .add(reportData);

    // Auto-resolve the report using the same algorithm as chat reports
    await resolveMessageReport(reportRef.id, reportData);

    return {
      success: true,
      reportId: reportRef.id,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';

    logger.error('Message report failed', {
      messageId: request.data?.messageId,
      chatId: request.data?.chatId,
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

const resolveMessageReport = async (reportId: string, report: FirestoreMessageReport) => {
  try {
    // Apply moderation penalty to the message author
    await applyModerationPenalty(report.messageAuthorId);

    logger.info(`Report resolved for user ${report.messageAuthorId}, message ${report.messageId} in chat ${report.chatId}`);

    // Update the message's report count in both Realtime Database and messageMeta
    await updateMessageReportCount(report.chatId, report.messageId);

    // Calculate parentDocId from the report's creation time
    const parentDocId = getDateBasedDocId(report.createdAt.toDate());

    // Update the report status in Firestore
    await firestore
      .collection('reports')
      .doc(parentDocId)
      .collection('chatMessages')
      .doc(reportId)
      .update({
        status: 'resolved',
      });

  } catch (error) {
    logger.error('Error resolving message report:', error);
  }
};

const updateMessageReportCount = async (chatId: string, messageId: string) => {
  try {
    let newReportCount = 0;

    // Update the message's report count in Realtime Database (for backward compatibility)
    const messageRef = db.ref(`messages/${chatId}/${messageId}`);
    await messageRef.transaction((message: MessageData | null) => {
      if (message === null) return message;

      const currentCount = message.reportCount || 0;
      newReportCount = currentCount + 1;
      message.reportCount = newReportCount;

      logger.info(`Message ${messageId} report count updated to ${newReportCount} in Realtime Database`);

      return message;
    });

    // Update/store the report count in messageMeta subcollection for live streams
    const metaCollectionPath = `chats/${chatId}/messageMeta`;
    const metaRef = firestore.collection(metaCollectionPath).doc(messageId);

    await firestore.runTransaction(async (transaction) => {
      const currentMeta = await transaction.get(metaRef);
      const currentMetaData = currentMeta.exists ? currentMeta.data() : null;

      logger.info('Updating chat message meta with report count', {
        messageId,
        chatId,
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

    logger.info(`Message ${messageId} report count updated to ${newReportCount} in both Realtime Database and messageMeta`);

  } catch (error) {
    logger.error(`Error updating message ${messageId} report count:`, error);
  }
};

export default reportMessage;
