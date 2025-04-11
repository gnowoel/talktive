import 'dart:io';

import 'package:flutter/foundation.dart';

bool get isAndroid {
  if (kIsWeb) return false;
  if (Platform.isAndroid) return true;
  return false;
}
