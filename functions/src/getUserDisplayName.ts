import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';
import { onRequest } from 'firebase-functions/v2/https';
import { defineSecret } from 'firebase-functions/params';

if (!admin.app.length) {
  admin.initializeApp();
}

// Define the API key parameter
const API_KEY = defineSecret('GET_USER_API_SECRET');

export const getUserDisplayName = onRequest(
  {
    cors: true,
    secrets: [API_KEY],
  },
  async (request, response) => {
    try {
      // Only allow GET requests
      if (request.method !== 'GET') {
        response.status(405).json({
          success: false,
          error: 'Method not allowed. Use GET.'
        });
        return;
      }

      // Check API key
      const providedApiKey = request.headers.authorization?.replace('Bearer ', '') ||
        request.headers['x-api-key'] ||
        request.query.apiKey;

      if (!providedApiKey || providedApiKey !== API_KEY.value()) {
        logger.warn('Unauthorized access attempt to getUserDisplayName');
        response.status(401).json({
          success: false,
          error: 'Unauthorized. Valid API key required.'
        });
        return;
      }

      // Get userId from query parameters
      const userId = request.query.userId as string;

      if (!userId) {
        response.status(400).json({
          success: false,
          error: 'Missing required parameter: userId'
        });
        return;
      }

      // Validate userId format (basic validation)
      if (typeof userId !== 'string' || userId.length === 0) {
        response.status(400).json({
          success: false,
          error: 'Invalid userId format'
        });
        return;
      }

      // Get user from Firebase Authentication
      const userRecord = await admin.auth().getUser(userId);

      // Return the displayName
      response.status(200).json({
        success: true,
        data: {
          userId: userRecord.uid,
          displayName: userRecord.displayName || null,
          email: userRecord.email || null, // Optional: include email
          emailVerified: userRecord.emailVerified
        }
      });

    } catch (error) {
      logger.error('Error getting user display name:', error);

      // Handle specific Firebase Auth errors
      if (error instanceof Error) {
        if (error.message.includes('There is no user record')) {
          response.status(404).json({
            success: false,
            error: 'User not found'
          });
          return;
        }

        if (error.message.includes('Invalid user ID')) {
          response.status(400).json({
            success: false,
            error: 'Invalid user ID format'
          });
          return;
        }
      }

      // Generic error response
      response.status(500).json({
        success: false,
        error: 'Internal server error'
      });
    }
  }
);
