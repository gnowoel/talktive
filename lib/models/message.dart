import 'image_message.dart';
import 'text_message.dart';
import '../config/message_report_config.dart';

abstract class Message {
  final String? id;
  final int createdAt;
  final String type; // 'text' or 'image'
  final bool recalled;
  final int? revivedAt;
  final int? reportCount;

  const Message({
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

  factory Message.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'image') {
      return ImageMessage.fromJson(json);
    } else {
      return TextMessage.fromJson(json);
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
