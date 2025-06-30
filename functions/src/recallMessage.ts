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

// Constants
const VALID_MESSAGE_TYPES = ['chat', 'topic'] as const;
const MAX_MESSAGE_ID_LENGTH = 100;

// Utility functions
const validateMessageId = (messageId: string): void => {
  if (!messageId || typeof messageId !== 'string') {
    throw new Error('Invalid messageId: must be a non-empty string');
  }
  if (messageId.trim() === '') {
    throw new Error('Invalid messageId: cannot be empty or whitespace');
  }
  if (messageId.length > MAX_MESSAGE_ID_LENGTH) {
    throw new Error(`Invalid messageId: exceeds maximum length of ${MAX_MESSAGE_ID_LENGTH}`);
  }
};

const validateCollectionId = (id: string, type: string): void => {
  if (!id || typeof id !== 'string' || id.trim() === '') {
    throw new Error(`Invalid ${type}: must be a non-empty string`);
  }
};

const validateMessageType = (messageType: string): void => {
  if (!messageType || !VALID_MESSAGE_TYPES.includes(messageType as any)) {
    throw new Error('Invalid messageType: must be either "chat" or "topic"');
  }
};

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
  const requesterId = request.auth?.uid;

  try {
    // Get the authenticated user
    if (!requesterId) {
      throw new Error('Authentication required');
    }
    const { messageId, messageType, chatId, topicId } = request.data as RecallMessageRequest;

    // Validate input using utility functions
    validateMessageId(messageId);
    validateMessageType(messageType);

    if (messageType === 'chat') {
      validateCollectionId(chatId!, 'chatId');
    }

    if (messageType === 'topic') {
      validateCollectionId(topicId!, 'topicId');
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

      // Validate message data structure
      if (!messageData || !messageData.author || !messageData.author.id) {
        throw new Error('Invalid chat message data structure');
      }

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

      // Validate message data structure
      if (!messageData || !messageData.author || !messageData.author.id) {
        throw new Error('Invalid topic message data structure');
      }

      isMessageAuthor = messageData.author.id === requesterId;
      metaCollectionPath = `topics/${topicId}/messageMeta`;

      // Check if requester is topic creator
      const topicRef = firestore.collection('topics').doc(topicId!);
      const topicSnapshot = await topicRef.get();

      if (topicSnapshot.exists) {
        const topicData = topicSnapshot.data() as TopicData;
        if (topicData && topicData.creator && topicData.creator.id) {
          isTopicCreator = topicData.creator.id === requesterId;
        }
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
      return {
        success: false,
        error: 'Message is already recalled',
      };
    }

    // Store recall metadata and update original message for backward compatibility
    const recallTimestamp = Timestamp.now();

    if (messageType === 'chat') {
      // For chat messages: Update Firestore metadata first, then Realtime Database
      await firestore.runTransaction(async (transaction) => {
        // Re-check if message is already recalled within transaction
        const currentMeta = await transaction.get(metaRef);
        if (currentMeta.exists && currentMeta.data()?.isRecalled === true) {
          throw new Error('Message was recalled by another operation');
        }

        // Store recall metadata
        transaction.set(metaRef, {
          isRecalled: true,
          recalledAt: recallTimestamp,
          recalledBy: requesterId,
        }, { merge: true });
      });

      // Update original chat message in Realtime Database for backward compatibility
      const originalMessageRef = database.ref(`chats/${chatId}/messages/${messageId}`);
      await originalMessageRef.update({
        recalled: true,
      });

    } else {
      // For topic messages: Update both Firestore message and metadata atomically
      await firestore.runTransaction(async (transaction) => {
        // Re-check if message is already recalled within transaction
        const currentMeta = await transaction.get(metaRef);
        if (currentMeta.exists && currentMeta.data()?.isRecalled === true) {
          throw new Error('Message was recalled by another operation');
        }

        // Store recall metadata
        transaction.set(metaRef, {
          isRecalled: true,
          recalledAt: recallTimestamp,
          recalledBy: requesterId,
        }, { merge: true });

        // Update original topic message for backward compatibility
        const originalMessageRef = firestore.collection('topics').doc(topicId!).collection('messages').doc(messageId);
        transaction.update(originalMessageRef, {
          recalled: true,
        });
      });
    }

    const contextId = chatId || topicId;
    logger.info(`Message recall successful`, {
      messageId,
      messageType,
      contextId,
      recalledBy: requesterId,
      timestamp: recallTimestamp.toDate().toISOString(),
    });

    return {
      success: true,
      message: 'Message successfully recalled',
    };

  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';

    logger.error('Message recall failed', {
      messageId: request.data?.messageId,
      messageType: request.data?.messageType,
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

export default recallMessage;
