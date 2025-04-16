import 'package:flutter/material.dart';

class TopicsPage extends StatelessWidget {
  const TopicsPage({super.key});

  void _showCreateTopicDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Shout'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter topic title...',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Handle create shout
                  if (controller.text.isNotEmpty) {
                    // Call createShout method
                    Navigator.pop(context);
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shared Topics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTopicDialog(context),
          ),
        ],
      ),
      body: const Center(child: Text('Shared Topics')),
    );
  }
}
