const functions = require('firebase-functions/v1');
const { logger } = require("firebase-functions");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const syncUser = functions.auth.user().onCreate((user) => {
  const uid = user.uid;
  const userRef = db.ref(`users/${uid}`);
  const createdAt = new Date().toJSON();
  const params = {
    filter: `temp-${createdAt}`
  };

  userRef.set(params);
});

module.exports = syncUser;
