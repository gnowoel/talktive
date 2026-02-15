import 'package:flutter/material.dart';
import '../../config/theme.dart';

/// A consistent loading indicator widget used across the app.
class DuoLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double? size;

  const DuoLoadingIndicator({super.key, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
