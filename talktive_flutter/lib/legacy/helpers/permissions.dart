import '../models/user.dart';

// Abilities

bool canSendMessage(User? user) {
  if (user == null) return false;
  return _isBeginner(user);
}

bool canReportOthers(User? user) {
  if (user == null) return false;
  return _isIntermediate(user);
}

bool canGreetFemaleNewcomer(User? user) {
  if (user == null) return false;
  return _isIntermediate(user);
}

bool canJoinTopic(User? user) {
  if (user == null) return false;
  return _isBeginner(user);
}

bool canCreateTopic(User? user) {
  if (user == null) return false;
  return _isIntermediate(user);
}

bool canSendPrivatePicture(User? user) {
  if (user == null) return false;
  return _isIntermediate(user);
}

bool canSendPublicPicture(User? user) {
  if (user == null) return false;
  return _isAdvanced(user);
}

// Floors

bool _isBeginner(User? user) {
  if (user == null) return false;
  return _withoutWarning(user);
}

bool _isIntermediate(User? user) {
  if (user == null) return false;

  return _withoutWarning(user) &&
      _hasDecentReputation(user) &&
      _hasIntermediateFloorExperience(user);
}

bool _isAdvanced(User? user) {
  if (user == null) return false;

  return _withoutWarning(user) &&
      _hasGoodReputation(user) &&
      _hasHighFloorExperience(user);
}

// Utilities

bool _hasDecentReputation(User? user) {
  if (user == null) return false;
  return user.hasDecentReputation;
}

bool _hasGoodReputation(User? user) {
  if (user == null) return false;
  return user.hasGoodReputation;
}

bool _hasIntermediateFloorExperience(User? user) {
  if (user == null) return false;
  return user.level >= 4; // 27 messages
}

bool _hasHighFloorExperience(User? user) {
  if (user == null) return false;
  return user.level >= 6; // 244 messages
}

// bool _hasFollowers(FollowCache? followCache) {
//   if (followCache == null) return false;
//   return followCache.followers.isNotEmpty;
// }

bool _withoutWarning(User? user) {
  if (user == null) return false;
  return !user.withWarning;
}
