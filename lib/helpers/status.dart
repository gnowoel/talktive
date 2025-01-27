import '../models/user.dart';

String getUserStatus(User user, DateTime now) {
  final revivedAt = DateTime.fromMillisecondsSinceEpoch(user.revivedAt ?? 0);
  final thirtyDays = const Duration(days: 30);

  if (now.isAfter(revivedAt)) {
    return 'normal';
  }

  if (now.add(thirtyDays).isAfter(revivedAt)) {
    return 'warning';
  }

  return 'alert';
}
