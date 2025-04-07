import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/exception.dart';
import '../services/fireauth.dart';
import '../widgets/layout.dart';

class BackupAccountPage extends StatefulWidget {
  const BackupAccountPage({super.key});

  @override
  State<BackupAccountPage> createState() => _BackupAccountPageState();
}

class _BackupAccountPageState extends State<BackupAccountPage> {
  bool _isProcessing = false;
  String? _token;

  Future<void> _generateToken() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final fireauth = context.read<Fireauth>();

      if (fireauth.hasBackup) {
        setState(() => _token = fireauth.getStoredToken());
      } else {
        final token = await fireauth.createRecoveryToken();
        setState(() => _token = token.toString());
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

  Future<void> _showToken() async {
    final fireauth = context.read<Fireauth>();
    setState(() => _token = fireauth.getStoredToken());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fireauth = context.watch<Fireauth>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        title: const Text('Backup Account'),
      ),
      body: SafeArea(
        child: Layout(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon
                Text('🔐', style: theme.textTheme.displayLarge),
                const SizedBox(height: 32),

                // Title
                Text(
                  fireauth.hasBackup
                      ? 'Your Recovery Token'
                      : 'Create Recovery Token',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  fireauth.hasBackup
                      ? 'Keep this token safe to restore your account later'
                      : 'Save this token somewhere safe. You\'ll need it to restore your account if you reinstall the app.',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Token or Button
                if (_token != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _token!,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Copy and save this token!',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ] else if (!fireauth.hasBackup) ...[
                  FilledButton(
                    onPressed: _isProcessing ? null : _generateToken,
                    child:
                        _isProcessing
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                            : const Text('Generate Recovery Token'),
                  ),
                ] else ...[
                  FilledButton(
                    onPressed: _isProcessing ? null : _showToken,
                    child: const Text('Show Recovery Token'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
