import * as admin from 'firebase-admin';
import { getAuth } from 'firebase-admin/auth';
import { getStorage } from 'firebase-admin/storage';
import { logger } from 'firebase-functions';
import { onRequest } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { formatDate, isDebugMode } from './helpers';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();
const firestore = admin.firestore();
const storage = getStorage();

const day = 24 * 60 * 60 * 1000;

const timeBeforeUserDeleting = isDebugMode() ? 0 * day : 200 * day;
const timeBeforeRoomDeleting = isDebugMode() ? 0 : 3 * day;
const timeBeforePairDeleting = isDebugMode() ? 0 : 3 * day;
const timeBeforeReportDeleting = isDebugMode() ? 0 : 7 * day;

interface Params {
  [id: string]: null;
}

interface RtdbUpdate {
  [path: string]: null | number; // Can be null for deletion or number for updatedAt
}

class SafeBatch {
  private batch: FirebaseFirestore.WriteBatch;
  private operationCount = 0;

  constructor(firestore: FirebaseFirestore.Firestore) {
    this.batch = firestore.batch();
  }

  delete(ref: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>): void {
    this.batch.delete(ref);
    this.operationCount++;
  }

  set(
    ref: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>,
    data: FirebaseFirestore.DocumentData
  ): void {
    this.batch.set(ref, data);
    this.operationCount++;
  }

  update(
    ref: FirebaseFirestore.DocumentReference<FirebaseFirestore.DocumentData>,
    data: FirebaseFirestore.UpdateData<FirebaseFirestore.DocumentData>
  ): void {
    this.batch.update(ref, data);
    this.operationCount++;
  }

  async commit(): Promise<void> {
    if (this.operationCount > 0) {
      await this.batch.commit();
    }
  }

  hasOperations(): boolean {
    return this.operationCount > 0;
  }
}

export const scheduledCleanup = onSchedule('every hour', async (_event) => {
  try {
    await setup();
    await cleanup();
  } catch (error) {
    logger.error(error);
  }
});

export const requestedCleanup = onRequest(async (_req, res) => {
  try {
    await setup();
    await migrate();
    await cleanup();
  } catch (error) {
    logger.error(error);
  }

  res.send('success');
});

const setup = async () => {
  const today = new Date();
  const tomorrow = new Date(today.getTime() + 24 * 3600 * 1000);

  try {
    await setupDailyStats(today);
    await setupDailyStats(tomorrow);
  } catch (error) {
    logger.error(error);
  }
};

const setupDailyStats = async (timestamp: Date) => {
  const statRef = db.ref(`stats/${formatDate(timestamp)}`);
  const snapshot = await statRef.get();

  try {
    if (!snapshot.exists()) {
      await statRef.set({
        users: 0,
        chats: 0,
        rooms: 0,
        messages: 0,
        responses: 0,
        follows: 0,
        unfollows: 0
      });
    }
  } catch (error) {
    logger.error(error);
  }
}

const migrate = async () => {
  try {
    await migrateUsers();
  } catch (error) {
    logger.error(error);
  }
}

// TODO: Remove later
const migrateUsers = async () => {
  const usersRef = db.ref('users');

  const query = usersRef
    .orderByChild('updatedAt')
    .endBefore(0)
    .limitToFirst(1000);

  try {
    const snapshot = await query.get();

    if (!snapshot.exists()) return;

    const users = snapshot.val();
    logger.info(users);
    const userIds = Object.keys(users);
    const params: Params = {};

    userIds.forEach((userId) => {
      const user = users[userId];
      if (!user['updatedAt']) {
        const timestamp = user.filter.slice(5);
        const then = new Date(timestamp).getTime();
        user['createdAt'] = then;
        user['updatedAt'] = then;
        params[userId] = user;
      }
    });

    await usersRef.update(params);
  } catch (error) {
    logger.error(error);
  }
}

const cleanup = async () => {
  try {
    await cleanupUsers();
    await cleanupRooms();
    await cleanupPairs();
    await cleanupReports();
  } catch (error) {
    logger.error(error);
  }
};

const cleanupUsers = async () => {
  try {
    await cleanupTempUsers();
    await cleanupLegacyPermUsers();
    await cleanupPermUsers();
  } catch (error) {
    logger.error(error);
  }
}

const cleanupTempUsers = async () => {
  const usersRef = db.ref('users');
  const time = new Date(new Date().getTime() - timeBeforeUserDeleting).toJSON();

  const query = usersRef
    .orderByChild('filter')
    .startAt('temp-0000')
    .endAt(`temp-${time}`)
    .limitToFirst(1000);

  try {
    const snapshot = await query.get();

    if (!snapshot.exists()) return;

    const users = snapshot.val();
    const userIds = Object.keys(users);
    const params: Params = {};

    userIds.forEach((userId) => {
      params[userId] = null;
    });

    await usersRef.update(params);
    await getAuth().deleteUsers(userIds);
  } catch (error) {
    logger.error(error);
  }
};

