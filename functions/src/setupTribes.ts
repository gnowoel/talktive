import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onRequest } from 'firebase-functions/v2/https';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

interface TribeDefinition {
  name: string;
  description: string;
  iconEmoji: string;
}

// Predefined tribes for the application
const predefinedTribes: TribeDefinition[] = [
  {
    name: 'Friend Finder',
    description: 'Introduce yourself and meet new people',
    iconEmoji: '👋',
  },
  {
    name: 'Share Experiences',
    description: 'Share your life experiences and stories with others',
    iconEmoji: '📖',
  },
  {
    name: 'Casual Chat',
    description: 'Relaxed conversations about anything and everything',
    iconEmoji: '💬',
  },
  {
    name: 'Language Practice',
    description: 'Improve your language skills by chatting with others',
    iconEmoji: '🗣️',
  },
  {
    name: 'Deep Discussions',
    description: 'Engage in meaningful discussions about complex topics',
    iconEmoji: '🧠',
  },
  {
    name: 'App Feedback',
    description: 'Share your ideas to help improve this platform',
    iconEmoji: '💡',
  },
  // {
  //   name: 'Creative Corner',
  //   description: 'Express yourself and celebrate creativity',
  //   iconEmoji: '🎨',
  // },
  // {
  //   name: 'Tech Talk',
  //   description: 'Chat about the latest in technology and digital innovations',
  //   iconEmoji: '💻',
  // },
];

export const setupTribes = onRequest(async (_req, res) => {
  try {
    const now = Timestamp.now();
    const batch = firestore.batch();
    let createdCount = 0;
    let updatedCount = 0;

    // Process each predefined tribe
    for (const tribe of predefinedTribes) {
      // Check if tribe with this name already exists
      const existingTribes = await firestore
        .collection('tribes')
        .where('name', '==', tribe.name)
        .get();

      if (!existingTribes.empty) {
        // Update existing tribe
        const existingTribe = existingTribes.docs[0];
        batch.update(existingTribe.ref, {
          description: tribe.description,
          iconEmoji: tribe.iconEmoji,
          updatedAt: now,
        });
        updatedCount++;
      } else {
        // Create new tribe
        const tribeRef = firestore.collection('tribes').doc();
        batch.set(tribeRef, {
          name: tribe.name,
          description: tribe.description,
          iconEmoji: tribe.iconEmoji,
          createdAt: now,
          updatedAt: now,
          topicCount: 0,
        });
        createdCount++;
      }
    }

    // Commit all changes
    await batch.commit();

    logger.info(`Setup tribes completed: created ${createdCount}, updated ${updatedCount}`);
    res.status(200).send({
      success: true,
      created: createdCount,
      updated: updatedCount,
      tribes: predefinedTribes.map(t => t.name),
    });
  } catch (error) {
    logger.error('Error setting up tribes:', error);
    res.status(500).send({
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error',
    });
  }
});
