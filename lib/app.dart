import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home.dart';
import 'services/avatar.dart';
import 'services/fireauth.dart';
import 'services/firedata.dart';
import 'services/history.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (context) => Fireauth()),
        Provider(create: (context) => Firedata()),
        Provider(create: (context) => History()),
        ChangeNotifierProvider(create: (context) => Avatar()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Talktive',
        theme: ThemeData(scaffoldBackgroundColor: Colors.white),
        home: const Home(),
      ),
    );
  }
}
