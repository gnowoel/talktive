import 'package:flutter/material.dart';

import 'pages/home.dart';
import 'services/messaging.dart';

class Notifier extends StatefulWidget {
  const Notifier({super.key});

  @override
  State<Notifier> createState() => _NotifierState();
}

class _NotifierState extends State<Notifier> {
  @override
  void initState() {
    super.initState();
    Messaging().init();
  }

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}
