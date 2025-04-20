import 'user.dart';

class Topic {
  final String id;
  final String title;
  final int createdAt;
  final int updatedAt;
  final UserStub creator;
  final int messageCount;

  const Topic({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.creator,
    required this.messageCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'creator': creator.toJson(),
      'messageCount': messageCount,
    };
  }

  factory Topic.fromJson(String id, Map<String, dynamic> json) {
    return Topic(
      id: id,
      title: json['title'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      creator: UserStub.fromJson(
        Map<String, dynamic>.from(json['creator'] as Map),
      ),
      messageCount: json['messageCount'] as int,
    );
  }
}
