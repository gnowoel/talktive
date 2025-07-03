import '../models/user.dart';
import '../services/follow_cache.dart';

bool canSendMessage(User? user) {
  if (user == null) return false;
  return _isBasic(user);
}

bool canReportOthers(User? user) {
  if (user == null) return false;
  return _isBasic(user);
}

bool canGreetFemaleNewcomer(User? user) {
  if (user == null) return false;
  return _isIntermediate(user);
}

bool canJoinTopic(User? user) {
  if (user == null) return false;
  return _isIntermediate(user);
}

bool canCreateTopic(User? user, FollowCache? followCache) {
  if (user == null) return false;
  return _isAdvanced(user, followCache);
}

// Three levels

bool _isBasic(User? user) {
  if (user == null) return false;
  return _withoutWarning(user);
}

bool _isIntermediate(User? user) {
  if (user == null) return false;

  return _hasGoodReputation(user) &&
      _hasIntermediateLevelExperience(user) &&
      _withoutWarning(user);
}

bool _isAdvanced(User? user, FollowCache? followCache) {
  if (user == null) return false;
  if (followCache == null) return false;

  return _hasGoodReputation(user) &&
      _hasHighLevelExperience(user) &&
      _withoutWarning(user) &&
      _hasFollowers(followCache);
}

bool _hasGoodReputation(User? user) {
  if (user == null) return false;
  return user.hasGoodReputation;
}

bool _hasIntermediateLevelExperience(User? user) {
  if (user == null) return false;
  return user.level >= 5; // 81 messages
}

bool _hasHighLevelExperience(User? user) {
  if (user == null) return false;
  return user.level >= 6; // 244 messages
}

bool _withoutAlert(User? user) {
  if (user == null) return false;
  return !user.withAlert;
}

bool _withoutWarning(User? user) {
  if (user == null) return false;
  return !user.withWarning;
}

bool _hasFollowers(FollowCache? followCache) {
  if (followCache == null) return false;
  return followCache.followers.isNotEmpty;
}
