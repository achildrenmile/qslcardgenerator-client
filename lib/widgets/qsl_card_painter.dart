import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/models.dart';

class QslCardPainter extends CustomPainter {
  final ui.Image? backgroundImage;
  final ui.Image? templateImage;
  final QsoData qsoData;
  final CardConfig cardConfig;
  final double scaleFactor;

  // Card dimensions at full resolution (matches web version)
  static const double fullWidth = 4961;
  static const double fullHeight = 3189;

  QslCardPainter({
    this.backgroundImage,
    this.templateImage,
    required this.qsoData,
    required this.cardConfig,
    this.scaleFactor = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / fullWidth;
    final scaleY = size.height / fullHeight;

    // Draw background image (layer 1)
    _drawBackground(canvas, size);

    // Draw template overlay (layer 2) - user's custom PNG with logos, address, etc.
    _drawTemplate(canvas, size);

    // Draw QSO data text at configured positions (layer 3)
    _drawQsoData(canvas, size, scaleX, scaleY);
  }

  void _drawBackground(Canvas canvas, Size size) {
    if (backgroundImage != null) {
      final paint = Paint();
      canvas.drawImageRect(
        backgroundImage!,
        Rect.fromLTWH(
          0,
          0,
          backgroundImage!.width.toDouble(),
          backgroundImage!.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    } else {
      // Default white background if no image
      final bgPaint = Paint()..color = Colors.white;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    }
  }

  void _drawTemplate(Canvas canvas, Size size) {
    if (templateImage != null) {
      final paint = Paint();
      canvas.drawImageRect(
        templateImage!,
        Rect.fromLTWH(
          0,
          0,
          templateImage!.width.toDouble(),
          templateImage!.height.toDouble(),
        ),
        Rect.fromLTWH(0, 0, size.width, size.height),
        paint,
      );
    }
  }

  void _drawQsoData(Canvas canvas, Size size, double scaleX, double scaleY) {
    final positions = cardConfig.textPositions;

    // Contact callsign
    if (qsoData.contactCallsign.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.contactCallsign.toUpperCase(),
        Offset(positions.callsign.x * scaleX, positions.callsign.y * scaleY),
        100 * scaleX,
        Colors.white,
        align: TextAlign.center,
        fontWeight: FontWeight.normal,
      );
    }

    // UTC Date/Time
    _drawText(
      canvas,
      qsoData.formattedDateTime,
      Offset(positions.utcDateTime.x * scaleX, positions.utcDateTime.y * scaleY),
      80 * scaleX,
      Colors.white,
      align: TextAlign.center,
    );

    // Frequency
    if (qsoData.frequency.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.frequency,
        Offset(positions.frequency.x * scaleX, positions.frequency.y * scaleY),
        100 * scaleX,
        Colors.white,
        align: TextAlign.center,
      );
    }

    // Mode
    if (qsoData.mode.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.mode.toUpperCase(),
        Offset(positions.mode.x * scaleX, positions.mode.y * scaleY),
        100 * scaleX,
        Colors.white,
        align: TextAlign.center,
      );
    }

    // RST
    if (qsoData.rst.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.rst,
        Offset(positions.rst.x * scaleX, positions.rst.y * scaleY),
        100 * scaleX,
        Colors.white,
        align: TextAlign.center,
      );
    }

    // Additional remarks
    if (qsoData.additionalLine1.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.additionalLine1,
        Offset(positions.additional.x * scaleX, positions.additional.y * scaleY),
        100 * scaleX,
        Colors.black,
        align: TextAlign.left,
        fontWeight: FontWeight.bold,
      );
    }
    if (qsoData.additionalLine2.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.additionalLine2,
        Offset(positions.additional.x * scaleX, (positions.additional.y + 120) * scaleY),
        100 * scaleX,
        Colors.black,
        align: TextAlign.left,
        fontWeight: FontWeight.bold,
      );
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    double fontSize,
    Color color, {
    TextAlign align = TextAlign.left,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFamily: 'Arial',
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: align,
    );

    textPainter.layout();

    double x = position.dx;
    double y = position.dy;

    // Adjust based on alignment
    if (align == TextAlign.center) {
      x -= textPainter.width / 2;
    } else if (align == TextAlign.right) {
      x -= textPainter.width;
    }
    y -= textPainter.height / 2;

    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant QslCardPainter oldDelegate) {
    return oldDelegate.backgroundImage != backgroundImage ||
        oldDelegate.templateImage != templateImage ||
        oldDelegate.qsoData != qsoData ||
        oldDelegate.cardConfig != cardConfig ||
        oldDelegate.scaleFactor != scaleFactor;
  }
}
