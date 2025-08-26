import * as admin from 'firebase-admin';

import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { User } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();
const firestore = admin.firestore();

interface MakeUserPrivateRequest {
  currentUserId: string;
  targetUserId: string;
}

export const makeUserPrivate = onCall(async (request) => {
  try {
    // Check authentication
    if (!request.auth?.uid) {
      throw new Error('Authentication required');
    }

    const requesterId = request.auth.uid;
    const { currentUserId, targetUserId } = request.data as MakeUserPrivateRequest;

    // Validate input
    if (!currentUserId || !targetUserId) {
      throw new Error('Missing required parameters: currentUserId, targetUserId');
    }

    // Ensure the requester is the same as the currentUserId parameter
    if (requesterId !== currentUserId) {
      throw new Error('User ID mismatch');
    }

    // Prevent users from unlisting themselves
    if (currentUserId === targetUserId) {
      throw new Error('You cannot unlist yourself');
    }

    // Fetch the requester's user data to check permissions
    const requesterRef = firestore.collection('users').doc(requesterId);
    const requesterSnapshot = await requesterRef.get();

    if (!requesterSnapshot.exists) {
      throw new Error('User not found');
    }

    const requesterData = requesterSnapshot.data() as User;

    // Check permissions: only admin or moderator can unlist users
    const isAdmin = requesterData.role === 'admin';
    const isModerator = requesterData.role === 'moderator';

    if (!isAdmin && !isModerator) {
      throw new Error('Insufficient permissions to unlist users');
    }

    // Fetch the target user from Realtime Database to check if they exist
    const targetUserRef = db.ref(`users/${targetUserId}`);
    const targetUserSnapshot = await targetUserRef.get();

    if (!targetUserSnapshot.exists()) {
      throw new Error('Target user not found');
    }

    const targetUserData = targetUserSnapshot.val() as User;

    // Check if user is already unlisted
    if (targetUserData.isPublic === false) {
      throw new Error('User is already unlisted');
    }

    // Update the user's isPublic field in Firebase Realtime Database
    await targetUserRef.update({
      isPublic: false,
    });

    // Also update the user cache in Firestore for consistency
    const firestoreUserRef = firestore.collection('users').doc(targetUserId);
    const firestoreUserSnapshot = await firestoreUserRef.get();

    if (firestoreUserSnapshot.exists) {
      await firestoreUserRef.update({
        isPublic: false,
      });
    }

    logger.info(`User ${targetUserId} unlisted by ${requesterId} (${requesterData.role})`);

    return {
      success: true,
      message: 'User successfully unlisted',
    };

  } catch (error) {
    logger.error('Error making user private:', error);

    // Return user-friendly error messages
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';

    return {
      success: false,
      error: errorMessage,
    };
  }
});

export default makeUserPrivate;
