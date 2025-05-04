import 'package:flutter/foundation.dart';

const delay = kDebugMode
    ? 1000 * 60 * 6 // 6 minutes
    : 1000 * 60 * 60 * 72; // 3 days

int? getNextTime(int? chatNextTime, int? topicNextTime) {
  if (chatNextTime != null && topicNextTime != null) {
    return chatNextTime < topicNextTime ? chatNextTime : topicNextTime;
  }
  return chatNextTime ?? topicNextTime;
}
