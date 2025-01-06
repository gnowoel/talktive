import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/settings.dart';
import 'setup/notification_step.dart';
import 'setup/profile_step.dart';
import 'setup/welcome_step.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      _redirectTo('/users');
    }
  }

  Future<void> _redirectTo(String uri) async {
    await Settings.setBool(Settings.hasCompletedSetup, true);
    if (mounted) context.go(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return WelcomeStep(onNext: _nextStep);
      case 1:
        return ProfileStep(onNext: _nextStep);
      case 2:
        return NotificationStep(onNext: _nextStep);
      default:
        return const SizedBox();
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
