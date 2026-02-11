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

abstract class DailyReward implements _i1.SerializableModel {
  DailyReward._({
    this.id,
    required this.userId,
    required this.claimedDate,
    required this.rewardType,
    required this.rewardAmount,
    required this.streakDay,
  });

  factory DailyReward({
    int? id,
    required _i1.UuidValue userId,
    required DateTime claimedDate,
    required String rewardType,
    required int rewardAmount,
    required int streakDay,
  }) = _DailyRewardImpl;

  factory DailyReward.fromJson(Map<String, dynamic> jsonSerialization) {
    return DailyReward(
      id: jsonSerialization['id'] as int?,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      claimedDate: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['claimedDate'],
      ),
      rewardType: jsonSerialization['rewardType'] as String,
      rewardAmount: jsonSerialization['rewardAmount'] as int,
      streakDay: jsonSerialization['streakDay'] as int,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue userId;

  DateTime claimedDate;

  String rewardType;

  int rewardAmount;

  int streakDay;

  /// Returns a shallow copy of this [DailyReward]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DailyReward copyWith({
    int? id,
    _i1.UuidValue? userId,
    DateTime? claimedDate,
    String? rewardType,
    int? rewardAmount,
    int? streakDay,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DailyReward',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'claimedDate': claimedDate.toJson(),
      'rewardType': rewardType,
      'rewardAmount': rewardAmount,
      'streakDay': streakDay,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DailyRewardImpl extends DailyReward {
  _DailyRewardImpl({
    int? id,
    required _i1.UuidValue userId,
    required DateTime claimedDate,
    required String rewardType,
    required int rewardAmount,
    required int streakDay,
  }) : super._(
         id: id,
         userId: userId,
         claimedDate: claimedDate,
         rewardType: rewardType,
         rewardAmount: rewardAmount,
         streakDay: streakDay,
       );

  /// Returns a shallow copy of this [DailyReward]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DailyReward copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userId,
    DateTime? claimedDate,
    String? rewardType,
    int? rewardAmount,
    int? streakDay,
  }) {
    return DailyReward(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      claimedDate: claimedDate ?? this.claimedDate,
      rewardType: rewardType ?? this.rewardType,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      streakDay: streakDay ?? this.streakDay,
    );
  }
}
