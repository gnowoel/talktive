import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../services/user_cache.dart';

class CreateTopicPage extends StatefulWidget {
  const CreateTopicPage({super.key});

  @override
  State<CreateTopicPage> createState() => _CreateTopicPageState();
}

class _CreateTopicPageState extends State<CreateTopicPage> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  Future<void> _createTopic() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('createTopic');

      final result = await callable.call({
        'userId': context.read<UserCache>().user!.id,
        'title': _titleController.text,
        'message': _messageController.text,
      });

      if (result.data['success'] == true) {
        if (mounted) {
          context.go('/topics');
        }
      } else {
        throw AppException(result.data['error'] ?? 'Failed to create topic');
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
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
