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
import 'resident.dart' as _i2;
import 'package:talktive_server/src/generated/protocol.dart' as _i3;

abstract class LegacyMigrationResult
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  LegacyMigrationResult._({
    required this.resident,
    required this.changedFields,
  });

  factory LegacyMigrationResult({
    required _i2.Resident resident,
    required List<String> changedFields,
  }) = _LegacyMigrationResultImpl;

  factory LegacyMigrationResult.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return LegacyMigrationResult(
      resident: _i3.Protocol().deserialize<_i2.Resident>(
        jsonSerialization['resident'],
      ),
      changedFields: _i3.Protocol().deserialize<List<String>>(
        jsonSerialization['changedFields'],
      ),
    );
  }

  _i2.Resident resident;

  List<String> changedFields;

  /// Returns a shallow copy of this [LegacyMigrationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  LegacyMigrationResult copyWith({
    _i2.Resident? resident,
    List<String>? changedFields,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'LegacyMigrationResult',
      'resident': resident.toJson(),
      'changedFields': changedFields.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'LegacyMigrationResult',
      'resident': resident.toJsonForProtocol(),
      'changedFields': changedFields.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _LegacyMigrationResultImpl extends LegacyMigrationResult {
  _LegacyMigrationResultImpl({
    required _i2.Resident resident,
    required List<String> changedFields,
  }) : super._(
         resident: resident,
         changedFields: changedFields,
       );

  /// Returns a shallow copy of this [LegacyMigrationResult]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  LegacyMigrationResult copyWith({
    _i2.Resident? resident,
    List<String>? changedFields,
  }) {
    return LegacyMigrationResult(
      resident: resident ?? this.resident.copyWith(),
      changedFields:
          changedFields ?? this.changedFields.map((e0) => e0).toList(),
    );
  }
}
