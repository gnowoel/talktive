import 'package:cloud_firestore/cloud_firestore.dart';

import '../helpers/time.dart';

class Tribe {
  final String id;
  final String name;
  final int createdAt;
  final int topicCount;
  final String? description;
  final String? iconEmoji;
  final int? sort;

  const Tribe({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.topicCount,
    this.description,
    this.iconEmoji,
    this.sort,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': Timestamp.fromMillisecondsSinceEpoch(createdAt),
      'topicCount': topicCount,
      'description': description,
      'iconEmoji': iconEmoji,
      'sort': sort,
    };
  }

  Tribe copyWith({
    String? id,
    String? name,
    int? createdAt,
    int? topicCount,
    String? description,
    String? iconEmoji,
    int? sort,
  }) {
    return Tribe(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      topicCount: topicCount ?? this.topicCount,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      sort: sort ?? this.sort,
    );
  }

  factory Tribe.fromJson(String id, Map<String, dynamic> json) {
    return Tribe(
      id: id,
      name: json['name'] as String,
      createdAt: (json['createdAt'] as Timestamp).millisecondsSinceEpoch,
      topicCount: json['topicCount'] as int? ?? 0,
      description: json['description'] as String?,
      iconEmoji: json['iconEmoji'] as String?,
      sort: json['sort'] as int?,
    );
  }

  static dummy({required String name, int? sort}) {
    return Tribe(
      id: 'tribeId',
      name: name,
      createdAt: 0,
      topicCount: 0,
      sort: sort,
    );
  }

  bool get isDummy => createdAt == 0;
  bool get isNotDummy => !isDummy;
  bool get isActive => isNotDummy && createdAt + activePeriod > DateTime.now().millisecondsSinceEpoch;
}