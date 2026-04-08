import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/duo/duo_button.dart';

class DuoUpgradeHelper {
  static void showUpgradePrompt(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
        ),
        title: Column(
          children: [
            const Text('💎', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Plus Feature',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
            ),
          ],
        ),
        content: Text(
          'Unlock $featureName and more with Talktive Plus.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          DuoButton(
            text: 'Try It Out',
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Visit Activity > Settings to start your trial! 🚀'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            width: double.infinity,
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Maybe Later',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      ),
    );
  }

  static void showPaidOnlyPrompt(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.duoRadiusLarge),
        ),
        title: Column(
          children: [
            const Text('✨', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Paid Feature',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
            ),
          ],
        ),
        content: Text(
          '$featureName is reserved for Residents with an active paid subscription. Ads support the community during free trials.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          DuoButton(
            text: 'Got it',
            onPressed: () => Navigator.pop(context),
            width: double.infinity,
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      ),
    );
  }
}
