import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../widgets/duo/duo_button.dart';

class DuoUpgradeHelper {
  static void showUpgradePrompt(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            const Text('💎', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'Premium Feature',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
            ),
          ],
        ),
        content: Text(
          '$featureName is a Plus feature. Try it out for free and support the community!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Rubik',
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Maybe Later',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to Settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Visit Activity > Settings to try it out! 🚀'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Try It Out',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'Rubik',
              ),
            ),
          ),
        ],
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      ),
    );
  }

  static void showPaidOnlyPrompt(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
