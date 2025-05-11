import 'package:flutter/foundation.dart';

const activePeriod = kDebugMode
    ? 6 * 60 * 1000 // 6 minutes
    : 3 * 24 * 60 * 60 * 1000; // 3 days

const refreshThreshold = kDebugMode
    ? 1 * 60 * 1000 // 1 minute
    : 12 * 60 * 60 * 1000; // 12 hours

int? getNextTime(int? chatNextTime, int? topicNextTime) {
  if (chatNextTime != null && topicNextTime != null) {
    return chatNextTime < topicNextTime ? chatNextTime : topicNextTime;
  }
  return chatNextTime ?? topicNextTime;
}
