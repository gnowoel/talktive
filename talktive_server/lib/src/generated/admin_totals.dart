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

abstract class AdminTotals
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  AdminTotals._({
    required this.users,
    required this.messages,
    required this.moments,
    required this.lounges,
    required this.reports,
    required this.pendingReports,
  });

  factory AdminTotals({
    required int users,
    required int messages,
    required int moments,
    required int lounges,
    required int reports,
    required int pendingReports,
  }) = _AdminTotalsImpl;

  factory AdminTotals.fromJson(Map<String, dynamic> jsonSerialization) {
    return AdminTotals(
      users: jsonSerialization['users'] as int,
      messages: jsonSerialization['messages'] as int,
      moments: jsonSerialization['moments'] as int,
      lounges: jsonSerialization['lounges'] as int,
      reports: jsonSerialization['reports'] as int,
      pendingReports: jsonSerialization['pendingReports'] as int,
    );
  }

  int users;

  int messages;

  int moments;

  int lounges;

  int reports;

  int pendingReports;

  /// Returns a shallow copy of this [AdminTotals]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AdminTotals copyWith({
    int? users,
    int? messages,
    int? moments,
    int? lounges,
    int? reports,
    int? pendingReports,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdminTotals',
      'users': users,
      'messages': messages,
      'moments': moments,
      'lounges': lounges,
      'reports': reports,
      'pendingReports': pendingReports,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'AdminTotals',
      'users': users,
      'messages': messages,
      'moments': moments,
      'lounges': lounges,
      'reports': reports,
      'pendingReports': pendingReports,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AdminTotalsImpl extends AdminTotals {
  _AdminTotalsImpl({
    required int users,
    required int messages,
    required int moments,
    required int lounges,
    required int reports,
    required int pendingReports,
  }) : super._(
         users: users,
         messages: messages,
         moments: moments,
         lounges: lounges,
         reports: reports,
         pendingReports: pendingReports,
       );

  /// Returns a shallow copy of this [AdminTotals]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AdminTotals copyWith({
    int? users,
    int? messages,
    int? moments,
    int? lounges,
    int? reports,
    int? pendingReports,
  }) {
    return AdminTotals(
      users: users ?? this.users,
      messages: messages ?? this.messages,
      moments: moments ?? this.moments,
      lounges: lounges ?? this.lounges,
      reports: reports ?? this.reports,
      pendingReports: pendingReports ?? this.pendingReports,
    );
  }
}
