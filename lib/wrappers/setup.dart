import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/fireauth.dart';
import '../theme.dart';
import 'setup/notification_step.dart';
import 'setup/profile_step.dart';
// import 'setup/signin_step.dart';
import 'setup/welcome_step.dart';

class Setup extends StatefulWidget {
  final Widget child;

  const Setup({super.key, required this.child});

  @override
  State<Setup> createState() => _SetupPageState();
}

class _SetupPageState extends State<Setup> {
  late Fireauth fireauth;

  int _currentStep = 0;
  final int _totalSteps = 3; // 4

  @override
  void initState() {
    super.initState();
    fireauth = context.read<Fireauth>();
    if (fireauth.hasSignedIn) {
      _currentStep = _totalSteps;
    }
  }

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
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
              Expanded(
                child: _buildCurrentStep(),
              ),
              _buildProgressDots(),
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
        return WelcomeStep(onNext: _nextStep);
      // case 1:
      //   return SignInStep(onNext: _nextStep);
      case 1:
        return ProfileStep(onNext: _nextStep);
      case 2:
        return NotificationStep(onNext: _nextStep);
      default:
        return widget.child;
    }
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalSteps, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentStep == index
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        );
      }),
    );
  }
}
