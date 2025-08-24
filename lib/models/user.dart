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
  final int? followeeCount;
  final int? followerCount;

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
    this.followeeCount,
    this.followerCount,
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
      'followeeCount': followeeCount,
      'followerCount': followerCount,
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
      followeeCount: value.followeeCount,
      followerCount: value.followerCount,
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
    final oneDay = 24 * 60 * 60 * 1000;
    return serverNow - createdAt < oneDay;
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

  /// Calculate reputation score based on follower-to-total-connections ratio.
  /// Uses the formula: followerCount / (followerCount + followeeCount)
  ///
  /// The theory is that trustworthy users tend to have more followers relative
  /// to the number of people they follow, while less trustworthy users tend to
  /// follow more people than follow them back.
  ///
  /// Returns a value between 0.0 and 1.0, where 1.0 is perfect reputation.
  /// Returns 0.5 (neutral) if both followerCount and followeeCount are 0 or null.
  double get reputationScore {
    final followers = followerCount ?? 0;
    final followees = followeeCount ?? 0;
    final totalConnections = followers + followees;

    // Return neutral score if user has no connections
    if (totalConnections == 0) return 0.5;

    // Calculate follower-to-total-connections ratio
    final score = followers / totalConnections;

    // Ensure score is between 0.0 and 1.0
    return score.clamp(0.0, 1.0);
  }

  /// Check if user has good reputation (score >= 0.60)
  bool get hasGoodReputation => reputationScore >= 0.60;

  /// Check if user has decent reputation (score >= 0.40)
  bool get hasDecentReputation => reputationScore >= 0.40;

  /// Check if user has poor reputation (score < 0.40)
  bool get hasPoorReputation => reputationScore < 0.40;

  /// Get reputation level as a string for display purposes
  String get reputationLevel {
    final score = reputationScore;
    if (score >= 0.80) return level >= 6 ? 'excellent' : 'fair';
    if (score >= 0.60) return level >= 6 ? 'good' : 'fair';
    if (score >= 0.40) return 'fair';
    if (score >= 0.20) return 'poor';
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
  final int? followeeCount;
  final int? followerCount;

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
    this.followeeCount,
    this.followerCount,
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
      'followeeCount': followeeCount,
      'followerCount': followerCount,
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
      followeeCount: json['followeeCount'] as int?,
      followerCount: json['followerCount'] as int?,
    );
  }
}
