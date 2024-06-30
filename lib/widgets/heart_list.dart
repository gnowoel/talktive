import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'heart_item.dart';

class HeartList extends StatelessWidget {
  final Duration elapsed;

  const HeartList({
    super.key,
    required this.elapsed,
  });

  final _full = const HeartItem();
  final _half = const HeartItem(icon: Icons.heart_broken);
  final _empty = const HeartItem(icon: Icons.favorite_outline);
  final _grey =
      const HeartItem(icon: Icons.favorite_outline, color: Colors.grey);

  @override
  Widget build(BuildContext context) {
    List<Widget> children;

    switch (elapsed.inMinutes) {
      case < (kDebugMode ? 1 : 10):
        children = [_full, _full, _full];
      case < (kDebugMode ? 2 : 20):
        children = [_half, _full, _full];
      case < (kDebugMode ? 3 : 30):
        children = [_empty, _full, _full];
      case < (kDebugMode ? 4 : 40):
        children = [_empty, _half, _full];
      case < (kDebugMode ? 5 : 50):
        children = [_empty, _empty, _full];
      case < (kDebugMode ? 6 : 60):
        children = [_empty, _empty, _half];
      default:
        children = [_grey, _grey, _grey];
    }

    return Row(children: children);
  }
}
