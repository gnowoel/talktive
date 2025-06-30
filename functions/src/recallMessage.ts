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
  if (!messageType || !VALID_MESSAGE_TYPES.includes(messageType as typeof VALID_MESSAGE_TYPES[number])) {
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
  userId: string;
  userDisplayName: string;
  userPhotoURL: string;
  content: string;
  createdAt: number;
  type: string;
}

interface TopicMessage {
  userId: string;
  userDisplayName: string;
  userPhotoURL: string;
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

    logger.info('Message recall request received', {
      messageId,
      messageType,
      chatId,
      topicId,
      requesterId,
    });

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
      const messageRef = database.ref(`messages/${chatId}/${messageId}`);
      const messageSnapshot = await messageRef.get();

      if (!messageSnapshot.exists()) {
        logger.error('Chat message not found', {
          messageId,
          chatId,
          databasePath: `messages/${chatId}/${messageId}`,
        });
        throw new Error('Chat message not found');
      }

      messageData = messageSnapshot.val() as ChatMessage;

      // Validate message data structure
      if (!messageData || !messageData.userId) {
        throw new Error('Invalid chat message data structure');
      }

      isMessageAuthor = messageData.userId === requesterId;
      metaCollectionPath = `chats/${chatId}/messageMeta`;

    } else {
      // Handle topic message recall
      const messageRef = firestore.collection('topics').doc(topicId!).collection('messages').doc(messageId);
      const messageSnapshot = await messageRef.get();

      if (!messageSnapshot.exists) {
        logger.error('Topic message not found', {
          messageId,
          topicId,
          firestorePath: `topics/${topicId}/messages/${messageId}`,
        });
        throw new Error('Topic message not found');
      }

      messageData = messageSnapshot.data() as TopicMessage;

      // Validate message data structure
      if (!messageData || !messageData.userId) {
        throw new Error('Invalid topic message data structure');
      }

      isMessageAuthor = messageData.userId === requesterId;
      metaCollectionPath = `topics/${topicId}/messageMeta`;

      // Check if requester is topic creator
      const topicRef = firestore.collection('topics').doc(topicId!);
      const topicSnapshot = await topicRef.get();

      if (topicSnapshot.exists) {
        const topicData = topicSnapshot.data() as TopicData;
        if (topicData && topicData.creator && topicData.creator.id) {
          isTopicCreator = topicData.creator.id === requesterId;
          logger.info('Topic creator validation', {
            messageId,
            topicId,
            requesterId,
            creatorId: topicData.creator.id,
            isTopicCreator,
          });
        } else {
          logger.warn('Invalid topic creator data structure', {
            messageId,
            topicId,
            hasTopicData: !!topicData,
            hasCreator: !!(topicData && topicData.creator),
            hasCreatorId: !!(topicData && topicData.creator && topicData.creator.id),
            creatorData: topicData ? topicData.creator : null,
          });
        }
      } else {
        logger.warn('Topic not found for creator validation', {
          messageId,
          topicId,
          requesterId,
        });
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

    logger.info('Checking message recall status', {
      messageId,
      messageType,
      metaCollectionPath,
      metaExists: metaSnapshot.exists,
      metaData: metaSnapshot.exists ? metaSnapshot.data() : null,
      isAlreadyRecalled: metaSnapshot.exists && metaSnapshot.data()?.isRecalled === true,
    });

    if (metaSnapshot.exists && metaSnapshot.data()?.isRecalled === true) {
      logger.warn('Message already recalled', {
        messageId,
        messageType,
        contextId: chatId || topicId,
        recalledAt: metaSnapshot.data()?.recalledAt,
        recalledBy: metaSnapshot.data()?.recalledBy,
      });
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
        const currentMetaData = currentMeta.exists ? currentMeta.data() : null;

        logger.info('Chat message transaction check', {
          messageId,
          chatId,
          metaExists: currentMeta.exists,
          isAlreadyRecalled: currentMeta.exists && currentMetaData?.isRecalled === true,
          currentMetaData,
        });

        if (currentMeta.exists && currentMetaData?.isRecalled === true) {
          logger.warn('Attempted to recall already recalled message', {
            messageId,
            messageType,
            contextId: chatId || topicId,
            existingRecallData: currentMetaData,
          });
          throw new Error('Message was recalled by another operation');
        }

        // Store recall metadata
        const metadataToStore = {
          isRecalled: true,
          recalledAt: recallTimestamp,
          recalledBy: requesterId,
        };

        logger.info('Storing chat message recall metadata', {
          messageId,
          chatId,
          metaCollectionPath,
          metadataToStore,
        });

        transaction.set(metaRef, metadataToStore, { merge: true });
      });

      // Update original chat message in Realtime Database for backward compatibility
      const originalMessageRef = database.ref(`messages/${chatId}/${messageId}`);
      const updateData = { recalled: true };

      logger.info('Updating original chat message', {
        messageId,
        chatId,
        databasePath: `messages/${chatId}/${messageId}`,
        updateData,
      });

      await originalMessageRef.update(updateData);

    } else {
      // For topic messages: Update both Firestore message and metadata atomically
      await firestore.runTransaction(async (transaction) => {
        // Re-check if message is already recalled within transaction
        const currentMeta = await transaction.get(metaRef);
        const currentMetaData = currentMeta.exists ? currentMeta.data() : null;

        logger.info('Topic message transaction check', {
          messageId,
          topicId,
          metaExists: currentMeta.exists,
          isAlreadyRecalled: currentMeta.exists && currentMetaData?.isRecalled === true,
          currentMetaData,
        });

        if (currentMeta.exists && currentMetaData?.isRecalled === true) {
          logger.warn('Attempted to recall already recalled topic message', {
            messageId,
            messageType,
            contextId: topicId,
            existingRecallData: currentMetaData,
          });
          throw new Error('Message was recalled by another operation');
        }

        // Store recall metadata
        const metadataToStore = {
          isRecalled: true,
          recalledAt: recallTimestamp,
          recalledBy: requesterId,
        };

        logger.info('Storing topic message recall metadata', {
          messageId,
          topicId,
          metaCollectionPath,
          metadataToStore,
        });

        transaction.set(metaRef, metadataToStore, { merge: true });

        // Update original topic message for backward compatibility
        const originalMessageRef = firestore.collection('topics').doc(topicId!).collection('messages').doc(messageId);
        const updateData = { recalled: true };

        logger.info('Updating original topic message', {
          messageId,
          topicId,
          firestorePath: `topics/${topicId}/messages/${messageId}`,
          updateData,
        });

        transaction.update(originalMessageRef, updateData);
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
