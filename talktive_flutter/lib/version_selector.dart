import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app.dart';
import 'serverpod_app.dart';
import 'widgets/duo/duo_button.dart';
import 'helpers/duo_snackbar_helper.dart';
import 'legacy/helpers/helpers.dart';
import 'config/theme.dart';

enum AppVersion { firebase, serverpod }

enum SelectorState {
  loading,
  chooseUserType,
  chooseExistingMethod,
  enterRecoveryToken,
  chooseVersion,
  runAppFirebase,
  runAppServerpod,
}

class VersionSelector extends StatefulWidget {
  const VersionSelector({super.key});

  @override
  State<VersionSelector> createState() => _VersionSelectorState();
}

class _VersionSelectorState extends State<VersionSelector> {
  SelectorState _state = SelectorState.loading;
  final _tokenController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkInitialState();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialState() async {
    debugPrint('VersionSelector: _checkInitialState started');
    try {
      final prefs = await SharedPreferences.getInstance();
      final activeVersion = prefs.getString('active_app_version');

      if (activeVersion == AppVersion.serverpod.name) {
        debugPrint('VersionSelector: Found persistent version: Serverpod');
        if (mounted) setState(() => _state = SelectorState.runAppServerpod);
        return;
      }

      // New logic: Check the current Firebase user and their provider.
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        debugPrint(
          'VersionSelector: Current Firebase user found: ${currentUser.uid}',
        );
        final isGoogleUser = currentUser.providerData.any(
          (info) => info.providerId == 'google.com',
        );

        if (isGoogleUser) {
          debugPrint(
            'VersionSelector: Google user detected, defaulting to Serverpod',
          );
          // If signed in with Google, default to the new Serverpod version.
          await prefs.setString(
            'active_app_version',
            AppVersion.serverpod.name,
          );
          if (mounted) {
            setState(() => _state = SelectorState.runAppServerpod);
          }
        } else {
          debugPrint(
            'VersionSelector: Non-Google user detected, allowing version choice',
          );
          // If signed in anonymously or with email (Existing User), offer to choose version.
          if (mounted) {
            setState(() => _state = SelectorState.chooseVersion);
          }
        }
        return;
      }
      debugPrint('VersionSelector: No user found, showing user type choice');
    } catch (e) {
      debugPrint('VersionSelector: Error in _checkInitialState: $e');
    }

