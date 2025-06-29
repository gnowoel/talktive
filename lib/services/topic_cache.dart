import 'package:flutter/foundation.dart';

import '../models/topic.dart';
import 'server_clock.dart';

class TopicCache extends ChangeNotifier {
  final Map<String, Topic> _topics = {};

  TopicCache._();
  static final TopicCache _instance = TopicCache._();
  factory TopicCache() => _instance;

  List<Topic> get topics => _topics.values.toList();
  List<Topic> get activeTopics =>
      _topics.values.where((topic) => topic.isActive).toList();

  List<String> get topicIds => _topics.keys.toList();

  List<String> get activeTopicIds => _topics.entries
      .where((entry) => entry.value.isActive)
      .map((entry) => entry.key)
      .toList();

  Topic? getTopic(String topicId) => _topics[topicId];

  void updateTopics(List<Topic> topics) {
    _topics.clear();
    for (final topic in topics) {
      _topics[topic.id] = topic;
    }
    notifyListeners();
  }

  void updateTopic(Topic topic) {
    _topics[topic.id] = topic;
    notifyListeners();
  }

  void removeTopic(String topicId) {
    _topics.remove(topicId);
    notifyListeners();
  }

  bool hasTopic(String topicId) => _topics.containsKey(topicId);

  int get unreadCount {
    return activeTopics
        .map((topic) => topic.unreadCount)
        .fold<int>(0, (sum, count) => sum + count);
  }

  int? getTimeLeft({int? now}) {
    final topics = activeTopics;
    if (topics.isEmpty) return null;

    now = now ?? ServerClock().now;
    final times = topics.map((topic) => topic.getTimeLeft(now: now)).toList();

    times.sort();
    return times.first;
  }

  @override
  void dispose() {
    _topics.clear();
    super.dispose();
  }
}
