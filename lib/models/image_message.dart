import 'message.dart';

class ImageMessage extends Message {
  final String userId;
  final String userDisplayName;
  final String userPhotoURL;
  final String content;
  final String uri;

  const ImageMessage({
    super.id,
    required super.createdAt,
    required this.userId,
    required this.userDisplayName,
    required this.userPhotoURL,
    required this.content,
    required this.uri,
    super.recalled = false,
    super.revivedAt,
    super.reportCount,
    super.reportStatus,
  }) : super(type: 'image');

  ImageMessage copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? userPhotoURL,
    String? content,
    String? uri,
    int? createdAt,
    bool? recalled,
    int? revivedAt,
    int? reportCount,
    String? reportStatus,
  }) {
    return ImageMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userPhotoURL: userPhotoURL ?? this.userPhotoURL,
      content: content ?? this.content,
      uri: uri ?? this.uri,
      createdAt: createdAt ?? this.createdAt,
      recalled: recalled ?? this.recalled,
      revivedAt: revivedAt ?? this.revivedAt,
      reportCount: reportCount ?? this.reportCount,
      reportStatus: reportStatus ?? this.reportStatus,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoURL': userPhotoURL,
      'content': content,
      'uri': uri,
      'type': type,
      'createdAt': createdAt,
      'recalled': recalled,
      'revivedAt': revivedAt,
      if (reportCount != null) 'reportCount': reportCount,
      if (reportStatus != null) 'reportStatus': reportStatus,
    };
  }

  factory ImageMessage.fromJson(Map<String, dynamic> json) {
    return ImageMessage(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      userPhotoURL: json['userPhotoURL'] as String,
      content: json['content'] as String,
      uri: json['uri'] as String,
      createdAt: json['createdAt'] as int,
      recalled: json['recalled'] as bool? ?? false,
      revivedAt: json['revivedAt'] as int?,
      reportCount: json['reportCount'] as int?,
      reportStatus: json['reportStatus'] as String?,
    );
  }
}
