import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions'
import { onValueCreated } from 'firebase-functions/database';
import { Report, User, ReportParams }  from './types';
import { isDebugMode } from './helpers';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onReportCreated = onValueCreated('/reports/{reportId}', async (event) => {
  const report: Report = event.data.val();
  const chatId = report.chatId;
  const userId = report.userId;
  const partnerId = chatId.replace(userId, '');

  const partnerRef = db.ref(`users/${partnerId}`);
  const snapshot = await partnerRef.get();

  if (!snapshot.exists()) return;

  const partner: User = snapshot.val();
  const params: ReportParams = {};

  const oneDay = 1 * 24 * 60 * 60 * 1000;
  const now = new Date().getTime();
  const then = now - 7 * oneDay;
  const startAt = Math.max(partner.revivedAt ?? 0, then);

  if (isDebugMode()) {
    params.revivedAt = startAt + oneDay;
  } else {
    params.revivedAt = admin.database.ServerValue.increment(oneDay);
  }

  try {
    await partnerRef.update(params);
  } catch (error) {
    logger.error(error);
  }
});

export default onReportCreated;
