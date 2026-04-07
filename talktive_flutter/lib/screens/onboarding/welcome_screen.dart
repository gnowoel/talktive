import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth/google_sign_in_button.dart';
import '../../widgets/duo/duo_button.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _animationController;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      emoji: '🎭',
      title: 'Create Your Persona',
      subtitle:
          'Sign in safely with Google, then choose an anonymous persona to protect your identity.',
      backgroundColor: AppTheme.primaryColor,
      features: [
        'Choose fun emoji avatars',
        'Create a unique persona',
        'No personal data tracking',
      ],
    ),
    OnboardingPage(
      emoji: '💬',
      title: 'Connect & Chat',
      subtitle:
          'Find interesting people from around the world and start meaningful conversations.',
      backgroundColor: AppTheme.secondaryColor,
      features: [
        'Smart matching algorithm',
        'Interest-based connections',
        'Real-time messaging',
      ],
    ),
    OnboardingPage(
      emoji: '🎮',
      title: 'Earn & Level Up',
      subtitle:
          'Chat, make friends, and earn points to unlock achievements and badges!',
      backgroundColor: AppTheme.accentColor,
      features: [
        'Gamified experience',
        'Unlock cool badges',
        'Build your trust score',
      ],
    ),
    OnboardingPage(
      emoji: '🔒',
      title: 'Safe & Secure',
      subtitle:
          'Auto-delete old chats, rate users for trust, and stay in control of your data.',
      backgroundColor: AppTheme.primaryColor,
      features: [
        'Auto-cleanup inactive chats',
        'User rating system',
        'Delete account anytime',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    HapticFeedback.lightImpact();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      _pages.length - 1,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _getStarted() async {
    HapticFeedback.mediumImpact();

    // Mark welcome as seen
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_seen', true);

    if (!mounted) return;

    // Trigger Google Sign-In
    try {
      final status = await ref.read(authProvider.notifier).loginWithGoogle();

      if (!mounted) return;

      switch (status) {
        case AuthStatus.authenticated:
          break;
        case AuthStatus.needsProfile:
        case AuthStatus.migrating:
          break;
        case AuthStatus.cancelled:
          // Just stay on the screen
          break;
        case AuthStatus.error:
          final errorMessage =
              ref.read(authProvider).error?.toString() ??
              'Sign in failed. Please try again.';
          DuoSnackBarHelper.showError(context, errorMessage);
          break;
      }
    } catch (e) {
      if (mounted) {
        DuoSnackBarHelper.showError(context, e);
      }
    }
  }

  void _showWhyGoogleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🛡️ Why Google?',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Talktive is anonymous, but we use Google Sign-In to keep the community safe:',
              style: TextStyle(fontFamily: 'Rubik', height: 1.4),
            ),
            const SizedBox(height: 16),
            _buildBulletPoint('Prevent ban evasion from spammers/abusers.'),
            _buildBulletPoint('Stop malicious users from just reinstalling.'),
            _buildBulletPoint('Zero data collection of names/emails.'),
            const SizedBox(height: 16),
            const Text(
              'Your Google info is used ONLY for secure authentication. We don\'t even store your email address!',
              style: TextStyle(
                fontFamily: 'Rubik',
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Got it!',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'Rubik', fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (previous, next) {
      if (!mounted || !next.hasValue) return;
      final authState = next.value;

      if (authState is Authenticated) {
        context.go('/');
      } else if (authState is NeedsProfile) {
        context.go(
          '/profile-setup',
          extra: {'migrationData': authState.migrationData},
        );
      }
    });

    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index], index);
            },
          ),

          // Skip Button
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: 50,
              right: 20,
              child: SafeArea(
                child: DuoButton(
                  text: 'Skip',
                  onPressed: _skipToEnd,
                  variant: DuoButtonVariant.ghost,
                  size: DuoButtonSize.small,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => _buildPageIndicator(index),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Button
                    SizedBox(
                          width: double.infinity,
                          child: _currentPage < _pages.length - 1
                              ? DuoButton(
                                  text: 'Next',
                                  onPressed: _nextPage,
                                  variant: DuoButtonVariant.secondary,
                                  size: DuoButtonSize.large,
                                  color: _pages[_currentPage].backgroundColor,
                                )
                              : Column(
                                  children: [
                                    GoogleSignInButton(
                                      onPressed: _getStarted,
                                      isLoading: authState.isLoading,
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton(
                                      onPressed: _showWhyGoogleDialog,
                                      child: Text(
                                        'Why do I need to sign in with Google?',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withValues(
                                            alpha: 0.7,
                                          ),
                                          decoration: TextDecoration.underline,
                                          decorationColor: Colors.white
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        )
                        .animate(
                          key: ValueKey(_currentPage == _pages.length - 1),
                        )
                        .fadeIn(delay: 200.ms)
                        .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 300.ms,
                          curve: Curves.easeOut,
                        ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page, int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            page.backgroundColor,
            page.backgroundColor.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Emoji Icon with animation
              Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        page.emoji,
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                  )
                  .animate(
                    key: ValueKey('emoji_$index'),
                    onPlay: (controller) => controller.forward(),
                  )
                  .scale(
                    duration: 600.ms,
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1, 1),
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(),

              const SizedBox(height: 48),

              // Title
              Text(
                    page.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate(key: ValueKey('title_$index'))
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                    page.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  )
                  .animate(key: ValueKey('subtitle_$index'))
                  .fadeIn(delay: 300.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 40),

              // Feature List
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: page.features
                      .asMap()
                      .entries
                      .map(
                        (entry) => _buildFeatureItem(
                          entry.value,
                          delay: 400 + (entry.key * 100),
                        ),
                      )
                      .toList(),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String feature, {int delay = 0}) {
    return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  feature,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: delay.ms)
        .slideX(begin: -0.2, end: 0, curve: Curves.easeOutQuad);
  }

  Widget _buildPageIndicator(int index) {
    bool isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final List<String> features;

  OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.features,
  });
}
