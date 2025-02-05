import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions'
import { onValueCreated } from 'firebase-functions/database';
import { Report, User, PartnerParams, ReportParams }  from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onReportCreated = onValueCreated('/reports/{reportId}', async (event) => {
  const reportId = event.params.reportId;
  const report: Report = event.data.val();

  try {
    await updatePartnerRevivedAt(report);
    await updateReportStatus(reportId);
  } catch (error) {
    logger.error(error);
  }
});

const updatePartnerRevivedAt = async (report: Report) => {
  const chatId = report.chatId;
  const userId = report.userId;
  const partnerId = chatId.replace(userId, '');

  const partnerRef = db.ref(`users/${partnerId}`);
  const snapshot = await partnerRef.get();

  if (!snapshot.exists()) return;

  const partner: User = snapshot.val();
  const params: PartnerParams = {};

  const oneDay = 1 * 24 * 60 * 60 * 1000;
  const now = new Date().getTime();
  const then = now - 7 * oneDay;
  const startAt = Math.max(partner.revivedAt ?? 0, then);

  params.revivedAt = startAt + oneDay;

  try {
    await partnerRef.update(params);
  } catch (error) {
    logger.error(error);
  }
}

const updateReportStatus = async (reportId: string) => {
  const reportRef = db.ref(`reports/${reportId}`);
  const snapshot = await reportRef.get();

  if (!snapshot.exists()) return;

  const params: ReportParams = {};

  params.status = 'resolved';

  try {
    await reportRef.update(params);
  } catch (error) {
    logger.error(error);
  }
}

export default onReportCreated;
