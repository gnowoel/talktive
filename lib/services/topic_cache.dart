import 'package:flutter/foundation.dart';

import '../models/public_topic.dart';

class TopicCache extends ChangeNotifier {
  final Map<String, PublicTopic> _topics = {};

  TopicCache._();
  static final TopicCache _instance = TopicCache._();
  factory TopicCache() => _instance;

  List<PublicTopic> get topics => _topics.values.toList();
  List<PublicTopic> get activeTopics =>
      _topics.values.where((topic) => topic.isActive).toList();

  List<String> get activeTopicIds =>
      _topics.entries
          .where((entry) => entry.value.isActive)
          .map((entry) => entry.key)
          .toList();

  PublicTopic? getTopic(String topicId) => _topics[topicId];

  void updateTopics(List<PublicTopic> topics) {
    _topics.clear();
    for (final topic in topics) {
      _topics[topic.id] = topic;
    }
    notifyListeners();
  }

  void updateTopic(PublicTopic topic) {
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
}
