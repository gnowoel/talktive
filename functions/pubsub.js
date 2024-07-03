const { PubSub } = require("@google-cloud/pubsub");
const { logger } = require("firebase-functions");

const pubsub = new PubSub({
  apiEndpoint: "localhost:8085",
});

const func = "scheduledCleanup";
const name = `firebase-schedule-${func}`;
const json = {};

pubsub.topic(name).publishMessage({ json }, (err, messageId) => {
  if (err) {
    logger.error(err);
  } else {
    logger.info(messageId);
  }
});
