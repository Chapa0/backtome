import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class ImageViewerDialog extends StatefulWidget {
  final File? imageFile;
  final Uint8List? imageBytes;
  final String? imageUrl;
  final String? title;
  final String? subtitle;

  const ImageViewerDialog({
    super.key,
    required this.imageFile,
    this.title,
    this.subtitle,
  })  : imageBytes = null,
        imageUrl = null;

  const ImageViewerDialog.bytes({
    super.key,
    required this.imageBytes,
    this.title,
    this.subtitle,
  })  : imageFile = null,
        imageUrl = null;

  const ImageViewerDialog.network({
    super.key,
    required String url,
    this.title,
    this.subtitle,
  })  : imageFile = null,
        imageBytes = null,
        imageUrl = url;

  static Future<void> show({
    required BuildContext context,
    required File imageFile,
    String? title,
    String? subtitle,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => ImageViewerDialog(
          imageFile: imageFile,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  static Future<void> showBytes({
    required BuildContext context,
    required Uint8List imageBytes,
    String? title,
    String? subtitle,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => ImageViewerDialog.bytes(
          imageBytes: imageBytes,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  static Future<void> showNetwork({
    required BuildContext context,
    required String url,
    String? title,
    String? subtitle,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => ImageViewerDialog.network(
          url: url,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  @override
  State<ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<ImageViewerDialog>
    with TickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animationController;
  Animation<Matrix4>? _animation;
  int _quarterTurns = 0;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _animateTo(Matrix4.identity());
  }

  void _handleDoubleTap() {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final targetMatrix = currentScale > 1.5
        ? Matrix4.identity()
        : (Matrix4.identity()..scale(2.5));
    _animateTo(targetMatrix);
  }

  void _animateTo(Matrix4 targetMatrix) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.reset();
    _animation!.addListener(() {
      _transformationController.value = _animation!.value;
    });
    _animationController.forward();
  }

  Widget _buildImage() {
    final imageUrl = widget.imageUrl;
    final imageBytes = widget.imageBytes;
    final imageFile = widget.imageFile;

    late final Widget imageWidget;
    if (imageUrl != null) {
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final total = loadingProgress.expectedTotalBytes;
          return Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              value: total == null
                  ? null
                  : loadingProgress.cumulativeBytesLoaded / total,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else if (imageBytes != null) {
      imageWidget = Image.memory(
        imageBytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else if (imageFile != null) {
      imageWidget = Image.file(
        imageFile,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      );
    } else {
      imageWidget = _buildErrorWidget();
    }

    return RotatedBox(
      quarterTurns: _quarterTurns,
      child: imageWidget,
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.white54),
          SizedBox(height: 8),
          Text(
            'Error al cargar imagen',
            style: TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 5,
                clipBehavior: Clip.none,
                child: Center(child: _buildImage()),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _ImageViewerButton(
                icon: Icons.close,
                shape: BoxShape.circle,
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            if (widget.title != null || widget.subtitle != null)
              Positioned(
                top: 16,
                left: 16,
                right: 72,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(153),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (widget.subtitle != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            widget.subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 16,
              left: 16,
              child: _ImageViewerButton(
                icon: Icons.rotate_90_degrees_cw,
                onTap: () {
                  setState(() {
                    _quarterTurns = (_quarterTurns + 1) % 4;
                  });
                  _resetZoom();
                },
              ),
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: AnimatedBuilder(
                animation: _transformationController,
                builder: (context, child) {
                  final hasZoom =
                      _transformationController.value.getMaxScaleOnAxis() > 1.1;
                  return AnimatedOpacity(
                    opacity: hasZoom ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: hasZoom
                        ? _ImageViewerButton(
                            icon: Icons.zoom_out_map,
                            onTap: _resetZoom,
                          )
                        : const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageViewerButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final BoxShape shape;

  const _ImageViewerButton({
    required this.icon,
    required this.onTap,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(153),
          shape: shape,
          borderRadius:
              shape == BoxShape.circle ? null : BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
