import * as admin from 'firebase-admin';

import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { User } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();
const firestore = admin.firestore();

interface ApplyUserAlertRequest {
  currentUserId: string;
  targetUserId: string;
}

export const applyUserAlert = onCall(async (request) => {
  try {
    // Check authentication
    if (!request.auth?.uid) {
      throw new Error('Authentication required');
    }

    const requesterId = request.auth.uid;
    const { currentUserId, targetUserId } = request.data as ApplyUserAlertRequest;

    // Validate input
    if (!currentUserId || !targetUserId) {
      throw new Error('Missing required parameters: currentUserId, targetUserId');
    }

    // Ensure the requester is the same as the currentUserId parameter
    if (requesterId !== currentUserId) {
      throw new Error('User ID mismatch');
    }

    // Prevent users from applying alert to themselves
    if (currentUserId === targetUserId) {
      throw new Error('You cannot apply timeout to yourself');
    }

    // Fetch the requester's user data to check permissions
    const requesterRef = firestore.collection('users').doc(requesterId);
    const requesterSnapshot = await requesterRef.get();

    if (!requesterSnapshot.exists) {
      throw new Error('User not found');
    }

    const requesterData = requesterSnapshot.data() as User;

    // Check permissions: only admin or moderator can apply user alerts
    const isAdmin = requesterData.role === 'admin';
    const isModerator = requesterData.role === 'moderator';

    if (!isAdmin && !isModerator) {
      throw new Error('Insufficient permissions to apply user timeout');
    }

    // Fetch the target user from Realtime Database to check if they exist
    const targetUserRef = db.ref(`users/${targetUserId}`);
    const targetUserSnapshot = await targetUserRef.get();

    if (!targetUserSnapshot.exists()) {
      throw new Error('Target user not found');
    }

    const targetUserData = targetUserSnapshot.val() as User;

    // Calculate one day from now (24 hours in milliseconds)
    const now = Date.now();
    const oneDayFromNow = now + (24 * 60 * 60 * 1000);

    // Check if user already has a future revivedAt (already has a timeout)
    if (targetUserData.revivedAt && targetUserData.revivedAt > now) {
      throw new Error('User already has an active timeout');
    }

    // Update the user's revivedAt field in Firebase Realtime Database
    await targetUserRef.update({
      revivedAt: oneDayFromNow,
    });

    // Also update the user cache in Firestore for consistency
    // const firestoreUserRef = firestore.collection('users').doc(targetUserId);
    // const firestoreUserSnapshot = await firestoreUserRef.get();

    // if (firestoreUserSnapshot.exists) {
    //   await firestoreUserRef.update({
    //     revivedAt: oneDayFromNow,
    //   });
    // }

    logger.info(`User ${targetUserId} given 1-day timeout by ${requesterId} (${requesterData.role})`);

    return {
      success: true,
      message: 'User timeout applied successfully',
      revivedAt: oneDayFromNow,
    };

  } catch (error) {
    logger.error('Error applying user alert:', error);

    // Return user-friendly error messages
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';

    return {
      success: false,
      error: errorMessage,
    };
  }
});

export default applyUserAlert;
