import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:country_picker/country_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:confetti/confetti.dart';
import '../../config/theme.dart';
import '../../config/languages.dart';
import '../../providers/auth_provider.dart';

import 'package:talktive_client/talktive_client.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  final Resident? initialResident;
  final String? initialName;

  const ProfileSetupScreen({super.key, this.initialResident, this.initialName});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  late ConfettiController _confettiController;

  int _currentStep = 0;
  String _selectedAvatar = '😊';
  String _selectedGender = 'prefer-not-to-say';
  String _selectedCountry = 'Unknown';
  String _selectedCountryFlag = '🌍';
  String _selectedMood = '😊';
  List<String> _selectedInterests = [];
  List<String> _selectedLanguages = ['en'];
  bool _isLoading = false;

  final List<String> _popularAvatars = [
    '😊',
    '😎',
    '🥳',
    '🤩',
    '😇',
    '🤠',
    '🥷',
    '👽',
    '🤖',
    '👻',
    '🎃',
    '🦄',
    '🐱',
    '🐶',
    '🐼',
    '🦊',
    '🦁',
    '🐯',
    '🐨',
    '🐵',
    '🦉',
    '🦋',
    '🐢',
    '🐙',
    '🌟',
    '⭐',
    '🌙',
    '☀️',
    '🌈',
    '⚡',
    '🔥',
    '💫',
  ];

  final List<String> _moods = [
    '😊',
    '😄',
    '😎',
    '🥳',
    '😇',
    '🤔',
    '😴',
    '🥰',
    '😤',
    '😭',
    '🤪',
    '🤯',
    '🥶',
    '🥵',
    '🤒',
    '😈',
  ];

  final List<String> _availableInterests = [
    '🎮 Gaming',
    '🎵 Music',
    '🎬 Movies',
    '📚 Books',
    '🎨 Art',
    '📷 Photography',
    '✈️ Travel',
    '🍔 Food',
    '💪 Fitness',
    '🧘 Yoga',
    '⚽ Sports',
    '💻 Tech',
    '🌱 Nature',
    '🐕 Pets',
    '👗 Fashion',
    '💄 Beauty',
    '🎭 Theater',
    '🎪 Comedy',
    '🔬 Science',
    '🌍 Culture',
    '💰 Crypto',
    '📈 Trading',
    '🎯 Business',
    '🚀 Startups',
  ];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );

    if (widget.initialResident != null) {
      final resident = widget.initialResident!;
      // Need to fetch user name from auth state if possible, but let's prefill from provider later,
      // actually, just keep it blank or read from provider in post frame callback
      _selectedAvatar = resident.avatar ?? '😊';
      _selectedGender = resident.gender ?? 'prefer-not-to-say';
      _selectedCountry = resident.country ?? 'Unknown';

      if (_selectedCountry != 'Unknown') {
        try {
          final countries = CountryService().getAll();
          for (var c in countries) {
            if (c.name.toLowerCase() == _selectedCountry.toLowerCase()) {
              _selectedCountryFlag = c.flagEmoji;
              break;
            }
          }
        } catch (_) {}
      }

      _selectedInterests = List<String>.from(resident.interests ?? []);
      _selectedLanguages = List<String>.from(resident.languages ?? ['en']);

      final bioText = resident.bio ?? '';
      _bioController.text = bioText;
      _selectedMood = resident.mood ?? '😊';

      if (widget.initialName != null) {
        _nameController.text = widget.initialName!;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < 6) {
        // Updated for 7 steps (0-6)
        setState(() {
          _currentStep++;
        });
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        HapticFeedback.lightImpact();
      } else {
        _completeSetup();
      }
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.lightImpact();
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Avatar
        return _selectedAvatar.isNotEmpty;
      case 1: // Name
        if (_nameController.text.trim().isEmpty) {
          _showError('Please enter a name');
          return false;
        }
        if (_nameController.text.trim().length < 3) {
          _showError('Name must be at least 3 characters');
          return false;
        }
        return true;
      case 2: // Gender & Country
        return true;
      case 3: // Languages (New)
        if (_selectedLanguages.isEmpty) {
          _showError('Please select at least one language');
          return false;
        }
        return true;
      case 4: // Bio
        return true; // Optional
      case 5: // Interests
        if (_selectedInterests.isEmpty) {
          _showError('Please select at least one interest');
          return false;
        }
        return true;
      case 6: // Mood
        return true; // Has default
      default:
        return true;
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _completeSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isEditing = widget.initialResident != null;
      final bool success;

      if (isEditing) {
        success = await ref
            .read(authProvider.notifier)
            .updateProfile(
              name: _nameController.text.trim(),
              avatar: _selectedAvatar,
              gender: _selectedGender,
              country: _selectedCountry,
              bio: _bioController.text.trim(),
              interests: _selectedInterests,
              languages: _selectedLanguages,
              mood: _selectedMood,
            );
      } else {
        success = await ref
            .read(authProvider.notifier)
            .completeSetup(
              name: _nameController.text.trim(),
              avatar: _selectedAvatar,
              gender: _selectedGender,
              country: _selectedCountry,
              bio: _bioController.text.trim(),
              interests: _selectedInterests,
              languages: _selectedLanguages,
              mood: _selectedMood,
            );
      }

      if (success) {
        if (!isEditing) {
          _confettiController.play();
          await Future.delayed(const Duration(seconds: 2));
        }

        if (mounted) {
          if (isEditing) {
            context.pop();
          } else {
            context.go('/');
          }
        }
      } else {
        _showError(
          'Failed to ${isEditing ? 'update' : 'create'} profile. Please try again.',
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showError('An error occurred: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.secondaryColor.withValues(alpha: 0.1),
                ],
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildProgressIndicator(),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildAvatarStep(),
                      _buildNameStep(),
                      _buildGenderCountryStep(),
                      _buildLanguagesStep(), // New Step
                      _buildBioStep(),
                      _buildInterestsStep(),
                      _buildMoodStep(),
                    ],
                  ),
                ),

                _buildNavigationButtons(),
              ],
            ),
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                AppTheme.primaryColor,
                AppTheme.secondaryColor,
                AppTheme.accentColor,
                Colors.yellow,
                Colors.green,
              ],
              numberOfParticles: 30,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Step counter
          Text(
            'Step ${_currentStep + 1} of 7',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / 7,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2, end: 0);
  }

  Widget _buildAvatarStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Choose Your Avatar',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'Pick an emoji that represents you!',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 32),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: AppTheme.primaryGradient),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _selectedAvatar,
                style: const TextStyle(fontSize: 60),
              ),
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _popularAvatars.length,
              itemBuilder: (context, index) {
                final avatar = _popularAvatars[index];
                final isSelected = avatar == _selectedAvatar;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedAvatar = avatar;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child:
                      Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            avatar,
                            style: const TextStyle(fontSize: 32),
                          ),
                        ),
                      ).animate().scale(
                        delay: Duration(milliseconds: index * 20),
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),
                );
              },
            ),
          ),
          TextButton.icon(
            onPressed: _showEmojiPicker,
            icon: const Icon(Icons.add_reaction_outlined),
            label: const Text('Choose Custom Emoji'),
          ),
        ],
      ),
    );
  }

  Widget _buildNameStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'What\'s Your Name?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'Choose any name you like!',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Text(
                        _selectedAvatar,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ).animate().scale(),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _nameController,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      hintStyle: const TextStyle(
                        color: AppTheme.textLight,
                        fontWeight: FontWeight.normal,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                    textCapitalization: TextCapitalization.words,
                    maxLength: 20,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: ['Mystic', 'Phoenix', 'Luna', 'Star', 'Sky', 'Nova'].map((
                      name,
                    ) {
                      return ActionChip(
                        label: Text(name),
                        onPressed: () {
                          _nameController.text = name;
                          HapticFeedback.selectionClick();
                        },
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        labelStyle: const TextStyle(color: AppTheme.primaryColor),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCountryStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Tell Us About You',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'This helps us find better matches',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Gender',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildGenderOption('male', '♂️', 'Male')),
                      const SizedBox(width: 12),
                      Expanded(child: _buildGenderOption('female', '♀️', 'Female')),
                    ],
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGenderOption('non-binary', '⚧️', 'Non-binary'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildGenderOption('prefer-not-to-say', '🔒', 'Private'),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 48),
                  Text(
                    'Country',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: _selectCountry,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _selectedCountryFlag,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _selectedCountry,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagesStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Languages You Speak',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),

          const SizedBox(height: 8),

          Text(
            'Select languages to find people who speak them',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 24),

          // Selected count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.duoGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_selectedLanguages.length} selected',
              style: const TextStyle(
                color: AppTheme.duoGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3,
              ),
              itemCount: AppLanguages.all.length,
              itemBuilder: (context, index) {
                final language = AppLanguages.all[index];
                final code = language['code']!;
                final name = language['name']!;
                final flag = language['flag']!;
                final isSelected = _selectedLanguages.contains(code);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        if (_selectedLanguages.length > 1) {
                          _selectedLanguages.remove(code);
                        }
                      } else {
                        _selectedLanguages.add(code);
                      }
                    });
                    HapticFeedback.selectionClick();
                  },
                  child:
                      Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.duoGreen.withValues(alpha: 0.2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.duoGreen
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(flag, style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppTheme.duoGreen
                                    : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(
                        delay: Duration(milliseconds: index * 30),
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Describe Yourself',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'Write a short bio (optional)',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  TextField(
                    controller: _bioController,
                    maxLines: 5,
                    maxLength: 150,
                    decoration: InputDecoration(
                      hintText:
                          'Tell others about yourself...\n\nExample: Love coffee ☕, late night chats 🌙, and good vibes ✨',
                      hintStyle: const TextStyle(color: AppTheme.textLight),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  const Text(
                    'Need inspiration? Try these:',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        [
                          '🎮 Gamer at heart',
                          '🎵 Music is life',
                          '📚 Bookworm',
                          '✈️ Travel addict',
                          '🎬 Movie buff',
                          '☕ Coffee lover',
                        ].map((template) {
                          return ActionChip(
                            label: Text(template),
                            onPressed: () {
                              if (_bioController.text.isNotEmpty) {
                                _bioController.text += '\n$template';
                              } else {
                                _bioController.text = template;
                              }
                              HapticFeedback.selectionClick();
                            },
                            backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
                            labelStyle: const TextStyle(
                              color: AppTheme.secondaryColor,
                              fontSize: 12,
                            ),
                          );
                        }).toList(),
                  ).animate().fadeIn(delay: 300.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Your Interests',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'Select at least one interest',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_selectedInterests.length} selected',
              style: const TextStyle(
                color: AppTheme.accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3,
              ),
              itemCount: _availableInterests.length,
              itemBuilder: (context, index) {
                final interest = _availableInterests[index];
                final isSelected = _selectedInterests.contains(interest);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedInterests.remove(interest);
                      } else {
                        _selectedInterests.add(interest);
                      }
                    });
                    HapticFeedback.selectionClick();
                  },
                  child:
                      Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.accentColor.withValues(alpha: 0.2)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.accentColor
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            interest,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppTheme.accentColor
                                  : AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ).animate().scale(
                        delay: Duration(milliseconds: index * 30),
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'How Are You Feeling?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ).animate().fadeIn().slideY(begin: 0.2, end: 0),
          const SizedBox(height: 8),
          Text(
            'Set your current mood',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 48),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.happyColor.withValues(alpha: 0.3),
                  AppTheme.excitedColor.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Center(
              child: Text(_selectedMood, style: const TextStyle(fontSize: 50)),
            ),
          ).animate().scale(duration: 300.ms, curve: Curves.elasticOut),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _moods.length,
              itemBuilder: (context, index) {
                final mood = _moods[index];
                final isSelected = mood == _selectedMood;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedMood = mood;
                    });
                    HapticFeedback.selectionClick();
                  },
                  child:
                      Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.happyColor.withValues(alpha: 0.2)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.happyColor
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            mood,
                            style: const TextStyle(fontSize: 28),
                          ),
                        ),
                      ).animate().scale(
                        delay: Duration(milliseconds: index * 20),
                        duration: 300.ms,
                        curve: Curves.easeOut,
                      ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '💡 You can change your mood anytime',
            style: TextStyle(color: AppTheme.textLight, fontSize: 14),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String value, String emoji, String label) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _previousStep,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 2,
                    ),
                  ),
                  child: const Text(
                    'Back',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              flex: _currentStep == 0 ? 1 : 2,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _currentStep < 6 ? 'Next' : 'Complete Setup',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Choose Custom Emoji',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  setState(() {
                    _selectedAvatar = emoji.emoji;
                  });
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                },
                config: const Config(
                  height: 256,
                  checkPlatformCompatibility: true,
                  emojiViewConfig: EmojiViewConfig(
                    columns: 7,
                    emojiSizeMax: 32,
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    gridPadding: EdgeInsets.zero,
                    recentsLimit: 28,
                    noRecents: Text(
                      'No Recents',
                      style: TextStyle(fontSize: 20, color: Colors.black26),
                      textAlign: TextAlign.center,
                    ),
                    loadingIndicator: SizedBox.shrink(),
                    buttonMode: ButtonMode.MATERIAL,
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    initCategory: Category.RECENT,
                    backgroundColor: Colors.white,
                    indicatorColor: AppTheme.primaryColor,
                    iconColor: Colors.grey,
                    iconColorSelected: AppTheme.primaryColor,
                    backspaceColor: AppTheme.primaryColor,
                    tabIndicatorAnimDuration: kTabScrollDuration,
                    categoryIcons: CategoryIcons(),
                  ),
                  skinToneConfig: SkinToneConfig(
                    dialogBackgroundColor: Colors.white,
                    indicatorColor: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: false,
      onSelect: (Country country) {
        setState(() {
          _selectedCountry = country.name;
          _selectedCountryFlag = country.flagEmoji;
        });
        HapticFeedback.selectionClick();
      },
      countryListTheme: CountryListThemeData(
        flagSize: 25,
        backgroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 16, color: Colors.black),
        bottomSheetHeight: 500,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        inputDecoration: InputDecoration(
          labelText: 'Search',
          hintText: 'Start typing to search',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: const Color(0xFF8C98A8).withValues(alpha: 0.2),
            ),
          ),
        ),
      ),
    );
  }
}
