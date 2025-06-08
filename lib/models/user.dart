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
    final oneDay = 1 * 24 * 60 * 60 * 1000;
    return serverNow - createdAt < oneDay;
  }

  bool get _isNovice {
    return level <= 3; // messages <= 27
  }

  bool get isTrainee {
    return _isNewcomer || _isNovice;
  }

  bool get canReportOthers => !withWarning;

  String get status {
    if (withWarning) return 'warning';
    if (withAlert) return 'alert';
    if (_isNewcomer) return 'newcomer';
    return 'regular';
  }

  int get level {
    if (messageCount == null) return 0;
    if (messageCount! < 1) return 0;
    return (log(messageCount!) / log(3)).ceil();
  }
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
    );
  }
}
