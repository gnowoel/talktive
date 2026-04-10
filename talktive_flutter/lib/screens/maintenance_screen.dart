import 'package:flutter/material.dart';
import '../widgets/duo/duo_page_scaffold.dart';
import '../config/theme.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DuoPageScaffold(
      emoji: '🏠',
      title: 'Building Maintenance',
      subtitle: 'The residence is being polished.',
      gradient: AppTheme.primaryGradient,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Hold tight, Resident!',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.duoSpacingMedium),
              const Text(
                'We are performing some essential maintenance to keep the building running smoothly. We\'ll be back online shortly.',
                style: TextStyle(
                  fontFamily: 'Rubik',
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.duoSpacingXXLarge),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
