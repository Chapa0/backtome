import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Builds the Mapbox bitmap used for delivery and pickup points.
///
/// Lost objects use colored circles. Delivery points deliberately use a
/// pin-shaped depot marker so both concepts remain visually distinct.
class DeliveryPointMarkerImage {
  const DeliveryPointMarkerImage._();

  static final Map<String, Uint8List> _cache = {};

  static Future<Uint8List> build({
    bool highlighted = false,
    bool active = true,
  }) async {
    final cacheKey = '$highlighted:$active';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    const width = 96.0;
    const height = 112.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fillColor =
        active ? const Color(0xFF006D77) : const Color(0xFF757575);
    final borderColor = highlighted
        ? const Color(0xFFFFB300)
        : active
            ? const Color(0xFF83C5BE)
            : const Color(0xFFBDBDBD);

    final markerPath = Path()
      ..moveTo(22, 6)
      ..quadraticBezierTo(10, 6, 10, 20)
      ..lineTo(10, 68)
      ..quadraticBezierTo(10, 80, 22, 80)
      ..lineTo(37, 80)
      ..lineTo(48, 106)
      ..lineTo(59, 80)
      ..lineTo(74, 80)
      ..quadraticBezierTo(86, 80, 86, 68)
      ..lineTo(86, 20)
      ..quadraticBezierTo(86, 6, 74, 6)
      ..close();

    canvas.drawShadow(markerPath, Colors.black54, 6, true);
    canvas.drawPath(markerPath, Paint()..color = fillColor);
    canvas.drawPath(
      markerPath,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = highlighted ? 7 : 5
        ..strokeJoin = StrokeJoin.round,
    );

    const icon = Icons.storefront_rounded;
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset((width - iconPainter.width) / 2, 19),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (bytes == null) {
      throw StateError('No se pudo generar el marcador del punto de entrega.');
    }

    final result = bytes.buffer.asUint8List();
    _cache[cacheKey] = result;
    return result;
  }
}
