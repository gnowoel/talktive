import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth.dart';
import 'models/chat.dart';
import 'pages/chat.dart';
import 'services/avatar.dart';
import 'services/cache.dart';
import 'services/fireauth.dart';
import 'services/firedata.dart';
import 'services/messaging.dart';
import 'services/storage.dart';
import 'theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = FirebaseAuth.instance;
    final database = FirebaseDatabase.instance;
    final storage = FirebaseStorage.instance;
    final messaging = FirebaseMessaging.instance;

    // Define the router configuration
    final router = GoRouter(
      navigatorKey: Messaging.navigationKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const Auth(),
        ),
        GoRoute(
          path: '/chat/:id',
          builder: (context, state) {
            final chatId = state.pathParameters['id']!;
            return FutureBuilder(
              future: _fetchChat(context, chatId),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ChatPage(chat: snapshot.data as Chat);
                }
                // Return loading or error state
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            );
          },
        ),
      ],
    );

    return MultiProvider(
      providers: [
        Provider(create: (context) => Fireauth(auth)),
        Provider(create: (context) => Firedata(database)),
        Provider(create: (context) => Storage(storage)),
        Provider(create: (context) => Messaging(messaging)),
        ChangeNotifierProvider(create: (context) => Avatar()),
        ChangeNotifierProvider(create: (context) => Cache()),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        title: 'Talktive',
        theme: getTheme(context),
      ),
    );
  }

  // Helper method to fetch chat data
  Future<Chat?> _fetchChat(BuildContext context, String chatId) async {
    final firedata = Provider.of<Firedata>(context, listen: false);
    final fireauth = Provider.of<Fireauth>(context, listen: false);
    final userId = fireauth.instance.currentUser!.uid;

    // Subscribe to get the latest chat data
    return await firedata.fetchChat(userId, chatId);
  }
}
