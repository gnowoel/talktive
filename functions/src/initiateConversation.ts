import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { Chat, Pair, User } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

// interface UserData {
//   id: string;
//   languageCode?: string | null;
//   photoURL?: string | null;
//   displayName?: string | null;
//   description?: string | null;
//   gender?: string | null;
//   revivedAt?: number | null;
//   messageCount?: number | null;
//   createdAt: number;
//   updatedAt: number;
// }

// interface ConversationRequest {
//   senderId: string;
//   receiverId: string;
//   message: string;
// }

// interface ConversationResponse {
//   success: boolean;
//   chatId: string;
//   error?: string;
// }

export const initiateConversation = onCall(async (request) => {
  try {
    const { senderId, receiverId, message } = request.data;

    // Enhanced input validation
    if (!senderId || !receiverId || !message) {
      logger.warn('Missing required fields in initiateConversation', { senderId, receiverId, hasMessage: !!message });
      return {
        success: false,
        chatId: '',
        error: 'Missing required fields: senderId, receiverId, and message are required'
      };
    }

    if (typeof senderId !== 'string' || typeof receiverId !== 'string' || typeof message !== 'string') {
      logger.warn('Invalid field types in initiateConversation', { senderId, receiverId, message });
      return {
        success: false,
        chatId: '',
        error: 'Invalid field types: all fields must be strings'
      };
    }

    if (senderId.trim() === '' || receiverId.trim() === '' || message.trim() === '') {
      logger.warn('Empty fields in initiateConversation', { senderId, receiverId, message });
      return {
        success: false,
        chatId: '',
        error: 'Fields cannot be empty'
      };
    }

    if (message.length > 1000) {
      logger.warn('Message too long in initiateConversation', { messageLength: message.length });
      return {
        success: false,
        chatId: '',
        error: 'Message is too long (maximum 1000 characters)'
      };
    }

    if (senderId === receiverId) {
      logger.warn('User trying to message themselves', { senderId });
      return {
        success: false,
        chatId: '',
        error: "You can't start a conversation with yourself"
      };
    }

    // Fetch user data for both users with better error handling
    let senderSnapshot, receiverSnapshot;
    try {
      [senderSnapshot, receiverSnapshot] = await Promise.all([
        db.ref(`users/${senderId}`).get(),
        db.ref(`users/${receiverId}`).get()
      ]);
    } catch (error) {
      logger.error('Database error fetching user data', { senderId, receiverId, error });
      return {
        success: false,
        chatId: '',
        error: 'Unable to fetch user data. Please try again.'
      };
    }

    if (!senderSnapshot.exists()) {
      logger.warn('Sender not found', { senderId });
      return {
        success: false,
        chatId: '',
        error: 'Sender profile not found. Please ensure you are logged in.'
      };
    }

    if (!receiverSnapshot.exists()) {
      logger.warn('Receiver not found', { receiverId });
      return {
        success: false,
        chatId: '',
        error: 'The user you are trying to message was not found.'
      };
    }

    const sender: User = senderSnapshot.val();
    const receiver: User = receiverSnapshot.val();

    // Validate user data integrity
    if (!sender || !receiver) {
      logger.error('Invalid user data', { senderId, receiverId, senderExists: !!sender, receiverExists: !!receiver });
      return {
        success: false,
        chatId: '',
        error: 'Invalid user data. Please try again.'
      };
    }

    // Check if both users have complete profiles
    if (!isUserProfileComplete(sender)) {
      logger.warn('Sender profile incomplete', { senderId });
      return {
        success: false,
        chatId: '',
        error: 'Your profile is incomplete. Please complete your profile before starting a conversation.'
      };
    }

    if (!isUserProfileComplete(receiver)) {
      logger.warn('Receiver profile incomplete', { receiverId });
      return {
        success: false,
        chatId: '',
        error: 'The user you are trying to message has an incomplete profile.'
      };
    }

    const chatId = ([senderId, receiverId].sort()).join('');
    const now = Date.now();

    // Check if conversation already exists
    let existingChat;
    try {
      const chatSnapshot = await db.ref(`pairs/${chatId}`).get();
      if (chatSnapshot.exists()) {
        existingChat = chatSnapshot.val();
        logger.info('Conversation already exists', { chatId, senderId, receiverId });
        // Return existing chat instead of creating new one
        return {
          success: true,
          chatId: chatId,
          chatCreatedAt: existingChat.createdAt.toString(),
        };
      }
    } catch (error) {
      logger.error('Error checking existing conversation', { chatId, error });
      // Continue to create new conversation if check fails
    }

    try {
      await createFullConversation(chatId, senderId, receiverId, sender, receiver, now);
      logger.info('Conversation created successfully', { chatId, senderId, receiverId });
    } catch (error) {
      logger.error('Error creating conversation', { chatId, senderId, receiverId, error });
      return {
        success: false,
        chatId: '',
        error: 'Failed to create conversation. Please try again.'
      };
    }

    try {
      await sendFirstMessage(chatId, senderId, sender, message);
      logger.info('First message sent successfully', { chatId, senderId });
    } catch (error) {
      logger.error('Error sending first message', { chatId, senderId, error });
      // Don't fail the entire operation if message sending fails
      // The conversation is already created
      logger.warn('Conversation created but first message failed', { chatId });
    }

    return {
      success: true,
      chatId: chatId,
      chatCreatedAt: now.toString(),
    };
  } catch (error) {
    logger.error('Unexpected error initiating conversation:', error);

    // Provide user-friendly error messages based on error type
    let userMessage = 'An unexpected error occurred. Please try again.';

    if (error instanceof Error) {
      if (error.message.includes('permission')) {
        userMessage = 'You don\'t have permission to perform this action.';
      } else if (error.message.includes('network') || error.message.includes('timeout')) {
        userMessage = 'Network error. Please check your connection and try again.';
      } else if (error.message.includes('database')) {
        userMessage = 'Database error. Please try again in a moment.';
      }
    }

    return {
      success: false,
      chatId: '',
      error: userMessage
    };
  }
});

