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

abstract class Group implements _i1.SerializableModel {
  Group._({
    this.id,
    required this.channelId,
    required this.name,
    this.description,
    this.emoji,
    required this.creatorId,
    required this.createdAt,
    int? memberCount,
    bool? isPublic,
    int? maxMembers,
  }) : memberCount = memberCount ?? 1,
       isPublic = isPublic ?? false,
       maxMembers = maxMembers ?? 50;

  factory Group({
    int? id,
    required int channelId,
    required String name,
    String? description,
    String? emoji,
    required _i1.UuidValue creatorId,
    required DateTime createdAt,
    int? memberCount,
    bool? isPublic,
    int? maxMembers,
  }) = _GroupImpl;

  factory Group.fromJson(Map<String, dynamic> jsonSerialization) {
    return Group(
      id: jsonSerialization['id'] as int?,
      channelId: jsonSerialization['channelId'] as int,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      emoji: jsonSerialization['emoji'] as String?,
      creatorId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['creatorId'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      memberCount: jsonSerialization['memberCount'] as int?,
      isPublic: jsonSerialization['isPublic'] as bool?,
      maxMembers: jsonSerialization['maxMembers'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int channelId;

  String name;

  String? description;

  String? emoji;

  _i1.UuidValue creatorId;

  DateTime createdAt;

  int memberCount;

  bool isPublic;

  int maxMembers;

  /// Returns a shallow copy of this [Group]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Group copyWith({
    int? id,
    int? channelId,
    String? name,
    String? description,
    String? emoji,
    _i1.UuidValue? creatorId,
    DateTime? createdAt,
    int? memberCount,
    bool? isPublic,
    int? maxMembers,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Group',
      if (id != null) 'id': id,
      'channelId': channelId,
      'name': name,
      if (description != null) 'description': description,
      if (emoji != null) 'emoji': emoji,
      'creatorId': creatorId.toJson(),
      'createdAt': createdAt.toJson(),
      'memberCount': memberCount,
      'isPublic': isPublic,
      'maxMembers': maxMembers,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GroupImpl extends Group {
  _GroupImpl({
    int? id,
    required int channelId,
    required String name,
    String? description,
    String? emoji,
    required _i1.UuidValue creatorId,
    required DateTime createdAt,
    int? memberCount,
    bool? isPublic,
    int? maxMembers,
  }) : super._(
         id: id,
         channelId: channelId,
         name: name,
         description: description,
         emoji: emoji,
         creatorId: creatorId,
         createdAt: createdAt,
         memberCount: memberCount,
         isPublic: isPublic,
         maxMembers: maxMembers,
       );

  /// Returns a shallow copy of this [Group]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Group copyWith({
    Object? id = _Undefined,
    int? channelId,
    String? name,
    Object? description = _Undefined,
    Object? emoji = _Undefined,
    _i1.UuidValue? creatorId,
    DateTime? createdAt,
    int? memberCount,
    bool? isPublic,
    int? maxMembers,
  }) {
    return Group(
      id: id is int? ? id : this.id,
      channelId: channelId ?? this.channelId,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      emoji: emoji is String? ? emoji : this.emoji,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      memberCount: memberCount ?? this.memberCount,
      isPublic: isPublic ?? this.isPublic,
      maxMembers: maxMembers ?? this.maxMembers,
    );
  }
}
