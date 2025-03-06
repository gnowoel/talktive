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

    // Validate input
    if (!senderId || !receiverId || !message) {
      return {
        success: false,
        chatId: '',
        error: 'Missing required fields'
      };
    }

    if (senderId === receiverId) {
      return {
        success: false,
        chatId: '',
        error: "You can't talk to yourself"
      };
    }

    // Fetch user data for both users
    const senderSnapshot = await db.ref(`users/${senderId}`).get();
    const receiverSnapshot = await db.ref(`users/${receiverId}`).get();

    if (!senderSnapshot.exists() || !receiverSnapshot.exists()) {
      return {
        success: false,
        chatId: '',
        error: 'One or both users not found'
      };
    }

    const sender: User = senderSnapshot.val();
    const receiver: User = receiverSnapshot.val();
    const chatId = ([senderId, receiverId].sort()).join('');

    await createFullConversation(chatId, senderId, receiverId, sender, receiver);
    await sendFirstMessage(chatId, senderId, sender, message);

    return {
      success: true,
      chatId: chatId
    };
  } catch (error) {
    logger.error('Error initiating conversation:', error);
    return {
      success: false,
      chatId: '',
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});

async function createFullConversation(
  chatId: string,
  senderId: string,
  receiverId: string,
  sender: User,
  receiver: User
): Promise<void> {
  const now = Date.now();

  // Create partner stubs (only include necessary fields to save space)
  const senderStub = createPartnerStub(sender);
  const receiverStub = createPartnerStub(receiver);

  // Create batch updates
  const updates: Record<string, Pair|Chat> = {};

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

  // Apply all updates atomically
  await db.ref().update(updates);
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

async function sendFirstMessage(chatId: string, senderId: string, sender: User, message: string): Promise<void> {
  try {
    const messageRef = db.ref(`messages/${chatId}`).push();
    const now = Date.now();

    await messageRef.set({
      type: 'text',
      userId: senderId,
      userDisplayName: sender.displayName ?? '',
      userPhotoURL: sender.photoURL ?? '',
      content: message,
      createdAt: now
    });

  } catch (error) {
    logger.error('Error sending first message:', error);
    throw error;
  }
}
