import 'package:flutter/material.dart';

import 'hearts.dart';

class Health extends StatelessWidget {
  final int roomUpdatedAt;

  const Health({
    super.key,
    required this.roomUpdatedAt,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final then = DateTime.fromMillisecondsSinceEpoch(roomUpdatedAt);
    final elapsed = now.difference(then);

    return Hearts(elapsed: elapsed);
  }
}
