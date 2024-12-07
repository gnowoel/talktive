import 'package:flutter/foundation.dart';

import '../models/chat.dart';
import '../services/cache.dart';

const delay = kDebugMode
    ? 1000 * 60 * 6 // 6 minutes
    : 1000 * 60 * 60 * 72; // 3 days

int getTimeLeft(Chat chat, {int? now}) {
  now = now ?? Cache().now;
  final then = chat.updatedAt;
  final elapsed = now - then;
  final diff = delay - elapsed;
  return diff < 0 ? 0 : diff;
}

int? getNextTime(List<Chat> chats) {
  if (chats.isEmpty) return null;
  final times = chats.map((chat) => getTimeLeft(chat)).toList();
  times.sort();
  return times.first;
}
