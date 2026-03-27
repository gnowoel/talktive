import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/lounge_provider.dart';
import '../../config/theme.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import 'package:country_picker/country_picker.dart';
import '../../config/languages.dart';
import '../../config/interests.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_input.dart';
import '../../widgets/duo/duo_keyboard_dismissible.dart';

class CreateLoungeDialog extends ConsumerStatefulWidget {
  final Lounge? existingLounge;

  const CreateLoungeDialog({super.key, this.existingLounge});

  @override
  ConsumerState<CreateLoungeDialog> createState() => _CreateLoungeDialogState();
}

class _CreateLoungeDialogState extends ConsumerState<CreateLoungeDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rulesController = TextEditingController();
  String _selectedEmoji = '👥';
  bool _isPublic = true;
  int _maxMembers = 50;
  List<String> _selectedInterests = [];
  List<String> _selectedLanguages = ['en'];
  String _selectedCountry = 'Unknown';
  String _selectedCountryFlag = '🌍';
  bool _isCreating = false;

  final List<String> _emojiOptions = [
    '👥',
    '🎮',
    '🎨',
    '🎵',
    '📚',
    '💻',
    '🏀',
    '🍕',
    '🌍',
    '🚀',
    '💡',
    '🎯',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingLounge != null) {
      final g = widget.existingLounge!;
      _nameController.text = g.name;
      _descriptionController.text = g.description ?? '';
      _selectedEmoji = g.emoji ?? '👥';
      _isPublic = g.isPublic;
      _maxMembers = g.maxMembers;
      _selectedInterests = List<String>.from(g.interests ?? []);
      _selectedLanguages = List<String>.from(g.languages ?? ['en']);
      _selectedCountry = g.country ?? 'Unknown';
      _rulesController.text = g.rules ?? '';
      // Attempt to find flag if country is known
      if (_selectedCountry != 'Unknown') {
        try {
          final c = CountryParser.parseCountryCode(_selectedCountry);
          _selectedCountryFlag = c.flagEmoji;
        } catch (_) {
          _selectedCountryFlag = '🌍';
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _saveLounge() async {
    final name = _nameController.text.trim();
    final isEditing = widget.existingLounge != null;

    if (name.isEmpty) {
      DuoSnackBarHelper.showError(context, 'Please enter a lounge name');
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      if (isEditing) {
        await ref
            .read(loungeListProvider.notifier)
            .updateLounge(
              widget.existingLounge!.id!,
              name: name,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              emoji: _selectedEmoji,
              isPublic: _isPublic,
              maxMembers: _maxMembers,
              interests: _selectedInterests.isEmpty ? null : _selectedInterests,
              languages: _selectedLanguages,
              country: _selectedCountry == 'Unknown' ? null : _selectedCountry,
              rules: _rulesController.text.trim().isEmpty
                  ? null
                  : _rulesController.text.trim(),
            );
      } else {
        await ref
            .read(loungeListProvider.notifier)
            .createLounge(
              name,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              emoji: _selectedEmoji,
              isPublic: _isPublic,
              maxMembers: _maxMembers,
              interests: _selectedInterests.isEmpty ? null : _selectedInterests,
              languages: _selectedLanguages,
              country: _selectedCountry == 'Unknown' ? null : _selectedCountry,
              rules: _rulesController.text.trim().isEmpty
                  ? null
                  : _rulesController.text.trim(),
            );
      }

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        if (isEditing) {
          DuoSnackBarHelper.showSuccess(context, 'Lounge updated!');
        } else {
          DuoSnackBarHelper.showSuccess(context, 'Lounge "$name" created!');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        DuoSnackBarHelper.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DuoKeyboardDismissible(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.duoRadiusLarge),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.duoSpacingLarge,
                vertical: AppTheme.duoSpacingMedium,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: AppTheme.duoBlueGradient,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.duoRadiusLarge),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: AppTheme.duoSpacingSmall),
                    Expanded(
                      child: Text(
                        widget.existingLounge != null
                            ? 'Edit Lounge'
                            : 'Create New Lounge',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Emoji Section
                    _buildSectionHeader(
                      'Emoji',
                      'Pick an icon for your lounge',
                    ),
                    const SizedBox(height: AppTheme.duoSpacingSmall),
                    Center(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _emojiOptions.map((emoji) {
                          final isSelected = emoji == _selectedEmoji;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setState(() => _selectedEmoji = emoji);
                            },
                            child: AnimatedContainer(
                              duration: 150.ms,
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.duoBlue.withValues(alpha: 0.2)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(
                                  AppTheme.duoRadiusMedium,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.duoBlue
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),

                    // Name Section
                    _buildSectionHeader('Lounge Name', 'Give it a catchy name'),
                    const SizedBox(height: AppTheme.duoSpacingSmall),
                    DuoInput(
                      controller: _nameController,
                      hintText: 'e.g. Pixel Artists, Morning Coffee...',
                      maxLength: 50,
                      enabled: !_isCreating,
                    ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),

                    // Description Section
                    _buildSectionHeader('Description', 'What happens here?'),
                    const SizedBox(height: AppTheme.duoSpacingSmall),
                    DuoInput(
                      controller: _descriptionController,
                      hintText: 'Share what makes this lounge special...',
                      maxLines: 3,
                      maxLength: 200,
                      enabled: !_isCreating,
                    ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),

                    // House Rules Section (NEW)
                    _buildSectionHeader(
                      'House Rules',
                      'Behavioral guidelines ✋',
                    ),
                    const SizedBox(height: AppTheme.duoSpacingSmall),
                    DuoInput(
                      controller: _rulesController,
                      hintText: 'e.g. Respect others, No SPAM, Have fun!',
                      maxLines: 4,
                      maxLength: 1000,
                      enabled: !_isCreating,
                    ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),

                    // Interests Section
                    _buildSectionHeader('Interests', 'Help others find you'),
                    const SizedBox(height: AppTheme.duoSpacingSmall),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: AppInterests.all.map((interest) {
                        final isSelected = _selectedInterests.contains(
                          interest,
                        );
                        return FilterChip(
                          label: Text(
                            interest,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: _isCreating
                              ? null
                              : (selected) {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    if (selected) {
                                      if (_selectedInterests.length < 5) {
                                        _selectedInterests.add(interest);
                                      }
                                    } else {
                                      _selectedInterests.remove(interest);
                                    }
                                  });
                                },
                          selectedColor: AppTheme.duoBlue,
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),

                    // Country Section
                    _buildSectionHeader(
                      'Region',
                      'Specify the country for this lounge',
                    ),
                    const SizedBox(height: AppTheme.duoSpacingSmall),
                    InkWell(
                      onTap: () {
                        showCountryPicker(
                          context: context,
                          onSelect: (Country country) {
                            setState(() {
                              _selectedCountry = country.countryCode;
                              _selectedCountryFlag = country.flagEmoji;
                            });
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(
                          AppTheme.duoSpacingMedium,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(
                            AppTheme.duoRadiusMedium,
                          ),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Row(
                          children: [
                            Text(
                              _selectedCountryFlag,
                              style: const TextStyle(fontSize: 22),
                            ),
                            const SizedBox(width: AppTheme.duoSpacingMedium),
                            Expanded(
                              child: Text(
                                _selectedCountry == 'Unknown'
                                    ? 'Select Country'
                                    : _selectedCountry,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),

                    // Languages Section
                    _buildSectionHeader(
                      'Languages',
                      'Which languages are spoken here?',
                    ),
                    const SizedBox(height: AppTheme.duoSpacingSmall),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: AppLanguages.all.map((lang) {
                        final code = lang['code']!;
                        final name = lang['name']!;
                        final flag = lang['flag']!;
                        final isSelected = _selectedLanguages.contains(code);
                        return FilterChip(
                          label: Text(
                            '$flag $name',
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: _isCreating
                              ? null
                              : (selected) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    if (selected) {
                                      _selectedLanguages.add(code);
                                    } else {
                                      if (_selectedLanguages.length > 1) {
                                        _selectedLanguages.remove(code);
                                      }
                                    }
                                  });
                                },
                          selectedColor: AppTheme.duoBlue,
                          checkmarkColor: Colors.white,
                          backgroundColor: Colors.grey[100],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide.none,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),

                    // Visibility Section
                    _buildSectionHeader('Public Lounge', 'Discoverability'),
                    const SizedBox(height: AppTheme.duoSpacingSmall),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(
                          AppTheme.duoRadiusMedium,
                        ),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _isPublic ? '🌍' : '🔒',
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: AppTheme.duoSpacingMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isPublic ? 'Visible' : 'Hidden',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _isPublic
                                      ? 'Anyone can find and apply to join.'
                                      : 'Only invited members can join.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isPublic,
                            activeThumbColor: AppTheme.duoBlue,
                            onChanged:
                                (_isCreating ||
                                    (widget.existingLounge?.isStaffLocked ??
                                        false))
                                ? null
                                : (val) {
                                    HapticFeedback.lightImpact();
                                    setState(() => _isPublic = val);
                                  },
                          ),
                        ],
                      ),
                    ),
                    if (widget.existingLounge?.isStaffLocked ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Row(
                          children: [
                            const Text('🛡️', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'This lounge visibility is locked by an administrator.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.duoRed,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),

                    // Max Members / Capacity Section (Redesigned)
                    _buildSectionHeader(
                      'Capacity',
                      'Total member limit for this lounge',
                    ),
                    const SizedBox(height: AppTheme.duoSpacingSmall),
                    Container(
                      padding: const EdgeInsets.all(AppTheme.duoSpacingMedium),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(
                          AppTheme.duoRadiusMedium,
                        ),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        children: [
                          const Text('📈', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: AppTheme.duoSpacingMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Limit: $_maxMembers members',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  widget.existingLounge == null
                                      ? 'New lounges start with 50 seats. Increase your Lounge Level for more!'
                                      : 'Lounge Level ${widget.existingLounge?.level ?? 1}. Level up to expand!',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),

                    // Bottom Padding for FAB safety
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // Action Button
            Padding(
              padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
              child: SafeArea(
                top: false,
                child: DuoButton(
                  width: double.infinity,
                  text: widget.existingLounge != null
                      ? 'Save Changes'
                      : 'Create Lounge',
                  emoji: widget.existingLounge != null ? '💾' : '➕',
                  onPressed: _isCreating ? null : _saveLounge,
                  isLoading: _isCreating,
                  color: AppTheme.duoBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(
      begin: 1.0,
      end: 0.0,
      duration: 400.ms,
      curve: Curves.easeOutCubic,
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.duoBlue,
          ),
        ),
        Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        const SizedBox(height: 4),
      ],
    );
  }
}
