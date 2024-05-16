import 'package:flutter/material.dart';

import 'heart.dart';

class Hearts extends StatelessWidget {
  const Hearts({super.key});

  final _full = const Heart();

  @override
  Widget build(BuildContext context) {
    List<Widget> children;

    children = [_full, _full, _full];

    return Row(children: children);
  }
}
