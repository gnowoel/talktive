import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../helpers/url_helper.dart';

class ImageGalleryScreen extends StatelessWidget {
  final String imageUrl;

  const ImageGalleryScreen({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Hero(
            tag: 'moment_image_${imageUrl.hashCode}', // Fallback hero tag
            child: Image.network(
              UrlHelper.resolve(imageUrl),
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
      ),
    );
  }
}
