import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../helpers/helpers.dart';
import '../services/fireauth.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  String? _validateToken(String? value) {
    value = value?.trim().toLowerCase();
    if (value == null || value.isEmpty) {
      return 'Please enter your recovery token';
    }
    // _emailLength + _passwordLength
    if (value.length != 16) {
      return 'Invalid token length';
    }
    if (!RegExp(r'^[0-9][a-z0-9]+$').hasMatch(value)) {
      return 'Invalid token format';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isProcessing) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);

      try {
        final fireauth = context.read<Fireauth>();
        await fireauth.signInWithToken(_tokenController.text.trim());

        if (mounted) {
          context.go('/users');
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Restore Account')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('🔑', style: theme.textTheme.displayLarge),
              const SizedBox(height: 32),
              Text(
                'Welcome Back!',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Enter your recovery token to restore your account',
                style: theme.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Recovery Token',
                  hintText: 'Enter your token',
                ),
                validator: _validateToken,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isProcessing ? null : _submit,
                child:
                    _isProcessing
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 3),
                        )
                        : const Text('Restore Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
