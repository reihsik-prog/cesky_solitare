import 'package:flutter/material.dart';
import 'dart:math';

// ============================================================================
// --- PAINTERS (Vykreslování textur a rubu) ---
// ============================================================================

class RubKartyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = const Color.fromARGB(230, 255, 255, 255)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
        const Radius.circular(4));

    canvas.drawRRect(rect, borderPaint);

    final patternPaint = Paint()
      ..color = const Color.fromARGB(31, 0, 0, 0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.save();
    canvas.clipRRect(rect);
    for (double i = -size.height; i < size.width; i += 5) {
      canvas.drawLine(
          Offset(i, size.height), Offset(i + size.height, 0), patternPaint);
    }
    for (double i = 0; i < size.width + size.height; i += 5) {
      canvas.drawLine(
          Offset(i, 0), Offset(i - size.height, size.height), patternPaint);
    }
    canvas.drawCircle(Offset(size.width / 2, size.height / 2), 12,
        Paint()..color = const Color.fromARGB(38, 255, 255, 255)..style = PaintingStyle.fill);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PozadiTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    drawCrossHatch(
      canvas,
      size,
      Paint()
        ..color = const Color.fromARGB(38, 0, 0, 0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
      step: 4,
    );
    canvas.save();
    canvas.translate(2.5, 1.5);
    canvas.rotate(0.05);
    drawCrossHatch(
      canvas,
      size,
      Paint()
        ..color = const Color.fromARGB(20, 255, 255, 255)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
      step: 5,
    );
    canvas.restore();
  }

  void drawCrossHatch(Canvas canvas, Size size, Paint paint,
      {required double step}) {
    for (double i = -size.height; i < size.width; i += step) {
      canvas.drawLine(Offset(i, size.height), Offset(i + size.height, 0), paint);
    }
    for (double i = 0; i < size.width + size.height; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i - size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class PaperTexturePainter extends CustomPainter {
  final Random _random = Random(1); // Seed for consistency

  @override
  void paint(Canvas canvas, Size size) {
    // --- 1. TMAVÉ TEČKY (SPECKLES) ---
    final specklePaint = Paint()
      ..color = const Color.fromARGB(25, 0, 0, 0) // Zvýšená viditelnost
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 300; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      // Větší tečky, aby byly vidět
      canvas.drawCircle(Offset(x, y), _random.nextDouble() * 1.2 + 0.5, specklePaint);
    }

    // --- 2. SVĚTLEJŠÍ TEČKY (PRO KONTRAST) ---
    final lightSpecklePaint = Paint()
      ..color = const Color.fromARGB(15, 255, 255, 255)
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < 150; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), _random.nextDouble() * 1.5 + 0.5, lightSpecklePaint);
    }

    // --- 3. KRÁTKÁ VLÁKNA (FIBERS) ---
    final fiberPaint = Paint()
      ..color = const Color.fromARGB(12, 0, 0, 0)
      ..strokeWidth = 0.8;

    for (int i = 0; i < 80; i++) {
      final x = _random.nextDouble() * size.width;
      final y = _random.nextDouble() * size.height;
      final angle = _random.nextDouble() * 3.14159 * 2;
      final length = _random.nextDouble() * 4 + 2; // Délka 2 až 6px
      
      final endX = x + cos(angle) * length;
      final endY = y + sin(angle) * length;

      canvas.drawLine(Offset(x, y), Offset(endX, endY), fiberPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
