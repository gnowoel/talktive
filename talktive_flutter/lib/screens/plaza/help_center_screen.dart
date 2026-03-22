import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_page_scaffold.dart';
import '../../widgets/duo/duo_card.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DuoPageScaffold(
      icon: Icons.help_outline,
      title: 'Help Center',
      subtitle: 'How can we help you today?',
      gradient: AppTheme.primaryGradient,
      hasBackButton: true,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Column(
          children: [
            _buildHelpCard(
              icon: Icons.person_outline,
              title: 'What is a Persona?',
              description:
                  'Talktive is about personas, not profiles. You can be whoever you want to be in different spaces. Your real identity is always private.',
            ),
            const SizedBox(height: AppTheme.duoSpacingMedium),
            _buildHelpCard(
              icon: Icons.apartment,
              title: 'How do Floors work?',
              description:
                  'Your Floor represents your standing in the building. Earn XP by chatting and sharing moments to climb to higher floors and unlock new features.',
            ),
            const SizedBox(height: AppTheme.duoSpacingMedium),
            _buildHelpCard(
              icon: Icons.security,
              title: 'Safety & Privacy',
              description:
                  'We take your privacy seriously. All chats are encrypted, and you have full control over who can see your activity and status.',
            ),
            const SizedBox(height: AppTheme.duoSpacingMedium),
            _buildHelpCard(
              icon: Icons.stars,
              title: 'What is Talktive Plus?',
              description:
                  'Talktive Plus is our premium subscription that unlocks advanced features like custom avatars, voice messages, and exclusive badges.',
            ),
            const SizedBox(height: AppTheme.duoSpacingLarge * 2),
            Center(
              child: Text(
                'Still need help? Contact us at support@talktive.app',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  Widget _buildHelpCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return DuoCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: AppTheme.duoSpacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
