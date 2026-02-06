import 'package:flutter/widgets.dart';

class ScrollableCenter extends StatelessWidget {
  const ScrollableCenter({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: child,
          ),
        ),
      );
    });
  }
}
