import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../services/firedata.dart';
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
  late Firedata firedata;
  late Ticker ticker;
  late Duration elapsed;

  @override
  void initState() {
    super.initState();
    firedata = Provider.of<Firedata>(context, listen: false);
    elapsed = _getElapsed();
    ticker = createTicker((_) {
      final newElapsed = _getElapsed();
      if (newElapsed.inSeconds != elapsed.inSeconds) {
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
    final now = DateTime.fromMillisecondsSinceEpoch(firedata.now());
    final then = DateTime.fromMillisecondsSinceEpoch(widget.roomUpdatedAt);
    return now.difference(then);
  }

  @override
  Widget build(BuildContext context) {
    return HeartList(elapsed: elapsed);
  }
}
