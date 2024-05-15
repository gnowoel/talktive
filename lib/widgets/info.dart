import 'package:flutter/material.dart';

class Info extends StatelessWidget {
  final List<String> lines;

  const Info({
    super.key,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: lines.map((line) => _buildLine(line)).toList(),
    );
  }

  Widget _buildLine(line) {
    return Text(
      line,
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.grey[400],
      ),
    );
  }
}
