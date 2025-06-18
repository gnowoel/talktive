import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/fireauth.dart';
import '../services/settings.dart';
import '../theme.dart';

class WhatsNew extends StatefulWidget {
  final Widget child;

  const WhatsNew({super.key, required this.child});

  @override
  State<WhatsNew> createState() => _WhatsNewState();
}

class _WhatsNewState extends State<WhatsNew> {
  late Fireauth fireauth;
  late Settings settings;

  bool _shouldShow = false;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    settings = context.read<Settings>();

    if (fireauth.hasSignedIn && settings.shouldShowWhatnew) {
      _shouldShow = true;
    }
  }

  void _continue() async {
    await settings.saveWhatsNewVersion();
    setState(() => _shouldShow = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) {
      return widget.child;
    }

    return MaterialApp(
      theme: getTheme(context),
      home: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 32),
                          Text(
                            "What's New",
                            style: Theme.of(context).textTheme.headlineMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          _buildFeatureCard(
                            Theme.of(context),
                            '🛡️ Enhanced Safety',
                            'Introduced a comprehensive message-based reporting and moderation system to keep everyone safe.',
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureCard(
                            Theme.of(context),
                            '👥 Group Chats Return',
                            'Re-enabled group chat functionality with improved moderation and organized categories.',
                          ),
                          const SizedBox(height: 16),
                          _buildFeatureCard(
                            Theme.of(context),
                            '⚡ Performance Boost',
                            'Optimized app performance by hiding read messages by default and added pull-to-refresh support.',
                          ),
                          const SizedBox(height: 48),
                          FilledButton(
                            onPressed: _continue,
                            child: const Text('Continue'),
                          ),
                        ],
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

Widget _buildFeatureCard(ThemeData theme, String title, String description) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      ],
    ),
  );
}
