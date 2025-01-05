import 'package:flutter/material.dart';

import 'auth.dart';
import 'notifier.dart';
import 'streams.dart';

class Initializers extends StatelessWidget {
  final Widget child;

  const Initializers({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Auth(
      child: Notifier(
        child: Streams(
          child: child,
        ),
      ),
    );
  }
}
