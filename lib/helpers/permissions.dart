import '../models/user.dart';
import '../services/follow_cache.dart';

bool canGreetNewFemale(User? user, FollowCache? followCache) {
  return _isUserDecent(user, followCache);
}

bool canCreateTopic(User? user, FollowCache? followCache) {
  return _isUserDecent(user, followCache);
}

bool canJoinTopic(User? user) {
  if (user == null) return false;
  return _withoutWarning(user);
}

bool canSendMessage(User? user) {
  if (user == null) return false;
  return _withoutWarning(user);
}

bool canReportOthers(User? user) {
  if (user == null) return false;
  return _withoutWarning(user);
}

bool _isUserDecent(User? user, FollowCache? followCache) {
  if (user == null) return false;
  if (followCache == null) return false;

  return _hasFairReputation(user) &&
      _reachedLevelFour(user) &&
      _withoutAlert(user) &&
      _hasFollowers(followCache);
}

bool _hasFairReputation(User? user) {
  if (user == null) return false;
  return !user.hasPoorReputation;
}

bool _reachedLevelFour(User? user) {
  if (user == null) return false;
  return user.level >= 4;
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
