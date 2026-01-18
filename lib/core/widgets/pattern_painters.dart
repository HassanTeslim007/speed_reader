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

class SpeedLogoPainter extends CustomPainter {
  final Color color;
  final double progress; // 0.0 to 1.0 for animation

  SpeedLogoPainter({required this.color, this.progress = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final bookWidth = size.width * 0.35;
    final bookHeight = size.height * 0.45;

    // Center spine
    canvas.drawLine(
      Offset(center.dx, center.dy - bookHeight / 2 + 5),
      Offset(center.dx, center.dy + bookHeight / 2 - 5),
      paint,
    );

    // Left page
    final leftPath = Path();
    leftPath.moveTo(center.dx, center.dy - bookHeight / 2 + 5);
    leftPath.quadraticBezierTo(
      center.dx - bookWidth / 2,
      center.dy - bookHeight / 2 - 10,
      center.dx - bookWidth,
      center.dy - bookHeight / 2 + 5,
    );
    leftPath.lineTo(center.dx - bookWidth, center.dy + bookHeight / 2 - 5);
    leftPath.quadraticBezierTo(
      center.dx - bookWidth / 2,
      center.dy + bookHeight / 2 - 20,
      center.dx,
      center.dy + bookHeight / 2 - 5,
    );
    canvas.drawPath(leftPath, paint);

    // Right page
    final rightPath = Path();
    rightPath.moveTo(center.dx, center.dy - bookHeight / 2 + 5);
    rightPath.quadraticBezierTo(
      center.dx + bookWidth / 2,
      center.dy - bookHeight / 2 - 10,
      center.dx + bookWidth,
      center.dy - bookHeight / 2 + 5,
    );
    rightPath.lineTo(center.dx + bookWidth, center.dy + bookHeight / 2 - 5);
    rightPath.quadraticBezierTo(
      center.dx + bookWidth / 2,
      center.dy + bookHeight / 2 - 20,
      center.dx,
      center.dy + bookHeight / 2 - 5,
    );
    canvas.drawPath(rightPath, paint);

    // Speed lines (animated)
    final linesPaint = Paint()
      ..color = color.withValues(alpha: progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final yOffset = -25.0 + (i * 25.0);
      final length = 50.0 * progress;
      final startX = center.dx - bookWidth - 15.0 - (i * 12.0);
      canvas.drawLine(
        Offset(startX, center.dy + yOffset),
        Offset(startX - length, center.dy + yOffset),
        linesPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant SpeedLogoPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
