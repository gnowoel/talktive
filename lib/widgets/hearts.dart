import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../helpers/helpers.dart';
import '../models/private_chat.dart';
import '../services/firedata.dart';
import '../services/server_clock.dart';
import 'heart_list.dart';

class Hearts extends StatefulWidget {
  final PrivateChat chat;

  const Hearts({super.key, required this.chat});

  @override
  State<Hearts> createState() => _HeartsState();
}

class _HeartsState extends State<Hearts> {
  late Firedata firedata;
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();

    firedata = Provider.of<Firedata>(context, listen: false);

    _elapsed = _getElapsed();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed = _getElapsed());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Duration _getElapsed() {
    if (widget.chat.isNew || widget.chat.isClosed || widget.chat.isDummy) {
      return const Duration(hours: 72);
    }

    final now = ServerClock().now;
    final then = widget.chat.updatedAt;

    return Duration(milliseconds: now - then);
  }

  String _getInfoText(PrivateChat chat) {
    final now = ServerClock().now;
    final diff = getTimeLeft(chat, now: now);

    if (chat.isNew) return 'New chat';

    if (diff == 0) return 'Chat closed';

    var text = timeago.format(
      DateTime.fromMillisecondsSinceEpoch(now - diff),
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
      child: HeartList(elapsed: _elapsed),
    );
  }
}
