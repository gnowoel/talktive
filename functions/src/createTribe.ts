import * as admin from 'firebase-admin';
import { Timestamp } from 'firebase-admin/firestore';
import { logger } from 'firebase-functions';
import { onCall } from 'firebase-functions/v2/https';

if (!admin.apps.length) {
  admin.initializeApp();
}

const firestore = admin.firestore();

export const createTribe = onCall(async (request) => {
  try {
    const { name, description, iconEmoji } = request.data;

    if (!name) {
      return {
        success: false,
        error: 'Missing tribe name'
      }
    }

    // Check if tribe with this name already exists
    const existingTribes = await firestore
      .collection('tribes')
      .where('name', '==', name)
      .get();

    if (!existingTribes.empty) {
      // Return the existing tribe instead of creating a new one
      const existingTribe = existingTribes.docs[0];
      return {
        success: true,
        tribeId: existingTribe.id,
        existing: true
      };
    }

    const now = Timestamp.now();
    
    const tribeRef = await firestore.collection('tribes').add({
      name,
      description: description || null,
      iconEmoji: iconEmoji || null,
      createdAt: now,
      updatedAt: now,
      topicCount: 0,
    });

    const tribeId = tribeRef.id;

    return {
      success: true,
      tribeId,
      existing: false
    };
  } catch (error) {
    logger.error('Error creating tribe:', error);
    return {
      success: false,
      error: error instanceof Error ? error.message : 'Unknown error'
    };
  }
});