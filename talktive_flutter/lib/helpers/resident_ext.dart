import 'package:talktive_client/talktive_client.dart';

extension ResidentStaffExtension on Resident {
  bool get isAdmin => role == ResidentRole.admin;
  bool get isModerator => role == ResidentRole.moderator;
  bool get isStaff =>
      role == ResidentRole.admin || role == ResidentRole.moderator;

  /// Whether the resident has access to premium features (Paid or Trial).
  bool get isPlus =>
      isPremium ||
      (premiumTrialExpires != null &&
          premiumTrialExpires!.isAfter(DateTime.now()));

  /// Whether the resident is currently in an active trial period.
  bool get isTrialActive =>
      !isPremium &&
      premiumTrialExpires != null &&
      premiumTrialExpires!.isAfter(DateTime.now());
}

extension UserProfileViewStaffExtension on UserProfileView {
  bool get isAdmin => role == ResidentRole.admin;
  bool get isModerator => role == ResidentRole.moderator;
  bool get isStaff =>
      role == ResidentRole.admin || role == ResidentRole.moderator;

  /// Note: Profile view doesn't carry trial expiration by default currently
  /// but we can keep the getter for consistency if we update the protocol later.
  bool get isPlus => isPremium;
}

extension UserSummaryStaffExtension on UserSummary {
  bool get isAdmin => role == ResidentRole.admin;
  bool get isModerator => role == ResidentRole.moderator;
  bool get isStaff =>
      role == ResidentRole.admin || role == ResidentRole.moderator;
}
