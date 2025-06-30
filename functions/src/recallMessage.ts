import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { User } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();
const database = admin.database();

interface RecallMessageRequest {
  messageId: string;
  messageType: 'chat' | 'topic';
  chatId?: string; // Required for chat messages
  topicId?: string; // Required for topic messages
}

interface TopicData {
  title: string;
  creator: User;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  messageCount: number;
  lastMessageContent?: string;
  tribeId?: string;
  isPublic: boolean;
  reportCount?: number;
}

interface ChatMessage {
  author: User;
  content: string;
  createdAt: number;
  type: string;
}

interface TopicMessage {
  author: User;
  content: string;
  createdAt: Timestamp;
  type: string;
}

export const recallMessage = onCall(async (request) => {
  try {
    // Get the authenticated user
    if (!request.auth?.uid) {
      throw new Error('Authentication required');
    }

    const requesterId = request.auth.uid;
    const { messageId, messageType, chatId, topicId } = request.data as RecallMessageRequest;

    // Validate input
    if (!messageId || !messageType) {
      throw new Error('Missing required parameters: messageId, messageType');
    }

    if (messageType === 'chat' && !chatId) {
      throw new Error('chatId is required for chat messages');
    }

    if (messageType === 'topic' && !topicId) {
      throw new Error('topicId is required for topic messages');
    }

    // Fetch the requester's user data to check for admin/moderator role
    const requesterRef = firestore.collection('users').doc(requesterId);
    const requesterSnapshot = await requesterRef.get();

    if (!requesterSnapshot.exists) {
      throw new Error('Requester user not found');
    }

    const requesterData = requesterSnapshot.data() as User;
    const isAdmin = requesterData.role === 'admin';
    const isModerator = requesterData.role === 'moderator';

    let messageData: ChatMessage | TopicMessage;
    let isMessageAuthor = false;
    let isTopicCreator = false;
    let metaCollectionPath: string;

    if (messageType === 'chat') {
      // Handle chat message recall
      const messageRef = database.ref(`chats/${chatId}/messages/${messageId}`);
      const messageSnapshot = await messageRef.get();

      if (!messageSnapshot.exists()) {
        throw new Error('Chat message not found');
      }

      messageData = messageSnapshot.val() as ChatMessage;
      isMessageAuthor = messageData.author.id === requesterId;
      metaCollectionPath = `chats/${chatId}/messageMeta`;

    } else {
      // Handle topic message recall
      const messageRef = firestore.collection('topics').doc(topicId!).collection('messages').doc(messageId);
      const messageSnapshot = await messageRef.get();

      if (!messageSnapshot.exists) {
        throw new Error('Topic message not found');
      }

      messageData = messageSnapshot.data() as TopicMessage;
      isMessageAuthor = messageData.author.id === requesterId;
      metaCollectionPath = `topics/${topicId}/messageMeta`;

      // Check if requester is topic creator
      const topicRef = firestore.collection('topics').doc(topicId!);
      const topicSnapshot = await topicRef.get();

      if (topicSnapshot.exists) {
        const topicData = topicSnapshot.data() as TopicData;
        isTopicCreator = topicData.creator.id === requesterId;
      }
    }

    // Check permissions: message author, admin, moderator, or topic creator (for topics)
    const hasPermission = isMessageAuthor || isAdmin || isModerator || isTopicCreator;

    if (!hasPermission) {
      throw new Error('Insufficient permissions to recall this message');
    }

    // Check if message is already recalled
    const metaRef = firestore.collection(metaCollectionPath).doc(messageId);
    const metaSnapshot = await metaRef.get();

    if (metaSnapshot.exists && metaSnapshot.data()?.isRecalled === true) {
      throw new Error('Message is already recalled');
    }

    // Store recall metadata in Firestore
    await metaRef.set({
      isRecalled: true,
      recalledAt: Timestamp.now(),
      recalledBy: requesterId,
    }, { merge: true });

    logger.info(`Message ${messageId} recalled by ${requesterId} in ${messageType} ${chatId || topicId}`);

    return {
      success: true,
      message: 'Message successfully recalled',
    };

  } catch (error) {
    logger.error('Error recalling message:', error);

    // Return user-friendly error messages
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';

    return {
      success: false,
      error: errorMessage,
    };
  }
});

export default recallMessage;
