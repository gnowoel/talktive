import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:uuid/uuid.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given Admin endpoint', (sessionBuilder, endpoints) {
    const uuid = Uuid();

    late protocol.Resident adminResident;
    late protocol.Resident moderatorResident;
    late protocol.Resident regularResident;
    late protocol.Resident targetResident;
    late protocol.Report pendingReport;

    AuthenticationOverride authFor(protocol.Resident resident) {
      return AuthenticationOverride.authenticationInfo(
        resident.userInfoId.uuid,
        {},
      );
    }

    setUp(() async {
      final session = sessionBuilder.build();

      adminResident = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(uuid.v4()),
          userName: 'Admin',
          xp: 500,
          level: 5,
          trustScore: 100,
          role: protocol.ResidentRole.admin,
        ),
      );

      moderatorResident = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(uuid.v4()),
          userName: 'Moderator',
          xp: 500,
          level: 5,
          trustScore: 100,
          role: protocol.ResidentRole.moderator,
        ),
      );

      regularResident = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(uuid.v4()),
          userName: 'Resident',
          xp: 500,
          level: 5,
          trustScore: 100,
          role: protocol.ResidentRole.user,
        ),
      );

      targetResident = await protocol.Resident.db.insertRow(
        session,
        protocol.Resident(
          userInfoId: UuidValue.fromString(uuid.v4()),
          userName: 'Target Resident',
          xp: 500,
          level: 4,
          trustScore: 95,
          role: protocol.ResidentRole.user,
        ),
      );

      pendingReport = await protocol.Report.db.insertRow(
        session,
        protocol.Report(
          reporterId: regularResident.userInfoId,
          targetId: targetResident.userInfoId,
          reason: 'Spam in the Plaza',
          createdAt: DateTime.now(),
          status: protocol.ReportStatus.pending,
        ),
      );
    });

    test('denies pending report access to non-staff residents', () async {
      expect(
        () => endpoints.admin.getPendingReports(
          sessionBuilder.copyWith(authentication: authFor(regularResident)),
          limit: 50,
          offset: 0,
        ),
        throwsA(
          isA<protocol.TalktiveException>().having(
            (e) => e.code,
            'code',
            'ACCESS_DENIED',
          ),
        ),
      );
    });

    test('allows moderators to fetch pending reports', () async {
      final reports = await endpoints.admin.getPendingReports(
        sessionBuilder.copyWith(authentication: authFor(moderatorResident)),
        limit: 50,
        offset: 0,
      );

      expect(reports, hasLength(1));
      expect(reports.first.report.id, pendingReport.id);
      expect(reports.first.reporter.userId, regularResident.userInfoId);
      expect(reports.first.target.userId, targetResident.userInfoId);
    });

    test('requires admin role for platform statistics', () async {
      expect(
        () => endpoints.admin.getStatistics(
          sessionBuilder.copyWith(authentication: authFor(moderatorResident)),
        ),
        throwsA(
          isA<protocol.TalktiveException>().having(
            (e) => e.code,
            'code',
            'ADMIN_ACCESS_REQUIRED',
          ),
        ),
      );
    });

    test('returns platform statistics for admins', () async {
      final stats = await endpoints.admin.getStatistics(
        sessionBuilder.copyWith(authentication: authFor(adminResident)),
      );

      expect(stats.totals.users, greaterThanOrEqualTo(4));
      expect(stats.totals.reports, greaterThanOrEqualTo(1));
      expect(stats.totals.pendingReports, greaterThanOrEqualTo(1));
    });
  });
}
