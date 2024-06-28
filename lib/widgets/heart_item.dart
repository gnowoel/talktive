import 'package:flutter/material.dart';

class HeartItem extends StatelessWidget {
  final IconData icon;
  final MaterialColor? color;

  const HeartItem({
    super.key,
    this.icon = Icons.favorite,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: color ?? Colors.pink.shade400,
      size: 20,
    );
  }
}
