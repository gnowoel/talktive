import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../helpers/exception.dart';

import '../models/tribe.dart';
import '../services/firestore.dart';

import '../services/tribe_cache.dart';
import '../services/user_cache.dart';
import '../services/ad_service/go_router_room_helper.dart';
import '../widgets/layout.dart';

class CreateTopicPage extends StatefulWidget {
  final String? initialTribeId;

  const CreateTopicPage({super.key, this.initialTribeId});

  @override
  State<CreateTopicPage> createState() => _CreateTopicPageState();
}

class _CreateTopicPageState extends State<CreateTopicPage> {
  late ThemeData theme;
  late Firestore firestore;
  late UserCache userCache;
  late TribeCache tribeCache;

  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _tribeController = TextEditingController();
  final _tribeFocusNode = FocusNode();

  bool _isProcessing = false;
  bool _isPublic = true;

  List<Tribe> _predefinedTribes = [];
  Tribe? _selectedTribe;

  @override
  void initState() {
    super.initState();

    firestore = context.read<Firestore>();
    userCache = context.read<UserCache>();
    tribeCache = context.read<TribeCache>();

    // Prefill message field with user's description
    final currentUser = userCache.user;
    if (currentUser?.description != null && currentUser!.description!.isNotEmpty) {
      _messageController.text = currentUser.description!;
    }

    _loadTribes();

    if (widget.initialTribeId != null) {
      _setInitialTribe();
    }

    _messageController.addListener(_onContentChanged);
  }

  Future<void> _loadTribes() async {
    await tribeCache.fetchTribes();
    if (!mounted) return;
    setState(() {
      _predefinedTribes = tribeCache.predefinedTribes;
      // Set "Friend Finder" as default (first entry)
      if (_predefinedTribes.isNotEmpty && _selectedTribe == null) {
        _selectedTribe = _predefinedTribes.first;
      }
    });
  }

  Future<void> _setInitialTribe() async {
    await tribeCache.fetchTribes();
    final tribe = tribeCache.getTribeById(widget.initialTribeId!);
    if (tribe != null && mounted) {
      setState(() {
        _selectedTribe = tribe;
        _tribeController.text = tribe.name;
      });
    }
  }

  // No longer needed with the new UI

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onContentChanged);
    _messageController.dispose();
    _tribeController.dispose();
    _tribeFocusNode.dispose();
    super.dispose();
  }



  String? _validateMessage(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) {
      return 'Please enter a message';
    }
    if (value.length < 10) {
      return 'Message must be at least 10 characters';
    }
    return null;
  }

  String? _validateTribe(Tribe? value) {
    if (value == null) {
      return 'Please select a category';
    }
    return null;
  }

  void _selectTribe(Tribe tribe) {
    setState(() {
      _selectedTribe = tribe;
      _tribeController.text = tribe.name;
    });
  }

  void _onContentChanged() {
    // Content validation can be added here if needed
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final user = userCache.user;
      if (user == null) return;

      if (!mounted) return;
      setState(() => _isProcessing = true);

      try {
        final topic = await firestore.createTopic(
          user: user,
          title: user.displayName ?? 'Moment',
          message: _messageController.text.trim(),
          tribeId: _selectedTribe?.id,
          isPublic: _isPublic,
        );

        if (mounted) {
          await context.goToTopic(topic.id, topic.creator.id);
        }
      } on AppException catch (e) {
        if (mounted) {
          ErrorHandler.showSnackBarMessage(context, e);
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Share a Moment'),
      ),
      body: SafeArea(
        child: Layout(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 64,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 32),
                            buildAboutTopics(),
                            // buildTopicVisibility(),
                            const SizedBox(height: 32),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _messageController,
                                        decoration: const InputDecoration(
                                          labelText: 'Current Status',
                                          hintText: 'What would you like to share with us at the moment?',
                                        ),
                                        validator: _validateMessage,
                                        minLines: 3,
                                        maxLines: 6,
                                        maxLength: 500,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      onPressed: () {
                                        _messageController.clear();
                                      },
                                      icon: const Icon(Icons.clear),
                                      tooltip: 'Clear text',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<Tribe>(
                                  value: _selectedTribe,
                                  decoration: const InputDecoration(
                                    hintText: 'Select a category',
                                  ),
                                  validator: _validateTribe,
                                  items: _predefinedTribes.map((tribe) {
                                    return DropdownMenuItem<Tribe>(
                                      value: tribe,
                                      child: Row(
                                        children: [
                                          Text(
                                            tribe.iconEmoji ?? '🏷️',
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(tribe.name),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (Tribe? newTribe) {
                                    if (newTribe != null) {
                                      _selectTribe(newTribe);
                                    }
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 32),
                            FilledButton(
                              onPressed: _isProcessing ? null : _submit,
                              child: _isProcessing
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                      ),
                                    )
                                  : const Text('Create Moment'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget buildAboutTopics() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'About Moments',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your moment will be public for a limited time before becoming private. Your followers will be notified automatically.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTopicVisibility() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.visibility,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Topic Visibility',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _isPublic = true),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isPublic
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.5,
                            )
                          : theme.colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _isPublic,
                          onChanged: (value) =>
                              setState(() => _isPublic = true),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🌍 Public Topic',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Appears on Moments tab for everyone to join',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                InkWell(
                  onTap: () => setState(() => _isPublic = false),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8),
                    bottomRight: Radius.circular(8),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: !_isPublic
                          ? theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.5,
                            )
                          : theme.colorScheme.surfaceContainerLow,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: false,
                          groupValue: _isPublic,
                          onChanged: (value) =>
                              setState(() => _isPublic = false),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '🔒 Private Topic',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Only visible to your followers',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'All your followers will be notified when you create any moment.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
