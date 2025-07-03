import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { User, Topic } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

interface MakeTopicPublicRequest {
  topicId: string;
  userId: string;
}

export const makeTopicPublic = onCall(async (request) => {
  try {
    // Check authentication
    if (!request.auth?.uid) {
      throw new Error('Authentication required');
    }

    const requesterId = request.auth.uid;
    const { topicId, userId } = request.data as MakeTopicPublicRequest;

    // Validate input
    if (!topicId || !userId) {
      throw new Error('Missing required parameters: topicId, userId');
    }

    // Ensure the requester is the same as the userId parameter
    if (requesterId !== userId) {
      throw new Error('User ID mismatch');
    }

    // Fetch the topic
    const topicRef = firestore.collection('topics').doc(topicId);
    const topicSnapshot = await topicRef.get();

    if (!topicSnapshot.exists) {
      throw new Error('Topic not found');
    }

    const topicData = topicSnapshot.data() as Topic;

    // Check if topic is already public
    if (topicData.isPublic === true) {
      throw new Error('Topic is already public');
    }

    // Fetch the requester's user data to check permissions
    const requesterRef = firestore.collection('users').doc(requesterId);
    const requesterSnapshot = await requesterRef.get();

    if (!requesterSnapshot.exists) {
      throw new Error('User not found');
    }

    const requesterData = requesterSnapshot.data() as User;

    // Check permissions: only admins can make private topics public
    const isAdmin = requesterData.role === 'admin';

    if (!isAdmin) {
      throw new Error('Only admins can make private topics public');
    }

    // Use batch operations for atomic updates
    const batch = firestore.batch();

    // Update the main topic document
    batch.update(topicRef, {
      isPublic: true,
      // updatedAt: Timestamp.now(),
    });

    // Get all topic followers to update their individual topic documents
    const followersSnapshot = await firestore
      .collection('topics')
      .doc(topicId)
      .collection('followers')
      .get();

    // Update each follower's topic document to reflect the privacy change
    followersSnapshot.docs.forEach((followerDoc) => {
      const followerId = followerDoc.id;
      const userTopicRef = firestore
        .collection('users')
        .doc(followerId)
        .collection('topics')
        .doc(topicId);

      // Use set with merge to handle cases where the document might not exist
      batch.set(userTopicRef, {
        isPublic: true,
        // updatedAt: Timestamp.now(),
      }, { merge: true });
    });

    // Commit all updates
    await batch.commit();

    logger.info(`Topic ${topicId} made public by admin ${requesterId}`);

    return {
      success: true,
      message: 'Topic successfully made public',
    };

  } catch (error) {
    logger.error('Error making topic public:', error);

    // Return user-friendly error messages
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';

    return {
      success: false,
      error: errorMessage,
    };
  }
});

export default makeTopicPublic;
