import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_card.dart';

/// The Help Center screen - A utility screen for FAQs and stories.
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightBackground,
      appBar: AppBar(
        title: const Text(
          'Help Center',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            HapticFeedback.lightImpact();
            context.pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Column(
          children: [
            // Story Section: The Building Metaphor
            _buildStoryCard(),
            const SizedBox(height: AppTheme.duoSpacingLarge),

            // FAQ Sections
            _buildHelpCard(
              emoji: '👤',
              title: 'What is a Persona?',
              description:
                  'Talktive is about personas, not profiles. You can be whoever you want to be in different lounges. If you want to be a "Chef" in the Kitchen but a "Reader" in the Library, you can! Your real identity is always your private sanctuary.',
              color: AppTheme.duoPurple,
            ),
            const SizedBox(height: AppTheme.duoSpacingMedium),
            _buildHelpCard(
              emoji: '🏢',
              title: 'The Reputation System',
              description:
                  'Your Floor represents your standing in our digital apartment building. Earn XP by chatting and sharing moments to climb higher. Higher floors unlock more influence and cooler features!',
              color: AppTheme.duoYellow,
            ),
            const SizedBox(height: AppTheme.duoSpacingMedium),
            _buildHelpCard(
              emoji: '🛡️',
              title: 'Safety & Privacy',
              description:
                  'Talktive is a safe and welcoming neighborhood. To protect your privacy and keep the community fresh, all user-generated content is ephemeral and automatically deleted after a certain period. This ensures your real identity remains your private sanctuary.',
              color: AppTheme.duoRed,
            ),
            const SizedBox(height: AppTheme.duoSpacingMedium),
            _buildHelpCard(
              emoji: '🌟',
              title: 'Talktive Plus',
              description:
                  'Become a premium resident! Unlock exclusive benefits like custom emojis, voice messages, and an ad-free experience to make your stay in the apartment truly unique.',
              color: AppTheme.duoBlue,
            ),
            const SizedBox(height: AppTheme.duoSpacingMedium),
            _buildHelpCard(
              emoji: '🔑',
              title: 'Why Google Sign-In?',
              description:
                  'To keep our community safe from spammers and ban evaders, we use Google Sign-In for authentication. As an anonymous app, we do NOT collect your personal info like name, email, or avatar. We only use it to ensure every resident plays by the rules!',
              color: AppTheme.duoGreen,
            ),
            const SizedBox(height: AppTheme.duoSpacingXXLarge),

            // Footer: Contact Info
            Column(
              children: [
                const Text('🛎️', style: TextStyle(fontSize: 48))
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .shake(duration: 2500.ms, hz: 1.5),
                const SizedBox(height: 16),
                const Text(
                  'Still need a hand?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The building manager is always on duty!',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontFamily: 'Rubik',
                  ),
                ),
                const SizedBox(height: 4),
                TextSelectionTheme(
                  data: TextSelectionThemeData(
                    selectionColor: AppTheme.primaryColor.withValues(
                      alpha: 0.3,
                    ),
                  ),
                  child: const SelectableText(
                    'gnowoel@gmail.com',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Copyright © 2026 Talktive Community',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 60),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
      ),
    );
  }

  Widget _buildStoryCard() {
    return DuoCard(
      padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
      color: AppTheme.duoBlue.withValues(alpha: 0.05),
      child: Column(
        children: [
          const Text('🏢', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          const Text(
            'Welcome Home!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              color: AppTheme.duoBlue,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Imagine living in a vibrant apartment building. Your room is your sanctuary, but the magic happens when you step out. Meeting in the Lobby (Plaza), updating the Bulletin Board (Moments), or hanging out in the Clubhouse (Lounges) with people who share your interests.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.6,
              fontFamily: 'Rubik',
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Talktive is designed for genuine connections. We prioritize your privacy so you can speak your mind and enjoy your neighborhood stay.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textSecondary,
              height: 1.6,
              fontFamily: 'Rubik',
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard({
    required String emoji,
    required String title,
    required String description,
    required Color color,
  }) {
    return DuoCard(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(emoji, style: const TextStyle(fontSize: 24)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.6,
                fontFamily: 'Rubik',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
