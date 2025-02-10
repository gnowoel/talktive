import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions'
import { onValueCreated } from 'firebase-functions/database';
import { Report, User, PartnerParams, ReportParams } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const onReportCreated = onValueCreated('/reports/{reportId}', async (event) => {
  const reportId = event.params.reportId;
  const report: Report = event.data.val();

  try {
    resolveReport(reportId, report);
  } catch (error) {
    logger.error(error);
  }
});

const resolveReport = async (reportId: string, report: Report) => {
  const revivedAt = await getRevivedAt(report);
  await updatePartnerRevivedAt(report, revivedAt);
  await updateReportStatusAndRevivedAt(reportId, revivedAt);
}

const getRevivedAt = async (report: Report) => {
  const chatId = report.chatId;
  const userId = report.userId;
  const partnerId = chatId.replace(userId, '');

  const partnerRef = db.ref(`users/${partnerId}`);
  const snapshot = await partnerRef.get();

  if (!snapshot.exists()) return null;

  const partner: User = snapshot.val();

  const oneDay = 1 * 24 * 60 * 60 * 1000;
  const now = new Date().getTime();
  const then = now - 7 * oneDay;
  const startAt = Math.max(partner.revivedAt ?? 0, then);
  const remaining = startAt - then;
  let days = Math.floor(remaining / (2 * oneDay));
  if (days > 180) days = 1;
  const revivedAt = startAt + Math.max(days, 1) * oneDay;

  return revivedAt;
}

const updatePartnerRevivedAt = async (report: Report, revivedAt: number | null) => {
  if (revivedAt == null) return;

  const chatId = report.chatId;
  const userId = report.userId;
  const partnerId = chatId.replace(userId, '');

  const partnerRef = db.ref(`users/${partnerId}`);
  const params: PartnerParams = { revivedAt };

  try {
    await partnerRef.update(params);
  } catch (error) {
    logger.error(error);
  }
}

const updateReportStatusAndRevivedAt = async (reportId: string, revivedAt: number | null) => {
  const reportRef = db.ref(`reports/${reportId}`);
  const snapshot = await reportRef.get();

  if (!snapshot.exists()) return;

  const params: ReportParams = {};

  params.status = 'resolved';

  if (revivedAt != null) {
    params.revivedAt = revivedAt;
  }

  try {
    await reportRef.update(params);
  } catch (error) {
    logger.error(error);
  }
}

export default onReportCreated;
