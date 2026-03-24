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
import 'package:serverpod/serverpod.dart' as _i1;
import 'resident_role.dart' as _i2;

abstract class AdminUserSummary
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AdminUserSummary._({
    required this.userId,
    this.userName,
    required this.floor,
    required this.trustScore,
    required this.level,
    required this.xp,
    required this.role,
    required this.suspended,
    required this.messageCount,
    required this.momentCount,
    required this.reportCount,
    this.createdAt,
    this.lastSeen,
  });

  factory AdminUserSummary({
    required _i1.UuidValue userId,
    String? userName,
    required int floor,
    required int trustScore,
    required int level,
    required int xp,
    required _i2.ResidentRole role,
    required bool suspended,
    required int messageCount,
    required int momentCount,
    required int reportCount,
    DateTime? createdAt,
    DateTime? lastSeen,
  }) = _AdminUserSummaryImpl;

  factory AdminUserSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return AdminUserSummary(
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      userName: jsonSerialization['userName'] as String?,
      floor: jsonSerialization['floor'] as int,
      trustScore: jsonSerialization['trustScore'] as int,
      level: jsonSerialization['level'] as int,
      xp: jsonSerialization['xp'] as int,
      role: _i2.ResidentRole.fromJson((jsonSerialization['role'] as String)),
      suspended: _i1.BoolJsonExtension.fromJson(jsonSerialization['suspended']),
      messageCount: jsonSerialization['messageCount'] as int,
      momentCount: jsonSerialization['momentCount'] as int,
      reportCount: jsonSerialization['reportCount'] as int,
      createdAt: jsonSerialization['createdAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['createdAt']),
      lastSeen: jsonSerialization['lastSeen'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['lastSeen']),
    );
  }

  _i1.UuidValue userId;

  String? userName;

  int floor;

  int trustScore;

  int level;

  int xp;

  _i2.ResidentRole role;

  bool suspended;

  int messageCount;

  int momentCount;

  int reportCount;

  DateTime? createdAt;

  DateTime? lastSeen;

  /// Returns a shallow copy of this [AdminUserSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AdminUserSummary copyWith({
    _i1.UuidValue? userId,
    String? userName,
    int? floor,
    int? trustScore,
    int? level,
    int? xp,
    _i2.ResidentRole? role,
    bool? suspended,
    int? messageCount,
    int? momentCount,
    int? reportCount,
    DateTime? createdAt,
    DateTime? lastSeen,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdminUserSummary',
      'userId': userId.toJson(),
      if (userName != null) 'userName': userName,
      'floor': floor,
      'trustScore': trustScore,
      'level': level,
      'xp': xp,
      'role': role.toJson(),
      'suspended': suspended,
      'messageCount': messageCount,
      'momentCount': momentCount,
      'reportCount': reportCount,
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (lastSeen != null) 'lastSeen': lastSeen?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AdminUserSummary',
      'userId': userId.toJson(),
      if (userName != null) 'userName': userName,
      'floor': floor,
      'trustScore': trustScore,
      'level': level,
      'xp': xp,
      'role': role.toJson(),
      'suspended': suspended,
      'messageCount': messageCount,
      'momentCount': momentCount,
      'reportCount': reportCount,
      if (createdAt != null) 'createdAt': createdAt?.toJson(),
      if (lastSeen != null) 'lastSeen': lastSeen?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AdminUserSummaryImpl extends AdminUserSummary {
  _AdminUserSummaryImpl({
    required _i1.UuidValue userId,
    String? userName,
    required int floor,
    required int trustScore,
    required int level,
    required int xp,
    required _i2.ResidentRole role,
    required bool suspended,
    required int messageCount,
    required int momentCount,
    required int reportCount,
    DateTime? createdAt,
    DateTime? lastSeen,
  }) : super._(
         userId: userId,
         userName: userName,
         floor: floor,
         trustScore: trustScore,
         level: level,
         xp: xp,
         role: role,
         suspended: suspended,
         messageCount: messageCount,
         momentCount: momentCount,
         reportCount: reportCount,
         createdAt: createdAt,
         lastSeen: lastSeen,
       );

  /// Returns a shallow copy of this [AdminUserSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AdminUserSummary copyWith({
    _i1.UuidValue? userId,
    Object? userName = _Undefined,
    int? floor,
    int? trustScore,
    int? level,
    int? xp,
    _i2.ResidentRole? role,
    bool? suspended,
    int? messageCount,
    int? momentCount,
    int? reportCount,
    Object? createdAt = _Undefined,
    Object? lastSeen = _Undefined,
  }) {
    return AdminUserSummary(
      userId: userId ?? this.userId,
      userName: userName is String? ? userName : this.userName,
      floor: floor ?? this.floor,
      trustScore: trustScore ?? this.trustScore,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      role: role ?? this.role,
      suspended: suspended ?? this.suspended,
      messageCount: messageCount ?? this.messageCount,
      momentCount: momentCount ?? this.momentCount,
      reportCount: reportCount ?? this.reportCount,
      createdAt: createdAt is DateTime? ? createdAt : this.createdAt,
      lastSeen: lastSeen is DateTime? ? lastSeen : this.lastSeen,
    );
  }
}
