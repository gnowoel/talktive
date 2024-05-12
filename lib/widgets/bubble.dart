import 'package:flutter/material.dart';

class Bubble extends StatelessWidget {
  final String content;
  final bool byMe;
  final bool byOp;

  const Bubble({
    super.key,
    required this.content,
    this.byMe = false,
    this.byOp = false,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        byMe ? Colors.green[200] : (byOp ? Colors.amber[50] : Colors.white);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: backgroundColor,
      ),
      child: Text(content),
    );
  }
}
