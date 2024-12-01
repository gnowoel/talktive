import 'message.dart';

class ImageMessage extends Message {
  String? id;
  final String userId;
  final String userDisplayName;
  final String userPhotoURL;
  final String uri;
  final int createdAt;

  ImageMessage({
    this.id,
    required this.userId,
    required this.userDisplayName,
    required this.userPhotoURL,
    required this.uri,
    required this.createdAt,
  }) : super(type: 'image');

  ImageMessage copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? userPhotoURL,
    String? uri,
    int? createdAt,
  }) {
    return ImageMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userPhotoURL: userPhotoURL ?? this.userPhotoURL,
      uri: uri ?? this.uri,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoURL': userPhotoURL,
      'uri': uri,
      'type': type,
      'createdAt': createdAt,
    };
  }

  factory ImageMessage.fromJson(Map<String, dynamic> json) {
    return ImageMessage(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      userPhotoURL: json['userPhotoURL'] as String,
      uri: json['uri'] as String,
      createdAt: json['createdAt'] as int,
    );
  }
}
