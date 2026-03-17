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
import 'report.dart' as _i2;
import 'admin_user_summary.dart' as _i3;
import 'package:talktive_client/src/protocol/protocol.dart' as _i4;

abstract class AdminReportSummary implements _i1.SerializableModel {
  AdminReportSummary._({
    required this.report,
    required this.reporter,
    required this.target,
  });

  factory AdminReportSummary({
    required _i2.Report report,
    required _i3.AdminUserSummary reporter,
    required _i3.AdminUserSummary target,
  }) = _AdminReportSummaryImpl;

  factory AdminReportSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return AdminReportSummary(
      report: _i4.Protocol().deserialize<_i2.Report>(
        jsonSerialization['report'],
      ),
      reporter: _i4.Protocol().deserialize<_i3.AdminUserSummary>(
        jsonSerialization['reporter'],
      ),
      target: _i4.Protocol().deserialize<_i3.AdminUserSummary>(
        jsonSerialization['target'],
      ),
    );
  }

  _i2.Report report;

  _i3.AdminUserSummary reporter;

  _i3.AdminUserSummary target;

  /// Returns a shallow copy of this [AdminReportSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AdminReportSummary copyWith({
    _i2.Report? report,
    _i3.AdminUserSummary? reporter,
    _i3.AdminUserSummary? target,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdminReportSummary',
      'report': report.toJson(),
      'reporter': reporter.toJson(),
      'target': target.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AdminReportSummaryImpl extends AdminReportSummary {
  _AdminReportSummaryImpl({
    required _i2.Report report,
    required _i3.AdminUserSummary reporter,
    required _i3.AdminUserSummary target,
  }) : super._(
         report: report,
         reporter: reporter,
         target: target,
       );

  /// Returns a shallow copy of this [AdminReportSummary]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AdminReportSummary copyWith({
    _i2.Report? report,
    _i3.AdminUserSummary? reporter,
    _i3.AdminUserSummary? target,
  }) {
    return AdminReportSummary(
      report: report ?? this.report.copyWith(),
      reporter: reporter ?? this.reporter.copyWith(),
      target: target ?? this.target.copyWith(),
    );
  }
}
