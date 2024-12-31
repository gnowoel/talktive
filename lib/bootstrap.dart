import 'package:flutter/material.dart';

import 'auth.dart';
import 'notifier.dart';
import 'pages/home.dart';
import 'streams.dart';

class Bootstrap extends StatelessWidget {
  const Bootstrap({super.key});

  @override
  Widget build(BuildContext context) {
    return Auth(
      child: Notifier(
        child: Streams(
          child: HomePage(),
        ),
      ),
    );
  }
}
