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
import 'lounge.dart' as _i3;
import 'moment.dart' as _i4;
import 'package:talktive_client/src/protocol/protocol.dart' as _i5;

/// Combined search results
abstract class SearchAllResults implements _i1.SerializableModel {
  SearchAllResults._({
    required this.users,
    required this.lounges,
    required this.moments,
  });

  factory SearchAllResults({
    required List<_i2.UserSummary> users,
    required List<_i3.Lounge> lounges,
    required List<_i4.Moment> moments,
  }) = _SearchAllResultsImpl;

  factory SearchAllResults.fromJson(Map<String, dynamic> jsonSerialization) {
    return SearchAllResults(
      users: _i5.Protocol().deserialize<List<_i2.UserSummary>>(
        jsonSerialization['users'],
      ),
      lounges: _i5.Protocol().deserialize<List<_i3.Lounge>>(
        jsonSerialization['lounges'],
      ),
      moments: _i5.Protocol().deserialize<List<_i4.Moment>>(
        jsonSerialization['moments'],
      ),
    );
  }

  List<_i2.UserSummary> users;

  List<_i3.Lounge> lounges;

  List<_i4.Moment> moments;

  /// Returns a shallow copy of this [SearchAllResults]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SearchAllResults copyWith({
    List<_i2.UserSummary>? users,
    List<_i3.Lounge>? lounges,
    List<_i4.Moment>? moments,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SearchAllResults',
      'users': users.toJson(valueToJson: (v) => v.toJson()),
      'lounges': lounges.toJson(valueToJson: (v) => v.toJson()),
      'moments': moments.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _SearchAllResultsImpl extends SearchAllResults {
  _SearchAllResultsImpl({
    required List<_i2.UserSummary> users,
    required List<_i3.Lounge> lounges,
    required List<_i4.Moment> moments,
  }) : super._(
         users: users,
         lounges: lounges,
         moments: moments,
       );

  /// Returns a shallow copy of this [SearchAllResults]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SearchAllResults copyWith({
    List<_i2.UserSummary>? users,
    List<_i3.Lounge>? lounges,
    List<_i4.Moment>? moments,
  }) {
    return SearchAllResults(
      users: users ?? this.users.map((e0) => e0.copyWith()).toList(),
      lounges: lounges ?? this.lounges.map((e0) => e0.copyWith()).toList(),
      moments: moments ?? this.moments.map((e0) => e0.copyWith()).toList(),
    );
  }
}
