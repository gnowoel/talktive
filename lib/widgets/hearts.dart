import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

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
    if (widget.chat.isNew || widget.chat.isClosed || widget.chat.isDummy) {
      return const Duration(hours: 72);
    }

    final now = Cache().now;
    final then = widget.chat.updatedAt;

    return Duration(milliseconds: now - then);
  }

  String _getRemains(Chat chat) {
    final now = Cache().now;
    final then = chat.updatedAt;
    final elapsed = now - then;
    final delay = kDebugMode
        ? 1000 * 60 * 6 // 6 minutes
        : 1000 * 60 * 60 * 72; // 3 days
    final diff = delay - elapsed;

    if (chat.isNew) return 'New chat';

    if (diff <= 0) return 'Chat closed';

    var remains = timeago.format(
      DateTime.fromMillisecondsSinceEpoch(now - diff),
      locale: 'en_short',
    );

    if (remains == 'now') {
      return 'Closing soon';
    }

    return 'Closing in $remains';
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _getRemains(widget.chat),
      child: HeartList(elapsed: elapsed),
    );
  }
}
