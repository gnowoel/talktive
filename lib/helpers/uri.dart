import 'dart:io';

import 'package:flutter/foundation.dart';

@override
String convertUri(String uri) {
  if (!kDebugMode) return uri;

  if (kIsWeb) {
    return uri.replaceFirst('10.0.2.2', 'localhost');
  } else if (Platform.isAndroid) {
    return uri.replaceFirst('localhost', '10.0.2.2');
  }

  return uri.replaceFirst('10.0.2.2', 'localhost');
}
