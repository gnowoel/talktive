import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:talktive_client/talktive_client.dart';

import '../screens/splash_screen.dart';
import '../screens/onboarding/welcome_screen.dart';
import '../screens/onboarding/profile_setup_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/chats/chat_thread_screen.dart';
import '../screens/chats/peephole_screen.dart';
import '../screens/activity/settings_screen.dart';

import '../screens/profile/user_profile_view_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/plaza/plaza_chat_screen.dart';
import '../screens/moments/moment_detail_screen.dart';
import '../screens/moments/image_gallery_screen.dart';
import '../screens/moments/user_moments_screen.dart';
import '../screens/discovery/people_search_screen.dart';
import '../screens/discovery/lounge_search_screen.dart';
import '../screens/lounges/lounge_profile_screen.dart';
import '../screens/lounges/lounge_chat_screen.dart';
import '../screens/lounges/lounge_members_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/users_screen.dart';
import '../screens/plaza/plaza_screen.dart';
import '../screens/moments/moments_screen.dart';
import '../screens/chats/chats_screen.dart';
import '../screens/lounges/lounges_screen.dart';
import '../screens/activity/activity_screen.dart';
import '../screens/plaza/help_center_screen.dart';

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

      // Redirect root to plaza
      GoRoute(
        path: '/',
        redirect: (context, state) => '/plaza',
      ),
      GoRoute(
        path: '/discovery',
        redirect: (context, state) => '/plaza',
      ),

      // Main Navigation using StatefulShellRoute
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          // Branch: Plaza (Index 0)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plaza',
                builder: (context, state) => const PlazaScreen(),
              ),
            ],
          ),
          // Branch: Moments (Index 1)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/moments',
                builder: (context, state) => const MomentsScreen(),
              ),
            ],
          ),
          // Branch: Chats (Index 2)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const ChatsScreen(),
              ),
            ],
          ),
          // Branch: Lounges (Index 3)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/lounges',
                builder: (context, state) => const LoungesScreen(),
              ),
            ],
          ),
          // Branch: Activity (Index 4)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                builder: (context, state) => const ActivityScreen(),
              ),
            ],
          ),
        ],
      ),
 
      // Utility/Detail Screens (Outer routes to hide bottom nav)
      GoRoute(
        path: '/plaza/chat',
        builder: (context, state) => const PlazaChatScreen(),
      ),
      GoRoute(
        path: '/plaza/help',
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: '/moments/detail',
        builder: (context, state) {
          final moment = state.extra as Moment;
          return MomentDetailScreen(moment: moment);
        },
      ),
      GoRoute(
        path: '/chats/peephole',
        builder: (context, state) {
          final chatItem = state.extra as PrivateChatWithProfile;
          return PeepholeScreen(chatItem: chatItem);
        },
      ),
      GoRoute(
        path: '/chats/thread/:channelId',
        builder: (context, state) {
          final channelId = int.parse(state.pathParameters['channelId']!);
          return ChatThreadScreen(channelId: channelId);
        },
      ),
      GoRoute(
        path: '/lounges/search',
        builder: (context, state) => const LoungeSearchScreen(),
      ),
      GoRoute(
        path: '/lounges/profile/:loungeId',
        builder: (context, state) {
          final loungeId = int.parse(state.pathParameters['loungeId']!);
          final lounge = state.extra as Lounge?;
          return LoungeProfileScreen(
            loungeId: loungeId,
            initialLounge: lounge,
          );
        },
      ),
      GoRoute(
        path: '/lounges/chat/:loungeId',
        builder: (context, state) {
          final loungeId = int.parse(state.pathParameters['loungeId']!);
          final lounge = state.extra as Lounge?;
          if (lounge != null) {
            return LoungeChatScreen(lounge: lounge);
          } else {
            return LoungeChatLoader(loungeId: loungeId);
          }
        },
      ),
      GoRoute(
        path: '/lounges/members/:loungeId',
        builder: (context, state) {
          final loungeId = int.parse(state.pathParameters['loungeId']!);
          final lounge = state.extra as Lounge?;
          return LoungeMembersScreen(
            loungeId: loungeId,
            initialLounge: lounge,
          );
        },
      ),
      GoRoute(
        path: '/activity/settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Other routes outside the shell if needed (e.g., discovery/people)
      GoRoute(
        path: '/discovery/people',
        builder: (context, state) => const PeopleSearchScreen(),
      ),
      GoRoute(
        path: '/discovery/lounges',
        builder: (context, state) => const LoungeSearchScreen(),
      ),
      GoRoute(
        path: '/gallery',
        builder: (context, state) {
          final imageUrl = state.extra as String;
          return ImageGalleryScreen(imageUrl: imageUrl);
        },
      ),
      GoRoute(
        path: '/my-profile',
        builder: (context, state) => const ProfileScreen(),
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
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'dashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) => const UsersScreen(),
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
