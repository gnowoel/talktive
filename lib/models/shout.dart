import 'user.dart';

class Shout {
  final String id;
  final String topic;
  final int createdAt;
  final int updatedAt;
  final UserStub user;
  final int messageCount;

  const Shout({
    required this.id,
    required this.topic,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.messageCount,
  });
}
