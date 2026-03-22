import 'package:talktive_client/talktive_client.dart';

extension ResidentStaffExtension on Resident {
  bool get isAdmin => role == ResidentRole.admin;
  bool get isModerator => role == ResidentRole.moderator;
  bool get isStaff =>
      role == ResidentRole.admin || role == ResidentRole.moderator;
}

extension UserProfileViewStaffExtension on UserProfileView {
  bool get isAdmin => role == ResidentRole.admin;
  bool get isModerator => role == ResidentRole.moderator;
  bool get isStaff =>
      role == ResidentRole.admin || role == ResidentRole.moderator;
}

extension UserSummaryStaffExtension on UserSummary {
  bool get isAdmin => role == ResidentRole.admin;
  bool get isModerator => role == ResidentRole.moderator;
  bool get isStaff =>
      role == ResidentRole.admin || role == ResidentRole.moderator;
}
