import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../models/chat.dart';
import '../services/cache.dart';
import '../services/firedata.dart';
import 'heart_list.dart';

class Hearts extends StatefulWidget {
  final Chat chat;

  const Hearts({
    super.key,
    required this.chat,
  });

  @override
  State<Hearts> createState() => _HeartsState();
}

class _HeartsState extends State<Hearts> with SingleTickerProviderStateMixin {
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
      if (newElapsed.compareTo(elapsed) != 0) {
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
      return const Duration(hours: 72);
    }

    final now = Cache().now;
    final then = widget.chat.updatedAt;

    return Duration(milliseconds: now - then);
  }

  @override
  Widget build(BuildContext context) {
    return HeartList(elapsed: elapsed);
  }
}
