import 'package:flutter/widgets.dart';

Widget renderButton({required dynamic configuration}) {
  return const SizedBox.shrink();
}

class GSIButtonConfiguration {
  final dynamic theme;
  final dynamic size;
  final dynamic text;
  final dynamic shape;
  final dynamic logoAlignment;

  GSIButtonConfiguration({
    this.theme,
    this.size,
    this.text,
    this.shape,
    this.logoAlignment,
  });
}

enum GSIButtonTheme { outline }

enum GSIButtonSize { large }

enum GSIButtonText { continueWith }

enum GSIButtonShape { pill }

enum GSIButtonLogoAlignment { left }
