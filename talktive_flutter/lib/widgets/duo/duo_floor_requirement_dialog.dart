import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'duo_card.dart';
import 'duo_button.dart';

class DuoFloorRequirementDialog extends StatelessWidget {
  final String message;
  final int requiredFloor;

  const DuoFloorRequirementDialog({
    super.key,
    required this.message,
    this.requiredFloor = 0,
  });

  static void show(
    BuildContext context, {
    required String message,
    int requiredFloor = 0,
  }) {
    showDialog(
      context: context,
      builder: (context) => DuoFloorRequirementDialog(
        message: message,
        requiredFloor: requiredFloor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: DuoCard(
        padding: const EdgeInsets.all(AppTheme.duoSpacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.apartment_rounded,
              size: 64,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: AppTheme.duoSpacingMedium),
            const Text(
              'High-Rise Access Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.duoSpacingSmall),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                fontFamily: 'Rubik',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.duoSpacingLarge),
            DuoButton(
              text: 'Got it',
              onPressed: () => Navigator.pop(context),
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
