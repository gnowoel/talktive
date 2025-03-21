import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../services/messaging.dart';
import '../theme.dart';

class LaunchPage extends StatefulWidget {
  final String chatId;
  final String chatCreatedAt;

  const LaunchPage({
    super.key,
    required this.chatId,
    required this.chatCreatedAt,
  });

  @override
  State<LaunchPage> createState() => _LaunchPageState();
}

class _LaunchPageState extends State<LaunchPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      final initialRoute = Messaging.encodeChatRoute(
        widget.chatId,
        widget.chatCreatedAt,
      );
      context.go('/chats');
      context.push(initialRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: getTheme(context),
      // TODO: Show circular progress indicator
      home: Scaffold(body: SizedBox()),
    );
  }
}
