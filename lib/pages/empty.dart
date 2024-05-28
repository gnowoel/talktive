import 'package:flutter/material.dart';

class EmptyPage extends StatelessWidget {
  final bool hasAppBar;
  final Widget? child;

  const EmptyPage({
    super.key,
    this.hasAppBar = true,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: hasAppBar ? AppBar(backgroundColor: Colors.white) : null,
      body: SafeArea(
        child: Center(
          child: child,
        ),
      ),
    );
  }
}
