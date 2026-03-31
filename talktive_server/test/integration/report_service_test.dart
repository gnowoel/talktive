import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart' as protocol;
import 'package:talktive_server/src/services/report_service.dart';
import 'package:uuid/uuid.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given ReportService', (sessionBuilder, endpoints) {
    late protocol.Resident reporter;
    late protocol.Resident target;
    const uuid = Uuid();

    setUp(() async {
      final session = sessionBuilder.build();

      // Create a reporter user (Floor 1 by default)
      final res1 = protocol.Resident(
        userInfoId: UuidValue.fromString('a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d'),
        level: 1,
        trustScore: 100,
        role: protocol.ResidentRole.user,
      );
      reporter = await protocol.Resident.db.insertRow(session, res1);

      // Create a target user
      final res2 = protocol.Resident(
        userInfoId: UuidValue.fromString('b2c3d4e5-f6a7-4b5c-9d0e-1f2a3b4c5d6e'),
        level: 1,
        trustScore: 100,
        role: protocol.ResidentRole.user,
      );
      target = await protocol.Resident.db.insertRow(session, res2);
    });

    group('createReport', () {
      test('throws exception when reporter is below Floor 1', () async {
        final session = sessionBuilder.build();
        reporter.level = 0;
        await protocol.Resident.db.updateRow(session, reporter);

        expect(
          () => ReportService.createReport(
            session,
            reporter: reporter,
            target: target,
            reason: 'Toxic behavior',
          ),
          throwsA(isA<protocol.TalktiveException>().having(
            (e) => e.message,
            'message',
            contains('reach Floor 1 to report users'),
          )),
        );
      });

      test('allows report from Floor 1 user and applies penalty', () async {
        final session = sessionBuilder.build();
        
        final report = await ReportService.createReport(
          session,
          reporter: reporter,
          target: target,
          reason: 'Spamming',
        );

        expect(report.id, isNotNull);
        expect(report.status, protocol.ReportStatus.pending);

        // Verify penalty (-30 trust score)
        final updatedTarget = await protocol.Resident.db.findById(session, target.id!);
        expect(updatedTarget!.trustScore, 70);
      });

      test('throws exception when reporting the same user twice (One-Vote Rule)', () async {
        final session = sessionBuilder.build();
        
        await ReportService.createReport(
          session,
          reporter: reporter,
          target: target,
          reason: 'First report',
        );

        expect(
          () => ReportService.createReport(
            session,
            reporter: reporter,
            target: target,
            reason: 'Second report',
          ),
          throwsA(isA<protocol.TalktiveException>().having(
            (e) => e.message,
            'message',
            contains('already reported this user'),
          )),
        );
      });

      test('throws exception when reporting a vouched (liked) user', () async {
        final session = sessionBuilder.build();
        
        // Add a like
        await protocol.UserLike.db.insertRow(session, protocol.UserLike(
          senderId: reporter.userInfoId,
          receiverId: target.userInfoId,
          createdAt: DateTime.now(),
        ));

        expect(
          () => ReportService.createReport(
            session,
            reporter: reporter,
            target: target,
            reason: 'Betrayal!',
          ),
          throwsA(isA<protocol.TalktiveException>().having(
            (e) => e.message,
            'message',
            contains('cannot report a user you have vouched for'),
          )),
        );
      });

      test('enforces 30-minute cooldown between any reports', () async {
        final session = sessionBuilder.build();
        
        // Create another target
        final target2 = await protocol.Resident.db.insertRow(session, protocol.Resident(
          userInfoId: UuidValue.fromString(uuid.v4()),
          level: 1,
          trustScore: 100,
        ));

        await ReportService.createReport(
          session,
          reporter: reporter,
          target: target,
          reason: 'Report 1',
        );

        expect(
          () => ReportService.createReport(
            session,
            reporter: reporter,
            target: target2,
            reason: 'Report 2 (too soon)',
          ),
          throwsA(isA<protocol.TalktiveException>().having(
            (e) => e.message,
            'message',
            contains('wait'),
          )),
        );
      });

      test('enforces daily limit of 3 reports', () async {
        final session = sessionBuilder.build();
        final now = DateTime.now();

        // Mansually insert 3 reports from today but more than 30 mins ago
        for (int i = 0; i < 3; i++) {
          await protocol.Report.db.insertRow(session, protocol.Report(
            reporterId: reporter.userInfoId,
            targetId: UuidValue.fromString(uuid.v4()),
            reason: 'Reason $i',
            createdAt: now.subtract(Duration(minutes: 40 + i)),
            status: protocol.ReportStatus.pending,
          ));
        }

        expect(
          () => ReportService.createReport(
            session,
            reporter: reporter,
            target: target,
            reason: 'Report 4',
          ),
          throwsA(isA<protocol.TalktiveException>().having(
            (e) => e.message,
            'message',
            contains('Daily report limit reached'),
          )),
        );
      });
    });

    group('Auto Moderation Escalation', () {
      test('3 reports in 7 days should log warning (backend check)', () async {
        final session = sessionBuilder.build();
        final now = DateTime.now();

        // Target gets 2 reports already
        for (int i = 0; i < 2; i++) {
          await protocol.Report.db.insertRow(session, protocol.Report(
            reporterId: UuidValue.fromString(uuid.v4()),
            targetId: target.userInfoId,
            reason: 'Reason $i',
            createdAt: now.subtract(Duration(days: 1 + i)),
            status: protocol.ReportStatus.pending,
          ));
        }

        // 3rd report
        await ReportService.createReport(
          session,
          reporter: reporter,
          target: target,
          reason: 'The 3rd report',
        );

        // Verify status
        final updated = await protocol.Resident.db.findById(session, target.id!);
        expect(updated!.trustScore, 70); // 100 - 30 (only the current report penalty)
        expect(updated.mutedUntil, isNull);
      });

      test('5 reports in 7 days triggers 24h mute', () async {
        final session = sessionBuilder.build();
        final now = DateTime.now();

        // Target gets 4 reports already
        for (int i = 0; i < 4; i++) {
          await protocol.Report.db.insertRow(session, protocol.Report(
            reporterId: UuidValue.fromString(uuid.v4()),
            targetId: target.userInfoId,
            reason: 'Reason $i',
            createdAt: now.subtract(Duration(days: 1 + i)),
            status: protocol.ReportStatus.pending,
          ));
        }

        // 5th report
        await ReportService.createReport(
          session,
          reporter: reporter,
          target: target,
          reason: 'The 5th report',
        );

        final updated = await protocol.Resident.db.findById(session, target.id!);
        expect(updated!.trustScore, 70); // 100 - 30
        expect(updated.mutedUntil, isNotNull);
        expect(updated.mutedUntil!.isAfter(now.add(const Duration(hours: 23))), true);
      });

      test('10 reports in 30 days sets Trust Score to 0', () async {
        final session = sessionBuilder.build();
        final now = DateTime.now();

        // Target gets 9 reports already
        for (int i = 0; i < 9; i++) {
          await protocol.Report.db.insertRow(session, protocol.Report(
            reporterId: UuidValue.fromString(uuid.v4()),
            targetId: target.userInfoId,
            reason: 'Reason $i',
            createdAt: now.subtract(Duration(days: i)),
            status: protocol.ReportStatus.pending,
          ));
        }

        // 10th report
        await ReportService.createReport(
          session,
          reporter: reporter,
          target: target,
          reason: 'The 10th report',
        );

        final updated = await protocol.Resident.db.findById(session, target.id!);
        expect(updated!.trustScore, 0); // Severe threshold reached
      });
    });
  });
}
