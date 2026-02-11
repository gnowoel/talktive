import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/group_provider.dart';
import '../../config/theme.dart';
import '../../widgets/duo/duo_button.dart';
import '../../widgets/duo/duo_input.dart';

class CreateGroupDialog extends ConsumerStatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  ConsumerState<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends ConsumerState<CreateGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedEmoji = '👥';
  bool _isPublic = false;
  int _maxMembers = 50;
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
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();

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
          );

      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Group "$name" created!'),
            backgroundColor: AppTheme.duoGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create group: $e'),
            backgroundColor: AppTheme.duoRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
      ),
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
                          AppTheme.duoOrange.withValues(alpha: 0.2),
                          AppTheme.duoYellow.withValues(alpha: 0.2),
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
                      'Create Group',
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
                            ? Border.all(color: AppTheme.primaryColor, width: 2)
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
                    activeColor: AppTheme.duoGreen,
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
                  text: 'Create Group',
                  onPressed: _isCreating ? null : _createGroup,
                  isLoading: _isCreating,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
