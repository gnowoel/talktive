import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/empty.dart';
import 'pages/error.dart';
import 'pages/user.dart';
import 'services/avatar.dart';
import 'services/fireauth.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  Key futureBuilderKey = UniqueKey();

  void refresh() {
    setState(() {
      futureBuilderKey = UniqueKey();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fireauth = Provider.of<Fireauth>(context);

    try {
      return FutureBuilder(
        key: futureBuilderKey,
        future: fireauth.signInAnonymously(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorPage(
              message: '${snapshot.error}',
              refresh: refresh,
            );
          } else if (!snapshot.hasData) {
            return EmptyPage(
              hasAppBar: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Offstage(child: Text(Avatar().code)),
                  const CircularProgressIndicator(),
                  Offstage(child: Text(Avatar().code)),
                ],
              ),
            );
          } else {
            return const UserPage();
          }
        },
      );
    } catch (e) {
      return ErrorPage(
        message: '$e',
        refresh: refresh,
      );
    }
  }
}
