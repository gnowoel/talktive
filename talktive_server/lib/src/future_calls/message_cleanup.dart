import 'package:serverpod/serverpod.dart' hide Message;
import '../generated/protocol.dart';

class MessageCleanupCall extends FutureCall {
  @override
  Future<void> invoke(Session session, dynamic object) async {
    // Delete messages older than 30 days.
    final cutoff = DateTime.now().subtract(Duration(days: 30));

    // Explicitly use the Message class from protocol.dart
    await Message.db.deleteWhere(session, where: (t) => t.createdAt < cutoff);

    session.log('Cleaned up messages older than $cutoff');
  }
}
