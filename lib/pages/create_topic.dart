import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../helpers/routes.dart';
import '../services/firestore.dart';
import '../services/user_cache.dart';
import '../widgets/layout.dart';

class CreateTopicPage extends StatefulWidget {
  const CreateTopicPage({super.key});

  @override
  State<CreateTopicPage> createState() => _CreateTopicPageState();
}

class _CreateTopicPageState extends State<CreateTopicPage> {
  late ThemeData theme;
  late Firestore firestore;
  late UserCache userCache;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    firestore = context.read<Firestore>();
    userCache = context.read<UserCache>();
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

  Future<void> _submit() async {
    if (_isProcessing) return;

    if (_formKey.currentState!.validate()) {
      final user = userCache.user;
      if (user == null) return;

      setState(() => _isProcessing = true);

      try {
        final topic = await firestore.createTopic(
          user: user,
          title: _titleController.text.trim(),
          message: _messageController.text.trim(),
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
                                              color:
                                                  theme
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
                              child:
                                  _isProcessing
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
