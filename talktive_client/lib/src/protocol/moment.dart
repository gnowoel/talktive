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

abstract class Moment implements _i1.SerializableModel {
  Moment._({
    this.id,
    required this.authorId,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.authorName,
    required this.authorAvatar,
    required this.authorFloor,
  });

  factory Moment({
    int? id,
    required int authorId,
    required String imageUrl,
    String? caption,
    required DateTime createdAt,
    required int likesCount,
    required int commentsCount,
    required String authorName,
    required String authorAvatar,
    required int authorFloor,
  }) = _MomentImpl;

  factory Moment.fromJson(Map<String, dynamic> jsonSerialization) {
    return Moment(
      id: jsonSerialization['id'] as int?,
      authorId: jsonSerialization['authorId'] as int,
      imageUrl: jsonSerialization['imageUrl'] as String,
      caption: jsonSerialization['caption'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      likesCount: jsonSerialization['likesCount'] as int,
      commentsCount: jsonSerialization['commentsCount'] as int,
      authorName: jsonSerialization['authorName'] as String,
      authorAvatar: jsonSerialization['authorAvatar'] as String,
      authorFloor: jsonSerialization['authorFloor'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int authorId;

  String imageUrl;

  String? caption;

  DateTime createdAt;

  int likesCount;

  int commentsCount;

  String authorName;

  String authorAvatar;

  int authorFloor;

  /// Returns a shallow copy of this [Moment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Moment copyWith({
    int? id,
    int? authorId,
    String? imageUrl,
    String? caption,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    String? authorName,
    String? authorAvatar,
    int? authorFloor,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Moment',
      if (id != null) 'id': id,
      'authorId': authorId,
      'imageUrl': imageUrl,
      if (caption != null) 'caption': caption,
      'createdAt': createdAt.toJson(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'authorFloor': authorFloor,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MomentImpl extends Moment {
  _MomentImpl({
    int? id,
    required int authorId,
    required String imageUrl,
    String? caption,
    required DateTime createdAt,
    required int likesCount,
    required int commentsCount,
    required String authorName,
    required String authorAvatar,
    required int authorFloor,
  }) : super._(
         id: id,
         authorId: authorId,
         imageUrl: imageUrl,
         caption: caption,
         createdAt: createdAt,
         likesCount: likesCount,
         commentsCount: commentsCount,
         authorName: authorName,
         authorAvatar: authorAvatar,
         authorFloor: authorFloor,
       );

  /// Returns a shallow copy of this [Moment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Moment copyWith({
    Object? id = _Undefined,
    int? authorId,
    String? imageUrl,
    Object? caption = _Undefined,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    String? authorName,
    String? authorAvatar,
    int? authorFloor,
  }) {
    return Moment(
      id: id is int? ? id : this.id,
      authorId: authorId ?? this.authorId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption is String? ? caption : this.caption,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorFloor: authorFloor ?? this.authorFloor,
    );
  }
}
