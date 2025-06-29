import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/time.dart';
import '../models/chat.dart';
import '../services/server_clock.dart';
import 'heart_list.dart';

class ChatHearts extends StatefulWidget {
  final Chat chat;

  const ChatHearts({super.key, required this.chat});

  @override
  State<ChatHearts> createState() => _ChatHeartsState();
}

class _ChatHeartsState extends State<ChatHearts> {
  late ServerClock serverClock;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    serverClock = context.read<ServerClock>();
    _refreshAgain();
  }

  @override
  void didUpdateWidget(ChatHearts oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.chat.updatedAt != oldWidget.chat.updatedAt) {
      _refreshAgain();
    }
  }

  void _refreshAgain() {
    if (!_isChatReady()) return;

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

  bool _isChatReady() {
    return widget.chat.isNotNew &&
        widget.chat.isNotClosed &&
        widget.chat.isNotDummy;
  }

  int _getElapsed() {
    return _isChatReady() ? widget.chat.getTimeElapsed() : activePeriod;
  }

  int _getTimeLeft() {
    return _isChatReady() ? widget.chat.getTimeLeft() : 0;
  }

  String _getInfoText(Chat chat) {
    if (chat.isNew) return 'New chat';

    final now = serverClock.now;
    final timeLeft = chat.getTimeLeft(now: now);

    if (timeLeft == 0) return 'Chat closed';

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
      message: _getInfoText(widget.chat),
      child: HeartList(elapsed: Duration(milliseconds: _getElapsed())),
    );
  }
}
