import 'package:flutter/material.dart';

class StatusNotice extends StatefulWidget {
  final String content;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Duration delay;

  const StatusNotice({
    super.key,
    required this.content,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    this.delay = const Duration(milliseconds: 500),
  });

  @override
  State<StatusNotice> createState() => _StatusNoticeState();
}

class _StatusNoticeState extends State<StatusNotice>
    with SingleTickerProviderStateMixin {
  bool _isVisible = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    Future.delayed(widget.delay, () {
      if (mounted) {
        setState(() => _isVisible = true);
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _animation,
      child: SizeTransition(
        sizeFactor: _animation,
        axisAlignment: -1.0,
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          color: widget.backgroundColor,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                Icon(widget.icon, size: 16, color: widget.foregroundColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.content,
                    style: TextStyle(
                      color: widget.foregroundColor,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
