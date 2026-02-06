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
import 'block.dart' as _i2;
import 'channel.dart' as _i3;
import 'channel_member.dart' as _i4;
import 'channel_member_status.dart' as _i5;
import 'channel_type.dart' as _i6;
import 'greetings/greeting.dart' as _i7;
import 'message.dart' as _i8;
import 'moment.dart' as _i9;
import 'report.dart' as _i10;
import 'resident.dart' as _i11;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i12;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i13;
export 'block.dart';
export 'channel.dart';
export 'channel_member.dart';
export 'channel_member_status.dart';
export 'channel_type.dart';
export 'greetings/greeting.dart';
export 'message.dart';
export 'moment.dart';
export 'report.dart';
export 'resident.dart';
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

    if (t == _i2.Block) {
      return _i2.Block.fromJson(data) as T;
    }
    if (t == _i3.Channel) {
      return _i3.Channel.fromJson(data) as T;
    }
    if (t == _i4.ChannelMember) {
      return _i4.ChannelMember.fromJson(data) as T;
    }
    if (t == _i5.ChannelMemberStatus) {
      return _i5.ChannelMemberStatus.fromJson(data) as T;
    }
    if (t == _i6.ChannelType) {
      return _i6.ChannelType.fromJson(data) as T;
    }
    if (t == _i7.Greeting) {
      return _i7.Greeting.fromJson(data) as T;
    }
    if (t == _i8.Message) {
      return _i8.Message.fromJson(data) as T;
    }
    if (t == _i9.Moment) {
      return _i9.Moment.fromJson(data) as T;
    }
    if (t == _i10.Report) {
      return _i10.Report.fromJson(data) as T;
    }
    if (t == _i11.Resident) {
      return _i11.Resident.fromJson(data) as T;
    }
    if (t == _i1.getType<_i2.Block?>()) {
      return (data != null ? _i2.Block.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i3.Channel?>()) {
      return (data != null ? _i3.Channel.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i4.ChannelMember?>()) {
      return (data != null ? _i4.ChannelMember.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i5.ChannelMemberStatus?>()) {
      return (data != null ? _i5.ChannelMemberStatus.fromJson(data) : null)
          as T;
    }
    if (t == _i1.getType<_i6.ChannelType?>()) {
      return (data != null ? _i6.ChannelType.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i7.Greeting?>()) {
      return (data != null ? _i7.Greeting.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i8.Message?>()) {
      return (data != null ? _i8.Message.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i9.Moment?>()) {
      return (data != null ? _i9.Moment.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i10.Report?>()) {
      return (data != null ? _i10.Report.fromJson(data) : null) as T;
    }
    if (t == _i1.getType<_i11.Resident?>()) {
      return (data != null ? _i11.Resident.fromJson(data) : null) as T;
    }
    try {
      return _i12.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _i13.Protocol().deserialize<T>(data, t);
    } on _i1.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i2.Block => 'Block',
      _i3.Channel => 'Channel',
      _i4.ChannelMember => 'ChannelMember',
      _i5.ChannelMemberStatus => 'ChannelMemberStatus',
      _i6.ChannelType => 'ChannelType',
      _i7.Greeting => 'Greeting',
      _i8.Message => 'Message',
      _i9.Moment => 'Moment',
      _i10.Report => 'Report',
      _i11.Resident => 'Resident',
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
      case _i2.Block():
        return 'Block';
      case _i3.Channel():
        return 'Channel';
      case _i4.ChannelMember():
        return 'ChannelMember';
      case _i5.ChannelMemberStatus():
        return 'ChannelMemberStatus';
      case _i6.ChannelType():
        return 'ChannelType';
      case _i7.Greeting():
        return 'Greeting';
      case _i8.Message():
        return 'Message';
      case _i9.Moment():
        return 'Moment';
      case _i10.Report():
        return 'Report';
      case _i11.Resident():
        return 'Resident';
    }
    className = _i12.Protocol().getClassNameForObject(data);
    if (className != null) {
      return 'serverpod_auth_idp.$className';
    }
    className = _i13.Protocol().getClassNameForObject(data);
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
    if (dataClassName == 'Block') {
      return deserialize<_i2.Block>(data['data']);
    }
    if (dataClassName == 'Channel') {
      return deserialize<_i3.Channel>(data['data']);
    }
    if (dataClassName == 'ChannelMember') {
      return deserialize<_i4.ChannelMember>(data['data']);
    }
    if (dataClassName == 'ChannelMemberStatus') {
      return deserialize<_i5.ChannelMemberStatus>(data['data']);
    }
    if (dataClassName == 'ChannelType') {
      return deserialize<_i6.ChannelType>(data['data']);
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_i7.Greeting>(data['data']);
    }
    if (dataClassName == 'Message') {
      return deserialize<_i8.Message>(data['data']);
    }
    if (dataClassName == 'Moment') {
      return deserialize<_i9.Moment>(data['data']);
    }
    if (dataClassName == 'Report') {
      return deserialize<_i10.Report>(data['data']);
    }
    if (dataClassName == 'Resident') {
      return deserialize<_i11.Resident>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _i12.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _i13.Protocol().deserializeByClassName(data);
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
      return _i12.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _i13.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
