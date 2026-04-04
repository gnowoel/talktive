import 'package:serverpod/serverpod.dart';

class ProtocolUtils {
  /// Consistently orders two UUIDs for 1:1 chat identifier generation.
  static List<UuidValue> orderParticipants(UuidValue id1, UuidValue id2) {
    if (id1.uuid.compareTo(id2.uuid) < 0) {
      return [id1, id2];
    } else {
      return [id2, id1];
    }
  }
}
