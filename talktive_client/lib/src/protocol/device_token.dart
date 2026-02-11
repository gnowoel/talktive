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

abstract class DeviceToken implements _i1.SerializableModel {
  DeviceToken._({
    this.id,
    required this.userId,
    required this.token,
    required this.platform,
    required this.lastUsed,
    required this.createdAt,
  });

  factory DeviceToken({
    int? id,
    required _i1.UuidValue userId,
    required String token,
    required String platform,
    required DateTime lastUsed,
    required DateTime createdAt,
  }) = _DeviceTokenImpl;

  factory DeviceToken.fromJson(Map<String, dynamic> jsonSerialization) {
    return DeviceToken(
      id: jsonSerialization['id'] as int?,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      token: jsonSerialization['token'] as String,
      platform: jsonSerialization['platform'] as String,
      lastUsed: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastUsed'],
      ),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue userId;

  String token;

  String platform;

  DateTime lastUsed;

  DateTime createdAt;

  /// Returns a shallow copy of this [DeviceToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeviceToken copyWith({
    int? id,
    _i1.UuidValue? userId,
    String? token,
    String? platform,
    DateTime? lastUsed,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeviceToken',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'token': token,
      'platform': platform,
      'lastUsed': lastUsed.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeviceTokenImpl extends DeviceToken {
  _DeviceTokenImpl({
    int? id,
    required _i1.UuidValue userId,
    required String token,
    required String platform,
    required DateTime lastUsed,
    required DateTime createdAt,
  }) : super._(
         id: id,
         userId: userId,
         token: token,
         platform: platform,
         lastUsed: lastUsed,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DeviceToken]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeviceToken copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userId,
    String? token,
    String? platform,
    DateTime? lastUsed,
    DateTime? createdAt,
  }) {
    return DeviceToken(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      token: token ?? this.token,
      platform: platform ?? this.platform,
      lastUsed: lastUsed ?? this.lastUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
