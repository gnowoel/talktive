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
import 'channel_type.dart' as _i2;

abstract class Channel implements _i1.SerializableModel {
  Channel._({
    this.id,
    required this.type,
    this.name,
    required this.createdAt,
    this.lastMessageAt,
    bool? isPersistent,
  }) : isPersistent = isPersistent ?? false;

  factory Channel({
    int? id,
    required _i2.ChannelType type,
    String? name,
    required DateTime createdAt,
    DateTime? lastMessageAt,
    bool? isPersistent,
  }) = _ChannelImpl;

  factory Channel.fromJson(Map<String, dynamic> jsonSerialization) {
    return Channel(
      id: jsonSerialization['id'] as int?,
      type: _i2.ChannelType.fromJson((jsonSerialization['type'] as String)),
      name: jsonSerialization['name'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      lastMessageAt: jsonSerialization['lastMessageAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastMessageAt'],
            ),
      isPersistent: jsonSerialization['isPersistent'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['isPersistent']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i2.ChannelType type;

  String? name;

  DateTime createdAt;

  DateTime? lastMessageAt;

  bool isPersistent;

  /// Returns a shallow copy of this [Channel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Channel copyWith({
    int? id,
    _i2.ChannelType? type,
    String? name,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    bool? isPersistent,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Channel',
      if (id != null) 'id': id,
      'type': type.toJson(),
      if (name != null) 'name': name,
      'createdAt': createdAt.toJson(),
      if (lastMessageAt != null) 'lastMessageAt': lastMessageAt?.toJson(),
      'isPersistent': isPersistent,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ChannelImpl extends Channel {
  _ChannelImpl({
    int? id,
    required _i2.ChannelType type,
    String? name,
    required DateTime createdAt,
    DateTime? lastMessageAt,
    bool? isPersistent,
  }) : super._(
         id: id,
         type: type,
         name: name,
         createdAt: createdAt,
         lastMessageAt: lastMessageAt,
         isPersistent: isPersistent,
       );

  /// Returns a shallow copy of this [Channel]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Channel copyWith({
    Object? id = _Undefined,
    _i2.ChannelType? type,
    Object? name = _Undefined,
    DateTime? createdAt,
    Object? lastMessageAt = _Undefined,
    bool? isPersistent,
  }) {
    return Channel(
      id: id is int? ? id : this.id,
      type: type ?? this.type,
      name: name is String? ? name : this.name,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt is DateTime?
          ? lastMessageAt
          : this.lastMessageAt,
      isPersistent: isPersistent ?? this.isPersistent,
    );
  }
}
