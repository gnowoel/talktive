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
import 'report_status.dart' as _i2;

abstract class Report implements _i1.SerializableModel {
  Report._({
    this.id,
    required this.reporterId,
    required this.targetId,
    required this.reason,
    this.channelId,
    this.messageId,
    required this.createdAt,
    _i2.ReportStatus? status,
    this.adminNotes,
    this.resolvedAt,
  }) : status = status ?? _i2.ReportStatus.pending;

  factory Report({
    int? id,
    required _i1.UuidValue reporterId,
    required _i1.UuidValue targetId,
    required String reason,
    int? channelId,
    int? messageId,
    required DateTime createdAt,
    _i2.ReportStatus? status,
    String? adminNotes,
    DateTime? resolvedAt,
  }) = _ReportImpl;

  factory Report.fromJson(Map<String, dynamic> jsonSerialization) {
    return Report(
      id: jsonSerialization['id'] as int?,
      reporterId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['reporterId'],
      ),
      targetId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['targetId'],
      ),
      reason: jsonSerialization['reason'] as String,
      channelId: jsonSerialization['channelId'] as int?,
      messageId: jsonSerialization['messageId'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      status: jsonSerialization['status'] == null
          ? null
          : _i2.ReportStatus.fromJson((jsonSerialization['status'] as String)),
      adminNotes: jsonSerialization['adminNotes'] as String?,
      resolvedAt: jsonSerialization['resolvedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['resolvedAt']),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue reporterId;

  _i1.UuidValue targetId;

  String reason;

  int? channelId;

  int? messageId;

  DateTime createdAt;

  _i2.ReportStatus status;

  String? adminNotes;

  DateTime? resolvedAt;

  /// Returns a shallow copy of this [Report]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Report copyWith({
    int? id,
    _i1.UuidValue? reporterId,
    _i1.UuidValue? targetId,
    String? reason,
    int? channelId,
    int? messageId,
    DateTime? createdAt,
    _i2.ReportStatus? status,
    String? adminNotes,
    DateTime? resolvedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Report',
      if (id != null) 'id': id,
      'reporterId': reporterId.toJson(),
      'targetId': targetId.toJson(),
      'reason': reason,
      if (channelId != null) 'channelId': channelId,
      if (messageId != null) 'messageId': messageId,
      'createdAt': createdAt.toJson(),
      'status': status.toJson(),
      if (adminNotes != null) 'adminNotes': adminNotes,
      if (resolvedAt != null) 'resolvedAt': resolvedAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReportImpl extends Report {
  _ReportImpl({
    int? id,
    required _i1.UuidValue reporterId,
    required _i1.UuidValue targetId,
    required String reason,
    int? channelId,
    int? messageId,
    required DateTime createdAt,
    _i2.ReportStatus? status,
    String? adminNotes,
    DateTime? resolvedAt,
  }) : super._(
         id: id,
         reporterId: reporterId,
         targetId: targetId,
         reason: reason,
         channelId: channelId,
         messageId: messageId,
         createdAt: createdAt,
         status: status,
         adminNotes: adminNotes,
         resolvedAt: resolvedAt,
       );

  /// Returns a shallow copy of this [Report]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Report copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? reporterId,
    _i1.UuidValue? targetId,
    String? reason,
    Object? channelId = _Undefined,
    Object? messageId = _Undefined,
    DateTime? createdAt,
    _i2.ReportStatus? status,
    Object? adminNotes = _Undefined,
    Object? resolvedAt = _Undefined,
  }) {
    return Report(
      id: id is int? ? id : this.id,
      reporterId: reporterId ?? this.reporterId,
      targetId: targetId ?? this.targetId,
      reason: reason ?? this.reason,
      channelId: channelId is int? ? channelId : this.channelId,
      messageId: messageId is int? ? messageId : this.messageId,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      adminNotes: adminNotes is String? ? adminNotes : this.adminNotes,
      resolvedAt: resolvedAt is DateTime? ? resolvedAt : this.resolvedAt,
    );
  }
}
