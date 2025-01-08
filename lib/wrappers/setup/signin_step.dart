import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../helpers/helpers.dart';
import '../../services/fireauth.dart';

class SignInStep extends StatefulWidget {
  final VoidCallback onNext;

  const SignInStep({
    super.key,
    required this.onNext,
  });

  @override
  State<SignInStep> createState() => _SignInStepState();
}

class _SignInStepState extends State<SignInStep> {
  bool _isProcessing = false;

  Future<void> _signInWithGoogle() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final fireauth = context.read<Fireauth>();
      // TODO: implement Google sign-in
      await Future.delayed(const Duration(seconds: 1)); // Temporary
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🔐',
            style: TextStyle(fontSize: 64),
          ),
          const SizedBox(height: 32),
          Text(
            'Secure Your Data',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in to save your chat history and preferences. We only use your account to secure your data and don\'t share any personal information.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          FilledButton.icon(
            onPressed: _isProcessing ? null : _signInWithGoogle,
            icon: const Icon(Icons.login),
            label: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                    ),
                  )
                : const Text('Sign in with Google'),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _isProcessing ? null : _signInAnonymously,
            child: const Text('Continue without signing in'),
          ),
        ],
      ),
    );
  }
}
