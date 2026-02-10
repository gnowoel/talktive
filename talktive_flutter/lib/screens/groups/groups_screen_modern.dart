import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_header.dart';
import '../../widgets/duo/duo_empty_state.dart';

/// Duolingo-style Groups screen - Group chats
class GroupsScreenModern extends StatelessWidget {
  const GroupsScreenModern({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            DuoHeader(
              emoji: '👥',
              title: 'Groups',
              subtitle: 'Join communities',
            ),
            Expanded(
              child: DuoEmptyState(
                emoji: '🎉',
                title: 'No groups yet',
                subtitle: 'Create or join a community',
                buttonText: 'Create Group',
                onButtonPressed: () {
                  // TODO: Navigate to create group screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Coming soon!'),
                      backgroundColor: AppTheme.duoOrange,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.duoRadiusMedium,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
