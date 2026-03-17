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
import 'admin_activity.dart' as _i3;
import 'admin_report_summary.dart' as _i4;
import 'admin_statistics.dart' as _i5;
import 'admin_totals.dart' as _i6;
import 'admin_user_details.dart' as _i7;
import 'admin_user_summary.dart' as _i8;
import 'block.dart' as _i9;
import 'cache_int.dart' as _i10;
import 'cache_string.dart' as _i11;
import 'channel.dart' as _i12;
import 'channel_member.dart' as _i13;
import 'channel_member_status.dart' as _i14;
import 'channel_subscription.dart' as _i15;
import 'channel_type.dart' as _i16;
import 'daily_reward.dart' as _i17;
import 'device_token.dart' as _i18;
import 'greetings/greeting.dart' as _i19;
import 'group.dart' as _i20;
import 'group_member_with_profile.dart' as _i21;
import 'group_with_membership.dart' as _i22;
import 'message.dart' as _i23;
import 'moment.dart' as _i24;
import 'moment_comment.dart' as _i25;
import 'moment_like.dart' as _i26;
import 'private_chat.dart' as _i27;
import 'private_chat_with_profile.dart' as _i28;
import 'report.dart' as _i29;
import 'report_status.dart' as _i30;
import 'resident.dart' as _i31;
import 'resident_role.dart' as _i32;
import 'talktive_exception.dart' as _i33;
import 'user_achievement.dart' as _i34;
import 'user_like.dart' as _i35;
import 'user_notification.dart' as _i36;
import 'user_profile_view.dart' as _i37;
import 'package:talktive_client/src/protocol/admin_report_summary.dart' as _i38;
import 'package:talktive_client/src/protocol/admin_user_summary.dart' as _i39;
import 'package:talktive_client/src/protocol/daily_reward.dart' as _i40;
import 'package:talktive_client/src/protocol/group_with_membership.dart'
    as _i41;
import 'package:talktive_client/src/protocol/group.dart' as _i42;
import 'package:talktive_client/src/protocol/group_member_with_profile.dart'
    as _i43;
import 'package:talktive_client/src/protocol/resident.dart' as _i44;
import 'package:talktive_client/src/protocol/message.dart' as _i45;
import 'package:talktive_client/src/protocol/moment.dart' as _i46;
import 'package:talktive_client/src/protocol/moment_like.dart' as _i47;
import 'package:talktive_client/src/protocol/moment_comment.dart' as _i48;
import 'package:talktive_client/src/protocol/user_notification.dart' as _i49;
import 'package:talktive_client/src/protocol/private_chat_with_profile.dart'
    as _i50;
