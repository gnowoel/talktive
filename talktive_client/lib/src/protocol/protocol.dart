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
import 'achievement.dart' as _i2;
import 'block.dart' as _i3;
import 'channel.dart' as _i4;
import 'channel_member.dart' as _i5;
import 'channel_member_status.dart' as _i6;
import 'channel_subscription.dart' as _i7;
import 'channel_type.dart' as _i8;
import 'greetings/greeting.dart' as _i9;
import 'group.dart' as _i10;
import 'message.dart' as _i11;
import 'moment.dart' as _i12;
import 'private_chat.dart' as _i13;
import 'rate_limit.dart' as _i14;
import 'report.dart' as _i15;
import 'resident.dart' as _i16;
import 'user_achievement.dart' as _i17;
import 'package:talktive_client/src/protocol/group.dart' as _i18;
import 'package:talktive_client/src/protocol/resident.dart' as _i19;
import 'package:talktive_client/src/protocol/message.dart' as _i20;
import 'package:talktive_client/src/protocol/moment.dart' as _i21;
import 'package:talktive_client/src/protocol/private_chat.dart' as _i22;
import 'package:talktive_client/src/protocol/report.dart' as _i23;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i24;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i25;
export 'achievement.dart';
export 'block.dart';
export 'channel.dart';
export 'channel_member.dart';
export 'channel_member_status.dart';
export 'channel_subscription.dart';
export 'channel_type.dart';
export 'greetings/greeting.dart';
export 'group.dart';
export 'message.dart';
export 'moment.dart';
export 'private_chat.dart';
export 'rate_limit.dart';
export 'report.dart';
export 'resident.dart';
export 'user_achievement.dart';
export 'client.dart';

