import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../helpers/exception.dart';

class ErrorPage extends StatefulWidget {
  const ErrorPage({
    super.key,
    required this.message,
    required this.refresh,
  });

  final String message;
  final VoidCallback refresh;

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    theme = Theme.of(context);

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      ErrorHandler.showSnackBarMessage(
        context,
        AppException(widget.message),
        severe: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '\u{1f641}',
                style: TextStyle(fontSize: 64),
              ),
              TextButton(
                onPressed: widget.refresh,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
