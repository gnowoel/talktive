import 'package:flutter/material.dart';

import 'heart.dart';

class HeartList extends StatelessWidget {
  final Duration elapsed;

  const HeartList({
    super.key,
    required this.elapsed,
  });

  final _full = const Heart();
  final _half = const Heart(icon: Icons.heart_broken);
  final _empty = const Heart(icon: Icons.favorite_outline);
  final _grey = const Heart(icon: Icons.favorite_outline, color: Colors.grey);

  @override
  Widget build(BuildContext context) {
    List<Widget> children;

    switch (elapsed.inMinutes) {
      case < 10:
        children = [_full, _full, _full];
      case < 20:
        children = [_half, _full, _full];
      case < 30:
        children = [_empty, _full, _full];
      case < 40:
        children = [_empty, _half, _full];
      case < 50:
        children = [_empty, _empty, _full];
      case < 60:
        children = [_empty, _empty, _half];
      default:
        children = [_grey, _grey, _grey];
    }

    return Row(children: children);
  }
}
