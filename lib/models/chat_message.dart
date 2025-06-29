import '../config/message_report_config.dart';

abstract class ChatMessage {
  final String? id;
  final int createdAt;
  final String type; // 'text' or 'image'
  final bool recalled;
  final int? revivedAt;
  final int? reportCount;

  const ChatMessage({
    this.id,
    required this.createdAt,
    required this.type,
    this.recalled = false,
    this.revivedAt,
    this.reportCount,
  });

  // Abstract getters that must be implemented by subclasses
  String get userId;
  String get userDisplayName;
  String get userPhotoURL;
  String get content;

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'image') {
      return ChatImageMessage.fromJson(json);
    } else {
      return ChatTextMessage.fromJson(json);
    }
  }

  /// Check if the message has been flagged for review
  bool get isFlagged =>
      MessageReportConfig.getReportStatus(reportCount ?? 0) == 'flagged';

  /// Check if the message has been hidden due to reports
  bool get isHidden =>
      MessageReportConfig.getReportStatus(reportCount ?? 0) == 'hidden';

  /// Check if the message has been marked as severe
  bool get isSevere =>
      MessageReportConfig.getReportStatus(reportCount ?? 0) == 'severe';

  /// Check if the message has any report-related restrictions
  bool get isReported => reportCount != null && reportCount! > 0;

  /// Get the current report status
  String? get reportStatus =>
      MessageReportConfig.getReportStatus(reportCount ?? 0);

  /// Get a user-friendly description of the message's report status
  String get reportStatusDescription =>
      MessageReportConfig.getStatusDescription(reportCount ?? 0);
}

class ChatTextMessage extends ChatMessage {
  @override
  final String userId;
  @override
  final String userDisplayName;
  @override
  final String userPhotoURL;
  @override
  final String content;

  const ChatTextMessage({
    super.id,
    required super.createdAt,
    required this.userId,
    required this.userDisplayName,
    required this.userPhotoURL,
    required this.content,
    super.recalled = false,
    super.revivedAt,
    super.reportCount,
  }) : super(type: 'text');

  ChatTextMessage copyWith({
    String? id,
    String? userId,
    String? userDisplayName,
    String? userPhotoURL,
    String? content,
    int? createdAt,
    bool? recalled,
    int? revivedAt,
    int? reportCount,
  }) {
    return ChatTextMessage(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      userPhotoURL: userPhotoURL ?? this.userPhotoURL,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      recalled: recalled ?? this.recalled,
      revivedAt: revivedAt ?? this.revivedAt,
      reportCount: reportCount ?? this.reportCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'userPhotoURL': userPhotoURL,
      'content': content,
      'type': type,
      'createdAt': createdAt,
      'recalled': recalled,
      'revivedAt': revivedAt,
      if (reportCount != null) 'reportCount': reportCount,
    };
  }

  factory ChatTextMessage.fromJson(Map<String, dynamic> json) {
    return ChatTextMessage(
      id: json['id'] as String?,
      userId: json['userId'] as String,
      userDisplayName: json['userDisplayName'] as String,
      userPhotoURL: json['userPhotoURL'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] as int,
      recalled: json['recalled'] as bool? ?? false,
      revivedAt: json['revivedAt'] as int?,
      reportCount: json['reportCount'] as int?,
    );
  }
}

class ChatImageMessage extends ChatMessage {
  @override
  final String userId;
  @override
  final String userDisplayName;
  @override
  final String userPhotoURL;
  @override
  final String content;
  final String uri;

  const ChatImageMessage({
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
  }) : super(type: 'image');

  ChatImageMessage copyWith({
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
  }) {
    return ChatImageMessage(
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
    };
  }

  factory ChatImageMessage.fromJson(Map<String, dynamic> json) {
    return ChatImageMessage(
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
    );
  }
}
