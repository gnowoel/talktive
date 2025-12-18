import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:talktive/pages/friends.dart';

import 'models/user.dart';
import 'pages/backup_account.dart';

import 'pages/create_topic.dart';
import 'pages/edit_profile.dart';
import 'pages/launch.dart';
import 'pages/privacy_settings_page.dart';
import 'pages/profile.dart';
import 'pages/topic.dart';

import 'pages/topics.dart';
import 'pages/joined_topics.dart';
import 'pages/users.dart';

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
                    const NoTransitionPage(child: JoinedTopicsPage()),
                routes: [
                  GoRoute(
                    parentNavigatorKey: rootNavigatorKey,
                    path: '/topics/:id',
                    builder: (context, state) {
                      final topicId = state.pathParameters['id']!;
                      final encodedTopicCreatorId =
                          state.uri.queryParameters['topicCreatorId'] ?? '';
                      final topicCreatorId = Uri.decodeComponent(
                        encodedTopicCreatorId,
                      );

                      return TopicPage(
                        topicId: topicId,
                        topicCreatorId: topicCreatorId,
                      );
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
        path: '/profile/backup',
        builder: (context, state) => const BackupAccountPage(),
      ),
      GoRoute(
        path: '/profile/privacy-settings',
        builder: (context, state) => const PrivacySettingsPage(),
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
