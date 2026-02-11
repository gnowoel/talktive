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
import 'daily_reward.dart' as _i9;
import 'device_token.dart' as _i10;
import 'greetings/greeting.dart' as _i11;
import 'group.dart' as _i12;
import 'message.dart' as _i13;
import 'moment.dart' as _i14;
import 'moment_comment.dart' as _i15;
import 'moment_like.dart' as _i16;
import 'private_chat.dart' as _i17;
import 'rate_limit.dart' as _i18;
import 'report.dart' as _i19;
import 'resident.dart' as _i20;
import 'user_achievement.dart' as _i21;
import 'user_notification.dart' as _i22;
import 'user_profile_view.dart' as _i23;
import 'user_streak.dart' as _i24;
import 'package:talktive_client/src/protocol/group.dart' as _i25;
import 'package:talktive_client/src/protocol/resident.dart' as _i26;
import 'package:talktive_client/src/protocol/message.dart' as _i27;
import 'package:talktive_client/src/protocol/moment.dart' as _i28;
import 'package:talktive_client/src/protocol/moment_like.dart' as _i29;
import 'package:talktive_client/src/protocol/moment_comment.dart' as _i30;
import 'package:talktive_client/src/protocol/user_notification.dart' as _i31;
import 'package:talktive_client/src/protocol/private_chat.dart' as _i32;
import 'package:talktive_client/src/protocol/report.dart' as _i33;
import 'package:talktive_client/src/protocol/daily_reward.dart' as _i34;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i35;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i36;
export 'achievement.dart';
export 'block.dart';
export 'channel.dart';
export 'channel_member.dart';
export 'channel_member_status.dart';
export 'channel_subscription.dart';
export 'channel_type.dart';
export 'daily_reward.dart';
export 'device_token.dart';
export 'greetings/greeting.dart';
export 'group.dart';
export 'message.dart';
export 'moment.dart';
export 'moment_comment.dart';
export 'moment_like.dart';
export 'private_chat.dart';
export 'rate_limit.dart';
export 'report.dart';
export 'resident.dart';
export 'user_achievement.dart';
export 'user_notification.dart';
export 'user_profile_view.dart';
export 'user_streak.dart';
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
    if (t == _i9.DailyReward) {
      return _i9.DailyReward.fromJson(data) as T;
    }
    if (t == _i10.DeviceToken) {
      return _i10.DeviceToken.fromJson(data) as T;
    }
    if (t == _i11.Greeting) {
      return _i11.Greeting.fromJson(data) as T;
    }
    if (t == _i12.Group) {
      return _i12.Group.fromJson(data) as T;
    }
    if (t == _i13.Message) {
      return _i13.Message.fromJson(data) as T;
    }
    if (t == _i14.Moment) {
      return _i14.Moment.fromJson(data) as T;
    }
    if (t == _i15.MomentComment) {
      return _i15.MomentComment.fromJson(data) as T;
    }
    if (t == _i16.MomentLike) {
      return _i16.MomentLike.fromJson(data) as T;
    }
    if (t == _i17.PrivateChat) {
      return _i17.PrivateChat.fromJson(data) as T;
    }
    if (t == _i18.RateLimit) {
      return _i18.RateLimit.fromJson(data) as T;
    }
    if (t == _i19.Report) {
      return _i19.Report.fromJson(data) as T;
    }
    if (t == _i20.Resident) {
      return _i20.Resident.fromJson(data) as T;
    }
    if (t == _i21.UserAchievement) {
      return _i21.UserAchievement.fromJson(data) as T;
    }
    if (t == _i22.UserNotification) {
      return _i22.UserNotification.fromJson(data) as T;
    }
    if (t == _i23.UserProfileView) {
      return _i23.UserProfileView.fromJson(data) as T;
    }
    if (t == _i24.UserStreak) {
      return _i24.UserStreak.fromJson(data) as T;
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
    if (t == _i1.getType<_i9.DailyReward?>()) {
      return (data != null ? _i9.DailyReward.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.DeviceToken?>()) {
      return (data != null ? _i10.DeviceToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.Greeting?>()) {
      return (data != null ? _i11.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.Group?>()) {
      return (data != null ? _i12.Group.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.Message?>()) {
      return (data != null ? _i13.Message.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.Moment?>()) {
      return (data != null ? _i14.Moment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.MomentComment?>()) {
      return (data != null ? _i15.MomentComment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.MomentLike?>()) {
      return (data != null ? _i16.MomentLike.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.PrivateChat?>()) {
      return (data != null ? _i17.PrivateChat.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.RateLimit?>()) {
      return (data != null ? _i18.RateLimit.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.Report?>()) {
      return (data != null ? _i19.Report.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.Resident?>()) {
      return (data != null ? _i20.Resident.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.UserAchievement?>()) {
      return (data != null ? _i21.UserAchievement.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.UserNotification?>()) {
      return (data != null ? _i22.UserNotification.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.UserProfileView?>()) {
      return (data != null ? _i23.UserProfileView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.UserStreak?>()) {
      return (data != null ? _i24.UserStreak.fromJson(data) : null) as T;
    }
    if (t == List<_i14.Moment>) {
      return (data as List).map((e) => deserialize<_i14.Moment>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i14.Moment>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<_i14.Moment>(e)).toList()
              : null)
          as T;
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
    if (t == List<_i25.Group>) {
      return (data as List).map((e) => deserialize<_i25.Group>(e)).toList()
          as T;
    }
    if (t == List<_i26.Resident>) {
      return (data as List).map((e) => deserialize<_i26.Resident>(e)).toList()
          as T;
    }
    if (t == List<_i27.Message>) {
      return (data as List).map((e) => deserialize<_i27.Message>(e)).toList()
          as T;
    }
    if (t == List<_i28.Moment>) {
      return (data as List).map((e) => deserialize<_i28.Moment>(e)).toList()
          as T;
    }
    if (t == List<_i29.MomentLike>) {
      return (data as List).map((e) => deserialize<_i29.MomentLike>(e)).toList()
          as T;
    }
    if (t == List<_i30.MomentComment>) {
      return (data as List)
              .map((e) => deserialize<_i30.MomentComment>(e))
              .toList()
          as T;
    }
    if (t == List<_i31.UserNotification>) {
      return (data as List)
              .map((e) => deserialize<_i31.UserNotification>(e))
              .toList()
          as T;
    }
    if (t == List<_i32.PrivateChat>) {
      return (data as List)
              .map((e) => deserialize<_i32.PrivateChat>(e))
              .toList()
          as T;
    }
    if (t == List<_i33.Report>) {
      return (data as List).map((e) => deserialize<_i33.Report>(e)).toList()
          as T;
    }
    if (t == List<_i34.DailyReward>) {
      return (data as List)
              .map((e) => deserialize<_i34.DailyReward>(e))
              .toList()
          as T;
    }
    try {
      return _i35.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i36.Protocol().deserialize<T>(data, t);
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
      _i9.DailyReward => 'DailyReward',
      _i10.DeviceToken => 'DeviceToken',
      _i11.Greeting => 'Greeting',
      _i12.Group => 'Group',
      _i13.Message => 'Message',
      _i14.Moment => 'Moment',
      _i15.MomentComment => 'MomentComment',
      _i16.MomentLike => 'MomentLike',
      _i17.PrivateChat => 'PrivateChat',
      _i18.RateLimit => 'RateLimit',
      _i19.Report => 'Report',
      _i20.Resident => 'Resident',
      _i21.UserAchievement => 'UserAchievement',
      _i22.UserNotification => 'UserNotification',
      _i23.UserProfileView => 'UserProfileView',
      _i24.UserStreak => 'UserStreak',
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
      case _i9.DailyReward():
        return 'DailyReward';
      case _i10.DeviceToken():
        return 'DeviceToken';
      case _i11.Greeting():
        return 'Greeting';
      case _i12.Group():
        return 'Group';
      case _i13.Message():
        return 'Message';
      case _i14.Moment():
        return 'Moment';
      case _i15.MomentComment():
        return 'MomentComment';
      case _i16.MomentLike():
        return 'MomentLike';
      case _i17.PrivateChat():
        return 'PrivateChat';
      case _i18.RateLimit():
        return 'RateLimit';
      case _i19.Report():
        return 'Report';
      case _i20.Resident():
        return 'Resident';
      case _i21.UserAchievement():
        return 'UserAchievement';
      case _i22.UserNotification():
        return 'UserNotification';
      case _i23.UserProfileView():
        return 'UserProfileView';
      case _i24.UserStreak():
        return 'UserStreak';
    }
    className = _i35.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i36.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'DailyReward') {
      return deserialize<_i9.DailyReward>(data['data']);
    }
    if (dataClassName == 'DeviceToken') {
      return deserialize<_i10.DeviceToken>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i11.Greeting>(data['data']);
    }
    if (dataClassName == 'Group') {
      return deserialize<_i12.Group>(data['data']);
    }
    if (dataClassName == 'Message') {
      return deserialize<_i13.Message>(data['data']);
    }
    if (dataClassName == 'Moment') {
      return deserialize<_i14.Moment>(data['data']);
    }
    if (dataClassName == 'MomentComment') {
      return deserialize<_i15.MomentComment>(data['data']);
    }
    if (dataClassName == 'MomentLike') {
      return deserialize<_i16.MomentLike>(data['data']);
    }
    if (dataClassName == 'PrivateChat') {
      return deserialize<_i17.PrivateChat>(data['data']);
    }
    if (dataClassName == 'RateLimit') {
      return deserialize<_i18.RateLimit>(data['data']);
    }
    if (dataClassName == 'Report') {
      return deserialize<_i19.Report>(data['data']);
    }
    if (dataClassName == 'Resident') {
      return deserialize<_i20.Resident>(data['data']);
    }
    if (dataClassName == 'UserAchievement') {
      return deserialize<_i21.UserAchievement>(data['data']);
    }
    if (dataClassName == 'UserNotification') {
      return deserialize<_i22.UserNotification>(data['data']);
    }
    if (dataClassName == 'UserProfileView') {
      return deserialize<_i23.UserProfileView>(data['data']);
    }
    if (dataClassName == 'UserStreak') {
      return deserialize<_i24.UserStreak>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i35.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i36.Protocol().deserializeByClassName(data);
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
      return _i35.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i36.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
