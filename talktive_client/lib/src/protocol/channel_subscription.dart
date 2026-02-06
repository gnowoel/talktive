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

abstract class ChannelSubscription implements _i1.SerializableModel {
  ChannelSubscription._({required this.channelId});

  factory ChannelSubscription({required int channelId}) =
      _ChannelSubscriptionImpl;

  factory ChannelSubscription.fromJson(Map<String, dynamic> jsonSerialization) {
    return ChannelSubscription(
      channelId: jsonSerialization['channelId'] as int,
    );
  }

  int channelId;

  /// Returns a shallow copy of this [ChannelSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ChannelSubscription copyWith({int? channelId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ChannelSubscription',
      'channelId': channelId,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ChannelSubscriptionImpl extends ChannelSubscription {
  _ChannelSubscriptionImpl({required int channelId})
    : super._(channelId: channelId);

  /// Returns a shallow copy of this [ChannelSubscription]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ChannelSubscription copyWith({int? channelId}) {
    return ChannelSubscription(channelId: channelId ?? this.channelId);
  }
}
