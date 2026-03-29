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
import 'package:serverpod/protocol.dart' as _i2;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _i3;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _i4;
import 'package:serverpod_auth_server/serverpod_auth_server.dart' as _i5;
import 'achievement.dart' as _i6;
import 'admin_activity.dart' as _i7;
import 'admin_report_summary.dart' as _i8;
import 'admin_statistics.dart' as _i9;
import 'admin_totals.dart' as _i10;
import 'admin_user_details.dart' as _i11;
import 'admin_user_summary.dart' as _i12;
import 'block.dart' as _i13;
import 'cache_int.dart' as _i14;
import 'cache_string.dart' as _i15;
import 'channel.dart' as _i16;
import 'channel_member.dart' as _i17;
import 'channel_member_status.dart' as _i18;
import 'channel_subscription.dart' as _i19;
import 'channel_type.dart' as _i20;
import 'daily_reward.dart' as _i21;
import 'device_token.dart' as _i22;
import 'discovery_feed.dart' as _i23;
import 'gamification_status.dart' as _i24;
import 'greetings/greeting.dart' as _i25;
import 'lounge.dart' as _i26;
import 'lounge_member_with_profile.dart' as _i27;
import 'lounge_with_membership.dart' as _i28;
import 'message.dart' as _i29;
import 'moment.dart' as _i30;
import 'moment_comment.dart' as _i31;
import 'moment_like.dart' as _i32;
import 'private_chat.dart' as _i33;
import 'private_chat_with_profile.dart' as _i34;
import 'read_receipt_event.dart' as _i35;
import 'report.dart' as _i36;
import 'report_status.dart' as _i37;
import 'resident.dart' as _i38;
import 'resident_role.dart' as _i39;
import 'search_all_results.dart' as _i40;
import 'talktive_exception.dart' as _i41;
import 'typing_indicator.dart' as _i42;
import 'user_achievement.dart' as _i43;
import 'user_achievement_view.dart' as _i44;
import 'user_like.dart' as _i45;
import 'user_notification.dart' as _i46;
import 'user_profile_view.dart' as _i47;
import 'user_summary.dart' as _i48;
import 'package:talktive_server/src/generated/admin_report_summary.dart'
    as _i49;
import 'package:talktive_server/src/generated/admin_user_summary.dart' as _i50;
import 'package:talktive_server/src/generated/user_achievement_view.dart'
    as _i51;
import 'package:talktive_server/src/generated/daily_reward.dart' as _i52;
import 'package:talktive_server/src/generated/lounge_with_membership.dart'
    as _i53;
import 'package:talktive_server/src/generated/lounge.dart' as _i54;
import 'package:talktive_server/src/generated/lounge_member_with_profile.dart'
    as _i55;
import 'package:talktive_server/src/generated/message.dart' as _i56;
import 'package:talktive_server/src/generated/moment.dart' as _i57;
import 'package:talktive_server/src/generated/moment_like.dart' as _i58;
import 'package:talktive_server/src/generated/moment_comment.dart' as _i59;
import 'package:talktive_server/src/generated/user_notification.dart' as _i60;
import 'package:talktive_server/src/generated/private_chat_with_profile.dart'
    as _i61;
import 'package:talktive_server/src/generated/user_summary.dart' as _i62;
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
export 'discovery_feed.dart';
export 'gamification_status.dart';
export 'greetings/greeting.dart';
export 'lounge.dart';
export 'lounge_member_with_profile.dart';
export 'lounge_with_membership.dart';
export 'message.dart';
export 'moment.dart';
export 'moment_comment.dart';
export 'moment_like.dart';
export 'private_chat.dart';
export 'private_chat_with_profile.dart';
export 'read_receipt_event.dart';
export 'report.dart';
export 'report_status.dart';
export 'resident.dart';
export 'resident_role.dart';
export 'search_all_results.dart';
export 'talktive_exception.dart';
export 'typing_indicator.dart';
export 'user_achievement.dart';
export 'user_achievement_view.dart';
export 'user_like.dart';
export 'user_notification.dart';
export 'user_profile_view.dart';
export 'user_summary.dart';

