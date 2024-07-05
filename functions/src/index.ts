import { onValueCreated } from "firebase-functions/v2/database";
import * as logger from "firebase-functions/logger";

export const helloWorld = onValueCreated("/messages/{roomId}/*", (event) => {
  const roomId = event.params.roomId;
  logger.info(`roomId: ${roomId}`);
});
