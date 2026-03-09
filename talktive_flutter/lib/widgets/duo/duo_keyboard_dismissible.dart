import 'package:flutter/material.dart';

/// A wrapper widget that dismisses the virtual keyboard when tapping outside of a focused input.
class DuoKeyboardDismissible extends StatelessWidget {
  final Widget child;

  const DuoKeyboardDismissible({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final currentFocus = FocusScope.of(context);
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      },
      // This is important to allow the gesture to be caught even on empty spaces
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
