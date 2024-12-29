import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'auth.dart';
import 'models/chat.dart';
import 'pages/chat.dart';
import 'pages/reports.dart';
import 'services/fireauth.dart';
import 'services/firedata.dart';
import 'services/messaging.dart';

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
    GoRoute(
      path: '/admin/reports',
      builder: (context, state) => FutureBuilder(
        future: _checkAdminAccess(context),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data == true) {
            return const ReportsPage();
          }
          // Return unauthorized or loading state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    ),
  ],
);

Future<Chat?> _fetchChat(BuildContext context, String chatId) async {
  final firedata = Provider.of<Firedata>(context, listen: false);
  final fireauth = Provider.of<Fireauth>(context, listen: false);
  final userId = fireauth.instance.currentUser!.uid;

  return await firedata.fetchChat(userId, chatId);
}

Future<bool> _checkAdminAccess(BuildContext context) async {
  final firedata = Provider.of<Firedata>(context, listen: false);
  final fireauth = Provider.of<Fireauth>(context, listen: false);

  final userId = fireauth.instance.currentUser!.uid;
  final admin = await firedata.fetchAdmin(userId);

  return admin != null;
}
