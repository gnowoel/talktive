import 'dart:async';

import 'package:flutter/material.dart';
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

class _HealthState extends State<Health> {
  late Firedata firedata;
  late Timer timer;
  late Duration elapsed;

  @override
  void initState() {
    super.initState();

    firedata = Provider.of<Firedata>(context, listen: false);

    elapsed = _getElapsed();

    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newElapsed = _getElapsed();
      if (newElapsed.inMinutes != elapsed.inMinutes) {
        setState(() => elapsed = newElapsed);
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  Duration _getElapsed() {
    if (widget.chat.isNew || widget.chat.isClosed) {
      return const Duration(minutes: 60);
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
