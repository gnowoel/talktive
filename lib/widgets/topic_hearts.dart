import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/time.dart';
import '../models/public_topic.dart';
import '../services/server_clock.dart';
import 'heart_list.dart';

class TopicHearts extends StatefulWidget {
  final PublicTopic? topic;

  const TopicHearts({super.key, required this.topic});

  @override
  State<TopicHearts> createState() => _TopicHeartsState();
}

class _TopicHeartsState extends State<TopicHearts> {
  late ServerClock serverClock;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    serverClock = context.read<ServerClock>();
    _refreshAgain();
  }

  @override
  void didUpdateWidget(TopicHearts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.topic?.updatedAt != oldWidget.topic?.updatedAt) {
      _refreshAgain();
    }
  }

  void _refreshAgain() {
    if (widget.topic == null) return;

    _refreshTimer?.cancel();

    final timeLeft = _getTimeLeft();
    if (timeLeft == 0) return;

    final delay = timeLeft % refreshThreshold;
    final duration = Duration(milliseconds: delay);

    _refreshTimer = Timer(duration, () {
      setState(() => _refreshAgain());
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  int _getElapsed() {
    return widget.topic?.getTimeElapsed() ?? activePeriod;
  }

  int _getTimeLeft() {
    return widget.topic?.getTimeLeft() ?? 0;
  }

  String _getInfoText(PublicTopic? topic) {
    if (topic == null) return 'New Topic';

    final now = serverClock.now;
    final timeLeft = topic.getTimeLeft(now: now);

    if (timeLeft == 0) return 'Topic closed';

    var text = timeago.format(
      DateTime.fromMillisecondsSinceEpoch(now - timeLeft),
      locale: 'en_short',
      clock: DateTime.fromMillisecondsSinceEpoch(now),
    );

    if (text == 'now') {
      return 'Closing soon';
    }

    return 'Closing in $text';
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _getInfoText(widget.topic),
      child: HeartList(elapsed: Duration(milliseconds: _getElapsed())),
    );
  }
}
