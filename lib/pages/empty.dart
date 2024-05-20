import 'package:flutter/material.dart';

class EmptyPage extends StatelessWidget {
  final Widget child;

  const EmptyPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: child,
        ),
      ),
    );
  }
}
