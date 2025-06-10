import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions'
import { onCall } from 'firebase-functions/v2/https';
import { User } from './types';
import { getDateBasedDocId } from './helpers';

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

const db = admin.database();
const firestore = admin.firestore();

const oneDay = 1 * 24 * 60 * 60 * 1000;

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
  const { topicId, messageId, reporterUserId } = request.data as ReportTopicMessageRequest;

  try {
    // Validate input
    if (!topicId || !messageId || !reporterUserId) {
      throw new Error('Missing required parameters: topicId, messageId, reporterUserId');
    }

    // Fetch the message from Firestore
    const messageRef = firestore.collection('topics').doc(topicId).collection('messages').doc(messageId);
    const messageSnapshot = await messageRef.get();

    if (!messageSnapshot.exists) {
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

    return {
      success: true,
      reportId: reportRef.id,
    };
  } catch (error) {
    logger.error('Error reporting topic message:', error);
    throw error;
  }
});

const resolveTopicMessageReport = async (reportId: string, report: FirestoreTopicMessageReport) => {
  try {
    const messageAuthor = await getUser(report.messageAuthorId);
    if (!messageAuthor) {
      logger.error(`User not found: ${report.messageAuthorId}`);
      return;
    }

    const now = new Date().getTime();
    const oldRevivedAt = getOldRevivedAt(now, messageAuthor);
    const newRevivedAt = await getNewRevivedAt(now, oldRevivedAt, messageAuthor);

    // Update the message author's revivedAt and reportCount in Realtime Database
    await updateUserRevivedAtAndReportCount(report.messageAuthorId, newRevivedAt);

    logger.info(`Topic message report resolved for user ${report.messageAuthorId}, message ${report.messageId} in topic ${report.topicId}`);

    // Update the topic message's report count in Firestore
    await updateTopicMessageReportCount(report.topicId, report.messageId);

    // Update all chats where this user is a partner
    await updatePartnerChatsRevivedAt(report.messageAuthorId, newRevivedAt);

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

const getNewRevivedAt = async (now: number, oldRevivedAt: number, user: User) => {
  const then = now - 7 * oneDay;
  const remaining = oldRevivedAt - then;

  let days = Math.ceil(remaining / oneDay);
  if (days < 1 || days > 256) days = 1;

  // Calculate reputation score and apply it to scale the restriction duration
  const reputationScore = calculateReputationScore(user);
  days = Math.max(Math.ceil(days * (1 - reputationScore)), 1);

  const newRevivedAt = oldRevivedAt + days * oneDay;
  return newRevivedAt;
};

const updateUserRevivedAtAndReportCount = async (userId: string, revivedAt: number) => {
  try {
    const userRef = db.ref(`users/${userId}`);

    // Update revivedAt and increment reportCount atomically
    await userRef.update({
      revivedAt,
      reportCount: admin.database.ServerValue.increment(1),
    });

    logger.info(`User ${userId} revivedAt and reportCount updated`);
  } catch (error) {
    logger.error(`Error updating user ${userId} revivedAt and reportCount:`, error);
  }
};

const updateTopicMessageReportCount = async (topicId: string, messageId: string) => {
  try {
    const messageRef = firestore.collection('topics').doc(topicId).collection('messages').doc(messageId);

    await firestore.runTransaction(async (transaction) => {
      const messageDoc = await transaction.get(messageRef);
      
      if (!messageDoc.exists) {
        logger.error(`Topic message ${messageId} not found in topic ${topicId}`);
        return;
      }

      const currentCount = messageDoc.data()?.reportCount || 0;
      const newCount = currentCount + 1;

      transaction.update(messageRef, { reportCount: newCount });

      logger.info(`Topic message ${messageId} report count updated to ${newCount}`);
    });
  } catch (error) {
    logger.error(`Error updating topic message ${messageId} report count:`, error);
  }
};

const calculateReputationScore = (user: User): number => {
  if (!user.messageCount || user.messageCount <= 0) return 1.0;
  if (!user.reportCount || user.reportCount <= 0) return 1.0;

  const ratio = user.reportCount / user.messageCount;
  const score = 1.0 - ratio;

  // Ensure score is between 0.0 and 1.0
  return Math.max(0.0, Math.min(1.0, score));
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

export default reportTopicMessage;
