import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talktive_client/talktive_client.dart';
import '../../providers/group_provider.dart';
import '../../config/theme.dart';
import '../../helpers/snackbar_helper.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a group name'),
          backgroundColor: AppTheme.duoRed,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing ? 'Group updated!' : 'Group "$name" created!',
            ),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        SnackBarHelper.showError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
      ),
      child: DuoKeyboardDismissible(
        child: Container(
          padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.duoBlueGradient[0].withValues(alpha: 0.2),
                            AppTheme.duoBlueGradient[1].withValues(alpha: 0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('✨', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: AppTheme.duoSpacingMedium),
                    Expanded(
                      child: Text(
                        widget.existingGroup != null
                            ? 'Edit Group'
                            : 'Create Group',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.duoSpacingLarge),

                // Emoji selector
                Text(
                  'Choose an emoji',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.duoSpacingSmall),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _emojiOptions.map((emoji) {
                    final isSelected = emoji == _selectedEmoji;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _selectedEmoji = emoji;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.2)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(
                            AppTheme.duoRadiusSmall,
                          ),
                          border: isSelected
                              ? Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                )
                              : null,
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
                const SizedBox(height: AppTheme.duoSpacingLarge),

                // Group name
                Text(
                  'Group name',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.duoSpacingSmall),
                DuoInput(
                  controller: _nameController,
                  hintText: 'Enter group name',
                  maxLength: 50,
                ),
                const SizedBox(height: AppTheme.duoSpacingMedium),

                // Description
                Text(
                  'Description (optional)',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppTheme.duoSpacingSmall),
                DuoInput(
                  controller: _descriptionController,
                  hintText: 'What is this group about?',
                  maxLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: AppTheme.duoSpacingMedium),

                // Interests
                Text(
                  'Add Interest Tags',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
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
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
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
                const SizedBox(height: AppTheme.duoSpacingMedium),

                // Public/Private toggle
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Public group',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Anyone can discover and join',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isPublic,
                      onChanged: (value) {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _isPublic = value;
                        });
                      },
                      activeThumbColor: AppTheme.duoGreen,
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.duoSpacingMedium),

                // Max members slider
                Text(
                  'Max members: $_maxMembers',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: _maxMembers.toDouble(),
                  min: 2,
                  max: 500,
                  divisions: 49,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() {
                      _maxMembers = value.toInt();
                    });
                  },
                ),
                const SizedBox(height: AppTheme.duoSpacingLarge),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: DuoButton(
                    text: widget.existingGroup != null
                        ? 'Save Changes'
                        : 'Create Group',
                    onPressed: _isCreating ? null : _saveGroup,
                    isLoading: _isCreating,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
