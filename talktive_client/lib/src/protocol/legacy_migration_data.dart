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
import 'resident_role.dart' as _i2;
import 'package:talktive_client/src/protocol/protocol.dart' as _i3;

abstract class LegacyMigrationData implements _i1.SerializableModel {
  LegacyMigrationData._({
    this.name,
    this.bio,
    this.avatar,
    this.gender,
    this.languages,
    this.xp,
    this.level,
    this.role,
  });

  factory LegacyMigrationData({
    String? name,
    String? bio,
    String? avatar,
    String? gender,
    List<String>? languages,
    int? xp,
    int? level,
    _i2.ResidentRole? role,
  }) = _LegacyMigrationDataImpl;

  factory LegacyMigrationData.fromJson(Map<String, dynamic> jsonSerialization) {
    return LegacyMigrationData(
      name: jsonSerialization['name'] as String?,
      bio: jsonSerialization['bio'] as String?,
      avatar: jsonSerialization['avatar'] as String?,
      gender: jsonSerialization['gender'] as String?,
      languages: jsonSerialization['languages'] == null
          ? null
          : _i3.Protocol().deserialize<List<String>>(
              jsonSerialization['languages'],
            ),
      xp: jsonSerialization['xp'] as int?,
      level: jsonSerialization['level'] as int?,
      role: jsonSerialization['role'] == null
          ? null
          : _i2.ResidentRole.fromJson((jsonSerialization['role'] as String)),
    );
  }

  String? name;

  String? bio;

  String? avatar;

  String? gender;

  List<String>? languages;

  int? xp;

  int? level;

  _i2.ResidentRole? role;

  /// Returns a shallow copy of this [LegacyMigrationData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LegacyMigrationData copyWith({
    String? name,
    String? bio,
    String? avatar,
    String? gender,
    List<String>? languages,
    int? xp,
    int? level,
    _i2.ResidentRole? role,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LegacyMigrationData',
      if (name != null) 'name': name,
      if (bio != null) 'bio': bio,
      if (avatar != null) 'avatar': avatar,
      if (gender != null) 'gender': gender,
      if (languages != null) 'languages': languages?.toJson(),
      if (xp != null) 'xp': xp,
      if (level != null) 'level': level,
      if (role != null) 'role': role?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _LegacyMigrationDataImpl extends LegacyMigrationData {
  _LegacyMigrationDataImpl({
    String? name,
    String? bio,
    String? avatar,
    String? gender,
    List<String>? languages,
    int? xp,
    int? level,
    _i2.ResidentRole? role,
  }) : super._(
         name: name,
         bio: bio,
         avatar: avatar,
         gender: gender,
         languages: languages,
         xp: xp,
         level: level,
         role: role,
       );

  /// Returns a shallow copy of this [LegacyMigrationData]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LegacyMigrationData copyWith({
    Object? name = _Undefined,
    Object? bio = _Undefined,
    Object? avatar = _Undefined,
    Object? gender = _Undefined,
    Object? languages = _Undefined,
    Object? xp = _Undefined,
    Object? level = _Undefined,
    Object? role = _Undefined,
  }) {
    return LegacyMigrationData(
      name: name is String? ? name : this.name,
      bio: bio is String? ? bio : this.bio,
      avatar: avatar is String? ? avatar : this.avatar,
      gender: gender is String? ? gender : this.gender,
      languages: languages is List<String>?
          ? languages
          : this.languages?.map((e0) => e0).toList(),
      xp: xp is int? ? xp : this.xp,
      level: level is int? ? level : this.level,
      role: role is _i2.ResidentRole? ? role : this.role,
    );
  }
}
