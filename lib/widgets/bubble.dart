import 'package:flutter/material.dart';

class Bubble extends StatelessWidget {
  final String content;

  const Bubble({
    super.key,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.green[200],
      ),
      child: Text(content),
    );
  }
}