import 'package:talktive_client/src/protocol/report.dart' as _i51;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i52;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i53;
import 'package:serverpod_auth_client/serverpod_auth_client.dart' as _i54;
export 'achievement.dart';
export 'admin_activity.dart';
export 'admin_report_summary.dart';
export 'admin_statistics.dart';
export 'admin_totals.dart';
export 'admin_user_details.dart';
export 'admin_user_summary.dart';
export 'block.dart';
export 'cache_int.dart';
export 'cache_string.dart';
export 'channel.dart';
export 'channel_member.dart';
export 'channel_member_status.dart';
export 'channel_subscription.dart';
export 'channel_type.dart';
export 'daily_reward.dart';
export 'device_token.dart';
export 'greetings/greeting.dart';
export 'group.dart';
export 'group_member_with_profile.dart';
export 'group_with_membership.dart';
export 'message.dart';
export 'moment.dart';
export 'moment_comment.dart';
export 'moment_like.dart';
export 'private_chat.dart';
export 'private_chat_with_profile.dart';
export 'report.dart';
export 'report_status.dart';
export 'resident.dart';
export 'resident_role.dart';
export 'talktive_exception.dart';
export 'user_achievement.dart';
export 'user_like.dart';
export 'user_notification.dart';
export 'user_profile_view.dart';
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
    if (t == _i3.AdminActivity) {
      return _i3.AdminActivity.fromJson(data) as T;
    }
    if (t == _i4.AdminReportSummary) {
      return _i4.AdminReportSummary.fromJson(data) as T;
    }
    if (t == _i5.AdminStatistics) {
      return _i5.AdminStatistics.fromJson(data) as T;
    }
    if (t == _i6.AdminTotals) {
      return _i6.AdminTotals.fromJson(data) as T;
    }
    if (t == _i7.AdminUserDetails) {
      return _i7.AdminUserDetails.fromJson(data) as T;
    }
    if (t == _i8.AdminUserSummary) {
      return _i8.AdminUserSummary.fromJson(data) as T;
    }
    if (t == _i9.Block) {
      return _i9.Block.fromJson(data) as T;
    }
    if (t == _i10.CacheInt) {
      return _i10.CacheInt.fromJson(data) as T;
    }
    if (t == _i11.CacheString) {
      return _i11.CacheString.fromJson(data) as T;
    }
    if (t == _i12.Channel) {
      return _i12.Channel.fromJson(data) as T;
    }
    if (t == _i13.ChannelMember) {
      return _i13.ChannelMember.fromJson(data) as T;
    }
    if (t == _i14.ChannelMemberStatus) {
      return _i14.ChannelMemberStatus.fromJson(data) as T;
    }
    if (t == _i15.ChannelSubscription) {
      return _i15.ChannelSubscription.fromJson(data) as T;
    }
    if (t == _i16.ChannelType) {
      return _i16.ChannelType.fromJson(data) as T;
    }
    if (t == _i17.DailyReward) {
      return _i17.DailyReward.fromJson(data) as T;
    }
    if (t == _i18.DeviceToken) {
      return _i18.DeviceToken.fromJson(data) as T;
    }
    if (t == _i19.Greeting) {
      return _i19.Greeting.fromJson(data) as T;
    }
    if (t == _i20.Group) {
      return _i20.Group.fromJson(data) as T;
    }
    if (t == _i21.GroupMemberWithProfile) {
      return _i21.GroupMemberWithProfile.fromJson(data) as T;
    }
    if (t == _i22.GroupWithMembership) {
      return _i22.GroupWithMembership.fromJson(data) as T;
    }
    if (t == _i23.Message) {
      return _i23.Message.fromJson(data) as T;
    }
    if (t == _i24.Moment) {
      return _i24.Moment.fromJson(data) as T;
    }
    if (t == _i25.MomentComment) {
      return _i25.MomentComment.fromJson(data) as T;
    }
    if (t == _i26.MomentLike) {
      return _i26.MomentLike.fromJson(data) as T;
    }
    if (t == _i27.PrivateChat) {
      return _i27.PrivateChat.fromJson(data) as T;
    }
    if (t == _i28.PrivateChatWithProfile) {
      return _i28.PrivateChatWithProfile.fromJson(data) as T;
    }
    if (t == _i29.Report) {
      return _i29.Report.fromJson(data) as T;
    }
    if (t == _i30.ReportStatus) {
      return _i30.ReportStatus.fromJson(data) as T;
    }
    if (t == _i31.Resident) {
      return _i31.Resident.fromJson(data) as T;
    }
    if (t == _i32.ResidentRole) {
      return _i32.ResidentRole.fromJson(data) as T;
    }
    if (t == _i33.TalktiveException) {
      return _i33.TalktiveException.fromJson(data) as T;
    }
    if (t == _i34.UserAchievement) {
      return _i34.UserAchievement.fromJson(data) as T;
    }
    if (t == _i35.UserLike) {
      return _i35.UserLike.fromJson(data) as T;
    }
    if (t == _i36.UserNotification) {
      return _i36.UserNotification.fromJson(data) as T;
    }
    if (t == _i37.UserProfileView) {
      return _i37.UserProfileView.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Achievement?>()) {
      return (data != null ? _i2.Achievement.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.AdminActivity?>()) {
      return (data != null ? _i3.AdminActivity.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.AdminReportSummary?>()) {
      return (data != null ? _i4.AdminReportSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.AdminStatistics?>()) {
      return (data != null ? _i5.AdminStatistics.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i6.AdminTotals?>()) {
      return (data != null ? _i6.AdminTotals.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.AdminUserDetails?>()) {
      return (data != null ? _i7.AdminUserDetails.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.AdminUserSummary?>()) {
      return (data != null ? _i8.AdminUserSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.Block?>()) {
      return (data != null ? _i9.Block.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.CacheInt?>()) {
      return (data != null ? _i10.CacheInt.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.CacheString?>()) {
      return (data != null ? _i11.CacheString.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.Channel?>()) {
      return (data != null ? _i12.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.ChannelMember?>()) {
      return (data != null ? _i13.ChannelMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.ChannelMemberStatus?>()) {
      return (data != null ? _i14.ChannelMemberStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i15.ChannelSubscription?>()) {
      return (data != null ? _i15.ChannelSubscription.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i16.ChannelType?>()) {
      return (data != null ? _i16.ChannelType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.DailyReward?>()) {
      return (data != null ? _i17.DailyReward.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.DeviceToken?>()) {
      return (data != null ? _i18.DeviceToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i19.Greeting?>()) {
      return (data != null ? _i19.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i20.Group?>()) {
      return (data != null ? _i20.Group.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.GroupMemberWithProfile?>()) {
      return (data != null ? _i21.GroupMemberWithProfile.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i22.GroupWithMembership?>()) {
      return (data != null ? _i22.GroupWithMembership.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i23.Message?>()) {
      return (data != null ? _i23.Message.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.Moment?>()) {
      return (data != null ? _i24.Moment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i25.MomentComment?>()) {
      return (data != null ? _i25.MomentComment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.MomentLike?>()) {
      return (data != null ? _i26.MomentLike.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.PrivateChat?>()) {
      return (data != null ? _i27.PrivateChat.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i28.PrivateChatWithProfile?>()) {
      return (data != null ? _i28.PrivateChatWithProfile.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i29.Report?>()) {
      return (data != null ? _i29.Report.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.ReportStatus?>()) {
      return (data != null ? _i30.ReportStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.Resident?>()) {
      return (data != null ? _i31.Resident.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i32.ResidentRole?>()) {
      return (data != null ? _i32.ResidentRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.TalktiveException?>()) {
      return (data != null ? _i33.TalktiveException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.UserAchievement?>()) {
      return (data != null ? _i34.UserAchievement.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i35.UserLike?>()) {
      return (data != null ? _i35.UserLike.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.UserNotification?>()) {
      return (data != null ? _i36.UserNotification.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i37.UserProfileView?>()) {
      return (data != null ? _i37.UserProfileView.fromJson(data) : null) as T;
    }
    if (t == List<_i23.Message>) {
      return (data as List).map((e) => deserialize<_i23.Message>(e)).toList()
          as T;
    }
    if (t == List<_i24.Moment>) {
      return (data as List).map((e) => deserialize<_i24.Moment>(e)).toList()
          as T;
    }
    if (t == List<_i29.Report>) {
      return (data as List).map((e) => deserialize<_i29.Report>(e)).toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == _i1.getType<List<_i24.Moment>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<_i24.Moment>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i38.AdminReportSummary>) {
      return (data as List)
              .map((e) => deserialize<_i38.AdminReportSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i39.AdminUserSummary>) {
      return (data as List)
              .map((e) => deserialize<_i39.AdminUserSummary>(e))
              .toList()
          as T;
    }
    if (t == Map<String, int>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<int>(v)),
          )
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
    if (t == List<_i40.DailyReward>) {
      return (data as List)
              .map((e) => deserialize<_i40.DailyReward>(e))
              .toList()
          as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _i1.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i41.GroupWithMembership>) {
      return (data as List)
              .map((e) => deserialize<_i41.GroupWithMembership>(e))
              .toList()
          as T;
    }
    if (t == List<_i42.Group>) {
      return (data as List).map((e) => deserialize<_i42.Group>(e)).toList()
          as T;
    }
    if (t == List<_i43.GroupMemberWithProfile>) {
      return (data as List)
              .map((e) => deserialize<_i43.GroupMemberWithProfile>(e))
              .toList()
          as T;
    }
    if (t == List<_i44.Resident>) {
      return (data as List).map((e) => deserialize<_i44.Resident>(e)).toList()
          as T;
    }
    if (t == List<_i45.Message>) {
      return (data as List).map((e) => deserialize<_i45.Message>(e)).toList()
          as T;
    }
    if (t == List<_i46.Moment>) {
      return (data as List).map((e) => deserialize<_i46.Moment>(e)).toList()
          as T;
    }
    if (t == List<_i47.MomentLike>) {
      return (data as List).map((e) => deserialize<_i47.MomentLike>(e)).toList()
          as T;
    }
    if (t == Map<int, bool>) {
      return Map.fromEntries(
            (data as List).map(
              (e) =>
                  MapEntry(deserialize<int>(e['k']), deserialize<bool>(e['v'])),
            ),
          )
          as T;
    }
    if (t == List<_i48.MomentComment>) {
      return (data as List)
              .map((e) => deserialize<_i48.MomentComment>(e))
              .toList()
          as T;
    }
    if (t == List<_i49.UserNotification>) {
      return (data as List)
              .map((e) => deserialize<_i49.UserNotification>(e))
              .toList()
          as T;
    }
    if (t == List<_i50.PrivateChatWithProfile>) {
      return (data as List)
              .map((e) => deserialize<_i50.PrivateChatWithProfile>(e))
              .toList()
          as T;
    }
    if (t == List<_i51.Report>) {
      return (data as List).map((e) => deserialize<_i51.Report>(e)).toList()
          as T;
    }
    try {
      return _i52.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i53.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i54.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.Achievement => 'Achievement',
      _i3.AdminActivity => 'AdminActivity',
      _i4.AdminReportSummary => 'AdminReportSummary',
      _i5.AdminStatistics => 'AdminStatistics',
      _i6.AdminTotals => 'AdminTotals',
      _i7.AdminUserDetails => 'AdminUserDetails',
      _i8.AdminUserSummary => 'AdminUserSummary',
      _i9.Block => 'Block',
      _i10.CacheInt => 'CacheInt',
      _i11.CacheString => 'CacheString',
      _i12.Channel => 'Channel',
      _i13.ChannelMember => 'ChannelMember',
      _i14.ChannelMemberStatus => 'ChannelMemberStatus',
      _i15.ChannelSubscription => 'ChannelSubscription',
      _i16.ChannelType => 'ChannelType',
      _i17.DailyReward => 'DailyReward',
      _i18.DeviceToken => 'DeviceToken',
      _i19.Greeting => 'Greeting',
      _i20.Group => 'Group',
      _i21.GroupMemberWithProfile => 'GroupMemberWithProfile',
      _i22.GroupWithMembership => 'GroupWithMembership',
      _i23.Message => 'Message',
      _i24.Moment => 'Moment',
      _i25.MomentComment => 'MomentComment',
      _i26.MomentLike => 'MomentLike',
      _i27.PrivateChat => 'PrivateChat',
      _i28.PrivateChatWithProfile => 'PrivateChatWithProfile',
      _i29.Report => 'Report',
      _i30.ReportStatus => 'ReportStatus',
      _i31.Resident => 'Resident',
      _i32.ResidentRole => 'ResidentRole',
      _i33.TalktiveException => 'TalktiveException',
      _i34.UserAchievement => 'UserAchievement',
      _i35.UserLike => 'UserLike',
      _i36.UserNotification => 'UserNotification',
      _i37.UserProfileView => 'UserProfileView',
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
      case _i3.AdminActivity():
        return 'AdminActivity';
      case _i4.AdminReportSummary():
        return 'AdminReportSummary';
      case _i5.AdminStatistics():
        return 'AdminStatistics';
      case _i6.AdminTotals():
        return 'AdminTotals';
      case _i7.AdminUserDetails():
        return 'AdminUserDetails';
      case _i8.AdminUserSummary():
        return 'AdminUserSummary';
      case _i9.Block():
        return 'Block';
      case _i10.CacheInt():
        return 'CacheInt';
      case _i11.CacheString():
        return 'CacheString';
      case _i12.Channel():
        return 'Channel';
      case _i13.ChannelMember():
        return 'ChannelMember';
      case _i14.ChannelMemberStatus():
        return 'ChannelMemberStatus';
      case _i15.ChannelSubscription():
        return 'ChannelSubscription';
      case _i16.ChannelType():
        return 'ChannelType';
      case _i17.DailyReward():
        return 'DailyReward';
      case _i18.DeviceToken():
        return 'DeviceToken';
      case _i19.Greeting():
        return 'Greeting';
      case _i20.Group():
        return 'Group';
      case _i21.GroupMemberWithProfile():
        return 'GroupMemberWithProfile';
      case _i22.GroupWithMembership():
        return 'GroupWithMembership';
      case _i23.Message():
        return 'Message';
      case _i24.Moment():
        return 'Moment';
      case _i25.MomentComment():
        return 'MomentComment';
      case _i26.MomentLike():
        return 'MomentLike';
      case _i27.PrivateChat():
        return 'PrivateChat';
      case _i28.PrivateChatWithProfile():
        return 'PrivateChatWithProfile';
      case _i29.Report():
        return 'Report';
      case _i30.ReportStatus():
        return 'ReportStatus';
      case _i31.Resident():
        return 'Resident';
      case _i32.ResidentRole():
        return 'ResidentRole';
      case _i33.TalktiveException():
        return 'TalktiveException';
      case _i34.UserAchievement():
        return 'UserAchievement';
      case _i35.UserLike():
        return 'UserLike';
      case _i36.UserNotification():
        return 'UserNotification';
      case _i37.UserProfileView():
        return 'UserProfileView';
    }
    className = _i52.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i53.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i54.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth.$className';
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
    if (dataClassName == 'AdminActivity') {
      return deserialize<_i3.AdminActivity>(data['data']);
    }
    if (dataClassName == 'AdminReportSummary') {
      return deserialize<_i4.AdminReportSummary>(data['data']);
    }
    if (dataClassName == 'AdminStatistics') {
      return deserialize<_i5.AdminStatistics>(data['data']);
    }
    if (dataClassName == 'AdminTotals') {
      return deserialize<_i6.AdminTotals>(data['data']);
    }
    if (dataClassName == 'AdminUserDetails') {
      return deserialize<_i7.AdminUserDetails>(data['data']);
    }
    if (dataClassName == 'AdminUserSummary') {
      return deserialize<_i8.AdminUserSummary>(data['data']);
    }
    if (dataClassName == 'Block') {
      return deserialize<_i9.Block>(data['data']);
    }
    if (dataClassName == 'CacheInt') {
      return deserialize<_i10.CacheInt>(data['data']);
    }
    if (dataClassName == 'CacheString') {
      return deserialize<_i11.CacheString>(data['data']);
    }
    if (dataClassName == 'Channel') {
      return deserialize<_i12.Channel>(data['data']);
    }
    if (dataClassName == 'ChannelMember') {
      return deserialize<_i13.ChannelMember>(data['data']);
    }
    if (dataClassName == 'ChannelMemberStatus') {
      return deserialize<_i14.ChannelMemberStatus>(data['data']);
    }
    if (dataClassName == 'ChannelSubscription') {
      return deserialize<_i15.ChannelSubscription>(data['data']);
    }
    if (dataClassName == 'ChannelType') {
      return deserialize<_i16.ChannelType>(data['data']);
    }
    if (dataClassName == 'DailyReward') {
      return deserialize<_i17.DailyReward>(data['data']);
    }
    if (dataClassName == 'DeviceToken') {
      return deserialize<_i18.DeviceToken>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i19.Greeting>(data['data']);
    }
    if (dataClassName == 'Group') {
      return deserialize<_i20.Group>(data['data']);
    }
    if (dataClassName == 'GroupMemberWithProfile') {
      return deserialize<_i21.GroupMemberWithProfile>(data['data']);
    }
    if (dataClassName == 'GroupWithMembership') {
      return deserialize<_i22.GroupWithMembership>(data['data']);
    }
    if (dataClassName == 'Message') {
      return deserialize<_i23.Message>(data['data']);
    }
    if (dataClassName == 'Moment') {
      return deserialize<_i24.Moment>(data['data']);
    }
    if (dataClassName == 'MomentComment') {
      return deserialize<_i25.MomentComment>(data['data']);
    }
    if (dataClassName == 'MomentLike') {
      return deserialize<_i26.MomentLike>(data['data']);
    }
    if (dataClassName == 'PrivateChat') {
      return deserialize<_i27.PrivateChat>(data['data']);
    }
    if (dataClassName == 'PrivateChatWithProfile') {
      return deserialize<_i28.PrivateChatWithProfile>(data['data']);
    }
    if (dataClassName == 'Report') {
      return deserialize<_i29.Report>(data['data']);
    }
    if (dataClassName == 'ReportStatus') {
      return deserialize<_i30.ReportStatus>(data['data']);
    }
    if (dataClassName == 'Resident') {
      return deserialize<_i31.Resident>(data['data']);
    }
    if (dataClassName == 'ResidentRole') {
      return deserialize<_i32.ResidentRole>(data['data']);
    }
    if (dataClassName == 'TalktiveException') {
      return deserialize<_i33.TalktiveException>(data['data']);
    }
    if (dataClassName == 'UserAchievement') {
      return deserialize<_i34.UserAchievement>(data['data']);
    }
    if (dataClassName == 'UserLike') {
      return deserialize<_i35.UserLike>(data['data']);
    }
    if (dataClassName == 'UserNotification') {
      return deserialize<_i36.UserNotification>(data['data']);
    }
    if (dataClassName == 'UserProfileView') {
      return deserialize<_i37.UserProfileView>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i52.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i53.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth.')) {
      data['className'] = dataClassName.substring(15);
      return _i54.Protocol().deserializeByClassName(data);
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
      return _i52.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i53.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i54.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }

  /// Maps container types (like [List], [Map], [Set]) containing
  /// [Record]s or non-String-keyed [Map]s to their JSON representation.
  ///
  /// It should not be called for [SerializableModel] types. These
  /// handle the "[Record] in container" mapping internally already.
  ///
  /// It is only supposed to be called from generated protocol code.
  ///
  /// Returns either a `List<dynamic>` (for List, Sets, and Maps with
  /// non-String keys) or a `Map<String, dynamic>` in case the input was
  /// a `Map<String, …>`.
  Object? mapContainerToJson(Object obj) {
    if (obj is! Iterable && obj is! Map) {
      throw ArgumentError.value(
        obj,
        'obj',
        'The object to serialize should be of type List, Map, or Set',
      );
    }

    dynamic mapIfNeeded(Object? obj) {
      return switch (obj) {
        Record record => mapRecordToJson(record),
        Iterable iterable => mapContainerToJson(iterable),
        Map map => mapContainerToJson(map),
        Object? value => value,
      };
    }

    switch (obj) {
      case Map<String, dynamic>():
        return {
          for (var entry in obj.entries) entry.key: mapIfNeeded(entry.value),
        };
      case Map():
        return [
          for (var entry in obj.entries)
            {
              'k': mapIfNeeded(entry.key),
              'v': mapIfNeeded(entry.value),
            },
        ];

      case Iterable():
        return [
          for (var e in obj) mapIfNeeded(e),
        ];
    }

    return obj;
  }
}
