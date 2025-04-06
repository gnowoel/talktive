import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/helpers.dart';
import '../../services/fireauth.dart';

class WelcomeStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback enableRestoreAccount;

  const WelcomeStep({
    super.key,
    required this.onNext,
    required this.enableRestoreAccount,
  });

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep> {
  bool _isProcessing = false;

  Future<void> _signInAnonymously() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final fireauth = context.read<Fireauth>();
      await fireauth.signInAnonymously();
      widget.onNext();
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

  Future<void> _restoreAccount() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      widget.enableRestoreAccount();
      widget.onNext();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👋', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 32),
          Text(
            'Welcome to Talktive',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Chat privately, connect freely, and your messages disappear after expiration.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Spread ❤️ and respect!',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          FilledButton(
            onPressed: _isProcessing ? null : _signInAnonymously,
            child: const Text('Get Started'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isProcessing ? null : _restoreAccount,
            child: const Text('Restore your account'),
          ),
        ],
      ),
    );
  }
}