// TODO: Remove this once we have fully upgraded to v2.
const cleanupLegacyPermUsers = async () => {
  const usersRef = db.ref('users');
  const time = new Date(new Date().getTime() - timeBeforeUserDeleting * 3).toJSON();

  const query = usersRef
    .orderByChild('filter')
    .startAt('perm-0000')
    .endAt(`perm-${time}`)
    .limitToFirst(1000);

  try {
    const snapshot = await query.get();

    if (!snapshot.exists()) return;

    const users = snapshot.val();
    const userIds = Object.keys(users);
    const params: Params = {};

    userIds.forEach((userId) => {
      params[userId] = null;
    });

    await usersRef.update(params);
    await getAuth().deleteUsers(userIds);
  } catch (error) {
    logger.error(error);
  }
};

const cleanupPermUsers = async () => {
  const usersRef = db.ref('users');
  const now = Date.now();
  const thirtyDaysAgo = now - timeBeforeUserDeleting;

  // Query oldest users from RTDB
  const query = usersRef
    .orderByChild('updatedAt')
    .endAt(thirtyDaysAgo)
    .limitToFirst(1000);

  try {
    const snapshot = await query.get();
    if (!snapshot.exists()) return;

    const users = snapshot.val();
    const userIds = Object.keys(users);

    logger.info(`Found ${userIds.length} potentially inactive users`);

    // Process users in smaller batches to avoid memory issues
    const batchSize = 100;
    for (let i = 0; i < userIds.length; i += batchSize) {
      const batch = userIds.slice(i, i + batchSize);
      await processUserBatch(batch);
    }
  } catch (error) {
    logger.error('Error in cleanupPermUsers:', error);
  }
};

const processUserBatch = async (userIds: string[]) => {
  const firestoreBatch = new SafeBatch(firestore);
  const rtdbUpdates: RtdbUpdate = {};
  const usersToDelete: string[] = [];

  for (const userId of userIds) {
    try {
      // Check Firestore version
      const firestoreDoc = await firestore.collection('users').doc(userId).get();

      if (!firestoreDoc.exists) {
        // If no Firestore record exists, proceed with deletion
        rtdbUpdates[`users/${userId}`] = null;
        usersToDelete.push(userId);
        continue;
      }

      const firestoreData = firestoreDoc.data();
      if (!firestoreData) {
        // Handle the case where data is undefined, which wouldn't happen
        logger.warn(`No data found for user ${userId} in Firestore`);
        continue;
      }

      const firestoreUpdatedAt = firestoreData.updatedAt;
      if (typeof firestoreUpdatedAt !== 'number') {
        // Handle invalid updatedAt value, which wouldn't happen
        logger.warn(`Invalid updatedAt value for user ${userId}`);
        continue;
      }

      if (firestoreData.updatedAt <= Date.now() - timeBeforeUserDeleting) {
        // User is truly inactive, process for deletion
        await cleanupUserConnections(userId, firestoreBatch);
        firestoreBatch.delete(firestoreDoc.ref);
        rtdbUpdates[`users/${userId}`] = null;
        usersToDelete.push(userId);
      } else {
        // User is actually active, update RTDB
        rtdbUpdates[`users/${userId}/updatedAt`] = firestoreData.updatedAt;
      }
    } catch (error) {
      logger.error(`Error processing user ${userId}:`, error);
    }
  }

  try {
    // Execute all Firestore operations
    if (firestoreBatch.hasOperations()) {
      await firestoreBatch.commit();
    }

    // Execute all RTDB oprations
    if (Object.keys(rtdbUpdates).length > 0) {
      await db.ref().update(rtdbUpdates);
    }

    // Delete Authentication records
    if (usersToDelete.length > 0) {
      try {
        await getAuth().deleteUsers(usersToDelete);
        logger.info(`Successfully deleted ${usersToDelete.length} users`);
      } catch (error) {
        logger.error('Error deleting authentication records:', error);
      }
    }
  } catch (error) {
    logger.error('Error committing batch operations:', error);
  }
}