class Protocol extends _i1.SerializationManagerServer {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static final List<_i2.TableDefinition> targetTableDefinitions = [
    _i2.TableDefinition(
      name: 'achievements',
      dartName: 'Achievement',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'achievements_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'key',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'emoji',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'category',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'targetValue',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'points',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '10',
        ),
        _i2.ColumnDefinition(
          name: 'isSecret',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'achievements_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'achievement_key_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'key',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'channel',
      dartName: 'Channel',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'channel_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'type',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ChannelType',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'lastMessageAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'isPersistent',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'channel_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'channel_member',
      dartName: 'ChannelMember',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'channel_member_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'channelId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'userInfoId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'joinedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'role',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ChannelMemberStatus',
        ),
        _i2.ColumnDefinition(
          name: 'invitedBy',
          columnType: _i2.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _i2.ColumnDefinition(
          name: 'isMuted',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'lastReadAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'CURRENT_TIMESTAMP',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'channel_member_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'channel_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'channelId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userInfoId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'channel_member_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userInfoId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'daily_rewards',
      dartName: 'DailyReward',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'daily_rewards_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'claimedDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'rewardType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'rewardAmount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'streakDay',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'daily_rewards_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'user_date_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'claimedDate',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'device_tokens',
      dartName: 'DeviceToken',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'device_tokens_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'token',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'platform',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'lastUsed',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'device_tokens_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'user_token_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'token',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'token_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'token',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'lounge',
      dartName: 'Lounge',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'lounge_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'channelId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'name',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'description',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'emoji',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'creatorId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'memberCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'isPublic',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'maxMembers',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '50',
        ),
        _i2.ColumnDefinition(
          name: 'lastMessageAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'lastMessage',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'interests',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _i2.ColumnDefinition(
          name: 'languages',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _i2.ColumnDefinition(
          name: 'country',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'rules',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'level',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '1',
        ),
        _i2.ColumnDefinition(
          name: 'xp',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'isStaffLocked',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'lounge_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'lounge_channel_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'channelId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'lounge_creator_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'creatorId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'lounge_active_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'isPublic',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'isStaffLocked',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'lastMessageAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'lounge_member_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'memberCount',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'lounge_lastmsg_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'lastMessageAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'message',
      dartName: 'Message',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'message_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'channelId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'senderId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'content',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'imageUrl',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'mediaUrl',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'mediaType',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'isSystem',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _i2.ColumnDefinition(
          name: 'isPinned',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'pinnedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'duration',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'fileSize',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'isRecalled',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'recalledAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'senderName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'senderAvatar',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'senderMood',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'senderFloor',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'senderTrustScore',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'message_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'message_channel_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'channelId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'message_sender_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'senderId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'message_created_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'message_channel_created_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'channelId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'moment',
      dartName: 'Moment',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'moment_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'authorId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'imageUrl',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'caption',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'mediaType',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'image\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'likesCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'commentsCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'fileSize',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'authorName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'authorAvatar',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'authorMood',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'authorFloor',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'authorTrustScore',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'moment_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'moment_author_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'authorId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'moment_created_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'moment_likes_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'likesCount',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'moment_created_likes_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'likesCount',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'moment_comments',
      dartName: 'MomentComment',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'moment_comments_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'momentId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'text',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'userName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'userAvatar',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'userMood',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'userFloor',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'userTrustScore',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'moment_comments_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'moment_comment_created_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'momentId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'moment_likes',
      dartName: 'MomentLike',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'moment_likes_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'momentId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'userName',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'userAvatar',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'userMood',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'userFloor',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'userTrustScore',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'moment_likes_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'moment_user_unique',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'momentId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'private_chat',
      dartName: 'PrivateChat',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'private_chat_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'channelId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'participant1Id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'participant2Id',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'lastMessageAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'lastMessage',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'private_chat_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'private_chat_channel_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'channelId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'private_chat_participants_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'participant1Id',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'participant2Id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'report',
      dartName: 'Report',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'report_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'reporterId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'targetId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'reason',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'channelId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'messageId',
          columnType: _i2.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _i2.ColumnDefinition(
          name: 'status',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ReportStatus',
          columnDefault: '\'pending\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'adminNotes',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'resolvedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'report_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'report_target_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'targetId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'report_reporter_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'reporterId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'report_status_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'resident',
      dartName: 'Resident',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'resident_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userInfoId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'trustScore',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '100',
        ),
        _i2.ColumnDefinition(
          name: 'lastReputationIncrease',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'mutedUntil',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'suspended',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'xp',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'level',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'currentStreak',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'longestStreak',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'lastLoginDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'lastMessageDate',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'experienceMessageCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'userName',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'gender',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'country',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'bio',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'mood',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'avatar',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'ageRange',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
          columnDefault: '\'18-24\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'interests',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _i2.ColumnDefinition(
          name: 'languages',
          columnType: _i2.ColumnType.json,
          isNullable: true,
          dartType: 'List<String>?',
        ),
        _i2.ColumnDefinition(
          name: 'role',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ResidentRole',
          columnDefault: '\'user\'::text',
        ),
        _i2.ColumnDefinition(
          name: 'lastSeen',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'isPremium',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'premiumTrialExpires',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'trialCount',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'showOnlineStatus',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'showReadReceipts',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'showTypingIndicator',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'showVoiceMessages',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'showNeighborsDiscovery',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'allowDiscovery',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'showCustomAvatar',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'showImagesInPlaza',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'showImagesInLounges',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'showImagesInPrivateChats',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'showImagesInMoments',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'showOthersOnlineStatus',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'showOthersReadReceipts',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'showOthersTypingIndicators',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'keepPrivateChats',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _i2.ColumnDefinition(
          name: 'customAvatarUrl',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'resident_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'resident_user_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userInfoId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'resident_search_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'allowDiscovery',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'lastSeen',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'resident_geo_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'country',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'gender',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'ageRange',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'resident_xp_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'xp',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'resident_level_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'level',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'resident_role_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'role',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'resident_lastseen_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'lastSeen',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'user_achievements',
      dartName: 'UserAchievement',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'user_achievements_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'achievementId',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _i2.ColumnDefinition(
          name: 'progress',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _i2.ColumnDefinition(
          name: 'unlockedAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _i2.ColumnDefinition(
          name: 'notified',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'user_achievements_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'user_achievement_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'achievementId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'user_unlocked_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'unlockedAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'user_block',
      dartName: 'Block',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'user_block_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'blockerId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'blockedId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'user_block_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'block_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'blockerId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'blockedId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'user_like',
      dartName: 'UserLike',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'user_like_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'senderId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'receiverId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'user_like_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'user_like_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'senderId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'receiverId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _i2.TableDefinition(
      name: 'user_notifications',
      dartName: 'UserNotification',
      schema: 'public',
      module: 'talktive',
      columns: [
        _i2.ColumnDefinition(
          name: 'id',
          columnType: _i2.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'nextval(\'user_notifications_id_seq\'::regclass)',
        ),
        _i2.ColumnDefinition(
          name: 'userId',
          columnType: _i2.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _i2.ColumnDefinition(
          name: 'type',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'title',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'body',
          columnType: _i2.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _i2.ColumnDefinition(
          name: 'data',
          columnType: _i2.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _i2.ColumnDefinition(
          name: 'read',
          columnType: _i2.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _i2.ColumnDefinition(
          name: 'createdAt',
          columnType: _i2.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _i2.IndexDefinition(
          indexName: 'user_notifications_pkey',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: true,
        ),
        _i2.IndexDefinition(
          indexName: 'user_created_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _i2.IndexDefinition(
          indexName: 'user_read_idx',
          tableSpace: null,
          elements: [
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _i2.IndexElementDefinition(
              type: _i2.IndexElementDefinitionType.column,
              definition: 'read',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._i3.Protocol.targetTableDefinitions,
    ..._i4.Protocol.targetTableDefinitions,
    ..._i5.Protocol.targetTableDefinitions,
    ..._i2.Protocol.targetTableDefinitions,
  ];

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

    if (t == _i6.Achievement) {
      return _i6.Achievement.fromJson(data) as T;
    }
    if (t == _i7.AdminActivity) {
      return _i7.AdminActivity.fromJson(data) as T;
    }
    if (t == _i8.AdminReportSummary) {
      return _i8.AdminReportSummary.fromJson(data) as T;
    }
    if (t == _i9.AdminStatistics) {
      return _i9.AdminStatistics.fromJson(data) as T;
    }
    if (t == _i10.AdminTotals) {
      return _i10.AdminTotals.fromJson(data) as T;
    }
    if (t == _i11.AdminUserDetails) {
      return _i11.AdminUserDetails.fromJson(data) as T;
    }
    if (t == _i12.AdminUserSummary) {
      return _i12.AdminUserSummary.fromJson(data) as T;
    }
    if (t == _i13.Block) {
      return _i13.Block.fromJson(data) as T;
    }
    if (t == _i14.CacheInt) {
      return _i14.CacheInt.fromJson(data) as T;
    }
    if (t == _i15.CacheString) {
      return _i15.CacheString.fromJson(data) as T;
    }
    if (t == _i16.Channel) {
      return _i16.Channel.fromJson(data) as T;
    }
    if (t == _i17.ChannelMember) {
      return _i17.ChannelMember.fromJson(data) as T;
    }
    if (t == _i18.ChannelMemberStatus) {
      return _i18.ChannelMemberStatus.fromJson(data) as T;
    }
    if (t == _i19.ChannelSubscription) {
      return _i19.ChannelSubscription.fromJson(data) as T;
    }
    if (t == _i20.ChannelType) {
      return _i20.ChannelType.fromJson(data) as T;
    }
    if (t == _i21.DailyReward) {
      return _i21.DailyReward.fromJson(data) as T;
    }
    if (t == _i22.DeviceToken) {
      return _i22.DeviceToken.fromJson(data) as T;
    }
    if (t == _i23.DiscoveryFeed) {
      return _i23.DiscoveryFeed.fromJson(data) as T;
    }
    if (t == _i24.GamificationStatus) {
      return _i24.GamificationStatus.fromJson(data) as T;
    }
    if (t == _i25.Greeting) {
      return _i25.Greeting.fromJson(data) as T;
    }
    if (t == _i26.Lounge) {
      return _i26.Lounge.fromJson(data) as T;
    }
    if (t == _i27.LoungeMemberWithProfile) {
      return _i27.LoungeMemberWithProfile.fromJson(data) as T;
    }
    if (t == _i28.LoungeWithMembership) {
      return _i28.LoungeWithMembership.fromJson(data) as T;
    }
    if (t == _i29.Message) {
      return _i29.Message.fromJson(data) as T;
    }
    if (t == _i30.Moment) {
      return _i30.Moment.fromJson(data) as T;
    }
    if (t == _i31.MomentComment) {
      return _i31.MomentComment.fromJson(data) as T;
    }
    if (t == _i32.MomentLike) {
      return _i32.MomentLike.fromJson(data) as T;
    }
    if (t == _i33.PrivateChat) {
      return _i33.PrivateChat.fromJson(data) as T;
    }
    if (t == _i34.PrivateChatWithProfile) {
      return _i34.PrivateChatWithProfile.fromJson(data) as T;
    }
    if (t == _i35.ReadReceiptEvent) {
      return _i35.ReadReceiptEvent.fromJson(data) as T;
    }
    if (t == _i36.Report) {
      return _i36.Report.fromJson(data) as T;
    }
    if (t == _i37.ReportStatus) {
      return _i37.ReportStatus.fromJson(data) as T;
    }
    if (t == _i38.Resident) {
      return _i38.Resident.fromJson(data) as T;
    }
    if (t == _i39.ResidentRole) {
      return _i39.ResidentRole.fromJson(data) as T;
    }
    if (t == _i40.SearchAllResults) {
      return _i40.SearchAllResults.fromJson(data) as T;
    }
    if (t == _i41.TalktiveException) {
      return _i41.TalktiveException.fromJson(data) as T;
    }
    if (t == _i42.TypingIndicator) {
      return _i42.TypingIndicator.fromJson(data) as T;
    }
    if (t == _i43.UserAchievement) {
      return _i43.UserAchievement.fromJson(data) as T;
    }
    if (t == _i44.UserAchievementView) {
      return _i44.UserAchievementView.fromJson(data) as T;
    }
    if (t == _i45.UserLike) {
      return _i45.UserLike.fromJson(data) as T;
    }
    if (t == _i46.UserNotification) {
      return _i46.UserNotification.fromJson(data) as T;
    }
    if (t == _i47.UserProfileView) {
      return _i47.UserProfileView.fromJson(data) as T;
    }
    if (t == _i48.UserSummary) {
      return _i48.UserSummary.fromJson(data) as T;
    }
    if (t == _i1.getType<_i6.Achievement?>()) {
      return (data != null ? _i6.Achievement.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.AdminActivity?>()) {
      return (data != null ? _i7.AdminActivity.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.AdminReportSummary?>()) {
      return (data != null ? _i8.AdminReportSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.AdminStatistics?>()) {
      return (data != null ? _i9.AdminStatistics.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.AdminTotals?>()) {
      return (data != null ? _i10.AdminTotals.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.AdminUserDetails?>()) {
      return (data != null ? _i11.AdminUserDetails.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i12.AdminUserSummary?>()) {
      return (data != null ? _i12.AdminUserSummary.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i13.Block?>()) {
      return (data != null ? _i13.Block.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i14.CacheInt?>()) {
      return (data != null ? _i14.CacheInt.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i15.CacheString?>()) {
      return (data != null ? _i15.CacheString.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i16.Channel?>()) {
      return (data != null ? _i16.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i17.ChannelMember?>()) {
      return (data != null ? _i17.ChannelMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i18.ChannelMemberStatus?>()) {
      return (data != null ? _i18.ChannelMemberStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i19.ChannelSubscription?>()) {
      return (data != null ? _i19.ChannelSubscription.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i20.ChannelType?>()) {
      return (data != null ? _i20.ChannelType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i21.DailyReward?>()) {
      return (data != null ? _i21.DailyReward.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i22.DeviceToken?>()) {
      return (data != null ? _i22.DeviceToken.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i23.DiscoveryFeed?>()) {
      return (data != null ? _i23.DiscoveryFeed.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i24.GamificationStatus?>()) {
      return (data != null ? _i24.GamificationStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i25.Greeting?>()) {
      return (data != null ? _i25.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i26.Lounge?>()) {
      return (data != null ? _i26.Lounge.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i27.LoungeMemberWithProfile?>()) {
      return (data != null ? _i27.LoungeMemberWithProfile.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i28.LoungeWithMembership?>()) {
      return (data != null ? _i28.LoungeWithMembership.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i29.Message?>()) {
      return (data != null ? _i29.Message.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i30.Moment?>()) {
      return (data != null ? _i30.Moment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i31.MomentComment?>()) {
      return (data != null ? _i31.MomentComment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i32.MomentLike?>()) {
      return (data != null ? _i32.MomentLike.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i33.PrivateChat?>()) {
      return (data != null ? _i33.PrivateChat.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i34.PrivateChatWithProfile?>()) {
      return (data != null ? _i34.PrivateChatWithProfile.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i35.ReadReceiptEvent?>()) {
      return (data != null ? _i35.ReadReceiptEvent.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i36.Report?>()) {
      return (data != null ? _i36.Report.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i37.ReportStatus?>()) {
      return (data != null ? _i37.ReportStatus.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i38.Resident?>()) {
      return (data != null ? _i38.Resident.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i39.ResidentRole?>()) {
      return (data != null ? _i39.ResidentRole.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i40.SearchAllResults?>()) {
      return (data != null ? _i40.SearchAllResults.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i41.TalktiveException?>()) {
      return (data != null ? _i41.TalktiveException.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i42.TypingIndicator?>()) {
      return (data != null ? _i42.TypingIndicator.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i43.UserAchievement?>()) {
      return (data != null ? _i43.UserAchievement.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i44.UserAchievementView?>()) {
      return (data != null ? _i44.UserAchievementView.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i45.UserLike?>()) {
      return (data != null ? _i45.UserLike.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i46.UserNotification?>()) {
      return (data != null ? _i46.UserNotification.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i47.UserProfileView?>()) {
      return (data != null ? _i47.UserProfileView.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i48.UserSummary?>()) {
      return (data != null ? _i48.UserSummary.fromJson(data) : null) as T;
    }
    if (t == List<_i29.Message>) {
      return (data as List).map((e) => deserialize<_i29.Message>(e)).toList()
          as T;
    }
    if (t == List<_i30.Moment>) {
      return (data as List).map((e) => deserialize<_i30.Moment>(e)).toList()
          as T;
    }
    if (t == List<_i36.Report>) {
      return (data as List).map((e) => deserialize<_i36.Report>(e)).toList()
          as T;
    }
    if (t == List<_i48.UserSummary>) {
      return (data as List)
              .map((e) => deserialize<_i48.UserSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i26.Lounge>) {
      return (data as List).map((e) => deserialize<_i26.Lounge>(e)).toList()
          as T;
    }
    if (t == _i1.getType<List<_i26.Lounge>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<_i26.Lounge>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i44.UserAchievementView>) {
      return (data as List)
              .map((e) => deserialize<_i44.UserAchievementView>(e))
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
    if (t == _i1.getType<List<_i30.Moment>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<_i30.Moment>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_i49.AdminReportSummary>) {
      return (data as List)
              .map((e) => deserialize<_i49.AdminReportSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i50.AdminUserSummary>) {
      return (data as List)
              .map((e) => deserialize<_i50.AdminUserSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_i51.UserAchievementView>) {
      return (data as List)
              .map((e) => deserialize<_i51.UserAchievementView>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i52.DailyReward>) {
      return (data as List)
              .map((e) => deserialize<_i52.DailyReward>(e))
              .toList()
          as T;
    }
    if (t == Map<String, dynamic>) {
      return (data as Map).map(
            (k, v) => MapEntry(deserialize<String>(k), deserialize<dynamic>(v)),
          )
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
    if (t == List<_i53.LoungeWithMembership>) {
      return (data as List)
              .map((e) => deserialize<_i53.LoungeWithMembership>(e))
              .toList()
          as T;
    }
    if (t == List<_i54.Lounge>) {
      return (data as List).map((e) => deserialize<_i54.Lounge>(e)).toList()
          as T;
    }
    if (t == List<_i55.LoungeMemberWithProfile>) {
      return (data as List)
              .map((e) => deserialize<_i55.LoungeMemberWithProfile>(e))
              .toList()
          as T;
    }
    if (t == List<_i56.Message>) {
      return (data as List).map((e) => deserialize<_i56.Message>(e)).toList()
          as T;
    }
    if (t == List<_i57.Moment>) {
      return (data as List).map((e) => deserialize<_i57.Moment>(e)).toList()
          as T;
    }
    if (t == List<_i58.MomentLike>) {
      return (data as List).map((e) => deserialize<_i58.MomentLike>(e)).toList()
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
    if (t == List<_i59.MomentComment>) {
      return (data as List)
              .map((e) => deserialize<_i59.MomentComment>(e))
              .toList()
          as T;
    }
    if (t == List<_i60.UserNotification>) {
      return (data as List)
              .map((e) => deserialize<_i60.UserNotification>(e))
              .toList()
          as T;
    }
    if (t == List<_i61.PrivateChatWithProfile>) {
      return (data as List)
              .map((e) => deserialize<_i61.PrivateChatWithProfile>(e))
              .toList()
          as T;
    }
    if (t == List<_i62.UserSummary>) {
      return (data as List)
              .map((e) => deserialize<_i62.UserSummary>(e))
              .toList()
          as T;
    }
    try {
      return _i3.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i4.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i5.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i2.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i6.Achievement => 'Achievement',
      _i7.AdminActivity => 'AdminActivity',
      _i8.AdminReportSummary => 'AdminReportSummary',
      _i9.AdminStatistics => 'AdminStatistics',
      _i10.AdminTotals => 'AdminTotals',
      _i11.AdminUserDetails => 'AdminUserDetails',
      _i12.AdminUserSummary => 'AdminUserSummary',
      _i13.Block => 'Block',
      _i14.CacheInt => 'CacheInt',
      _i15.CacheString => 'CacheString',
      _i16.Channel => 'Channel',
      _i17.ChannelMember => 'ChannelMember',
      _i18.ChannelMemberStatus => 'ChannelMemberStatus',
      _i19.ChannelSubscription => 'ChannelSubscription',
      _i20.ChannelType => 'ChannelType',
      _i21.DailyReward => 'DailyReward',
      _i22.DeviceToken => 'DeviceToken',
      _i23.DiscoveryFeed => 'DiscoveryFeed',
      _i24.GamificationStatus => 'GamificationStatus',
      _i25.Greeting => 'Greeting',
      _i26.Lounge => 'Lounge',
      _i27.LoungeMemberWithProfile => 'LoungeMemberWithProfile',
      _i28.LoungeWithMembership => 'LoungeWithMembership',
      _i29.Message => 'Message',
      _i30.Moment => 'Moment',
      _i31.MomentComment => 'MomentComment',
      _i32.MomentLike => 'MomentLike',
      _i33.PrivateChat => 'PrivateChat',
      _i34.PrivateChatWithProfile => 'PrivateChatWithProfile',
      _i35.ReadReceiptEvent => 'ReadReceiptEvent',
      _i36.Report => 'Report',
      _i37.ReportStatus => 'ReportStatus',
      _i38.Resident => 'Resident',
      _i39.ResidentRole => 'ResidentRole',
      _i40.SearchAllResults => 'SearchAllResults',
      _i41.TalktiveException => 'TalktiveException',
      _i42.TypingIndicator => 'TypingIndicator',
      _i43.UserAchievement => 'UserAchievement',
      _i44.UserAchievementView => 'UserAchievementView',
      _i45.UserLike => 'UserLike',
      _i46.UserNotification => 'UserNotification',
      _i47.UserProfileView => 'UserProfileView',
      _i48.UserSummary => 'UserSummary',
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
      case _i6.Achievement():
        return 'Achievement';
      case _i7.AdminActivity():
        return 'AdminActivity';
      case _i8.AdminReportSummary():
        return 'AdminReportSummary';
      case _i9.AdminStatistics():
        return 'AdminStatistics';
      case _i10.AdminTotals():
        return 'AdminTotals';
      case _i11.AdminUserDetails():
        return 'AdminUserDetails';
      case _i12.AdminUserSummary():
        return 'AdminUserSummary';
      case _i13.Block():
        return 'Block';
      case _i14.CacheInt():
        return 'CacheInt';
      case _i15.CacheString():
        return 'CacheString';
      case _i16.Channel():
        return 'Channel';
      case _i17.ChannelMember():
        return 'ChannelMember';
      case _i18.ChannelMemberStatus():
        return 'ChannelMemberStatus';
      case _i19.ChannelSubscription():
        return 'ChannelSubscription';
      case _i20.ChannelType():
        return 'ChannelType';
      case _i21.DailyReward():
        return 'DailyReward';
      case _i22.DeviceToken():
        return 'DeviceToken';
      case _i23.DiscoveryFeed():
        return 'DiscoveryFeed';
      case _i24.GamificationStatus():
        return 'GamificationStatus';
      case _i25.Greeting():
        return 'Greeting';
      case _i26.Lounge():
        return 'Lounge';
      case _i27.LoungeMemberWithProfile():
        return 'LoungeMemberWithProfile';
      case _i28.LoungeWithMembership():
        return 'LoungeWithMembership';
      case _i29.Message():
        return 'Message';
      case _i30.Moment():
        return 'Moment';
      case _i31.MomentComment():
        return 'MomentComment';
      case _i32.MomentLike():
        return 'MomentLike';
      case _i33.PrivateChat():
        return 'PrivateChat';
      case _i34.PrivateChatWithProfile():
        return 'PrivateChatWithProfile';
      case _i35.ReadReceiptEvent():
        return 'ReadReceiptEvent';
      case _i36.Report():
        return 'Report';
      case _i37.ReportStatus():
        return 'ReportStatus';
      case _i38.Resident():
        return 'Resident';
      case _i39.ResidentRole():
        return 'ResidentRole';
      case _i40.SearchAllResults():
        return 'SearchAllResults';
      case _i41.TalktiveException():
        return 'TalktiveException';
      case _i42.TypingIndicator():
        return 'TypingIndicator';
      case _i43.UserAchievement():
        return 'UserAchievement';
      case _i44.UserAchievementView():
        return 'UserAchievementView';
      case _i45.UserLike():
        return 'UserLike';
      case _i46.UserNotification():
        return 'UserNotification';
      case _i47.UserProfileView():
        return 'UserProfileView';
      case _i48.UserSummary():
        return 'UserSummary';
    }
    className = _i2.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod.$className';
    }
    className = _i3.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i4.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_core.$className';
    }
    className = _i5.Protocol().getClassNameForObject(data);
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
      return deserialize<_i6.Achievement>(data['data']);
    }
    if (dataClassName == 'AdminActivity') {
      return deserialize<_i7.AdminActivity>(data['data']);
    }
    if (dataClassName == 'AdminReportSummary') {
      return deserialize<_i8.AdminReportSummary>(data['data']);
    }
    if (dataClassName == 'AdminStatistics') {
      return deserialize<_i9.AdminStatistics>(data['data']);
    }
    if (dataClassName == 'AdminTotals') {
      return deserialize<_i10.AdminTotals>(data['data']);
    }
    if (dataClassName == 'AdminUserDetails') {
      return deserialize<_i11.AdminUserDetails>(data['data']);
    }
    if (dataClassName == 'AdminUserSummary') {
      return deserialize<_i12.AdminUserSummary>(data['data']);
    }
    if (dataClassName == 'Block') {
      return deserialize<_i13.Block>(data['data']);
    }
    if (dataClassName == 'CacheInt') {
      return deserialize<_i14.CacheInt>(data['data']);
    }
    if (dataClassName == 'CacheString') {
      return deserialize<_i15.CacheString>(data['data']);
    }
    if (dataClassName == 'Channel') {
      return deserialize<_i16.Channel>(data['data']);
    }
    if (dataClassName == 'ChannelMember') {
      return deserialize<_i17.ChannelMember>(data['data']);
    }
    if (dataClassName == 'ChannelMemberStatus') {
      return deserialize<_i18.ChannelMemberStatus>(data['data']);
    }
    if (dataClassName == 'ChannelSubscription') {
      return deserialize<_i19.ChannelSubscription>(data['data']);
    }
    if (dataClassName == 'ChannelType') {
      return deserialize<_i20.ChannelType>(data['data']);
    }
    if (dataClassName == 'DailyReward') {
      return deserialize<_i21.DailyReward>(data['data']);
    }
    if (dataClassName == 'DeviceToken') {
      return deserialize<_i22.DeviceToken>(data['data']);
    }
    if (dataClassName == 'DiscoveryFeed') {
      return deserialize<_i23.DiscoveryFeed>(data['data']);
    }
    if (dataClassName == 'GamificationStatus') {
      return deserialize<_i24.GamificationStatus>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i25.Greeting>(data['data']);
    }
    if (dataClassName == 'Lounge') {
      return deserialize<_i26.Lounge>(data['data']);
    }
    if (dataClassName == 'LoungeMemberWithProfile') {
      return deserialize<_i27.LoungeMemberWithProfile>(data['data']);
    }
    if (dataClassName == 'LoungeWithMembership') {
      return deserialize<_i28.LoungeWithMembership>(data['data']);
    }
    if (dataClassName == 'Message') {
      return deserialize<_i29.Message>(data['data']);
    }
    if (dataClassName == 'Moment') {
      return deserialize<_i30.Moment>(data['data']);
    }
    if (dataClassName == 'MomentComment') {
      return deserialize<_i31.MomentComment>(data['data']);
    }
    if (dataClassName == 'MomentLike') {
      return deserialize<_i32.MomentLike>(data['data']);
    }
    if (dataClassName == 'PrivateChat') {
      return deserialize<_i33.PrivateChat>(data['data']);
    }
    if (dataClassName == 'PrivateChatWithProfile') {
      return deserialize<_i34.PrivateChatWithProfile>(data['data']);
    }
    if (dataClassName == 'ReadReceiptEvent') {
      return deserialize<_i35.ReadReceiptEvent>(data['data']);
    }
    if (dataClassName == 'Report') {
      return deserialize<_i36.Report>(data['data']);
    }
    if (dataClassName == 'ReportStatus') {
      return deserialize<_i37.ReportStatus>(data['data']);
    }
    if (dataClassName == 'Resident') {
      return deserialize<_i38.Resident>(data['data']);
    }
    if (dataClassName == 'ResidentRole') {
      return deserialize<_i39.ResidentRole>(data['data']);
    }
    if (dataClassName == 'SearchAllResults') {
      return deserialize<_i40.SearchAllResults>(data['data']);
    }
    if (dataClassName == 'TalktiveException') {
      return deserialize<_i41.TalktiveException>(data['data']);
    }
    if (dataClassName == 'TypingIndicator') {
      return deserialize<_i42.TypingIndicator>(data['data']);
    }
    if (dataClassName == 'UserAchievement') {
      return deserialize<_i43.UserAchievement>(data['data']);
    }
    if (dataClassName == 'UserAchievementView') {
      return deserialize<_i44.UserAchievementView>(data['data']);
    }
    if (dataClassName == 'UserLike') {
      return deserialize<_i45.UserLike>(data['data']);
    }
    if (dataClassName == 'UserNotification') {
      return deserialize<_i46.UserNotification>(data['data']);
    }
    if (dataClassName == 'UserProfileView') {
      return deserialize<_i47.UserProfileView>(data['data']);
    }
    if (dataClassName == 'UserSummary') {
      return deserialize<_i48.UserSummary>(data['data']);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _i2.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i3.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i4.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth.')) {
      data['className'] = dataClassName.substring(15);
      return _i5.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  @override
  _i1.Table? getTableForType(Type t) {
    {
      var table = _i3.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i4.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i5.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _i2.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i6.Achievement:
        return _i6.Achievement.t;
      case _i13.Block:
        return _i13.Block.t;
      case _i16.Channel:
        return _i16.Channel.t;
      case _i17.ChannelMember:
        return _i17.ChannelMember.t;
      case _i21.DailyReward:
        return _i21.DailyReward.t;
      case _i22.DeviceToken:
        return _i22.DeviceToken.t;
      case _i26.Lounge:
        return _i26.Lounge.t;
      case _i29.Message:
        return _i29.Message.t;
      case _i30.Moment:
        return _i30.Moment.t;
      case _i31.MomentComment:
        return _i31.MomentComment.t;
      case _i32.MomentLike:
        return _i32.MomentLike.t;
      case _i33.PrivateChat:
        return _i33.PrivateChat.t;
      case _i36.Report:
        return _i36.Report.t;
      case _i38.Resident:
        return _i38.Resident.t;
      case _i43.UserAchievement:
        return _i43.UserAchievement.t;
      case _i45.UserLike:
        return _i45.UserLike.t;
      case _i46.UserNotification:
        return _i46.UserNotification.t;
    }
    return null;
  }

  @override
  List<_i2.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

  @override
  String getModuleName() => 'talktive';

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
      return _i3.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i4.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i5.Protocol().mapRecordToJson(record);
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
