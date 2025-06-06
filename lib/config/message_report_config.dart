/// Configuration for message reporting system
class MessageReportConfig {
  MessageReportConfig._();

  /// Threshold for flagging a message for review
  static const int flagThreshold = 1;

  /// Threshold for hiding a message from normal view
  static const int hideThreshold = 3;

  /// Threshold for marking a message as severely inappropriate
  static const int severeThreshold = 5;

  /// Calculate report status from report count
  static String? getReportStatus(int reportCount) {
    if (reportCount >= severeThreshold) return 'severe';
    if (reportCount >= hideThreshold) return 'hidden';
    if (reportCount >= flagThreshold) return 'flagged';
    return null;
  }

  /// Check if a message should be visible to regular users
  static bool shouldShowMessage(int reportCount, {bool isAdmin = false}) {
    if (isAdmin) return true;
    final status = getReportStatus(reportCount);
    return status != 'hidden' && status != 'severe';
  }

  /// Check if a message should show a content warning
  static bool shouldShowContentWarning(int reportCount) {
    final status = getReportStatus(reportCount);
    return status == 'flagged';
  }

  /// Check if message content should be blurred
  static bool shouldBlurContent(int reportCount) {
    final status = getReportStatus(reportCount);
    return status == 'flagged' && reportCount >= 2;
  }

  /// Get user-friendly description of report status
  static String getStatusDescription(int reportCount) {
    switch (getReportStatus(reportCount)) {
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

  /// Get moderation priority (higher = more urgent)
  static int getModerationPriority(int reportCount) {
    final status = getReportStatus(reportCount);
    
    switch (status) {
      case 'severe':
        return 100 + reportCount;
      case 'hidden':
        return 50 + reportCount;
      case 'flagged':
        return 10 + reportCount;
      default:
        return 0;
    }
  }

  /// Calculate severity level (0.0 to 1.0)
  static double getSeverityLevel(int reportCount) {
    final status = getReportStatus(reportCount);
    
    switch (status) {
      case 'flagged':
        return 0.3;
      case 'hidden':
        return 0.7;
      case 'severe':
        return 1.0;
      default:
        return 0.0;
    }
  }

  /// Get tooltip text for status indicators
  static String getStatusTooltip(int reportCount) {
    final status = getReportStatus(reportCount);
    if (status == null) return '';

    return '${status.capitalize()} ($reportCount report${reportCount == 1 ? '' : 's'})';
  }
}

extension _StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}