class User {
  final String id;
  final int createdAt;
  final int updatedAt;
  final String? photoURL;
  final String? displayName;
  final String? description;
  final String? gender;

  User({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.photoURL,
    this.displayName,
    this.description,
    this.gender,
  });

  factory User.fromStub({
    required String key,
    required UserStub value,
  }) {
    return User(
      id: key,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
      photoURL: value.photoURL,
      displayName: value.displayName,
      description: value.description,
      gender: value.gender,
    );
  }
}

class UserStub {
  final int createdAt;
  final int updatedAt;
  final String? photoURL;
  final String? displayName;
  final String? description;
  final String? gender;

  UserStub({
    required this.createdAt,
    required this.updatedAt,
    this.photoURL,
    this.displayName,
    this.description,
    this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'photoURL': photoURL,
      'displayName': displayName,
      'description': description,
      'gender': gender,
    };
  }

  factory UserStub.fromJson(Map<String, dynamic> json) {
    return UserStub(
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      photoURL: json['photoURL'] as String?,
      displayName: json['displayName'] as String?,
      description: json['description'] as String?,
      gender: json['gender'] as String?,
    );
  }
}
