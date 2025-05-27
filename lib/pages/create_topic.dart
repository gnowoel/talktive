import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../helpers/routes.dart';
import '../models/tribe.dart';
import '../services/firestore.dart';
import '../services/tribe_cache.dart';
import '../services/user_cache.dart';
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
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _tribeController = TextEditingController();
  final _tribeFocusNode = FocusNode();
  bool _isProcessing = false;
  bool _isCreatingTribe = false;

  List<Tribe> _filteredTribes = [];
  Tribe? _selectedTribe;
  bool _showTribeList = false;

  @override
  void initState() {
    super.initState();
    firestore = context.read<Firestore>();
    userCache = context.read<UserCache>();
    tribeCache = context.read<TribeCache>();
    _loadTribes();
    _tribeFocusNode.addListener(_onTribeFocusChange);

    if (widget.initialTribeId != null) {
      _setInitialTribe();
    }
  }

  Future<void> _loadTribes() async {
    await tribeCache.fetchTribes();
    setState(() {
      _filteredTribes = tribeCache.tribes;
    });
  }

  Future<void> _setInitialTribe() async {
    await tribeCache.fetchTribes();
    final tribe = tribeCache.getTribeById(widget.initialTribeId!);
    if (tribe != null) {
      setState(() {
        _selectedTribe = tribe;
        _tribeController.text = tribe.name;
      });
    }
  }

  void _onTribeFocusChange() {
    if (_tribeFocusNode.hasFocus) {
      setState(() {
        _showTribeList = true;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _tribeController.dispose();
    _tribeFocusNode.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) {
      return 'Please enter a title';
    }
    if (value.length < 3) {
      return 'Title must be at least 3 characters';
    }
    return null;
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

  String? _validateTribe(String? value) {
    value = value?.trim();
    if (value == null || value.isEmpty) {
      return 'Please select or create a tribe';
    }
    return null;
  }

  void _filterTribes(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredTribes = tribeCache.tribes;
      });
      return;
    }

    setState(() {
      _filteredTribes = tribeCache.searchTribes(query);
    });
  }

  void _selectTribe(Tribe tribe) {
    setState(() {
      _selectedTribe = tribe;
      _tribeController.text = tribe.name;
      _showTribeList = false;
    });
  }

  Future<void> _createNewTribe() async {
    final tribeName = _tribeController.text.trim();
    if (tribeName.isEmpty) return;

    setState(() {
      _isCreatingTribe = true;
    });

    try {
      final tribe = await tribeCache.createTribe(tribeName);
      setState(() {
        _selectedTribe = tribe;
        _showTribeList = false;
      });
    } catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(
          context,
          e is AppException ? e : AppException(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingTribe = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_isProcessing) return;

    if (_formKey.currentState!.validate()) {
      final user = userCache.user;
      if (user == null) return;

      setState(() => _isProcessing = true);

      try {
        // If tribe doesn't exist but has a name, create it first
        if (_selectedTribe == null && _tribeController.text.trim().isNotEmpty) {
          await _createNewTribe();
        }

        final topic = await firestore.createTopic(
          user: user,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
          tribeId: _selectedTribe?.id,
        );

        if (mounted) {
          context.go('/chats');
          context.push(encodeTopicRoute(topic.id, topic.creator.id));
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
        title: const Text('Start a Topic'),
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
                              Icons.campaign,
                              size: 64,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: 48),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
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
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'About Topics',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your topic will be visible to everyone in the Topics tab. All your followers will be notified when you create it.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                            TextFormField(
                              controller: _tribeController,
                              focusNode: _tribeFocusNode,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                hintText: 'Search or create a category',
                                suffixIcon: _selectedTribe != null
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          setState(() {
                                            _selectedTribe = null;
                                            _tribeController.clear();
                                          });
                                        },
                                      )
                                    : null,
                              ),
                              validator: _validateTribe,
                              onChanged: _filterTribes,
                              onTap: () {
                                setState(() {
                                  _showTribeList = true;
                                });
                              },
                            ),
                            if (_showTribeList) ...[
                              const SizedBox(height: 8),
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 200,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: theme.colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _filteredTribes.isEmpty
                                    ? ListTile(
                                        title: Text(
                                          'Create "${_tribeController.text.trim()}"',
                                        ),
                                        leading: const Icon(Icons.add),
                                        onTap: _isCreatingTribe
                                            ? null
                                            : _createNewTribe,
                                        trailing: _isCreatingTribe
                                            ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                            : null,
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: _filteredTribes.length,
                                        itemBuilder: (context, index) {
                                          final tribe = _filteredTribes[index];
                                          return ListTile(
                                            title: Text(tribe.name),
                                            subtitle: tribe.description != null
                                                ? Text(
                                                    tribe.description!,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  )
                                                : null,
                                            leading: Text(
                                              tribe.iconEmoji ?? '🏷️',
                                              style: const TextStyle(
                                                fontSize: 24,
                                              ),
                                            ),
                                            onTap: () => _selectTribe(tribe),
                                          );
                                        },
                                      ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Topic Title',
                                hintText: 'What would you like to discuss?',
                              ),
                              validator: _validateTitle,
                              maxLength: 100,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _messageController,
                              decoration: const InputDecoration(
                                labelText: 'First Message',
                                hintText: 'Start the conversation...',
                              ),
                              validator: _validateMessage,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: 500,
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
                                  : const Text('Create Topic'),
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
}
