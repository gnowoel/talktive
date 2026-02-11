/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;

abstract class Achievement implements _i1.SerializableModel {
  Achievement._({
    this.id,
    required this.key,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    int? targetValue,
    int? points,
    bool? isSecret,
  }) : targetValue = targetValue ?? 1,
       points = points ?? 10,
       isSecret = isSecret ?? false;

  factory Achievement({
    int? id,
    required String key,
    required String name,
    required String description,
    required String emoji,
    required String category,
    int? targetValue,
    int? points,
    bool? isSecret,
  }) = _AchievementImpl;

  factory Achievement.fromJson(Map<String, dynamic> jsonSerialization) {
    return Achievement(
      id: jsonSerialization['id'] as int?,
      key: jsonSerialization['key'] as String,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String,
      emoji: jsonSerialization['emoji'] as String,
      category: jsonSerialization['category'] as String,
      targetValue: jsonSerialization['targetValue'] as int?,
      points: jsonSerialization['points'] as int?,
      isSecret: jsonSerialization['isSecret'] as bool?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String key;

  String name;

  String description;

  String emoji;

  String category;

  int targetValue;

  int points;

  bool isSecret;

  /// Returns a shallow copy of this [Achievement]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Achievement copyWith({
    int? id,
    String? key,
    String? name,
    String? description,
    String? emoji,
    String? category,
    int? targetValue,
    int? points,
    bool? isSecret,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Achievement',
      if (id != null) 'id': id,
      'key': key,
      'name': name,
      'description': description,
      'emoji': emoji,
      'category': category,
      'targetValue': targetValue,
      'points': points,
      'isSecret': isSecret,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AchievementImpl extends Achievement {
  _AchievementImpl({
    int? id,
    required String key,
    required String name,
    required String description,
    required String emoji,
    required String category,
    int? targetValue,
    int? points,
    bool? isSecret,
  }) : super._(
         id: id,
         key: key,
         name: name,
         description: description,
         emoji: emoji,
         category: category,
         targetValue: targetValue,
         points: points,
         isSecret: isSecret,
       );

  /// Returns a shallow copy of this [Achievement]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Achievement copyWith({
    Object? id = _Undefined,
    String? key,
    String? name,
    String? description,
    String? emoji,
    String? category,
    int? targetValue,
    int? points,
    bool? isSecret,
  }) {
    return Achievement(
      id: id is int? ? id : this.id,
      key: key ?? this.key,
      name: name ?? this.name,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      category: category ?? this.category,
      targetValue: targetValue ?? this.targetValue,
      points: points ?? this.points,
      isSecret: isSecret ?? this.isSecret,
    );
  }
}
