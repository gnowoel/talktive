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

    // TODO: 10, 20, 30, 40, 50, 60
    switch (elapsed.inMinutes) {
      case < 1:
        children = [_full, _full, _full];
      case < 2:
        children = [_half, _full, _full];
      case < 3:
        children = [_empty, _full, _full];
      case < 4:
        children = [_empty, _half, _full];
      case < 5:
        children = [_empty, _empty, _full];
      case < 6:
        children = [_empty, _empty, _half];
      default:
        children = [_grey, _grey, _grey];
    }

    return Row(children: children);
  }
}
