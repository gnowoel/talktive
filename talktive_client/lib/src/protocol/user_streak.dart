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

abstract class UserStreak implements _i1.SerializableModel {
  UserStreak._({
    this.id,
    required this.userId,
    int? currentStreak,
    int? longestStreak,
    this.lastActiveDate,
    int? totalActiveDays,
  }) : currentStreak = currentStreak ?? 0,
       longestStreak = longestStreak ?? 0,
       totalActiveDays = totalActiveDays ?? 0;

  factory UserStreak({
    int? id,
    required _i1.UuidValue userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? totalActiveDays,
  }) = _UserStreakImpl;

  factory UserStreak.fromJson(Map<String, dynamic> jsonSerialization) {
    return UserStreak(
      id: jsonSerialization['id'] as int?,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      currentStreak: jsonSerialization['currentStreak'] as int?,
      longestStreak: jsonSerialization['longestStreak'] as int?,
      lastActiveDate: jsonSerialization['lastActiveDate'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['lastActiveDate'],
            ),
      totalActiveDays: jsonSerialization['totalActiveDays'] as int?,
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  _i1.UuidValue userId;

  int currentStreak;

  int longestStreak;

  DateTime? lastActiveDate;

  int totalActiveDays;

  /// Returns a shallow copy of this [UserStreak]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  UserStreak copyWith({
    int? id,
    _i1.UuidValue? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? totalActiveDays,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'UserStreak',
      if (id != null) 'id': id,
      'userId': userId.toJson(),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      if (lastActiveDate != null) 'lastActiveDate': lastActiveDate?.toJson(),
      'totalActiveDays': totalActiveDays,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _UserStreakImpl extends UserStreak {
  _UserStreakImpl({
    int? id,
    required _i1.UuidValue userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? totalActiveDays,
  }) : super._(
         id: id,
         userId: userId,
         currentStreak: currentStreak,
         longestStreak: longestStreak,
         lastActiveDate: lastActiveDate,
         totalActiveDays: totalActiveDays,
       );

  /// Returns a shallow copy of this [UserStreak]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  UserStreak copyWith({
    Object? id = _Undefined,
    _i1.UuidValue? userId,
    int? currentStreak,
    int? longestStreak,
    Object? lastActiveDate = _Undefined,
    int? totalActiveDays,
  }) {
    return UserStreak(
      id: id is int? ? id : this.id,
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: lastActiveDate is DateTime?
          ? lastActiveDate
          : this.lastActiveDate,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
    );
  }
}
