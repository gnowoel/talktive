class Friend {
  final String id;
  final String userLanguageCode;
  final String userPhotoURL;
  final String userDisplayName;
  final String userDescription;
  final String userGender;
  final int createdAt;
  final int updatedAt;

  const Friend({
    required this.id,
    required this.userLanguageCode,
    required this.userPhotoURL,
    required this.userDisplayName,
    required this.userDescription,
    required this.userGender,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userLanguageCode': userLanguageCode,
      'userPhotoURL': userPhotoURL,
      'userDisplayName': userDisplayName,
      'userDescription': userDescription,
      'userGender': userGender,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      userLanguageCode: json['userLanguageCode'] as String,
      userPhotoURL: json['userPhotoURL'] as String,
      userDisplayName: json['userDisplayName'] as String,
      userDescription: json['userDescription'] as String,
      userGender: json['userGender'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}
