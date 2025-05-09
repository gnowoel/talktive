import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';

import '../helpers/routes.dart';
import '../theme.dart';

class LaunchChatPage extends StatefulWidget {
  final String chatId;
  final String chatCreatedAt;

  const LaunchChatPage({
    super.key,
    required this.chatId,
    required this.chatCreatedAt,
  });

  @override
  State<LaunchChatPage> createState() => _LaunchChatPageState();
}

class _LaunchChatPageState extends State<LaunchChatPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      final initialRoute = encodeChatRoute(widget.chatId, widget.chatCreatedAt);
      context.go('/chats');
      context.push(initialRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: getTheme(context),
      // TODO: Show circular progress indicator
      home: const Scaffold(body: SizedBox.shrink()),
    );
  }
}

class LaunchTopicPage extends StatefulWidget {
  final String topicId;
  final String topicCreatorId;

  const LaunchTopicPage({
    super.key,
    required this.topicId,
    required this.topicCreatorId,
  });

  @override
  State<LaunchTopicPage> createState() => _LaunchTopicPageState();
}

class _LaunchTopicPageState extends State<LaunchTopicPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      final initialRoute = encodeTopicRoute(
        widget.topicId,
        widget.topicCreatorId,
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
      home: const Scaffold(body: SizedBox.shrink()),
    );
  }
}
