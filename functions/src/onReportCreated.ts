import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions'
import { onValueCreated } from 'firebase-functions/database';
import { Report, User, PartnerParams, ReportParams } from './types';

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.database();

const oneDay = 1 * 24 * 60 * 60 * 1000;

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
  const partner = await getPartner(report);
  if (!partner) return;

  const now = new Date().getTime();
  const oldRevivedAt = getOldRevivedAt(now, partner);
  const newRevivedAt = await getNewRevivedAt(now, oldRevivedAt);

  await updatePartnerRevivedAt(report, newRevivedAt);
  await updateReportStatusAndRevivedAt(reportId, newRevivedAt);

  const oldUserStatus = getUserStatus(now, oldRevivedAt);
  const newUserStatus = getUserStatus(now, newRevivedAt);

  if (oldUserStatus !== newUserStatus) {
    // TODO: Update partner's chats
  }
}

const getPartner = async (report: Report) => {
  const chatId = report.chatId;
  const userId = report.userId;
  const partnerId = chatId.replace(userId, '');

  const partnerRef = db.ref(`users/${partnerId}`);
  const snapshot = await partnerRef.get();

  if (!snapshot.exists()) return null;

  const partner: User = snapshot.val();
  return partner;
}

const getOldRevivedAt = (now: number, partner: User) => {
  const then = now - 7 * oneDay;
  const oldRevivedAt = Math.max(partner.revivedAt ?? 0, then);
  return oldRevivedAt;
}

const getNewRevivedAt = async (now: number, oldRevivedAt: number) => {
  const then = now - 7 * oneDay;
  const remaining = oldRevivedAt - then;

  let days = Math.ceil(remaining / oneDay);
  if (days < 1 || days > 256) days = 1;

  const newRevivedAt = oldRevivedAt + days * oneDay;
  return newRevivedAt;
}

const getUserStatus = (now: number, revivedAt: number) => {
  if (revivedAt >= now + 14 * oneDay) return 'warning';
  if (revivedAt >= now) return 'alert';
  return 'regular';
}

const updatePartnerRevivedAt = async (report: Report, revivedAt: number | null) => {
  if (!revivedAt) return;

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

  if (revivedAt) {
    params.revivedAt = revivedAt;
  }

  try {
    await reportRef.update(params);
  } catch (error) {
    logger.error(error);
  }
}

export default onReportCreated;
