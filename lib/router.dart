import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:talktive/pages/friends.dart';

import 'models/chat.dart';
import 'models/user.dart';
import 'pages/backup_account.dart';
import 'pages/chat.dart';
import 'pages/chats.dart';
import 'pages/create_topic.dart';
import 'pages/edit_profile.dart';
import 'pages/launch.dart';
import 'pages/profile.dart';
import 'pages/report.dart';
import 'pages/reports.dart';
import 'pages/topic.dart';
import 'pages/topics.dart';
import 'pages/users.dart';
import 'services/fireauth.dart';
import 'services/firedata.dart';
import 'services/messaging.dart';
import 'widgets/navigation.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final _usersNavigatorKey = GlobalKey<NavigatorState>();
final _topicsNavigatorKey = GlobalKey<NavigatorState>();
final _chatsNavigatorKey = GlobalKey<NavigatorState>();
final _friendsNavigatorKey = GlobalKey<NavigatorState>();
final _profileNavigatorKey = GlobalKey<NavigatorState>();

Future<GoRouter> initRouter() async {
  final initialRoute = await Messaging.getInitialRoute();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialRoute ?? '/users',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Navigation(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: _usersNavigatorKey,
            routes: [
              GoRoute(
                path: '/users',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: UsersPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _topicsNavigatorKey,
            routes: [
              GoRoute(
                path: '/topics',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TopicsPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _chatsNavigatorKey,
            routes: [
              GoRoute(
                path: '/chats',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ChatsPage()),
                routes: [
                  GoRoute(
                    parentNavigatorKey:
                        rootNavigatorKey, // Hide the navigation bar
                    path: '/chats/:id',
                    builder: (context, state) {
                      final chatId = state.pathParameters['id']!;
                      final encodedChatCreatedAt =
                          state.uri.queryParameters['chatCreatedAt'] ?? '0';
                      final chatCreatedAt =
                          Uri.decodeComponent(encodedChatCreatedAt);

                      final userStub = UserStub(createdAt: 0, updatedAt: 0);
                      final chatStub = ChatStub(
                        createdAt: int.tryParse(chatCreatedAt) ?? 0,
                        updatedAt: 0,
                        partner: userStub,
                        messageCount: 0,
                      );
                      final chat =
                          Chat.fromStub(key: chatId, value: chatStub);

                      return ChatPage(chat: chat);
                    },
                  ),
                  GoRoute(
                    parentNavigatorKey:
                        rootNavigatorKey, // Hide the navigation bar
                    path: '/topics/:id',
                    builder: (context, state) {
                      final topicId = state.pathParameters['id']!;
                      final encodedTopicCreatorId =
                          state.uri.queryParameters['topicCreatorId'] ?? '';
                      final topicCreatorId =
                          Uri.decodeComponent(encodedTopicCreatorId);

                      return TopicPage(
                          topicId: topicId, topicCreatorId: topicCreatorId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _friendsNavigatorKey,
            routes: [
              GoRoute(
                path: '/friends',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: FriendsPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ProfilePage()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/launch/chat/:id',
        builder: (context, state) {
          final chatId = state.pathParameters['id']!;
          final encodedChatCreatedAt =
              state.uri.queryParameters['chatCreatedAt'] ?? '0';
          final chatCreatedAt = Uri.decodeComponent(encodedChatCreatedAt);

          return LaunchChatPage(chatId: chatId, chatCreatedAt: chatCreatedAt);
        },
      ),
      GoRoute(
        path: '/launch/topic/:id',
        builder: (context, state) {
          final topicId = state.pathParameters['id']!;
          final encodedTopicCreatorId =
              state.uri.queryParameters['topicCreatorId'] ?? '';
          final topicCreatorId = Uri.decodeComponent(encodedTopicCreatorId);

          return LaunchTopicPage(
            topicId: topicId,
            topicCreatorId: topicCreatorId,
          );
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) {
          final user = state.extra! as User;
          return EditProfilePage(user: user);
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
              body: Center(child: CircularProgressIndicator(strokeWidth: 3)),
            );
          },
        ),
      ),
      GoRoute(
        path: '/admin/reports/:id',
        builder: (context, state) {
          final chatId = state.pathParameters['id']!;

          final encodedUserId = state.uri.queryParameters['userId'] ?? '';
          final userId = Uri.decodeComponent(encodedUserId);

          final encodedChatCreatedAt =
              state.uri.queryParameters['chatCreatedAt'] ?? '0';
          final chatCreatedAt = Uri.decodeComponent(encodedChatCreatedAt);

          final userStub = UserStub(createdAt: 0, updatedAt: 0);
          final chatStub = ChatStub(
            createdAt: int.tryParse(chatCreatedAt) ?? 0,
            updatedAt: 0,
            partner: userStub,
            messageCount: 0,
          );
          final chat = Chat.fromStub(key: chatId, value: chatStub);

          return ReportPage(userId: userId, chat: chat);
        },
      ),
      GoRoute(
        path: '/profile/backup',
        builder: (context, state) => const BackupAccountPage(),
      ),
      GoRoute(
        path: '/topics/create',
        builder: (context, state) {
          final tribeId = state.uri.queryParameters['tribeId'];
          return CreateTopicPage(initialTribeId: tribeId);
        },
      ),
    ],
  );
}

Future<bool> _checkAdminAccess(BuildContext context) async {
  final firedata = Provider.of<Firedata>(context, listen: false);
  final fireauth = Provider.of<Fireauth>(context, listen: false);

  final userId = fireauth.instance.currentUser!.uid;
  final admin = await firedata.fetchAdmin(userId);

  return admin != null;
}
