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
    String? mediaType,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.authorName,
    this.authorAvatar,
    this.authorMood,
    required this.authorFloor,
    required this.authorTrustScore,
  }) : mediaType = mediaType ?? 'image';

  factory Moment({
    int? id,
    required _i1.UuidValue authorId,
    required String imageUrl,
    String? caption,
    String? mediaType,
    required DateTime createdAt,
    required int likesCount,
    required int commentsCount,
    required String authorName,
    String? authorAvatar,
    String? authorMood,
    required int authorFloor,
    required int authorTrustScore,
  }) = _MomentImpl;

  factory Moment.fromJson(Map<String, dynamic> jsonSerialization) {
    return Moment(
      id: jsonSerialization['id'] as int?,
      authorId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['authorId'],
      ),
      imageUrl: jsonSerialization['imageUrl'] as String,
      caption: jsonSerialization['caption'] as String?,
      mediaType: jsonSerialization['mediaType'] as String?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      likesCount: jsonSerialization['likesCount'] as int,
      commentsCount: jsonSerialization['commentsCount'] as int,
      authorName: jsonSerialization['authorName'] as String,
      authorAvatar: jsonSerialization['authorAvatar'] as String?,
      authorMood: jsonSerialization['authorMood'] as String?,
      authorFloor: jsonSerialization['authorFloor'] as int,
      authorTrustScore: jsonSerialization['authorTrustScore'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue authorId;

  String imageUrl;

  String? caption;

  String mediaType;

  DateTime createdAt;

  int likesCount;

  int commentsCount;

  String authorName;

  String? authorAvatar;

  String? authorMood;

  int authorFloor;

  int authorTrustScore;

  /// Returns a shallow copy of this [Moment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Moment copyWith({
    int? id,
    _i1.UuidValue? authorId,
    String? imageUrl,
    String? caption,
    String? mediaType,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    String? authorName,
    String? authorAvatar,
    String? authorMood,
    int? authorFloor,
    int? authorTrustScore,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Moment',
      if (id != null) 'id': id,
      'authorId': authorId.toJson(),
      'imageUrl': imageUrl,
      if (caption != null) 'caption': caption,
      'mediaType': mediaType,
      'createdAt': createdAt.toJson(),
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'authorName': authorName,
      if (authorAvatar != null) 'authorAvatar': authorAvatar,
      if (authorMood != null) 'authorMood': authorMood,
      'authorFloor': authorFloor,
      'authorTrustScore': authorTrustScore,
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
    required _i1.UuidValue authorId,
    required String imageUrl,
    String? caption,
    String? mediaType,
    required DateTime createdAt,
    required int likesCount,
    required int commentsCount,
    required String authorName,
    String? authorAvatar,
    String? authorMood,
    required int authorFloor,
    required int authorTrustScore,
  }) : super._(
         id: id,
         authorId: authorId,
         imageUrl: imageUrl,
         caption: caption,
         mediaType: mediaType,
         createdAt: createdAt,
         likesCount: likesCount,
         commentsCount: commentsCount,
         authorName: authorName,
         authorAvatar: authorAvatar,
         authorMood: authorMood,
         authorFloor: authorFloor,
         authorTrustScore: authorTrustScore,
       );

  /// Returns a shallow copy of this [Moment]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Moment copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? authorId,
    String? imageUrl,
    Object? caption = _Undefined,
    String? mediaType,
    DateTime? createdAt,
    int? likesCount,
    int? commentsCount,
    String? authorName,
    Object? authorAvatar = _Undefined,
    Object? authorMood = _Undefined,
    int? authorFloor,
    int? authorTrustScore,
  }) {
    return Moment(
      id: id is int? ? id : this.id,
      authorId: authorId ?? this.authorId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption is String? ? caption : this.caption,
      mediaType: mediaType ?? this.mediaType,
      createdAt: createdAt ?? this.createdAt,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar is String? ? authorAvatar : this.authorAvatar,
      authorMood: authorMood is String? ? authorMood : this.authorMood,
      authorFloor: authorFloor ?? this.authorFloor,
      authorTrustScore: authorTrustScore ?? this.authorTrustScore,
    );
  }
}
