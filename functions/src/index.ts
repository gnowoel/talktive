const onUserRegistered = require('./onUserRegistered');
const onRoomCreated = require('./onRoomCreated');
const onMessageCreated = require("./onMessageCreated");
const onAccessCreated = require("./onAccessCreated");
const onExpireCreated = require("./onExpireCreated");
const { onScheduledCleanup, onRequestedCleanup } = require("./onScheduledCleanup");

module.exports = {
  onUserRegistered,   // Copy user
  onRoomCreated,      // Update user timestamp
  onMessageCreated,   // Update user and room timestamp
  onAccessCreated,    // Update room timestamp
  onExpireCreated,    // Update room timestamp
  onScheduledCleanup, // Cleanup users and rooms with scheduler
  onRequestedCleanup, // Cleanup users and rooms with request (for localhost)
};
