import 'image_message.dart';
import 'text_message.dart';

abstract class Message {
  final String? id;
  final int createdAt;
  final String type; // 'text' or 'image'
  final bool recalled;
  final int? revivedAt;
  final int? reportCount;
  final String? reportStatus; // 'flagged', 'hidden', 'severe'

  const Message({
    this.id,
    required this.createdAt,
    required this.type,
    this.recalled = false,
    this.revivedAt,
    this.reportCount,
    this.reportStatus,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    if (json['type'] == 'image') {
      return ImageMessage.fromJson(json);
    } else {
      return TextMessage.fromJson(json);
    }
  }

  /// Check if the message has been flagged for review
  bool get isFlagged => reportStatus == 'flagged';

  /// Check if the message has been hidden due to reports
  bool get isHidden => reportStatus == 'hidden';

  /// Check if the message has been marked as severe
  bool get isSevere => reportStatus == 'severe';

  /// Check if the message has any report-related restrictions
  bool get isReported => reportCount != null && reportCount! > 0;

  /// Get a user-friendly description of the message's report status
  String get reportStatusDescription {
    switch (reportStatus) {
      case 'flagged':
        return 'This message has been flagged for review';
      case 'hidden':
        return 'This message has been hidden due to reports';
      case 'severe':
        return 'This message has been removed for violating guidelines';
      default:
        return '';
    }
  }
}
