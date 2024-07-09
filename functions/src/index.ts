const onUserRegistered = require('./onUserRegistered');
const onRoomCreated = require('./onRoomCreated');
const onMessageCreated = require("./onMessageCreated");
const onAccessCreated = require("./onAccessCreated");
const onExpireCreated = require("./onExpireCreated");
const { scheduledCleanup, requestedCleanup } = require("./scheduledCleanup");

module.exports = {
  onUserRegistered,   // Copy user
  onRoomCreated,      // Update user timestamp
  onMessageCreated,   // Update user and room timestamp
  onAccessCreated,    // Update room timestamp
  onExpireCreated,    // Update room timestamp
  scheduledCleanup, // Cleanup users and rooms with scheduler
  requestedCleanup, // Cleanup users and rooms with request (for localhost)
};
