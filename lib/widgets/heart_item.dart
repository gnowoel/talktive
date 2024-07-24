import 'package:flutter/material.dart';

class HeartItem extends StatelessWidget {
  final IconData icon;
  final MaterialColor? color;
  final String semanticLabel;

  const HeartItem({
    super.key,
    this.icon = Icons.favorite,
    this.color,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: color ?? Colors.pinkAccent,
      size: 20,
      semanticLabel: semanticLabel,
    );
  }
}
