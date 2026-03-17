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

abstract class AdminActivity implements _i1.SerializableModel {
  AdminActivity._({
    required this.messages,
    required this.moments,
    this.reports,
    this.activeUsers,
  });

  factory AdminActivity({
    required int messages,
    required int moments,
    int? reports,
    int? activeUsers,
  }) = _AdminActivityImpl;

  factory AdminActivity.fromJson(Map<String, dynamic> jsonSerialization) {
    return AdminActivity(
      messages: jsonSerialization['messages'] as int,
      moments: jsonSerialization['moments'] as int,
      reports: jsonSerialization['reports'] as int?,
      activeUsers: jsonSerialization['activeUsers'] as int?,
    );
  }

  int messages;

  int moments;

  int? reports;

  int? activeUsers;

  /// Returns a shallow copy of this [AdminActivity]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AdminActivity copyWith({
    int? messages,
    int? moments,
    int? reports,
    int? activeUsers,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdminActivity',
      'messages': messages,
      'moments': moments,
      if (reports != null) 'reports': reports,
      if (activeUsers != null) 'activeUsers': activeUsers,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _AdminActivityImpl extends AdminActivity {
  _AdminActivityImpl({
    required int messages,
    required int moments,
    int? reports,
    int? activeUsers,
  }) : super._(
         messages: messages,
         moments: moments,
         reports: reports,
         activeUsers: activeUsers,
       );

  /// Returns a shallow copy of this [AdminActivity]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AdminActivity copyWith({
    int? messages,
    int? moments,
    Object? reports = _Undefined,
    Object? activeUsers = _Undefined,
  }) {
    return AdminActivity(
      messages: messages ?? this.messages,
      moments: moments ?? this.moments,
      reports: reports is int? ? reports : this.reports,
      activeUsers: activeUsers is int? ? activeUsers : this.activeUsers,
    );
  }
}
