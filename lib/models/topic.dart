import 'user.dart';

class Topic {
  final String id;
  final String title;
  final int createdAt;
  final int updatedAt;
  final UserStub user;
  final int messageCount;

  const Topic({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    required this.messageCount,
  });
}
