import 'package:flutter/material.dart';

import 'initializers/auth.dart';
import 'initializers/notifier.dart';
import 'initializers/streams.dart';
import 'pages/home.dart';

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
