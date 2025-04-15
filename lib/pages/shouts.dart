import 'package:flutter/material.dart';

class ShoutsPage extends StatelessWidget {
  const ShoutsPage({super.key});

  void _showCreateShoutDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Shout'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Topic',
                hintText: 'Enter shout topic...',
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
        title: const Text('Public Shouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateShoutDialog(context),
          ),
        ],
      ),
      body: const Center(child: Text('Public Shouts')),
    );
  }
}
