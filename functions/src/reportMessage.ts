import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions'
import { onCall } from 'firebase-functions/v2/https';
import { Message } from './types';
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
  const { chatId, messageId, reporterUserId } = request.data as ReportMessageRequest;

  try {
    // Validate input
    if (!chatId || !messageId || !reporterUserId) {
      throw new Error('Missing required parameters: chatId, messageId, reporterUserId');
    }

    // Fetch the message from Realtime Database
    const messageRef = db.ref(`messages/${chatId}/${messageId}`);
    const messageSnapshot = await messageRef.get();

    if (!messageSnapshot.exists()) {
      throw new Error('Message not found');
    }

    const messageData = messageSnapshot.val() as Message;
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
    logger.error('Error reporting message:', error);
    throw error;
  }
});

const resolveMessageReport = async (reportId: string, report: FirestoreMessageReport) => {
  try {
    // Apply moderation penalty to the message author
    await applyModerationPenalty(report.messageAuthorId);

    logger.info(`Report resolved for user ${report.messageAuthorId}, message ${report.messageId} in chat ${report.chatId}`);

    // Update the message's report count in Realtime Database
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
    const messageRef = db.ref(`messages/${chatId}/${messageId}`);

    await messageRef.transaction((message: MessageData | null) => {
      if (message === null) return message;

      const currentCount = message.reportCount || 0;
      const newCount = currentCount + 1;
      message.reportCount = newCount;

      logger.info(`Message ${messageId} report count updated to ${newCount}`);

      return message;
    });
  } catch (error) {
    logger.error(`Error updating message ${messageId} report count:`, error);
  }
};



export default reportMessage;
