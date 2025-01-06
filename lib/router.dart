import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/chat.dart';
import 'models/user.dart';
import 'pages/chat.dart';
import 'pages/chats.dart';
import 'pages/profile.dart';
import 'pages/reports.dart';
import 'pages/users.dart';
import 'services/fireauth.dart';
import 'services/firedata.dart';
import 'widgets/navigation.dart';
import 'wrappers/initializers/initializers.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _chatsNavigatorKey = GlobalKey<NavigatorState>();
final _usersNavigatorKey = GlobalKey<NavigatorState>();
final _profileNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/users',
  routes: [
    // GoRoute(
    //   path: '/',
    //   builder: (context, state) => const HomePage(),
    // ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Initializers(
          child: Navigation(navigationShell: navigationShell),
        );
      },
      branches: [
        StatefulShellBranch(
          navigatorKey: _usersNavigatorKey,
          routes: [
            GoRoute(
              path: '/users',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: UsersPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _chatsNavigatorKey,
          routes: [
            GoRoute(
              path: '/chats',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ChatsPage(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          navigatorKey: _profileNavigatorKey,
          routes: [
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: ProfilePage(),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/chats/:id',
      builder: (context, state) {
        final chatId = state.pathParameters['id']!;
        final params = state.extra! as Map<String, String>;
        final partnerDisplayName = params['partnerDisplayName'];

        final userStub = UserStub(
          createdAt: 0,
          updatedAt: 0,
          displayName: partnerDisplayName,
        );

        final chatStub = ChatStub(
          createdAt: 0,
          updatedAt: 0,
          partner: userStub,
          messageCount: 0,
        );

        final chat = Chat.fromStub(
          key: chatId,
          value: chatStub,
        );

        return ChatPage(chat: chat);
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

Future<bool> _checkAdminAccess(BuildContext context) async {
  final firedata = Provider.of<Firedata>(context, listen: false);
  final fireauth = Provider.of<Fireauth>(context, listen: false);

  final userId = fireauth.instance.currentUser!.uid;
  final admin = await firedata.fetchAdmin(userId);

  return admin != null;
}
