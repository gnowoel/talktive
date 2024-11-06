import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'home.dart';
import 'services/avatar.dart';
import 'services/fireauth.dart';
import 'services/firedata.dart';
import 'services/history.dart';
import 'theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final database = FirebaseDatabase.instance;

    return MultiProvider(
      providers: [
        Provider(create: (context) => Fireauth(auth)),
        Provider(create: (context) => Firedata(database)..syncTime()),
        ChangeNotifierProvider(create: (context) => History()),
        ChangeNotifierProvider(create: (context) => Avatar()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Talktive',
        theme: getTheme(context),
        home: const Home(),
      ),
    );
  }
}
