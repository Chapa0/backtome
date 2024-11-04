// fullscreen_image_dialog.dart

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class FullscreenImageDialog extends StatelessWidget {
  final String imageUrl;

  FullscreenImageDialog({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black, // Fondo negro para una mejor visualización
      insetPadding: EdgeInsets.all(10), // Margen alrededor del diálogo
      child: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        backgroundDecoration: BoxDecoration(color: Colors.black),
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(),
        ),
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(Icons.error, color: Colors.red, size: 40),
        ),
      ),
    );
  }
}
