import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_header.dart';
import '../../widgets/duo/duo_empty_state.dart';

/// Duolingo-style Chats screen - Private messages
class ChatsScreenModern extends StatelessWidget {
  const ChatsScreenModern({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            DuoHeader(
              emoji: '💬',
              title: 'Chats',
              subtitle: 'Private conversations',
            ),
            Expanded(
              child: DuoEmptyState(
                emoji: '🤝',
                title: 'No chats yet',
                subtitle: 'Start a private conversation',
                buttonText: 'Find Friends',
                onButtonPressed: () {
                  // TODO: Navigate to find friends screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Coming soon!'),
                      backgroundColor: AppTheme.primaryColor,
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
