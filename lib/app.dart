import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home.dart';
import 'services/avatar.dart';
import 'services/fireauth.dart';
import 'services/firedata.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => Fireauth()),
        Provider(create: (context) => Firedata()),
        ChangeNotifierProvider(create: (context) => Avatar()),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Talktive',
        home: Home(),
      ),
    );
  }
}
