import '../models/user.dart';

String getUserStatus(User user) {
  if (user.withWarning) return 'warning';
  if (user.withAlert) return 'alert';
  if (user.isNewcomer) return 'newcomer';
  return 'normal';
}
