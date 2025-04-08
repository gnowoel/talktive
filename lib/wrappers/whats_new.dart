import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/fireauth.dart';
import '../services/settings.dart';

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

    if (fireauth.hasSignedIn && !settings.hasSeenWhatsNew) {
      _shouldShow = true;
    }
  }

  void _continue() async {
    await settings.setSeenWhatsNewVersion();
    setState(() => _shouldShow = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) {
      return widget.child;
    }

    final theme = Theme.of(context);

    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('✨', style: TextStyle(fontSize: 64)),
                const SizedBox(height: 32),
                Text(
                  "What's New in Talktive",
                  style: theme.textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildFeatureCard(
                  theme,
                  '🔑 Account Recovery',
                  'Now you can restore your account after reinstalling the app using a recovery token. Generate your token from Profile > Generate Recovery Token.',
                ),
                const SizedBox(height: 16),
                _buildFeatureCard(
                  theme,
                  '🐛 Bug Fixes',
                  'Various improvements and bug fixes to enhance your chat experience.',
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
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
        ),
      ],
    ),
  );
}
