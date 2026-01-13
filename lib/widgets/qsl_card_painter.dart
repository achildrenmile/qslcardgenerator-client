import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/models.dart';

class QslCardPainter extends CustomPainter {
  final ui.Image? backgroundImage;
  final ui.Image? templateImage;
  final QsoData qsoData;
  final TextPositions textPositions;
  final double scaleFactor;

  QslCardPainter({
    this.backgroundImage,
    this.templateImage,
    required this.qsoData,
    required this.textPositions,
    this.scaleFactor = 0.4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw background
    if (backgroundImage != null) {
      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(0, 0, backgroundImage!.width.toDouble(),
            backgroundImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    } else {
      // Default background color
      paint.color = const Color(0xFF1e293b);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    }

    // Draw template overlay
    if (templateImage != null) {
      canvas.drawImageRect(
        templateImage!,
        Rect.fromLTWH(0, 0, templateImage!.width.toDouble(),
            templateImage!.height.toDouble()),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    }

    // Draw text fields
    // Callsign (large, centered)
    _drawText(
      canvas,
      qsoData.contactCallsign.toUpperCase(),
      textPositions.callsign,
      100 * scaleFactor,
      TextAlign.center,
    );

    // UTC DateTime
    _drawText(
      canvas,
      qsoData.formattedDateTime,
      textPositions.utcDateTime,
      80 * scaleFactor,
      TextAlign.center,
    );

    // Frequency
    _drawText(
      canvas,
      qsoData.frequency,
      textPositions.frequency,
      100 * scaleFactor,
      TextAlign.center,
    );

    // Mode
    _drawText(
      canvas,
      qsoData.mode.toUpperCase(),
      textPositions.mode,
      100 * scaleFactor,
      TextAlign.center,
    );

    // RST
    _drawText(
      canvas,
      qsoData.rst,
      textPositions.rst,
      100 * scaleFactor,
      TextAlign.center,
    );

    // Additional lines (left aligned)
    _drawText(
      canvas,
      qsoData.additionalLine1,
      textPositions.additional,
      100 * scaleFactor,
      TextAlign.left,
      isBold: true,
    );

    _drawText(
      canvas,
      qsoData.additionalLine2,
      TextPosition(
        x: textPositions.additional.x,
        y: textPositions.additional.y + (120 * scaleFactor / scaleFactor),
      ),
      100 * scaleFactor,
      TextAlign.left,
      isBold: true,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    TextPosition position,
    double fontSize,
    TextAlign align, {
    bool isBold = false,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: Colors.black,
        fontSize: fontSize,
        fontFamily: 'Arial',
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: align,
    );

    textPainter.layout();

    double x = position.x * scaleFactor;
    double y = position.y * scaleFactor;

    // Adjust x based on alignment
    if (align == TextAlign.center) {
      x -= textPainter.width / 2;
    }

    // Center vertically
    y -= textPainter.height / 2;

    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant QslCardPainter oldDelegate) {
    return oldDelegate.backgroundImage != backgroundImage ||
        oldDelegate.templateImage != templateImage ||
        oldDelegate.qsoData != qsoData ||
        oldDelegate.textPositions != textPositions ||
        oldDelegate.scaleFactor != scaleFactor;
  }
}
