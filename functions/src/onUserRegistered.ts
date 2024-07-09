import * as functions from "firebase-functions/v1";
import { logger } from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onUserRegistered = functions.auth.user().onCreate((user) => {
  const userId = user.uid;
  const userRef = db.ref(`users/${userId}`);
  const createdAt = new Date().toJSON();
  const params = {
    filter: `temp-${createdAt}`,
  };

  return userRef.set(params).catch((error) => {
    logger.error(error);
  });
});

export default onUserRegistered;
