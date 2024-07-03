const { onSchedule } = require("firebase-functions/v2/scheduler");
const { logger } = require("firebase-functions");

const scheduledCleanup = onSchedule("1 * * * *", async (event) => {
  logger.info(event);
});

module.exports = scheduledCleanup;