    if (mounted) setState(() => _state = SelectorState.chooseUserType);
    debugPrint(
      'VersionSelector: _checkInitialState finished. Current state: $_state',
    );
  }

  void _selectNewUser(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_app_version', AppVersion.serverpod.name);
      if (mounted) setState(() => _state = SelectorState.runAppServerpod);
    } catch (e) {
      debugPrint('VersionSelector: Error in _selectNewUser: $e');
      if (context.mounted) {
        DuoSnackBarHelper.showError(
          context,
          Exception('Failed to save preferences. Please try again.'),
        );
      }
    }
  }

  void _selectExistingUser() {
    if (mounted) setState(() => _state = SelectorState.chooseExistingMethod);
  }

  Future<void> _loginWithGoogle(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('active_app_version', AppVersion.serverpod.name);
      if (mounted) setState(() => _state = SelectorState.runAppServerpod);
    } catch (e) {
      debugPrint('VersionSelector: Error in _loginWithGoogle: $e');
      if (context.mounted) {
        DuoSnackBarHelper.showError(
          context,
          Exception('Failed to sign in with Google. Please try again.'),
        );
      }
    }
  }

  Future<void> _submitRecoveryToken(BuildContext context) async {
    final token = _tokenController.text.trim().toLowerCase();
    if (token.length != 20 || !RegExp(r'^[a-z0-9]+$').hasMatch(token)) {
      DuoSnackBarHelper.showError(context, Exception('Invalid token format'));
      return;
    }

    if (mounted) setState(() => _isProcessing = true);

    try {
      final recoveryToken = RecoveryToken.fromString(token);
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: recoveryToken.email,
        password: recoveryToken.password,
      );
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _state = SelectorState.chooseVersion;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      if (context.mounted) {
        DuoSnackBarHelper.showError(
          context,
          Exception('Failed to restore account. Please check your token.'),
        );
      }
    }
  }

  void _selectVersion(AppVersion version, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (version == AppVersion.serverpod) {
        await prefs.setString('active_app_version', version.name);
      } else {
        // Don't persist Firebase selection so user can choose to migrate later.
        await prefs.remove('active_app_version');
      }

      if (mounted) {
        setState(() {
          _state = version == AppVersion.firebase
              ? SelectorState.runAppFirebase
              : SelectorState.runAppServerpod;
        });
      }
    } catch (e) {
      debugPrint('VersionSelector: Error in _selectVersion: $e');
      if (context.mounted) {
        DuoSnackBarHelper.showError(
          context,
          Exception('Failed to save selection. Please try again.'),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == SelectorState.runAppFirebase) {
      return const App();
    } else if (_state == SelectorState.runAppServerpod) {
      return const ServerpodApp();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: AppTheme.lightBackground,
            appBar:
                _state == SelectorState.enterRecoveryToken ||
                    _state == SelectorState.chooseVersion
                ? AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (mounted) {
                          setState(() => _state = SelectorState.chooseUserType);
                        }
                      },
                    ),
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                  )
                : null,
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: _buildBody(context),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_state) {
      case SelectorState.loading:
        return const CircularProgressIndicator();
      case SelectorState.chooseUserType:
        return _buildChooseUserType(context);
      case SelectorState.chooseExistingMethod:
        return _buildChooseExistingMethod(context);
      case SelectorState.enterRecoveryToken:
        return _buildRecoveryToken(context);
      case SelectorState.chooseVersion:
        return _buildChooseVersion(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChooseUserType(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Text(
          '💬',
          style: TextStyle(fontSize: 80, color: AppTheme.primaryColor),
        ),
        const SizedBox(height: 24),
        const Text(
          'Talktive',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Anonymous Chat',
          style: TextStyle(fontSize: 16, color: AppTheme.textSecondary),
        ),
        const Spacer(),
        DuoButton(
          text: "I'm a New User",
          onPressed: () => _selectNewUser(context),
          width: double.infinity,
          size: DuoButtonSize.large,
        ),
        const SizedBox(height: 16),
        DuoButton(
          text: "I'm an Existing User",
          onPressed: _selectExistingUser,
          variant: DuoButtonVariant.secondary,
          width: double.infinity,
          size: DuoButtonSize.large,
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => _selectVersion(AppVersion.firebase, context),
            child: const Text(
              'Direct to Firebase (Debug Only)',
              style: TextStyle(
                color: AppTheme.textSecondary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildChooseExistingMethod(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('👋', style: TextStyle(fontSize: 80)),
        const SizedBox(height: 32),
        const Text(
          'Welcome Back!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'How would you like to sign in?',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        DuoButton(
          text: 'Continue with Google',
          onPressed: () => _loginWithGoogle(context),
          width: double.infinity,
          size: DuoButtonSize.large,
        ),
        const SizedBox(height: 16),
        DuoButton(
          text: 'Use Recovery Token',
          onPressed: () {
            if (mounted) {
              setState(() => _state = SelectorState.enterRecoveryToken);
            }
          },
          variant: DuoButtonVariant.secondary,
          width: double.infinity,
          size: DuoButtonSize.large,
        ),
        const SizedBox(height: 16),
        DuoButton(
          text: 'Back',
          onPressed: () {
            if (mounted) {
              setState(() => _state = SelectorState.chooseUserType);
            }
          },
          variant: DuoButtonVariant.ghost,
          width: double.infinity,
          size: DuoButtonSize.large,
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildRecoveryToken(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('🔑', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 32),
        const Text(
          'Welcome Back!',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Enter your recovery token to restore your account',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        TextField(
          controller: _tokenController,
          decoration: const InputDecoration(
            labelText: 'Recovery Token',
            hintText: 'Enter your 20-character token',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitRecoveryToken(context),
        ),
        const SizedBox(height: 32),
        DuoButton(
          text: 'Restore Account',
          onPressed: _isProcessing ? null : () => _submitRecoveryToken(context),
          isLoading: _isProcessing,
          width: double.infinity,
          size: DuoButtonSize.large,
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildChooseVersion(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('✅', style: TextStyle(fontSize: 80)),
        const SizedBox(height: 32),
        const Text(
          'Account Found',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Which version of Talktive would you like to run?',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        DuoButton(
          text: 'New Safer Version',
          onPressed: () => _selectVersion(AppVersion.serverpod, context),
          width: double.infinity,
          size: DuoButtonSize.large,
        ),
        const SizedBox(height: 16),
        DuoButton(
          text: 'Old Version',
          onPressed: () => _selectVersion(AppVersion.firebase, context),
          variant: DuoButtonVariant.secondary,
          width: double.infinity,
          size: DuoButtonSize.large,
        ),
        const Spacer(),
      ],
    );
  }
}
