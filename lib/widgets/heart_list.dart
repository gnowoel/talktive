import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'heart_item.dart';

class HeartList extends StatelessWidget {
  final Duration elapsed;

  const HeartList({
    super.key,
    required this.elapsed,
  });

  final _full = const HeartItem(
    semanticLabel: 'Full heart',
  );
  final _half = const HeartItem(
    icon: Icons.heart_broken,
    semanticLabel: 'Half heart',
  );
  final _empty = const HeartItem(
    icon: Icons.favorite_outline,
    semanticLabel: 'Empty heart',
  );
  final _grey = const HeartItem(
    icon: Icons.favorite_outline,
    color: Colors.grey,
    semanticLabel: 'Empty heart',
  );

  @override
  Widget build(BuildContext context) {
    List<Widget> children;

    switch (elapsed.inMinutes) {
      case < (kDebugMode ? 1 : 60 * 12 * 1):
        children = [
          _full,
          _full,
          _full,
        ];
      case < (kDebugMode ? 2 : 60 * 12 * 2):
        children = [
          _half,
          _full,
          _full,
        ];
      case < (kDebugMode ? 3 : 60 * 12 * 3):
        children = [
          _empty,
          _full,
          _full,
        ];
      case < (kDebugMode ? 4 : 60 * 12 * 4):
        children = [
          _empty,
          _half,
          _full,
        ];
      case < (kDebugMode ? 5 : 60 * 12 * 5):
        children = [
          _empty,
          _empty,
          _full,
        ];
      case < (kDebugMode ? 6 : 60 * 12 * 6):
        children = [
          _empty,
          _empty,
          _half,
        ];
      default:
        children = [
          _grey,
          _grey,
          _grey,
        ];
    }

    return Row(children: children);
  }
}
