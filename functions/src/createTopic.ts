import * as admin from 'firebase-admin';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';
import { StatParams, User } from './types';
import { formatDate, isDebugMode } from './helpers';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();
const db = admin.database();

export const createTopic = onCall(async (request) => {
  try {
    const { userId, title, message, tribeId, isPublic } = request.data;

    if (!userId || !title || !message) {
      return {
        success: false,
        error: 'Missing required fields'
      }
    }

    const userDoc = await firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return {
        success: false,
        error: 'User not found'
      };
    }

    const now = Timestamp.now();
    const user = userDoc.data() as User;
    const creator: User = {
      id: userId,
      createdAt: 0,
      updatedAt: 0,
      photoURL: user.photoURL,
      displayName: user.displayName,
      languageCode: user.languageCode,
      gender: user.gender,
      revivedAt: user.revivedAt,
      messageCount: user.messageCount,
    };

    const topicRef = await firestore.collection('topics').add({
      title,
      creator,
      createdAt: now,
      updatedAt: now,
      messageCount: 0, // Copy to downstream
      lastMessageContent: message, // Copy to downstream
      tribeId: tribeId || null,
      isPublic: isPublic ?? true,
    });

    const topicId = topicRef.id;

    // Use a batch write for atomic operations
    const batch = firestore.batch();

    // Add first message
    const messageRef = firestore
      .collection('topics')
      .doc(topicId)
      .collection('messages')
      .doc();

    batch.set(messageRef, {
      type: 'text',
      userId,
      userDisplayName: user.displayName ?? '',
      userPhotoURL: user.photoURL ?? '',
      content: message,
      createdAt: now,
    });

    // Add creator to followers collection
    const followerRef = firestore
      .collection('topics')
      .doc(topicId)
      .collection('followers')
      .doc(userId)

    batch.set(followerRef, {
      muted: false,
    });

    // Add topic reference to user's topics collection
    const userTopicRef = firestore
      .collection('users')
      .doc(userId)
      .collection('topics')
      .doc(topicId);

    batch.set(userTopicRef, {
      title,
      creator,
      createdAt: now,
      updatedAt: now,
      messageCount: 0, // Copy from upstream
      readMessageCount: 1, // Creator has read their own message
      lastMessageContent: message, // Copy from upstream
      mute: false,
      tribeId: tribeId || null,
      isPublic: isPublic ?? true,
    });

    // Get the creator's followers
    const followersSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('followers')
      .get();

    // Add each follower to the topic's followers and add the topic to each follower's topics collection
    for (const followerDoc of followersSnapshot.docs) {
      const followerId = followerDoc.id;

      // Add follower to topic's followers collection
      const topicFollowerRef = firestore
        .collection('topics')
        .doc(topicId)
        .collection('followers')
        .doc(followerId);

      batch.set(topicFollowerRef, {
        muted: false,
      });

      // Add topic to follower's topics collection
      const followerTopicRef = firestore
        .collection('users')
        .doc(followerId)
        .collection('topics')
        .doc(topicId);

      batch.set(followerTopicRef, {
        title,
        creator,
        createdAt: now,
        updatedAt: now,
        messageCount: 0, // Copy from upstream
        readMessageCount: 0, // Follower hasn't read the first message yet
        lastMessageContent: message, // Copy from upstream
        mute: false,
        tribeId: tribeId || null,
        isPublic: isPublic ?? true,
      });
    }

    // Commit all operations
    await batch.commit();

    // If a tribe was specified, increment its topic count
    if (tribeId) {
      const tribeRef = firestore.collection('tribes').doc(tribeId);
      await tribeRef.update({
        topicCount: FieldValue.increment(1),
        updatedAt: now,
      });
    }

    await updateTopicStats();

    return {
      success: true,
      topicId,
      // topicCreatorId: userId // The client already knew.
    };
  } catch (error) {
    logger.error('Error creating topic:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});

const updateTopicStats = async () => {
  const now = new Date();
  const statRef = db.ref(`stats/${formatDate(now)}`);
  const snapshot = await statRef.get();

  if (!snapshot.exists()) return;

  const stat = snapshot.val();
  const params: StatParams = {};

  // `ServerValue` doesn't work with Emulators Suite
  if (isDebugMode()) {
    params.topics = (stat.topics ?? 0) + 1;
  } else {
    params.topics = admin.database.ServerValue.increment(1);
  }

  try {
    await statRef.update(params);
  } catch (error) {
    logger.error(error);
  }
};
