import 'package:flutter/material.dart';
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
    final prefs = await SharedPreferences.getInstance();
    final activeVersion = prefs.getString('active_app_version');

    if (activeVersion == AppVersion.firebase.name) {
      if (mounted) setState(() => _state = SelectorState.runAppFirebase);
      return;
    } else if (activeVersion == AppVersion.serverpod.name) {
      if (mounted) setState(() => _state = SelectorState.runAppServerpod);
      return;
    }

    // New logic: If the user is already signed in with Google (from a previous session or installation),
    // skip the version selection and default to the new Serverpod version. 
    // This resolves the confusion where logged-in users felt forced to choose "New User" or "Existing User".
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      await prefs.setString('active_app_version', AppVersion.serverpod.name);
      if (mounted) {
        setState(() => _state = SelectorState.runAppServerpod);
      }
      return;
    }

    if (mounted) setState(() => _state = SelectorState.chooseUserType);
  }

  void _selectNewUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_app_version', AppVersion.serverpod.name);
    if (mounted) setState(() => _state = SelectorState.runAppServerpod);
  }

  void _selectExistingUser() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      setState(() => _state = SelectorState.chooseVersion);
    } else {
      setState(() => _state = SelectorState.enterRecoveryToken);
    }
  }

  Future<void> _submitRecoveryToken() async {
    final token = _tokenController.text.trim().toLowerCase();
    if (token.length != 20 || !RegExp(r'^[a-z0-9]+$').hasMatch(token)) {
      DuoSnackBarHelper.showError(context, Exception('Invalid token format'));
      return;
    }

    setState(() => _isProcessing = true);

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
      if (mounted) {
        setState(() => _isProcessing = false);
        DuoSnackBarHelper.showError(
            context, Exception('Failed to restore account. Please check your token.'));
      }
    }
  }

  void _selectVersion(AppVersion version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_app_version', version.name);
    
    if (mounted) {
      setState(() {
        _state = version == AppVersion.firebase
            ? SelectorState.runAppFirebase
            : SelectorState.runAppServerpod;
      });
    }
  }

  void _reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_app_version');
    if (mounted) {
      setState(() {
        _state = SelectorState.chooseUserType;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == SelectorState.runAppFirebase) {
      return const App();
    } else if (_state == SelectorState.runAppServerpod) {
      return ServerpodApp(onExit: _reset);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: AppTheme.lightBackground,
        appBar: _state == SelectorState.enterRecoveryToken || _state == SelectorState.chooseVersion
            ? AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (_state == SelectorState.chooseVersion) {
                        setState(() => _state = SelectorState.chooseUserType);
                    } else if (_state == SelectorState.enterRecoveryToken) {
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
              child: _buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_state) {
      case SelectorState.loading:
        return const CircularProgressIndicator();
      case SelectorState.chooseUserType:
        return _buildChooseUserType();
      case SelectorState.enterRecoveryToken:
        return _buildRecoveryToken();
      case SelectorState.chooseVersion:
        return _buildChooseVersion();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildChooseUserType() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        const Icon(Icons.chat_bubble_outline_rounded, size: 80, color: AppTheme.primaryColor),
        const SizedBox(height: 24),
        const Text(
          'Talktive',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 8),
        const Text('Anonymous Chat', style: TextStyle(fontSize: 16, color: AppTheme.textSecondary)),
        const Spacer(),
        DuoButton(
          text: "I'm a New User",
          onPressed: _selectNewUser,
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
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildRecoveryToken() {
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
          onSubmitted: (_) => _submitRecoveryToken(),
        ),
        const SizedBox(height: 32),
        DuoButton(
          text: 'Restore Account',
          onPressed: _isProcessing ? null : _submitRecoveryToken,
          isLoading: _isProcessing,
          width: double.infinity,
          size: DuoButtonSize.large,
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildChooseVersion() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.verified_user, size: 80, color: Colors.green),
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
          text: 'Anonymous Chat (New)',
          onPressed: () => _selectVersion(AppVersion.serverpod),
          width: double.infinity,
          size: DuoButtonSize.large,
        ),
        const SizedBox(height: 16),
        DuoButton(
          text: 'Old Version',
          onPressed: () => _selectVersion(AppVersion.firebase),
          variant: DuoButtonVariant.secondary,
          width: double.infinity,
          size: DuoButtonSize.large,
        ),
        const Spacer(),
      ],
    );
  }
}
