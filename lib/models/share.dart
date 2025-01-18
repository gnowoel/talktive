class Share {
  final String id;
  final String topic;
  final String userId;
  final String userDisplayName;
  final String userPhotoURL;
  final String languageCode;
  final int createdAt;
  final int updatedAt;

  const Share({
    required this.id,
    required this.topic,
    required this.userId,
    required this.userDisplayName,
    required this.userPhotoURL,
    required this.languageCode,
    required this.createdAt,
    required this.updatedAt,
  });
}
