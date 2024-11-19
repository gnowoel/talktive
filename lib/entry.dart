import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/empty.dart';
import 'pages/error.dart';
import 'pages/user.dart';
import 'services/fireauth.dart';

class Entry extends StatefulWidget {
  const Entry({super.key});

  @override
  State<Entry> createState() => _EntryState();
}

class _EntryState extends State<Entry> {
  void refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fireauth = Provider.of<Fireauth>(context);

    return FutureBuilder(
      future: fireauth.signInAnonymously(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const EmptyPage(
            hasAppBar: false,
            child: SizedBox(), // CircularProgressIndicator()
          );
        }

        if (snapshot.hasError) {
          return ErrorPage(
            message: '${snapshot.error}',
            refresh: refresh,
          );
        }

        return const UserPage();
      },
    );
  }
}
