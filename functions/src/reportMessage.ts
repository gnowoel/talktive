import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions'
import { onCall } from 'firebase-functions/v2/https';
import { User, Message } from './types';
import { getDateBasedDocId } from './helpers';

interface MessageData {
  userId: string;
  userDisplayName: string;
  userPhotoURL: string;
  content: string;
  createdAt: number;
  type: string;
  reportCount?: number;
  reportStatus?: 'flagged' | 'hidden' | 'severe';
}

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();
const firestore = admin.firestore();

const oneDay = 1 * 24 * 60 * 60 * 1000;

// Message report thresholds
const MESSAGE_REPORT_THRESHOLDS = {
  FLAG: 1,     // Flag for review after 1 report
  HIDE: 3,     // Hide message after 3 reports
  SEVERE: 5,   // Mark as severe after 5 reports
};

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
  revivedAt?: number;
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
    const messageAuthor = await getUser(report.messageAuthorId);
    if (!messageAuthor) {
      logger.error(`User not found: ${report.messageAuthorId}`);
      return;
    }

    const now = new Date().getTime();
    const oldRevivedAt = getOldRevivedAt(now, messageAuthor);
    const newRevivedAt = await getNewRevivedAt(now, oldRevivedAt);

    // Update the message author's revivedAt in Realtime Database
    await updateUserRevivedAt(report.messageAuthorId, newRevivedAt);

    // Update the message's report count in Realtime Database
    await updateMessageReportCount(report.chatId, report.messageId);

    // Update all chats where this user is a partner
    await updatePartnerChatsRevivedAt(report.messageAuthorId, newRevivedAt);

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
        revivedAt: newRevivedAt,
      });

  } catch (error) {
    logger.error('Error resolving message report:', error);
  }
};

const getUser = async (userId: string): Promise<User | null> => {
  const userRef = db.ref(`users/${userId}`);
  const snapshot = await userRef.get();

  if (!snapshot.exists()) return null;

  const user: User = snapshot.val();
  return user;
};

const getOldRevivedAt = (now: number, user: User) => {
  const then = now - 7 * oneDay;
  const oldRevivedAt = Math.max(user.revivedAt ?? 0, then);
  return oldRevivedAt;
};

const getNewRevivedAt = async (now: number, oldRevivedAt: number) => {
  const then = now - 7 * oneDay;
  const remaining = oldRevivedAt - then;

  let days = Math.ceil(remaining / oneDay);
  if (days < 1 || days > 256) days = 1;

  const newRevivedAt = oldRevivedAt + days * oneDay;
  return newRevivedAt;
};

const updateUserRevivedAt = async (userId: string, revivedAt: number) => {
  try {
    const userRef = db.ref(`users/${userId}`);
    await userRef.update({ revivedAt });
  } catch (error) {
    logger.error(`Error updating user ${userId} revivedAt:`, error);
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
      
      // Apply threshold-based actions
      if (newCount >= MESSAGE_REPORT_THRESHOLDS.SEVERE) {
        message.reportStatus = 'severe';
      } else if (newCount >= MESSAGE_REPORT_THRESHOLDS.HIDE) {
        message.reportStatus = 'hidden';
      } else if (newCount >= MESSAGE_REPORT_THRESHOLDS.FLAG) {
        message.reportStatus = 'flagged';
      }
      
      logger.info(`Message ${messageId} report count updated to ${newCount}, status: ${message.reportStatus}`);
      
      return message;
    });
  } catch (error) {
    logger.error(`Error updating message ${messageId} report count:`, error);
  }
};

const updatePartnerChatsRevivedAt = async (userId: string, revivedAt: number) => {
  try {
    // Get all chat IDs where this user is a partner
    const userChatsRef = db.ref(`chats/${userId}`);
    const snapshot = await userChatsRef.get();

    if (!snapshot.exists()) return;

    const chatIds = Object.keys(snapshot.val());

    // Update each chat's partner revivedAt for all other users
    const updatePromises = chatIds.map(async (chatId) => {
      const partnerId = chatId.replace(userId, '');
      await updateChatPartnerRevivedAt(partnerId, chatId, revivedAt);
    });

    await Promise.all(updatePromises);
  } catch (error) {
    logger.error('Error updating partner chats revivedAt:', error);
  }
};

const updateChatPartnerRevivedAt = async (
  userId: string,
  chatId: string,
  revivedAt: number
): Promise<void> => {
  const chatRef = db.ref(`chats/${userId}/${chatId}`);

  try {
    const snapshot = await chatRef.get();
    if (!snapshot.exists()) return;

    await chatRef.child('partner').update({ revivedAt });
  } catch (error) {
    logger.error(`Error updating chat ${chatId} for user ${userId}:`, error);
  }
};

export default reportMessage;
