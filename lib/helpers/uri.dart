import 'dart:io';

import 'package:flutter/foundation.dart';

const _a = 'http://10.0.2.2';
const _b = 'http://localhost';

@override
String convertUri(String uri) {
  if (!kDebugMode) return uri;
  if (_isAndroid) return uri.replaceFirst(_b, _a);
  return uri.replaceFirst(_a, _b);
}

bool get _isAndroid {
  if (kIsWeb) return false;
  if (Platform.isAndroid) return true;
  return false;
}
