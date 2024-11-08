import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

String getLanguageCode(context) {
  return kIsWeb
      ? View.of(context).platformDispatcher.locale.languageCode
      : Platform.localeName.split('_').first;
}
