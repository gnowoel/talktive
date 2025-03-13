import 'user.dart';

class Friend {
  final String id;
  final int createdAt;
  final int updatedAt;
  final UserStub partner;

  const Friend({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.partner,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'partner': partner.toJson(),
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      partner: UserStub.fromJson(
        Map<String, dynamic>.from(json['partner'] as Map),
      ),
    );
  }
}
