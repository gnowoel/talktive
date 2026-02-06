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

abstract class Block implements _i1.SerializableModel {
  Block._({
    this.id,
    required this.blockerId,
    required this.blockedId,
    required this.createdAt,
  });

  factory Block({
    int? id,
    required int blockerId,
    required int blockedId,
    required DateTime createdAt,
  }) = _BlockImpl;

  factory Block.fromJson(Map<String, dynamic> jsonSerialization) {
    return Block(
      id: jsonSerialization['id'] as int?,
      blockerId: jsonSerialization['blockerId'] as int,
      blockedId: jsonSerialization['blockedId'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int blockerId;

  int blockedId;

  DateTime createdAt;

  /// Returns a shallow copy of this [Block]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Block copyWith({
    int? id,
    int? blockerId,
    int? blockedId,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Block',
      if (id != null) 'id': id,
      'blockerId': blockerId,
      'blockedId': blockedId,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BlockImpl extends Block {
  _BlockImpl({
    int? id,
    required int blockerId,
    required int blockedId,
    required DateTime createdAt,
  }) : super._(
         id: id,
         blockerId: blockerId,
         blockedId: blockedId,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Block]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Block copyWith({
    Object? id = _Undefined,
    int? blockerId,
    int? blockedId,
    DateTime? createdAt,
  }) {
    return Block(
      id: id is int? ? id : this.id,
      blockerId: blockerId ?? this.blockerId,
      blockedId: blockedId ?? this.blockedId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
