import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'heart_list.dart';

class Health extends StatefulWidget {
  final int roomUpdatedAt;

  const Health({
    super.key,
    required this.roomUpdatedAt,
  });

  @override
  State<Health> createState() => _HealthState();
}

class _HealthState extends State<Health> with SingleTickerProviderStateMixin {
  late Ticker ticker;
  late Duration elapsed;

  @override
  void initState() {
    super.initState();
    elapsed = _getElapsed();
    ticker = createTicker((_) {
      final newElapsed = _getElapsed();
      if (newElapsed.inMinutes % 10 == 0) {
        setState(() => elapsed = newElapsed);
      }
    });
    ticker.start();
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  Duration _getElapsed() {
    final now = DateTime.now();
    final then = DateTime.fromMillisecondsSinceEpoch(widget.roomUpdatedAt);
    return now.difference(then);
  }

  @override
  Widget build(BuildContext context) {
    return HeartList(elapsed: elapsed);
  }
}
