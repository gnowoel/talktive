import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../helpers/routes.dart';
import '../services/firestore.dart';
import '../services/user_cache.dart';

class CreateTopicPage extends StatefulWidget {
  const CreateTopicPage({super.key});

  @override
  State<CreateTopicPage> createState() => _CreateTopicPageState();
}

class _CreateTopicPageState extends State<CreateTopicPage> {
  late Firestore firestore;
  late UserCache userCache;
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    firestore = context.read<Firestore>();
    userCache = context.read<UserCache>();
  }

  Future<void> _createTopic() async {
    if (_isLoading) return;

    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      return;
    }

    final user = userCache.user;

    if (user == null) return;

    final userId = userCache.user?.id;
    final title = _titleController.text;
    final message = _messageController.text;

    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final topic = await firestore.createTopic(
        user: user,
        title: title,
        message: message,
      );
      final topicCreatedAt = topic.createdAt.toString();

      if (mounted) {
        context.go('/chats');
        context.push(encodeTopicRoute(topic.id, topicCreatedAt));
      }
    } on AppException catch (e) {
      if (mounted) {
        ErrorHandler.showSnackBarMessage(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start a Topic')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Topic Title',
              hintText: 'Enter a title for your topic...',
            ),
            maxLength: 100,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'First Message',
              hintText: 'Start the discussion...',
            ),
            maxLines: 3,
            maxLength: 500,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isLoading ? null : _createTopic,
            child:
                _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Create Topic'),
          ),
        ],
      ),
    );
  }
}
