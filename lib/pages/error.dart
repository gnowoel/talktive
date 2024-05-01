import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class ErrorPage extends StatefulWidget {
  const ErrorPage({super.key, required this.message});

  final String message;

  @override
  State<ErrorPage> createState() => _ErrorPageState();
}

class _ErrorPageState extends State<ErrorPage> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(widget.message),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            '\u{1f641}',
            style: TextStyle(fontSize: 64),
          ),
        ),
      ),
    );
  }
}
