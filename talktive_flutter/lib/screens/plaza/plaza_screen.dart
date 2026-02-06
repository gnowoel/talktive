import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class PlazaScreen extends ConsumerWidget {
  final VoidCallback onExit;

  const PlazaScreen({super.key, required this.onExit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth provider to get user info (floor, credits, etc.)
    // final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Plaza'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              // Sign out logic
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage(
              'https://placeholder.com/apartment_bg.png',
            ), // Placeholder
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          children: [
            // Top Status Bar (Credits, Floor)
            _buildStatusBar(ref),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Welcome to the Talktive Plaza',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.elevator),
                      label: const Text('Enter Elevator'),
                      onPressed: () {
                        // TODO: Open floor selection
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: onExit),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.people),
              onPressed: () {
                // TODO: Show residents list
              },
            ),
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {
                // Mock opening a general chat
                context.push('/chat/1', extra: 'General Plaza Chat');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.black.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              const Text(
                '100 Credits', // Mock data
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Lobby (Floor 0)', // Mock data
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
