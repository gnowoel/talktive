import 'package:flutter/material.dart';

class Info extends StatelessWidget {
  final List<String> lines;

  const Info({
    super.key,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: lines.map((line) => _buildLine(theme, line)).toList(),
    );
  }

  Widget _buildLine(ThemeData theme, String line) {
    return Text(
      line,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.surfaceDim,
      ),
    );
  }
}
