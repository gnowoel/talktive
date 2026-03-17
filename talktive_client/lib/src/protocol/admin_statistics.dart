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
import 'admin_totals.dart' as _i2;
import 'admin_activity.dart' as _i3;
import 'package:talktive_client/src/protocol/protocol.dart' as _i4;

abstract class AdminStatistics implements _i1.SerializableModel {
  AdminStatistics._({
    required this.totals,
    required this.last24h,
    required this.last7d,
    required this.last30d,
  });

  factory AdminStatistics({
    required _i2.AdminTotals totals,
    required _i3.AdminActivity last24h,
    required _i3.AdminActivity last7d,
    required _i3.AdminActivity last30d,
  }) = _AdminStatisticsImpl;

  factory AdminStatistics.fromJson(Map<String, dynamic> jsonSerialization) {
    return AdminStatistics(
      totals: _i4.Protocol().deserialize<_i2.AdminTotals>(
        jsonSerialization['totals'],
      ),
      last24h: _i4.Protocol().deserialize<_i3.AdminActivity>(
        jsonSerialization['last24h'],
      ),
      last7d: _i4.Protocol().deserialize<_i3.AdminActivity>(
        jsonSerialization['last7d'],
      ),
      last30d: _i4.Protocol().deserialize<_i3.AdminActivity>(
        jsonSerialization['last30d'],
      ),
    );
  }

  _i2.AdminTotals totals;

  _i3.AdminActivity last24h;

  _i3.AdminActivity last7d;

  _i3.AdminActivity last30d;

  /// Returns a shallow copy of this [AdminStatistics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  AdminStatistics copyWith({
    _i2.AdminTotals? totals,
    _i3.AdminActivity? last24h,
    _i3.AdminActivity? last7d,
    _i3.AdminActivity? last30d,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'AdminStatistics',
      'totals': totals.toJson(),
      'last24h': last24h.toJson(),
      'last7d': last7d.toJson(),
      'last30d': last30d.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _AdminStatisticsImpl extends AdminStatistics {
  _AdminStatisticsImpl({
    required _i2.AdminTotals totals,
    required _i3.AdminActivity last24h,
    required _i3.AdminActivity last7d,
    required _i3.AdminActivity last30d,
  }) : super._(
         totals: totals,
         last24h: last24h,
         last7d: last7d,
         last30d: last30d,
       );

  /// Returns a shallow copy of this [AdminStatistics]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  AdminStatistics copyWith({
    _i2.AdminTotals? totals,
    _i3.AdminActivity? last24h,
    _i3.AdminActivity? last7d,
    _i3.AdminActivity? last30d,
  }) {
    return AdminStatistics(
      totals: totals ?? this.totals.copyWith(),
      last24h: last24h ?? this.last24h.copyWith(),
      last7d: last7d ?? this.last7d.copyWith(),
      last30d: last30d ?? this.last30d.copyWith(),
    );
  }
}
