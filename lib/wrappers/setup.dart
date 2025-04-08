import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/fireauth.dart';
import '../services/settings.dart';
import '../theme.dart';
import 'setup/notification_step.dart';
import 'setup/profile_step.dart';
import 'setup/signin_step.dart';
import 'setup/welcome_step.dart';

class Setup extends StatefulWidget {
  final Widget child;

  const Setup({super.key, required this.child});

  @override
  State<Setup> createState() => _SetupPageState();
}

class _SetupPageState extends State<Setup> {
  late Fireauth fireauth;
  late Settings settings;

  int _currentStep = 0;
  final int _totalSteps = 3; // 4
  bool _restoreAccount = false;

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    settings = context.read<Settings>();

    if (!fireauth.hasSignedIn) {
      settings.clearSetupCompletion();
    }

    if (fireauth.hasSignedIn && settings.hasCompletedSetup) {
      _currentStep = _totalSteps; // Skip setup
    }
  }

  void _nextStep() {
    if (_currentStep == _totalSteps - 1) {
      settings.markSetupComplete(); // No wait
    }
    setState(() {
      _currentStep++;
    });
  }

  void _enableRestoreAccount() {
    setState(() => _restoreAccount = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep >= _totalSteps) {
      return _buildCurrentStep(); // widget.child
    }

    return MaterialApp(
      theme: getTheme(context),
      home: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(child: _buildCurrentStep()),
              Builder(
                builder: (context) {
                  return _buildProgressDots(context);
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return WelcomeStep(
          onNext: _nextStep,
          enableRestoreAccount: _enableRestoreAccount,
        );
      // case 1:
      //   return SignInStep(onNext: _nextStep);
      case 1:
        return _restoreAccount
            ? SigninStep(onNext: _nextStep)
            : ProfileStep(onNext: _nextStep);
      case 2:
        return NotificationStep(onNext: _nextStep);
      default:
        return widget.child;
    }
  }

  Widget _buildProgressDots(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                _currentStep == index
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
          ),
        );
      }),
    );
  }
}