class Protocol extends _i1.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on FormatException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i2.Achievement) {
      return _i2.Achievement.fromJson(data) as T;
    }
    if (t == _i3.Block) {
      return _i3.Block.fromJson(data) as T;
    }
    if (t == _i4.Channel) {
      return _i4.Channel.fromJson(data) as T;
    }
    if (t == _i5.ChannelMember) {
      return _i5.ChannelMember.fromJson(data) as T;
    }
    if (t == _i6.ChannelMemberStatus) {
      return _i6.ChannelMemberStatus.fromJson(data) as T;
    }
    if (t == _i7.ChannelSubscription) {
      return _i7.ChannelSubscription.fromJson(data) as T;
    }
    if (t == _i8.ChannelType) {
      return _i8.ChannelType.fromJson(data) as T;
    }
    if (t == _i9.Greeting) {
      return _i9.Greeting.fromJson(data) as T;
    }
    if (t == _i10.Group) {
      return _i10.Group.fromJson(data) as T;
    }
    if (t == _i11.Message) {
      return _i11.Message.fromJson(data) as T;
    }
    if (t == _i12.Moment) {
      return _i12.Moment.fromJson(data) as T;
    }
    if (t == _i13.PrivateChat) {
      return _i13.PrivateChat.fromJson(data) as T;
    }
    if (t == _i14.RateLimit) {
      return _i14.RateLimit.fromJson(data) as T;
    }
    if (t == _i15.Report) {
      return _i15.Report.fromJson(data) as T;
    }
    if (t == _i16.Resident) {
      return _i16.Resident.fromJson(data) as T;
    }
    if (t == _i17.UserAchievement) {
      return _i17.UserAchievement.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Achievement?>()) {
      return (data != null ? _i2.Achievement.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Block?>()) {
      return (data != null ? _i3.Block.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.Channel?>()) {
      return (data != null ? _i4.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.ChannelMember?>()) {
      return (data != null ? _i5.ChannelMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.ChannelMemberStatus?>()) {
      return (data != null ? _i6.ChannelMemberStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i7.ChannelSubscription?>()) {
      return (data != null ? _i7.ChannelSubscription.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i8.ChannelType?>()) {
      return (data != null ? _i8.ChannelType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.Greeting?>()) {
      return (data != null ? _i9.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.Group?>()) {
      return (data != null ? _i10.Group.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.Message?>()) {
      return (data != null ? _i11.Message.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.Moment?>()) {
      return (data != null ? _i12.Moment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.PrivateChat?>()) {
      return (data != null ? _i13.PrivateChat.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.RateLimit?>()) {
      return (data != null ? _i14.RateLimit.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.Report?>()) {
      return (data != null ? _i15.Report.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.Resident?>()) {
      return (data != null ? _i16.Resident.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.UserAchievement?>()) {
      return (data != null ? _i17.UserAchievement.fromJson(data) : null) as T;
    }
    if (t == List<Map<String, dynamic>>) {
      return (data as List)
              .map((e) => deserialize<Map<String, dynamic>>(e))
              .toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i18.Group>) {
      return (data as List).map((e) => deserialize<_i18.Group>(e)).toList()
          as T;
    }
    if (t == List<_i19.Resident>) {
      return (data as List).map((e) => deserialize<_i19.Resident>(e)).toList()
          as T;
    }
    if (t == List<_i20.Message>) {
      return (data as List).map((e) => deserialize<_i20.Message>(e)).toList()
          as T;
    }
    if (t == List<_i21.Moment>) {
      return (data as List).map((e) => deserialize<_i21.Moment>(e)).toList()
          as T;
    }
    if (t == List<_i22.PrivateChat>) {
      return (data as List)
              .map((e) => deserialize<_i22.PrivateChat>(e))
              .toList()
          as T;
    }
    if (t == List<_i23.Report>) {
      return (data as List).map((e) => deserialize<_i23.Report>(e)).toList()
          as T;
    }
    try {
      return _i24.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i25.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.Achievement => 'Achievement',
      _i3.Block => 'Block',
      _i4.Channel => 'Channel',
      _i5.ChannelMember => 'ChannelMember',
      _i6.ChannelMemberStatus => 'ChannelMemberStatus',
      _i7.ChannelSubscription => 'ChannelSubscription',
      _i8.ChannelType => 'ChannelType',
      _i9.Greeting => 'Greeting',
      _i10.Group => 'Group',
      _i11.Message => 'Message',
      _i12.Moment => 'Moment',
      _i13.PrivateChat => 'PrivateChat',
      _i14.RateLimit => 'RateLimit',
      _i15.Report => 'Report',
      _i16.Resident => 'Resident',
      _i17.UserAchievement => 'UserAchievement',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('talktive.', '');
    }

    switch (data) {
      case _i2.Achievement():
        return 'Achievement';
      case _i3.Block():
        return 'Block';
      case _i4.Channel():
        return 'Channel';
      case _i5.ChannelMember():
        return 'ChannelMember';
      case _i6.ChannelMemberStatus():
        return 'ChannelMemberStatus';
      case _i7.ChannelSubscription():
        return 'ChannelSubscription';
      case _i8.ChannelType():
        return 'ChannelType';
      case _i9.Greeting():
        return 'Greeting';
      case _i10.Group():
        return 'Group';
      case _i11.Message():
        return 'Message';
      case _i12.Moment():
        return 'Moment';
      case _i13.PrivateChat():
        return 'PrivateChat';
      case _i14.RateLimit():
        return 'RateLimit';
      case _i15.Report():
        return 'Report';
      case _i16.Resident():
        return 'Resident';
      case _i17.UserAchievement():
        return 'UserAchievement';
    }
    className = _i24.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i25.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'Achievement') {
      return deserialize<_i2.Achievement>(data['data']);
    }
    if (dataClassName == 'Block') {
      return deserialize<_i3.Block>(data['data']);
    }
    if (dataClassName == 'Channel') {
      return deserialize<_i4.Channel>(data['data']);
    }
    if (dataClassName == 'ChannelMember') {
      return deserialize<_i5.ChannelMember>(data['data']);
    }
    if (dataClassName == 'ChannelMemberStatus') {
      return deserialize<_i6.ChannelMemberStatus>(data['data']);
    }
    if (dataClassName == 'ChannelSubscription') {
      return deserialize<_i7.ChannelSubscription>(data['data']);
    }
    if (dataClassName == 'ChannelType') {
      return deserialize<_i8.ChannelType>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i9.Greeting>(data['data']);
    }
    if (dataClassName == 'Group') {
      return deserialize<_i10.Group>(data['data']);
    }
    if (dataClassName == 'Message') {
      return deserialize<_i11.Message>(data['data']);
    }
    if (dataClassName == 'Moment') {
      return deserialize<_i12.Moment>(data['data']);
    }
    if (dataClassName == 'PrivateChat') {
      return deserialize<_i13.PrivateChat>(data['data']);
    }
    if (dataClassName == 'RateLimit') {
      return deserialize<_i14.RateLimit>(data['data']);
    }
    if (dataClassName == 'Report') {
      return deserialize<_i15.Report>(data['data']);
    }
    if (dataClassName == 'Resident') {
      return deserialize<_i16.Resident>(data['data']);
    }
    if (dataClassName == 'UserAchievement') {
      return deserialize<_i17.UserAchievement>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i24.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i25.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _i24.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i25.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
