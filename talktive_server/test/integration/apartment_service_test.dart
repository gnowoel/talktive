import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talktive_server/src/generated/protocol.dart';
import 'package:talktive_server/src/services/apartment_service.dart';
import 'package:uuid/uuid.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Given ApartmentService', (sessionBuilder, endpoints) {
    late Resident resident;
    const uuid = Uuid();

    setUp(() async {
      final session = sessionBuilder.build();
      resident = Resident(
        userInfoId: UuidValue.fromString(uuid.v4()),
        level: 10, // High activity
        trustScore: 100, // Balanced reputation
      );
      // We don't necessarily need to insert it for pure formula tests,
      // but for restoration tests we do.
      resident = await Resident.db.insertRow(session, resident);
    });

    group('INVITE / SOCIAL RULES', () {
      test('canInvite returns false for self-invite', () async {
        final canInvite = ApartmentService.canInvite(
          sender: resident,
          receiver: resident,
        );
        expect(canInvite, isFalse);
      });

      test(
        'cannotInviteReason returns self-knock message for self-invite',
        () async {
          final reason = ApartmentService.cannotInviteReason(
            sender: resident,
            receiver: resident,
          );
          expect(reason, 'You cannot knock on your own door.');
        },
      );
    });

    group('Effective Floor Formula', () {
      test(
        'is capped by trust score if user is high-level but poorly behaved',
        () async {
          // level 20, but trust score 50 (cap is 15)
          resident.level = 20;
          resident.trustScore = 50;

          final effectiveFloor = ApartmentService.computeEffectiveFloor(
            resident,
          );
          expect(effectiveFloor, 15);
        },
      );

      test('is capped by level if user is trusted but low-level', () async {
        // level 2, but trust score 1000 (cap is 50)
        resident.level = 2;
        resident.trustScore = 1000;

        final effectiveFloor = ApartmentService.computeEffectiveFloor(resident);
        expect(effectiveFloor, 2);
      });

      test('returns 0 if trust score is zero', () async {
        resident.level = 50;
        resident.trustScore = 0;

        final effectiveFloor = ApartmentService.computeEffectiveFloor(resident);
        expect(effectiveFloor, 0);
      });
    });

    group('Trust Score Restoration', () {
      test('restores points over time', () async {
        final session = sessionBuilder.build();

        // 2 hours ago
        resident.trustScore = 50;
        resident.lastReputationIncrease = DateTime.now().subtract(
          const Duration(hours: 2),
        );
        await Resident.db.updateRow(session, resident);

        final changed = await ApartmentService.restoreTrustScore(
          session,
          resident,
        );
        expect(changed, true);
        // 50 + (2 * 5) = 60
        expect(resident.trustScore, 60);
      });

      test('does not restore beyond 100', () async {
        final session = sessionBuilder.build();

        resident.trustScore = 98;
        resident.lastReputationIncrease = DateTime.now().subtract(
          const Duration(hours: 10),
        );
        await Resident.db.updateRow(session, resident);

        await ApartmentService.restoreTrustScore(session, resident);
        expect(resident.trustScore, 100);
      });
    });

    group('Mute Logic', () {
      test('isMuted returns true for low trust score', () {
        resident.trustScore = 0;
        expect(ApartmentService.isMuted(resident), true);
      });

      test('isMuted returns true for suspension', () {
        resident.suspended = true;
        expect(ApartmentService.isMuted(resident), true);
      });

      test('isMuted returns true for temporary mute', () {
        resident.mutedUntil = DateTime.now().add(const Duration(hours: 1));
        expect(ApartmentService.isMuted(resident), true);
      });

      test('isMuted returns false for healthy resident', () {
        resident.trustScore = 100;
        resident.suspended = false;
        resident.mutedUntil = null;
        expect(ApartmentService.isMuted(resident), false);
      });
    });
  });
}
