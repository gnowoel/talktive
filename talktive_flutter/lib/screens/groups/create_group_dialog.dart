import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/group_provider.dart';
import '../../config/theme.dart';
import 'package:talktive/helpers/duo_snackbar_helper.dart';
import '../../config/interests.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_input.dart';
import '../../widgets/duo/duo_keyboard_dismissible.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  final Group? existingGroup;

  const CreateGroupDialog({super.key, this.existingGroup});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedEmoji = '👥';
  bool _isPublic = false;
  int _maxMembers = 50;
  List<String> _selectedInterests = [];
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
    if (widget.existingGroup != null) {
      final g = widget.existingGroup!;
      _nameController.text = g.name;
      _descriptionController.text = g.description ?? '';
      _selectedEmoji = g.emoji ?? '👥';
      _isPublic = g.isPublic;
      _maxMembers = g.maxMembers;
      _selectedInterests = List<String>.from(g.interests ?? []);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    final name = _nameController.text.trim();
    final isEditing = widget.existingGroup != null;

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
            .read(groupListProvider.notifier)
            .updateGroup(
              widget.existingGroup!.id!,
              name: name,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              emoji: _selectedEmoji,
              isPublic: _isPublic,
              maxMembers: _maxMembers,
              interests: _selectedInterests.isEmpty ? null : _selectedInterests,
            );
      } else {
        await ref
            .read(groupListProvider.notifier)
            .createGroup(
              name,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              emoji: _selectedEmoji,
              isPublic: _isPublic,
              maxMembers: _maxMembers,
              interests: _selectedInterests.isEmpty ? null : _selectedInterests,
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
        height: MediaQuery.of(context).size.height * 0.9,
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
              padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
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
                        widget.existingGroup != null
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
                      icon: const Icon(Icons.close, color: Colors.white),
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
                    _buildSectionHeader('Emoji', 'Pick an icon for your lounge'),
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
                              width: 56,
                              height: 56,
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

                    // Interests Section
                    _buildSectionHeader('Interests', 'Help others find you'),
                    const SizedBox(height: AppTheme.duoSpacingSmall),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: AppInterests.all.map((interest) {
                        final isSelected = _selectedInterests.contains(interest);
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

                    // Visibility Section
                    _buildSectionHeader('Public Group', 'Discoverability'),
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
                          Icon(
                            _isPublic ? Icons.public : Icons.public_off,
                            color: _isPublic ? AppTheme.duoBlue : Colors.grey,
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
                            onChanged: _isCreating
                                ? null
                                : (val) {
                                    HapticFeedback.lightImpact();
                                    setState(() => _isPublic = val);
                                  },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppTheme.duoSpacingLarge),

                    // Max Members Section
                    _buildSectionHeader(
                      'Capacity',
                      'Max members: $_maxMembers',
                    ),
                    Slider(
                      value: _maxMembers.toDouble(),
                      min: 2,
                      max: 500,
                      divisions: 49,
                      activeColor: AppTheme.duoBlue,
                      onChanged: _isCreating
                          ? null
                          : (value) {
                              setState(() => _maxMembers = value.toInt());
                            },
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
                  text: widget.existingGroup != null
                      ? 'Save Changes'
                      : 'Create Lounge',
                  icon:
                      widget.existingGroup != null ? Icons.save : Icons.add_circle,
                  onPressed: _isCreating ? null : _saveGroup,
                  isLoading: _isCreating,
                  color: AppTheme.duoBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().slideY(begin: 1.0, end: 0.0, duration: 400.ms, curve: Curves.easeOutCubic);
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
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
