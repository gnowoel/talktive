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

abstract class UserLike implements _i1.SerializableModel {
  UserLike._({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.createdAt,
  });

  factory UserLike({
    int? id,
    required _i1.UuidValue senderId,
    required _i1.UuidValue receiverId,
    required DateTime createdAt,
  }) = _UserLikeImpl;

  factory UserLike.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserLike(
      id: jsonSerialization['id'] as int?,
      senderId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['senderId'],
      ),
      receiverId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['receiverId'],
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

  _i1.UuidValue senderId;

  _i1.UuidValue receiverId;

  DateTime createdAt;

  /// Returns a shallow copy of this [UserLike]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserLike copyWith({
    int? id,
    _i1.UuidValue? senderId,
    _i1.UuidValue? receiverId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserLike',
      if (id != null) 'id': id,
      'senderId': senderId.toJson(),
      'receiverId': receiverId.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserLikeImpl extends UserLike {
  _UserLikeImpl({
    int? id,
    required _i1.UuidValue senderId,
    required _i1.UuidValue receiverId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         senderId: senderId,
         receiverId: receiverId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [UserLike]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserLike copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? senderId,
    _i1.UuidValue? receiverId,
    DateTime? createdAt,
  }) {
    return UserLike(
      id: id is int? ? id : this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
