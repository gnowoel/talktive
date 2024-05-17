import 'package:flutter/material.dart';

class HeartItem extends StatelessWidget {
  final IconData icon;
  final MaterialColor color;

  const HeartItem({
    super.key,
    this.icon = Icons.favorite,
    this.color = Colors.pink,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: color,
      size: 20,
    );
  }
}
