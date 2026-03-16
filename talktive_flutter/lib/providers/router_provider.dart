import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';

import '../screens/splash_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/chats/chat_thread_screen.dart';
import '../screens/chats/peephole_screen.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/activity/settings_screen.dart';

import '../screens/profile/user_profile_view_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/plaza/plaza_chat_screen.dart';
import '../screens/moments/moment_detail_screen.dart';
import '../screens/moments/image_gallery_screen.dart';
import '../screens/moments/user_moments_screen.dart';
import '../screens/groups/group_search_screen.dart';
import '../screens/groups/group_profile_screen.dart';
import '../screens/groups/group_chat_screen.dart';
import '../screens/groups/group_members_screen.dart';

part 'router_provider.g.dart';

@riverpod
GoRouter router(Ref ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final resident = extra?['resident'] as Resident?;
          final userName = extra?['userName'] as String?;
          return ProfileSetupScreen(
            initialResident: resident,
            initialName: userName,
          );
        },
      ),
      GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/plaza',
        builder: (context, state) => const HomeScreen(initialIndex: 0),
        routes: [
          GoRoute(
            path: 'chat',
            builder: (context, state) => const PlazaChatScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/moments',
        builder: (context, state) => const HomeScreen(initialIndex: 1),
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final moment = state.extra as Moment;
              return MomentDetailScreen(moment: moment);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) {
          final imageUrl = state.extra as String;
          return ImageGalleryScreen(imageUrl: imageUrl);
        },
      ),
      GoRoute(
        path: '/chats',
        builder: (context, state) => const HomeScreen(initialIndex: 2),
        routes: [
          GoRoute(
            path: 'peephole',
            builder: (context, state) {
              final chatItem = state.extra as PrivateChatWithProfile;
              return PeepholeScreen(chatItem: chatItem);
            },
          ),
          GoRoute(
            path: 'thread/:channelId',
            builder: (context, state) {
              final channelId =
                  int.tryParse(state.pathParameters['channelId'] ?? '') ?? 0;
              return ChatThreadScreen(channelId: channelId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/groups',
        builder: (context, state) => const HomeScreen(initialIndex: 3),
        routes: [
          GoRoute(
            path: 'search',
            builder: (context, state) => const GroupSearchScreen(),
          ),
          GoRoute(
            path: 'profile/:groupId',
            builder: (context, state) {
              final groupId = int.parse(state.pathParameters['groupId']!);
              final group = state.extra as Group?;
              return GroupProfileScreen(groupId: groupId, initialGroup: group);
            },
          ),
          GoRoute(
            path: 'chat/:groupId',
            builder: (context, state) {
              final groupId = int.parse(state.pathParameters['groupId']!);
              final group = state.extra as Group?;
              if (group != null) {
                return GroupChatScreen(group: group);
              } else {
                return GroupChatLoader(groupId: groupId);
              }
            },
          ),
          GoRoute(
            path: 'members/:groupId',
            builder: (context, state) {
              final groupId = int.parse(state.pathParameters['groupId']!);
              final group = state.extra as Group?;
              return GroupMembersScreen(groupId: groupId, initialGroup: group);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const HomeScreen(initialIndex: 4),
      ),
      GoRoute(
        path: '/my-profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/activity',
        builder: (context, state) => const ActivityScreen(),
        routes: [
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/user/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return UserProfileViewScreen(
            userId: userId,
            userName: extra?['userName'] as String?,
            userAvatar: extra?['userAvatar'] as String?,
            userFloor: extra?['userFloor'] as int?,
          );
        },
        routes: [
          GoRoute(
            path: 'moments',
            builder: (context, state) {
              final userId = state.pathParameters['userId']!;
              final userName = state.uri.queryParameters['name'] ?? 'Resident';
              return UserMomentsScreen(userId: userId, userName: userName);
            },
          ),
        ],
      ),
    ],
  );
}

extension GoRouterExtension on GoRouter {
  String get location {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
