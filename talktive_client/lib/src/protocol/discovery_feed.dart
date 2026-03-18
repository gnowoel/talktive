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
import 'user_summary.dart' as _i2;
import 'moment.dart' as _i3;
import 'lounge.dart' as _i4;
import 'package:talktive_client/src/protocol/protocol.dart' as _i5;

/// Personalized discovery feed
abstract class DiscoveryFeed implements _i1.SerializableModel {
  DiscoveryFeed._({
    required this.usersByInterests,
    required this.usersByLanguages,
    required this.trendingMoments,
    required this.popularLounges,
    this.recommendedLounges,
  });

  factory DiscoveryFeed({
    required List<_i2.UserSummary> usersByInterests,
    required List<_i2.UserSummary> usersByLanguages,
    required List<_i3.Moment> trendingMoments,
    required List<_i4.Lounge> popularLounges,
    List<_i4.Lounge>? recommendedLounges,
  }) = _DiscoveryFeedImpl;

  factory DiscoveryFeed.fromJson(Map<String, dynamic> jsonSerialization) {
    return DiscoveryFeed(
      usersByInterests: _i5.Protocol().deserialize<List<_i2.UserSummary>>(
        jsonSerialization['usersByInterests'],
      ),
      usersByLanguages: _i5.Protocol().deserialize<List<_i2.UserSummary>>(
        jsonSerialization['usersByLanguages'],
      ),
      trendingMoments: _i5.Protocol().deserialize<List<_i3.Moment>>(
        jsonSerialization['trendingMoments'],
      ),
      popularLounges: _i5.Protocol().deserialize<List<_i4.Lounge>>(
        jsonSerialization['popularLounges'],
      ),
      recommendedLounges: jsonSerialization['recommendedLounges'] == null
          ? null
          : _i5.Protocol().deserialize<List<_i4.Lounge>>(
              jsonSerialization['recommendedLounges'],
            ),
    );
  }

  List<_i2.UserSummary> usersByInterests;

  List<_i2.UserSummary> usersByLanguages;

  List<_i3.Moment> trendingMoments;

  List<_i4.Lounge> popularLounges;

  List<_i4.Lounge>? recommendedLounges;

  /// Returns a shallow copy of this [DiscoveryFeed]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DiscoveryFeed copyWith({
    List<_i2.UserSummary>? usersByInterests,
    List<_i2.UserSummary>? usersByLanguages,
    List<_i3.Moment>? trendingMoments,
    List<_i4.Lounge>? popularLounges,
    List<_i4.Lounge>? recommendedLounges,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DiscoveryFeed',
      'usersByInterests': usersByInterests.toJson(
        valueToJson: (v) => v.toJson(),
      ),
      'usersByLanguages': usersByLanguages.toJson(
        valueToJson: (v) => v.toJson(),
      ),
      'trendingMoments': trendingMoments.toJson(valueToJson: (v) => v.toJson()),
      'popularLounges': popularLounges.toJson(valueToJson: (v) => v.toJson()),
      if (recommendedLounges != null)
        'recommendedLounges': recommendedLounges?.toJson(
          valueToJson: (v) => v.toJson(),
        ),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DiscoveryFeedImpl extends DiscoveryFeed {
  _DiscoveryFeedImpl({
    required List<_i2.UserSummary> usersByInterests,
    required List<_i2.UserSummary> usersByLanguages,
    required List<_i3.Moment> trendingMoments,
    required List<_i4.Lounge> popularLounges,
    List<_i4.Lounge>? recommendedLounges,
  }) : super._(
         usersByInterests: usersByInterests,
         usersByLanguages: usersByLanguages,
         trendingMoments: trendingMoments,
         popularLounges: popularLounges,
         recommendedLounges: recommendedLounges,
       );

  /// Returns a shallow copy of this [DiscoveryFeed]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DiscoveryFeed copyWith({
    List<_i2.UserSummary>? usersByInterests,
    List<_i2.UserSummary>? usersByLanguages,
    List<_i3.Moment>? trendingMoments,
    List<_i4.Lounge>? popularLounges,
    Object? recommendedLounges = _Undefined,
  }) {
    return DiscoveryFeed(
      usersByInterests:
          usersByInterests ??
          this.usersByInterests.map((e0) => e0.copyWith()).toList(),
      usersByLanguages:
          usersByLanguages ??
          this.usersByLanguages.map((e0) => e0.copyWith()).toList(),
      trendingMoments:
          trendingMoments ??
          this.trendingMoments.map((e0) => e0.copyWith()).toList(),
      popularLounges:
          popularLounges ??
          this.popularLounges.map((e0) => e0.copyWith()).toList(),
      recommendedLounges: recommendedLounges is List<_i4.Lounge>?
          ? recommendedLounges
          : this.recommendedLounges?.map((e0) => e0.copyWith()).toList(),
    );
  }
}
