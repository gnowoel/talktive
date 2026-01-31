import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';

if (!admin.apps.length) {
  admin.initializeApp();
}

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

export const initiateConversation = onCall(async (_request) => {
  throw new HttpsError('failed-precondition', 'Please upgrade your app to the latest version to start a conversation.');
});

// Unused functions removed
