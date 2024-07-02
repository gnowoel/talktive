const admin = require("firebase-admin");

admin.initializeApp();
const db = admin.database();

module.exports = {
  db,
};
