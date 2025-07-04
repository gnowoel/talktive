import 'package:cloud_firestore/cloud_firestore.dart';

class MessageReport {
  final String? id;
  final String chatId;
  final String messageId;
  final String messageAuthorId;
  final String reporterUserId;
  final DateTime createdAt;
  final String status;
  const MessageReport({
    this.id,
    required this.chatId,
    required this.messageId,
    required this.messageAuthorId,
    required this.reporterUserId,
    required this.createdAt,
    required this.status,
  });

  factory MessageReport.fromJson(String id, Map<String, dynamic> json) {
    return MessageReport(
      id: id,
      chatId: json['chatId'] as String,
      messageId: json['messageId'] as String,
      messageAuthorId: json['messageAuthorId'] as String,
      reporterUserId: json['reporterUserId'] as String,
      createdAt: (json['createdAt'] as Timestamp).toDate(),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatId': chatId,
      'messageId': messageId,
      'messageAuthorId': messageAuthorId,
      'reporterUserId': reporterUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }

  MessageReport copyWith({
    String? id,
    String? chatId,
    String? messageId,
    String? messageAuthorId,
    String? reporterUserId,
    DateTime? createdAt,
    String? status,
  }) {
    return MessageReport(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      messageId: messageId ?? this.messageId,
      messageAuthorId: messageAuthorId ?? this.messageAuthorId,
      reporterUserId: reporterUserId ?? this.reporterUserId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MessageReport &&
        other.id == id &&
        other.chatId == chatId &&
        other.messageId == messageId &&
        other.messageAuthorId == messageAuthorId &&
        other.reporterUserId == reporterUserId &&
        other.createdAt == createdAt &&
        other.status == status;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        chatId.hashCode ^
        messageId.hashCode ^
        messageAuthorId.hashCode ^
        reporterUserId.hashCode ^
        createdAt.hashCode ^
        status.hashCode;
  }

  /// Calculate the parent document ID from the creation date (YYYY-MM-DD format)
  String getParentDocId() {
    final dateStr = createdAt.toIso8601String().split('T')[0];
    return dateStr; // Returns format like "2025-01-06"
  }

  @override
  String toString() {
    return 'MessageReport(id: $id, chatId: $chatId, messageId: $messageId, messageAuthorId: $messageAuthorId, reporterUserId: $reporterUserId, createdAt: $createdAt, status: $status)';
  }
}