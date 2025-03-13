class Friend {
  final String id;
  final String languageCode;
  final String photoURL;
  final String displayName;
  final String description;
  final String gender;
  final int createdAt;
  final int updatedAt;

  const Friend({
    required this.id,
    required this.languageCode,
    required this.photoURL,
    required this.displayName,
    required this.description,
    required this.gender,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userLanguageCode': languageCode,
      'userPhotoURL': photoURL,
      'userDisplayName': displayName,
      'userDescription': description,
      'userGender': gender,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      languageCode: json['userLanguageCode'] as String,
      photoURL: json['userPhotoURL'] as String,
      displayName: json['userDisplayName'] as String,
      description: json['userDescription'] as String,
      gender: json['userGender'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}
