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

abstract class TypingIndicator
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  TypingIndicator._({
    required this.channelId,
    required this.senderId,
    required this.userName,
    required this.isTyping,
  });

  factory TypingIndicator({
    required int channelId,
    required _i1.UuidValue senderId,
    required String userName,
    required bool isTyping,
  }) = _TypingIndicatorImpl;

  factory TypingIndicator.fromJson(Map<String, dynamic> jsonSerialization) {
    return TypingIndicator(
      channelId: jsonSerialization['channelId'] as int,
      senderId: _i1.UuidValueJsonExtension.fromJson(
        jsonSerialization['senderId'],
      ),
      userName: jsonSerialization['userName'] as String,
      isTyping: _i1.BoolJsonExtension.fromJson(jsonSerialization['isTyping']),
    );
  }

  int channelId;

  _i1.UuidValue senderId;

  String userName;

  bool isTyping;

  /// Returns a shallow copy of this [TypingIndicator]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TypingIndicator copyWith({
    int? channelId,
    _i1.UuidValue? senderId,
    String? userName,
    bool? isTyping,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TypingIndicator',
      'channelId': channelId,
      'senderId': senderId.toJson(),
      'userName': userName,
      'isTyping': isTyping,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'TypingIndicator',
      'channelId': channelId,
      'senderId': senderId.toJson(),
      'userName': userName,
      'isTyping': isTyping,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _TypingIndicatorImpl extends TypingIndicator {
  _TypingIndicatorImpl({
    required int channelId,
    required _i1.UuidValue senderId,
    required String userName,
    required bool isTyping,
  }) : super._(
         channelId: channelId,
         senderId: senderId,
         userName: userName,
         isTyping: isTyping,
       );

  /// Returns a shallow copy of this [TypingIndicator]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TypingIndicator copyWith({
    int? channelId,
    _i1.UuidValue? senderId,
    String? userName,
    bool? isTyping,
  }) {
    return TypingIndicator(
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      userName: userName ?? this.userName,
      isTyping: isTyping ?? this.isTyping,
    );
  }
}