const cleanupUserConnections = async (
  userId: string,
  batch: SafeBatch
) => {
  try {
    // Get user's followees and followers
    const followeesSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('followees')
      .get();

    const followersSnapshot = await firestore
      .collection('users')
      .doc(userId)
      .collection('followers')
      .get();

    // Remove user from followees' followers lists
    for (const doc of followeesSnapshot.docs) {
      const followeeId = doc.id;
      batch.delete(
        firestore
          .collection('users')
          .doc(followeeId)
          .collection('followers')
          .doc(userId)
      );
    }

    // Remove user from followers' followees lists
    for (const doc of followersSnapshot.docs) {
      const followerId = doc.id;
      batch.delete(
        firestore
          .collection('users')
          .doc(followerId)
          .collection('followees')
          .doc(userId)
      );
    }

    // Delete user's own followees and followers collections
    for (const doc of followeesSnapshot.docs) {
      batch.delete(doc.ref);
    }
    for (const doc of followersSnapshot.docs) {
      batch.delete(doc.ref);
    }
  } catch (error) {
    logger.error(`Error cleaning up connections for user ${userId}:`, error);
    throw error; // Propagate error to handle it in the calling function
  }
};

// Rooms, messages & images
const cleanupRooms = async () => {
  const ref = db.ref('rooms');
  const time = new Date().getTime() - timeBeforeRoomDeleting;
  const query = ref.orderByChild('closedAt').endAt(time).limitToFirst(1000);

  const snapshot = await query.get();

  if (!snapshot.exists()) return;

  const rooms = snapshot.val();
  const roomIds = Object.keys(rooms);

  try {
    for (const roomId of roomIds) {
      await removeRoomImages(roomId);
      await removeRoomMessages(roomId);
      await removeRoom(roomId);
    }
  } catch (error) {
    logger.error(error);
  }
};

const removeRoomImages = async (roomId: string) => {
  try {
    const bucket = storage.bucket();
    const prefix = `rooms/${roomId}/`;

    const [files] = await bucket.getFiles({ prefix });

    const deletePromises = files.map(file => file.delete());
    await Promise.all(deletePromises);
  } catch (error) {
    logger.error(`Failed to remove images from room ${roomId}:`, error);
  }
};

const removeRoomMessages = async (roomId: string) => {
  const messagesRef = db.ref(`messages/${roomId}`);

  try {
    await messagesRef.remove();
  } catch (error) {
    logger.error(error);
  }
};

const removeRoom = async (roomId: string) => {
  const roomRef = db.ref(`rooms/${roomId}`);

  try {
    await roomRef.remove();
  } catch (error) {
    logger.error(error);
  }
};

// Pairs, chats, messages & images
// TODO: Try to remove orphaned messages and images (Maybe we should move the data to Cloud Firestore)
const cleanupPairs = async () => {
  try {
    const ref = db.ref('pairs');
    const time = new Date().getTime() - timeBeforePairDeleting;
    const query = ref.orderByChild('updatedAt').endAt(time).limitToFirst(1000);

    const snapshot = await query.get();

    if (!snapshot.exists()) return;

    const pairs = snapshot.val();
    const pairIds = Object.keys(pairs);

    for (const pairId of pairIds) {
      const chatId = pairId;
      const userIds = pairs[pairId].followers;

      await removeChatImages(chatId);
      await removeChatMessages(chatId);

      for (const userId of userIds) {
        await removeChat(userId, chatId);
      }

      await removePair(pairId);
    }
  } catch (error) {
    logger.error(error);
  }
};

const removeChatImages = async (chatId: string) => {
  try {
    const bucket = storage.bucket();
    const prefix = `chats/${chatId}/`;

    const [files] = await bucket.getFiles({ prefix });

    const deletePromises = files.map(file => file.delete());
    await Promise.all(deletePromises);
  } catch (error) {
    logger.error(`Failed to remove images from chat ${chatId}:`, error);
  }
};

const removeChatMessages = async (chatId: string) => {
  try {
    const messagesRef = db.ref(`messages/${chatId}`);
    await messagesRef.remove();
  } catch (error) {
    logger.error(error);
  }
};

const removeChat = async (userId: string, chatId: string) => {
  try {
    const chatRef = db.ref(`chats/${userId}/${chatId}`);
    await chatRef.remove();
  } catch (error) {
    logger.error(error);
  }
};

const removePair = async (pairId: string) => {
  try {
    const pairRef = db.ref(`pairs/${pairId}`);
    await pairRef.remove();
  } catch (error) {
    logger.error(error);
  }
};

const cleanupReports = async () => {
  const reportsRef = db.ref('reports');

  const now = new Date().getTime();
  const then = now - timeBeforeReportDeleting;

  const query = reportsRef
    .orderByChild('createdAt')
    .endBefore(then)
    .limitToFirst(1000);

  try {
    const snapshot = await query.get();

    if (!snapshot.exists()) return;

    const reports = snapshot.val();
    const reportIds = Object.keys(reports);
    const params: Params = {};

    reportIds.forEach((reportId) => {
      params[reportId] = null;
    });

    await reportsRef.update(params);
  } catch (error) {
    logger.error(error);
  }
}
