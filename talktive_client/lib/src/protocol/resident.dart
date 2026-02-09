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

abstract class Resident implements _i1.SerializableModel {
  Resident._({
    this.id,
    required this.userInfoId,
    required this.floor,
    required this.creditScore,
    required this.experienceMessageCount,
    this.gender,
    this.country,
    this.bio,
    this.avatar,
    this.role,
    this.lastCreditIncrease,
  });

  factory Resident({
    int? id,
    required _i1.UuidValue userInfoId,
    required int floor,
    required int creditScore,
    required int experienceMessageCount,
    String? gender,
    String? country,
    String? bio,
    String? avatar,
    String? role,
    DateTime? lastCreditIncrease,
  }) = _ResidentImpl;

  factory Resident.fromJson(Map<String, dynamic> jsonSerialization) {
    return Resident(
      id: jsonSerialization['id'] as int?,
      userInfoId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['userInfoId'],
      ),
      floor: jsonSerialization['floor'] as int,
      creditScore: jsonSerialization['creditScore'] as int,
      experienceMessageCount:
          jsonSerialization['experienceMessageCount'] as int,
      gender: jsonSerialization['gender'] as String?,
      country: jsonSerialization['country'] as String?,
      bio: jsonSerialization['bio'] as String?,
      avatar: jsonSerialization['avatar'] as String?,
      role: jsonSerialization['role'] as String?,
      lastCreditIncrease: jsonSerialization['lastCreditIncrease'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastCreditIncrease'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue userInfoId;

  int floor;

  int creditScore;

  int experienceMessageCount;

  String? gender;

  String? country;

  String? bio;

  String? avatar;

  String? role;

  DateTime? lastCreditIncrease;

  /// Returns a shallow copy of this [Resident]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Resident copyWith({
    int? id,
    _i1.UuidValue? userInfoId,
    int? floor,
    int? creditScore,
    int? experienceMessageCount,
    String? gender,
    String? country,
    String? bio,
    String? avatar,
    String? role,
    DateTime? lastCreditIncrease,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Resident',
      if (id != null) 'id': id,
      'userInfoId': userInfoId.toJson(),
      'floor': floor,
      'creditScore': creditScore,
      'experienceMessageCount': experienceMessageCount,
      if (gender != null) 'gender': gender,
      if (country != null) 'country': country,
      if (bio != null) 'bio': bio,
      if (avatar != null) 'avatar': avatar,
      if (role != null) 'role': role,
      if (lastCreditIncrease != null)
        'lastCreditIncrease': lastCreditIncrease?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ResidentImpl extends Resident {
  _ResidentImpl({
    int? id,
    required _i1.UuidValue userInfoId,
    required int floor,
    required int creditScore,
    required int experienceMessageCount,
    String? gender,
    String? country,
    String? bio,
    String? avatar,
    String? role,
    DateTime? lastCreditIncrease,
  }) : super._(
         id: id,
         userInfoId: userInfoId,
         floor: floor,
         creditScore: creditScore,
         experienceMessageCount: experienceMessageCount,
         gender: gender,
         country: country,
         bio: bio,
         avatar: avatar,
         role: role,
         lastCreditIncrease: lastCreditIncrease,
       );

  /// Returns a shallow copy of this [Resident]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Resident copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userInfoId,
    int? floor,
    int? creditScore,
    int? experienceMessageCount,
    Object? gender = _Undefined,
    Object? country = _Undefined,
    Object? bio = _Undefined,
    Object? avatar = _Undefined,
    Object? role = _Undefined,
    Object? lastCreditIncrease = _Undefined,
  }) {
    return Resident(
      id: id is int? ? id : this.id,
      userInfoId: userInfoId ?? this.userInfoId,
      floor: floor ?? this.floor,
      creditScore: creditScore ?? this.creditScore,
      experienceMessageCount:
          experienceMessageCount ?? this.experienceMessageCount,
      gender: gender is String? ? gender : this.gender,
      country: country is String? ? country : this.country,
      bio: bio is String? ? bio : this.bio,
      avatar: avatar is String? ? avatar : this.avatar,
      role: role is String? ? role : this.role,
      lastCreditIncrease: lastCreditIncrease is DateTime?
          ? lastCreditIncrease
          : this.lastCreditIncrease,
    );
  }
}
