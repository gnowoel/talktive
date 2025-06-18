import '../models/user.dart';
import '../services/follow_cache.dart';

bool canGreetNewFemale(User? user, FollowCache? followCache) {
  return _canBeHost(user, followCache);
}

bool canCreateTopic(User? user, FollowCache? followCache) {
  return _canBeHost(user, followCache);
}

bool canJoinTopic(User? user) {
  if (user == null) return false;
  return _canBeGuest(user);
}

bool canSendMessage(User? user) {
  if (user == null) return false;
  return _canBeGuest(user);
}

bool canReportOthers(User? user) {
  if (user == null) return false;
  return _canBeGuest(user);
}

bool _canBeGuest(User? user) {
  if (user == null) return false;
  return _withoutWarning(user);
}

bool _canBeHost(User? user, FollowCache? followCache) {
  if (user == null) return false;
  if (followCache == null) return false;

  return _hasGoodReputation(user) &&
      _hasHighLevelExperience(user) &&
      _withoutRestrictions(user) &&
      _hasFollowers(followCache);
}

bool _hasGoodReputation(User? user) {
  if (user == null) return false;
  return user.hasGoodReputation;
}

bool _hasHighLevelExperience(User? user) {
  if (user == null) return false;
  return user.level >= 6; // 244 messages
}

bool _withoutRestrictions(User? user) {
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
