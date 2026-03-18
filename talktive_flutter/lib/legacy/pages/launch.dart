import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../helpers/routes.dart';
import '../services/ad_service/go_router_room_helper.dart';

import '../legacy/theme.dart';

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
      context.goWithoutAd(initialRoute);
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
