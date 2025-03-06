import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';

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

    const sender = senderSnapshot.val();
    const receiver = receiverSnapshot.val();

    // Generate the chat ID (sorted user IDs joined together)
    const chatId = ([senderId, receiverId].sort()).join('');

    // Check if pair already exists
    const pairSnapshot = await db.ref(`pairs/${chatId}`).get();
    if (pairSnapshot.exists()) {
      // Pair exists, just send the message
      await sendFirstMessage(chatId, senderId, sender, message);

      return {
        success: true,
        chatId: chatId
      };
    }

    // Create everything in a transaction
    await createFullConversation(chatId, senderId, receiverId, sender, receiver, message);

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
  sender: any,
  receiver: any,
  firstMessage: string
): Promise<void> {
  const now = Date.now();

  // Create partner stubs (only include necessary fields to save space)
  const senderStub = createPartnerStub(sender);
  const receiverStub = createPartnerStub(receiver);

  // Create batch updates
  const updates: Record<string, any> = {};

  // Create pair
  updates[`pairs/${chatId}`] = {
    followers: [senderId, receiverId],
    firstUserId: senderId,
    lastMessageContent: firstMessage,
    messageCount: 0,
    createdAt: now,
    updatedAt: now,
    v2: true,
  };

  // Create sender's chat
  updates[`chats/${senderId}/${chatId}`] = {
    partner: receiverStub,
    firstUserId: senderId,
    lastMessageContent: firstMessage,
    messageCount: 0,
    readMessageCount: 0,
    mute: false,
    createdAt: now,
    updatedAt: now,
  };

  // Create receiver's chat
  updates[`chats/${receiverId}/${chatId}`] = {
    partner: senderStub,
    firstUserId: senderId,
    lastMessageContent: firstMessage,
    messageCount: 0,
    readMessageCount: 0,
    mute: false,
    createdAt: now,
    updatedAt: now,
  };

  // Create first message
  const messageKey = db.ref(`messages/${chatId}`).push().key;
  updates[`messages/${chatId}/${messageKey}`] = {
    type: 'text',
    userId: senderId,
    userDisplayName: sender.displayName || '',
    userPhotoURL: sender.photoURL || '',
    content: firstMessage,
    createdAt: now,
  };

  // Apply all updates atomically
  await db.ref().update(updates);
}

function createPartnerStub(user: any,): any {
  return {
    createdAt: user.createdAt, // For checking `newcomer` status
    updatedAt: 0,
    languageCode: user.languageCode || null,
    photoURL: user.photoURL || null,
    displayName: user.displayName || null,
    description: '', // To save space
    gender: user.gender || null,
    revivedAt: user.revivedAt || null,
    messageCount: user.messageCount || null, // For calculating the level
  };
}

async function sendFirstMessage(chatId: string, senderId: string, sender: any, message: string): Promise<void> {
  try {
    // Just send the message if the pair and chats already exist
    const messageRef = db.ref(`messages/${chatId}`).push();

    await messageRef.set({
      type: 'text',
      userId: senderId,
      userDisplayName: sender.displayName || '',
      userPhotoURL: sender.photoURL || '',
      content: message,
      createdAt: admin.database.ServerValue.TIMESTAMP,
    });

    // // Update the pair with the new message
    // await db.ref(`pairs/${chatId}`).update({
    //   lastMessageContent: message,
    //   updatedAt: admin.database.ServerValue.TIMESTAMP,
    //   messageCount: admin.database.ServerValue.increment(1),
    //   firstUserId: senderId // Only set if it was null before
    // });

  } catch (error) {
    logger.error('Error sending first message:', error);
    throw error;
  }
}
