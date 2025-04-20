import 'package:flutter/foundation.dart';

import '../models/public_topic.dart';

class TopicCache extends ChangeNotifier {
  final Map<String, PublicTopic> _topics = {};

  TopicCache._();
  static final TopicCache _instance = TopicCache._();
  factory TopicCache() => _instance;

  List<PublicTopic> get topics => _topics.values.toList();

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

  void removeTopc(String topicId) {
    _topics.remove(topicId);
    notifyListeners();
  }

  bool hasTopic(String topicId) => _topics.containsKey(topicId);
}
