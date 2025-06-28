import 'dart:math';

import '../services/server_clock.dart';

class User {
  final String id;
  final int createdAt;
  final int updatedAt;
  final String? languageCode;
  final String? photoURL;
  final String? displayName;
  final String? description;
  final String? gender;
  final String? fcmToken;
  final int? revivedAt;
  final int? messageCount;
  final int? reportCount;
  final String? role;

  const User({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.languageCode,
    this.photoURL,
    this.displayName,
    this.description,
    this.gender,
    this.fcmToken,
    this.revivedAt,
    this.messageCount,
    this.reportCount,
    this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'languageCode': languageCode,
      'photoURL': photoURL,
      'displayName': displayName,
      'description': description,
      'gender': gender,
      'fcmToken': fcmToken,
      'revivedAt': revivedAt,
      'messageCount': messageCount,
      'reportCount': reportCount,
      'role': role,
    };
  }

  factory User.fromStub({required String key, required UserStub value}) {
    return User(
      id: key,
      createdAt: value.createdAt,
      updatedAt: value.updatedAt,
      languageCode: value.languageCode,
      photoURL: value.photoURL,
      displayName: value.displayName,
      description: value.description,
      gender: value.gender,
      fcmToken: value.fcmToken,
      revivedAt: value.revivedAt,
      messageCount: value.messageCount,
      reportCount: value.reportCount,
      role: value.role,
    );
  }

  bool get isNew {
    return languageCode == null ||
        photoURL == null ||
        displayName == null ||
        description == null ||
        gender == null;
  }

  bool get withAlert {
    if (revivedAt == null) return false;
    final serverNow = ServerClock().now;
    return revivedAt! >= serverNow;
  }

  bool get withWarning {
    if (revivedAt == null) return false;
    final serverNow = ServerClock().now;
    final twoWeeks = 14 * 24 * 60 * 60 * 1000;
    return revivedAt! >= serverNow + twoWeeks;
  }

  bool get _isNewcomer {
    final serverNow = ServerClock().now;
    final twoDays = 24 * 60 * 60 * 1000;
    return serverNow - createdAt < twoDays;
  }

  String get status {
    if (withWarning) return 'warning';
    if (withAlert) return 'alert';
    if (_isNewcomer) return 'newcomer';
    return 'regular';
  }

  bool get _isFemale => gender == 'F';

  bool get isFemaleNewcomer => _isFemale && _isNewcomer;

  int get level {
    if (messageCount == null) return 0;
    if (messageCount! < 1) return 0;
    return (log(messageCount!) / log(3)).ceil();
  }

  /// Calculate reputation score based on total reports vs total messages.
  /// Uses a dampened formula with sqrt(reportCount) to reduce the impact
  /// of multiple reports on a single message.
  /// Formula: 1.0 - (sqrt(totalReports) / (totalMessages + dampening))
  /// Where dampening = (totalMessages * 0.1).clamp(5.0, 50.0) to provide stability
  ///
  /// Returns a value between 0.0 and 1.0, where 1.0 is perfect reputation.
  /// Returns 1.0 if messageCount or reportCount is 0 or null.
  double get reputationScore {
    if (messageCount == null || messageCount! <= 0) return 1.0;
    if (reportCount == null || reportCount! <= 0) return 1.0;

    // Apply dampening to prevent extreme drops from limited data
    final dampening = (messageCount! * 0.1).clamp(5.0, 50.0);
    final adjustedTotal = messageCount! + dampening;
    // final ratio = sqrt(reportCount!) / adjustedTotal;
    final ratio = reportCount! / adjustedTotal;
    final score = 1.0 - ratio;

    // Ensure score is between 0.0 and 1.0
    return score.clamp(0.0, 1.0);
  }

  /// Check if user has good reputation (score >= 0.85)
  bool get hasGoodReputation => reputationScore >= 0.85;

  /// Check if user has poor reputation (score < 0.7)
  bool get hasPoorReputation => reputationScore < 0.7;

  /// Get reputation level as a string for display purposes
  String get reputationLevel {
    final score = reputationScore;
    if (score >= 0.92) return level >= 6 ? 'excellent' : 'fair';
    if (score >= 0.85) return level >= 6 ? 'good' : 'fair';
    if (score >= 0.7) return 'fair';
    if (score >= 0.5) return 'poor';
    return 'very_poor';
  }

  /// Check if user is an admin
  bool get isAdmin => role == 'admin';

  /// Check if user is a moderator
  bool get isModerator => role == 'moderator';

  /// Check if user is an admin or moderator
  bool get isAdminOrModerator => isAdmin || isModerator;
}

class UserStub {
  final int createdAt;
  final int updatedAt;
  final String? languageCode;
  final String? photoURL;
  final String? displayName;
  final String? description;
  final String? gender;
  final String? fcmToken;
  final int? revivedAt;
  final int? messageCount;
  final int? reportCount;
  final String? role;

  const UserStub({
    required this.createdAt,
    required this.updatedAt,
    this.languageCode,
    this.photoURL,
    this.displayName,
    this.description,
    this.gender,
    this.fcmToken,
    this.revivedAt,
    this.messageCount,
    this.reportCount,
    this.role,
  });

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'languageCode': languageCode,
      'photoURL': photoURL,
      'displayName': displayName,
      'description': description,
      'gender': gender,
      'fcmToken': fcmToken,
      'revivedAt': revivedAt,
      'messageCount': messageCount,
      'reportCount': reportCount,
      'role': role,
    };
  }

  factory UserStub.fromJson(Map<String, dynamic> json) {
    return UserStub(
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
      languageCode: json['languageCode'] as String?,
      photoURL: json['photoURL'] as String?,
      displayName: json['displayName'] as String?,
      description: json['description'] as String?,
      gender: json['gender'] as String?,
      fcmToken: json['fcmToken'] as String?,
      revivedAt: json['revivedAt'] as int?,
      messageCount: json['messageCount'] as int?,
      reportCount: json['reportCount'] as int?,
      role: json['role'] as String?,
    );
  }
}
