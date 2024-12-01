import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../services/cache.dart';
import '../services/firedata.dart';
import 'heart_list.dart';

class Health extends StatefulWidget {
  final Chat chat;

  const Health({
    super.key,
    required this.chat,
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
    if (widget.chat.isNew || widget.chat.isClosed) {
      return const Duration(minutes: 60);
    }

    final now = DateTime.fromMillisecondsSinceEpoch(Cache().now);
    final then = DateTime.fromMillisecondsSinceEpoch(widget.chat.updatedAt);

    return now.difference(then);
  }

  @override
  Widget build(BuildContext context) {
    return HeartList(elapsed: elapsed);
  }
}
