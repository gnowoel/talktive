import '../models/user.dart';

String getUserStatus(User user) {
  if (user.withWarning) return 'warning'; // 'Restricted'
  if (user.withAlert) return 'alert'; // 'Warning'
  if (user.isNewcomer) return 'newcomer'; // 'Newcomer'
  return 'normal'; // 'Regular'
}
