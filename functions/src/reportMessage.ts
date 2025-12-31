import { onCall, HttpsError } from 'firebase-functions/v2/https';

export const reportMessage = onCall(async (request) => {
  throw new HttpsError('failed-precondition', 'Please upgrade your app to the latest version to report a message.');
});


