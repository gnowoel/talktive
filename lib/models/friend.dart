class Friend {
  final String id;
  final String userPhotoURL;
  final String userDisplayName;
  final String userDescription;
  final int createdAt;
  final int updatedAt;

  const Friend({
    required this.id,
    required this.userPhotoURL,
    required this.userDisplayName,
    required this.userDescription,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userPhotoURL': userPhotoURL,
      'userDisplayName': userDisplayName,
      'userDescription': userDescription,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      userPhotoURL: json['userPhotoURL'] as String,
      userDisplayName: json['userDisplayName'] as String,
      userDescription: json['userDescription'] as String,
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }
}
