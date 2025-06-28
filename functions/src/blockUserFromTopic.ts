import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { User } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

interface BlockUserFromTopicRequest {
  topicId: string;
  userId: string; // User to be blocked
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

export const blockUserFromTopic = onCall(async (request) => {
  try {
    // Get the authenticated user
    if (!request.auth?.uid) {
      throw new Error('Authentication required');
    }

    const requesterId = request.auth.uid;
    const { topicId, userId } = request.data as BlockUserFromTopicRequest;

    // Validate input
    if (!topicId || !userId) {
      throw new Error('Missing required parameters: topicId, userId');
    }

    // Prevent self-blocking
    if (requesterId === userId) {
      throw new Error('Cannot block yourself');
    }

    // Fetch the topic to check permissions
    const topicRef = firestore.collection('topics').doc(topicId);
    const topicSnapshot = await topicRef.get();

    if (!topicSnapshot.exists) {
      throw new Error('Topic not found');
    }

    const topicData = topicSnapshot.data() as TopicData;

    // Fetch the requester's user data to check for admin/moderator role
    const requesterRef = firestore.collection('users').doc(requesterId);
    const requesterSnapshot = await requesterRef.get();

    if (!requesterSnapshot.exists) {
      throw new Error('Requester user not found');
    }

    const requesterData = requesterSnapshot.data() as User;

    // Check permissions: admin, moderator, or topic creator
    const isAdmin = requesterData.role === 'admin';
    const isModerator = requesterData.role === 'moderator';
    const isTopicCreator = topicData.creator.id === requesterId;

    if (!isAdmin && !isModerator && !isTopicCreator) {
      throw new Error('Insufficient permissions to block users from this topic');
    }

    // Check if the user is actually a follower of the topic
    const followerRef = firestore
      .collection('topics')
      .doc(topicId)
      .collection('followers')
      .doc(userId);

    const followerSnapshot = await followerRef.get();
    if (!followerSnapshot.exists) {
      throw new Error('User is not a follower of this topic');
    }

    // Check if user is already blocked
    const followerData = followerSnapshot.data();
    if (followerData?.isBlocked === true) {
      throw new Error('User is already blocked from this topic');
    }

    // Block the user by setting isBlocked to true
    await followerRef.update({
      isBlocked: true,
      blockedAt: Timestamp.now(),
    });

    // Remove the topic from the blocked user's topics collection
    const userTopicRef = firestore
      .collection('users')
      .doc(userId)
      .collection('topics')
      .doc(topicId);

    await userTopicRef.delete();

    logger.info(`User ${userId} blocked from topic ${topicId} by ${requesterId}`);

    return {
      success: true,
      message: 'User successfully blocked from topic',
    };

  } catch (error) {
    logger.error('Error blocking user from topic:', error);

    // Return user-friendly error messages
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred';

    return {
      success: false,
      error: errorMessage,
    };
  }
});

export default blockUserFromTopic;
