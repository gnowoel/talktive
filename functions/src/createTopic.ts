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
    const { userId, title, message, tribeId, isPublic, targetUserId } = request.data;

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

    // Prevent users from creating topics with themselves
    if (targetUserId && userId === targetUserId) {
      return {
        success: false,
        error: 'Cannot create a conversation with yourself'
      };
    }

    // Default to "Friend Finder" tribe if no tribe specified and not a two-person topic
    let finalTribeId = tribeId;
    if (!tribeId && !targetUserId) {
      try {
        const friendFinderQuery = await firestore
          .collection('tribes')
          .where('name', '==', 'Friend Finder')
          .limit(1)
          .get();

        if (!friendFinderQuery.empty) {
          finalTribeId = friendFinderQuery.docs[0].id;
        }
      } catch (error) {
        logger.info('Could not find Friend Finder tribe, proceeding without tribe');
      }
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
      followerCount: user.followerCount ?? 0,
    };

    const topicRef = await firestore.collection('topics').add({
      title,
      creator,
      createdAt: now,
      updatedAt: now,
      messageCount: 0, // Sync to downstream
      lastMessageContent: message, // Sync to downstream
      tribeId: finalTribeId || null,
      isPublic: isPublic ?? true, // Sync to downstream
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
      messageCount: 0, // Sync from upstream
      readMessageCount: 0, // Prevent showing divider after the first message
      lastMessageContent: message, // Sync from upstream
      mute: false,
      tribeId: finalTribeId || null,
      isPublic: isPublic ?? true, // Sync from upstream
    });

    // Handle follower addition based on topic type
    if (targetUserId) {
      // Two-person topic: only add the target user
      const targetUserDoc = await firestore.collection('users').doc(targetUserId).get();
      if (targetUserDoc.exists) {
        const targetUser = targetUserDoc.data() as User;
        const targetUserStub: User = {
          id: targetUserId,
          createdAt: 0,
          updatedAt: 0,
          photoURL: targetUser.photoURL,
          displayName: targetUser.displayName,
          languageCode: targetUser.languageCode,
          gender: targetUser.gender,
          revivedAt: targetUser.revivedAt,
          messageCount: targetUser.messageCount,
          followerCount: targetUser.followerCount ?? 0,
        };

        // Add target user to topic's followers collection
        const targetFollowerRef = firestore
          .collection('topics')
          .doc(topicId)
          .collection('followers')
          .doc(targetUserId);

        batch.set(targetFollowerRef, {
          muted: false,
        });

        // Add topic reference to target user's topics collection with creator's info
        const targetTopicRef = firestore
          .collection('users')
          .doc(targetUserId)
          .collection('topics')
          .doc(topicId);

        batch.set(targetTopicRef, {
          title: user.displayName || 'Two-person chat', // Target user sees creator's name as title
          creator, // Target user sees creator as the "creator"
          createdAt: now,
          updatedAt: now,
          messageCount: 0, // Copy from upstream
          readMessageCount: 0, // Target user hasn't read the first message yet
          lastMessageContent: message, // Copy from upstream
          mute: false,
          tribeId: finalTribeId || null,
          isPublic: isPublic ?? true,
        });

        // Add topic reference to creator's topics collection with target user's info
        const userTopicRef = firestore
          .collection('users')
          .doc(userId)
          .collection('topics')
          .doc(topicId);

        batch.set(userTopicRef, {
          title: targetUser.displayName || 'Two-person chat', // Creator sees target's name as title
          creator: targetUserStub, // Creator sees target user as the "creator"
          createdAt: now,
          updatedAt: now,
          messageCount: 0, // Sync from upstream
          readMessageCount: 0, // Prevent showing divider after the first message
          lastMessageContent: message, // Sync from upstream
          mute: false,
          tribeId: finalTribeId || null,
          isPublic: isPublic ?? true,
        });

      }
    } else {
      // Add topic reference to user's topics collection for regular topics
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
        messageCount: 0, // Sync from upstream
        readMessageCount: 0, // Prevent showing divider after the first message
        lastMessageContent: message, // Sync from upstream
        mute: false,
        tribeId: finalTribeId || null,
        isPublic: isPublic ?? true,
      });

      // Regular topic: add all followers
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
          tribeId: finalTribeId || null,
          isPublic: isPublic ?? true,
        });
      }
    }

    // Commit all operations
    await batch.commit();

    // If a tribe was specified or defaulted, increment its topic count
    if (finalTribeId) {
      const tribeRef = firestore.collection('tribes').doc(finalTribeId);
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
  const params: StatParams = {};

  // `ServerValue` doesn't work with Emulators Suite
  if (isDebugMode()) {
    const snapshot = await statRef.get();
    if (!snapshot.exists()) return;
    const stat = snapshot.val();
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
