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

abstract class ReadReceiptEvent implements _i1.SerializableModel {
  ReadReceiptEvent._({
    required this.channelId,
    required this.userId,
    required this.lastReadAt,
  });

  factory ReadReceiptEvent({
    required int channelId,
    required _i1.UuidValue userId,
    required DateTime lastReadAt,
  }) = _ReadReceiptEventImpl;

  factory ReadReceiptEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReadReceiptEvent(
      channelId: jsonSerialization['channelId'] as int,
      userId: _i1.UuidValueJsonExtension.fromJson(jsonSerialization['userId']),
      lastReadAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['lastReadAt'],
      ),
    );
  }

  int channelId;

  _i1.UuidValue userId;

  DateTime lastReadAt;

  /// Returns a shallow copy of this [ReadReceiptEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ReadReceiptEvent copyWith({
    int? channelId,
    _i1.UuidValue? userId,
    DateTime? lastReadAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReadReceiptEvent',
      'channelId': channelId,
      'userId': userId.toJson(),
      'lastReadAt': lastReadAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ReadReceiptEventImpl extends ReadReceiptEvent {
  _ReadReceiptEventImpl({
    required int channelId,
    required _i1.UuidValue userId,
    required DateTime lastReadAt,
  }) : super._(
         channelId: channelId,
         userId: userId,
         lastReadAt: lastReadAt,
       );

  /// Returns a shallow copy of this [ReadReceiptEvent]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ReadReceiptEvent copyWith({
    int? channelId,
    _i1.UuidValue? userId,
    DateTime? lastReadAt,
  }) {
    return ReadReceiptEvent(
      channelId: channelId ?? this.channelId,
      userId: userId ?? this.userId,
      lastReadAt: lastReadAt ?? this.lastReadAt,
    );
  }
}