async function createFullConversation(
  chatId: string,
  senderId: string,
  receiverId: string,
  sender: User,
  receiver: User,
  now: number
): Promise<void> {
  // Create partner stubs (only include necessary fields to save space)
  const senderStub = createPartnerStub(sender);
  const receiverStub = createPartnerStub(receiver);

  // Create batch updates
  const updates: Record<string, Pair | Chat> = {};

  // Create pair
  updates[`pairs/${chatId}`] = {
    followers: [senderId, receiverId],
    firstUserId: null,
    lastMessageContent: null,
    messageCount: 0,
    createdAt: now,
    updatedAt: now,
    v2: true,
  };

  // Create sender's chat
  updates[`chats/${senderId}/${chatId}`] = {
    partner: receiverStub,
    firstUserId: null,
    lastMessageContent: null,
    messageCount: 0,
    readMessageCount: 0,
    mute: false,
    createdAt: now,
    updatedAt: now,
  };

  // Create receiver's chat
  updates[`chats/${receiverId}/${chatId}`] = {
    partner: senderStub,
    firstUserId: null,
    lastMessageContent: null,
    messageCount: 0,
    readMessageCount: 0,
    mute: false,
    createdAt: now,
    updatedAt: now,
  };

  // Apply all updates atomically with error handling
  try {
    await db.ref().update(updates);
  } catch (error) {
    logger.error('Error applying database updates', { chatId, senderId, receiverId, error });
    throw new Error('Failed to create conversation in database');
  }
}

function createPartnerStub(user: User) {
  return {
    createdAt: user.createdAt, // For checking `newcomer` status
    updatedAt: 0,
    languageCode: user.languageCode ?? null,
    photoURL: user.photoURL ?? null,
    displayName: user.displayName ?? null,
    description: '', // To save space
    gender: user.gender ?? null,
    revivedAt: user.revivedAt ?? null,
    messageCount: user.messageCount ?? null, // For calculating the level
  };
}

function isUserProfileComplete(user: User): boolean {
  if (!user) return false;

  return !!(user.languageCode &&
    user.photoURL &&
    user.displayName &&
    user.gender);
}

async function sendFirstMessage(chatId: string, senderId: string, sender: User, message: string): Promise<void> {
  try {
    const messageRef = db.ref(`messages/${chatId}`).push();
    const now = Date.now();

    const messageData = {
      type: 'text',
      userId: senderId,
      userDisplayName: sender.displayName ?? 'Unknown User',
      userPhotoURL: sender.photoURL ?? '',
      content: message.trim(),
      createdAt: now
    };

    await messageRef.set(messageData);
    logger.info('First message sent', { chatId, senderId, messageId: messageRef.key });

  } catch (error) {
    logger.error('Error sending first message:', { chatId, senderId, error });
    throw new Error('Failed to send first message');
  }
}
