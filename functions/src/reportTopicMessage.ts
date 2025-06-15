import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions'
import { onCall } from 'firebase-functions/v2/https';
import { User } from './types';
import { getDateBasedDocId } from './helpers';
import { getRestrictionMultiplier } from './reputationUtils';

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

    // Update the topic's report count and check if it should be made private
    await updateTopicReportCountAndCheckPrivacy(report.topicId);

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
  if (days < 1 || days > 21) days = 1;

  // Calculate restriction multiplier based on reputation score
  const restrictionMultiplier = getRestrictionMultiplier(user);
  days = Math.max(Math.ceil(days * restrictionMultiplier), 1);

  const newRevivedAt = oldRevivedAt + days * oneDay;
  return Math.min(newRevivedAt, now + 21 * oneDay);
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
