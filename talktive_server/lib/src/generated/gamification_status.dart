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
import 'user_achievement_view.dart' as _i3;
import 'package:talktive_server/src/generated/protocol.dart' as _i4;

abstract class GamificationStatus
    implements _i1.SerializableModel, _i1.ProtocolSerialization {
  GamificationStatus._({
    required this.resident,
    required this.canClaimReward,
    required this.achievements,
  });

  factory GamificationStatus({
    required _i2.Resident resident,
    required bool canClaimReward,
    required List<_i3.UserAchievementView> achievements,
  }) = _GamificationStatusImpl;

  factory GamificationStatus.fromJson(Map<String, dynamic> jsonSerialization) {
    return GamificationStatus(
      resident: _i4.Protocol().deserialize<_i2.Resident>(
        jsonSerialization['resident'],
      ),
      canClaimReward: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['canClaimReward'],
      ),
      achievements: _i4.Protocol().deserialize<List<_i3.UserAchievementView>>(
        jsonSerialization['achievements'],
      ),
    );
  }

  _i2.Resident resident;

  bool canClaimReward;

  List<_i3.UserAchievementView> achievements;

  /// Returns a shallow copy of this [GamificationStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GamificationStatus copyWith({
    _i2.Resident? resident,
    bool? canClaimReward,
    List<_i3.UserAchievementView>? achievements,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GamificationStatus',
      'resident': resident.toJson(),
      'canClaimReward': canClaimReward,
      'achievements': achievements.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GamificationStatus',
      'resident': resident.toJsonForProtocol(),
      'canClaimReward': canClaimReward,
      'achievements': achievements.toJson(
        valueToJson: (v) => v.toJsonForProtocol(),
      ),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _GamificationStatusImpl extends GamificationStatus {
  _GamificationStatusImpl({
    required _i2.Resident resident,
    required bool canClaimReward,
    required List<_i3.UserAchievementView> achievements,
  }) : super._(
         resident: resident,
         canClaimReward: canClaimReward,
         achievements: achievements,
       );

  /// Returns a shallow copy of this [GamificationStatus]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GamificationStatus copyWith({
    _i2.Resident? resident,
    bool? canClaimReward,
    List<_i3.UserAchievementView>? achievements,
  }) {
    return GamificationStatus(
      resident: resident ?? this.resident.copyWith(),
      canClaimReward: canClaimReward ?? this.canClaimReward,
      achievements:
          achievements ?? this.achievements.map((e0) => e0.copyWith()).toList(),
    );
  }
}
