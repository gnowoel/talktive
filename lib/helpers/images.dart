import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

CachedNetworkImageProvider getCachedImageProvider(String uri) {
  return CachedNetworkImageProvider(
    convertUri(uri),
    // TODO: Configure caching parameters
    cacheKey: uri, // Using the original uri as cache key
  );
}

Widget getImagePlaceholder({Color? color}) {
  return Center(
    child: SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    ),
  );
}

Widget getImageErrorWidget() {
  return Icon(Icons.broken_image_rounded, size: 40, color: Colors.grey[400]);
}
