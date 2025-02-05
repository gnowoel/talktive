import '../models/user.dart';

String getUserStatus(User user, DateTime now) {
  final revivedAt = DateTime.fromMillisecondsSinceEpoch(user.revivedAt ?? 0);
  final delay = const Duration(days: 14);

  if (now.isAfter(revivedAt)) {
    return 'normal';
  }

  if (now.add(delay).isAfter(revivedAt)) {
    return 'alert';
  }

  return 'warning';
}
