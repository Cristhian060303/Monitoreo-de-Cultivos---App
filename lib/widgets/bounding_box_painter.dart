import 'package:flutter/material.dart';
import '../models/detection.dart';

class BoundingBoxPainter extends CustomPainter {
  final List<Detection> detections;
  final int frameW;
  final int frameH;

  BoundingBoxPainter({
    required this.detections,
    required this.frameW,
    required this.frameH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.red;

    final textPainter = TextPainter(
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    final scaleX = size.width / frameW;
    final scaleY = size.height / frameH;

    for (final d in detections) {
      final rect = Rect.fromLTWH(
        d.x * scaleX,
        d.y * scaleY,
        d.w * scaleX,
        d.h * scaleY,
      );

      canvas.drawRect(rect, paint);

      final label =
          '${d.label} ${(d.confidence * 100).toStringAsFixed(1)}%';

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          backgroundColor: Colors.red,
          fontSize: 12,
        ),
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(rect.left, rect.top - 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}