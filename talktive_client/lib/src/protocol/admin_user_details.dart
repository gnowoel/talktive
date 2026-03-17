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
import 'admin_user_summary.dart' as _i2;
import 'message.dart' as _i3;
import 'moment.dart' as _i4;
import 'report.dart' as _i5;
import 'package:talktive_client/src/protocol/protocol.dart' as _i6;

abstract class AdminUserDetails implements _i1.SerializableModel {
  AdminUserDetails._({
    required this.user,
    required this.recentMessages,
    required this.recentMoments,
    required this.reportsAgainst,
    required this.reportsMade,
  });

  factory AdminUserDetails({
    required _i2.AdminUserSummary user,
    required List<_i3.Message> recentMessages,
    required List<_i4.Moment> recentMoments,
    required List<_i5.Report> reportsAgainst,
    required List<_i5.Report> reportsMade,
  }) = _AdminUserDetailsImpl;

  factory AdminUserDetails.fromJson(Map<String, dynamic> jsonSerialization) {
    return AdminUserDetails(
      user: _i6.Protocol().deserialize<_i2.AdminUserSummary>(
        jsonSerialization['user'],
      ),
      recentMessages: _i6.Protocol().deserialize<List<_i3.Message>>(
        jsonSerialization['recentMessages'],
      ),
      recentMoments: _i6.Protocol().deserialize<List<_i4.Moment>>(
        jsonSerialization['recentMoments'],
      ),
      reportsAgainst: _i6.Protocol().deserialize<List<_i5.Report>>(
        jsonSerialization['reportsAgainst'],
      ),
      reportsMade: _i6.Protocol().deserialize<List<_i5.Report>>(
        jsonSerialization['reportsMade'],
      ),
    );
  }

  _i2.AdminUserSummary user;

  List<_i3.Message> recentMessages;

  List<_i4.Moment> recentMoments;

  List<_i5.Report> reportsAgainst;

  List<_i5.Report> reportsMade;

  /// Returns a shallow copy of this [AdminUserDetails]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AdminUserDetails copyWith({
    _i2.AdminUserSummary? user,
    List<_i3.Message>? recentMessages,
    List<_i4.Moment>? recentMoments,
    List<_i5.Report>? reportsAgainst,
    List<_i5.Report>? reportsMade,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdminUserDetails',
      'user': user.toJson(),
      'recentMessages': recentMessages.toJson(valueToJson: (v) => v.toJson()),
      'recentMoments': recentMoments.toJson(valueToJson: (v) => v.toJson()),
      'reportsAgainst': reportsAgainst.toJson(valueToJson: (v) => v.toJson()),
      'reportsMade': reportsMade.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AdminUserDetailsImpl extends AdminUserDetails {
  _AdminUserDetailsImpl({
    required _i2.AdminUserSummary user,
    required List<_i3.Message> recentMessages,
    required List<_i4.Moment> recentMoments,
    required List<_i5.Report> reportsAgainst,
    required List<_i5.Report> reportsMade,
  }) : super._(
         user: user,
         recentMessages: recentMessages,
         recentMoments: recentMoments,
         reportsAgainst: reportsAgainst,
         reportsMade: reportsMade,
       );

  /// Returns a shallow copy of this [AdminUserDetails]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AdminUserDetails copyWith({
    _i2.AdminUserSummary? user,
    List<_i3.Message>? recentMessages,
    List<_i4.Moment>? recentMoments,
    List<_i5.Report>? reportsAgainst,
    List<_i5.Report>? reportsMade,
  }) {
    return AdminUserDetails(
      user: user ?? this.user.copyWith(),
      recentMessages:
          recentMessages ??
          this.recentMessages.map((e0) => e0.copyWith()).toList(),
      recentMoments:
          recentMoments ??
          this.recentMoments.map((e0) => e0.copyWith()).toList(),
      reportsAgainst:
          reportsAgainst ??
          this.reportsAgainst.map((e0) => e0.copyWith()).toList(),
      reportsMade:
          reportsMade ?? this.reportsMade.map((e0) => e0.copyWith()).toList(),
    );
  }
}
