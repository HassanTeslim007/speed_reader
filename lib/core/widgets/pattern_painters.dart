import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A collection of procedural painters to create patterns without external assets.
class WoodGrainPainter extends CustomPainter {
  final Color color;

  WoodGrainPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final random = math.Random(42);
    for (var i = 0; i < size.height; i += 3) {
      final path = Path();
      path.moveTo(0, i.toDouble());

      for (var x = 0.0; x <= size.width; x += 20) {
        final dy = random.nextDouble() * 2 - 1;
        path.lineTo(x, i + dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class LeatherPainter extends CustomPainter {
  final Color color;

  LeatherPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    final random = math.Random(123);
    for (var i = 0; i < 1000; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final r = random.nextDouble() * 1.5;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GeometricGridPainter extends CustomPainter {
  final Color color;

  GeometricGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const spacing = 40.0;
    for (var x = 0.0; x < size.width; x += spacing) {
      for (var y = 0.0; y < size.height; y += spacing) {
        // Draw a small subtle diamond or square
        final path = Path();
        path.moveTo(x + spacing / 2, y);
        path.lineTo(x + spacing, y + spacing / 2);
        path.lineTo(x + spacing / 2, y + spacing);
        path.lineTo(x, y + spacing / 2);
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
