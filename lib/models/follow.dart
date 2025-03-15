import 'user.dart';

class Follow {
  final String id;
  final int createdAt;
  final int updatedAt;
  final UserStub user;

  const Follow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'user': user.toJson(),
    };
  }

  factory Follow.fromJson(Map<String, dynamic> json) {
    return Follow(
      id: json['id'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      user: UserStub.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
    );
  }
}
