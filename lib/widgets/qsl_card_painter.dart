import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/models.dart';

class QslCardPainter extends CustomPainter {
  final ui.Image? backgroundImage;
  final ui.Image? templateImage;
  final ui.Image? logoImage;
  final ui.Image? signatureImage;
  final QsoData qsoData;
  final CardConfig cardConfig;
  final double scaleFactor;

  // Card dimensions at full resolution (matches web version)
  static const double fullWidth = 4961;
  static const double fullHeight = 3189;

  // Layout zones from grid-based template generator
  static const double topBandHeight = 900;   // Top row for logo + callsign
  static const double leftZoneEnd = fullWidth * 0.40;  // 1984.4 - left zone width
  static const double rightZoneStart = fullWidth * 0.42; // 2083.62

  // Logo zone (top-left area, within top band)
  static const double logoZoneWidth = leftZoneEnd;
  static const double logoZoneHeight = topBandHeight;
  static const double logoMargin = 80;

  // QSO box layout constants (from template_generator)
  static const double qsoBoxTop = fullHeight - 950 - 100;  // 2139 (with larger signature)
  static const double headerHeight = 65.0;
  static const double gridPadding = 40.0;
  static const double gridTop = qsoBoxTop + headerHeight + 25;  // 2229 (compact spacing)
  static const double gridLeft = rightZoneStart + gridPadding + 10;  // 2133.62 (centered with margin)
  static const double qsoBoxWidth = fullWidth - rightZoneStart - 80;  // 2797.38
  static const double gridWidth = qsoBoxWidth - gridPadding * 2 - 20;  // 2697.38 (side margin)
  static const double dataRowHeight = 110.0;

  // Row calculations (compact layout)
  static const double toRadioY = gridTop;  // 2229
  static const double row1Y = toRadioY + 120;  // 2349
  static const double row2Y = row1Y + dataRowHeight;  // 2459
  static const double row3Y = row2Y + dataRowHeight + 15;  // 2584 (checkboxes)
  static const double row4Y = row3Y + 80;  // 2664 (remarks)
  static const double row5Y = row4Y + 160;  // 2824 (signature)

  // Signature zone (Row 5 in grid)
  static const double signatureHeight = 180.0;  // 1.8x original size
  static const double signatureLineY = row5Y + signatureHeight - 35;  // 2969

  QslCardPainter({
    this.backgroundImage,
    this.templateImage,
    this.logoImage,
    this.signatureImage,
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

    // Draw template overlay (layer 2) - the generated PNG with header/footer
    _drawTemplate(canvas, size);

    // Draw logo in header (layer 3)
    _drawLogo(canvas, size, scaleX, scaleY);

    // Draw signature in footer (layer 4)
    _drawSignature(canvas, size, scaleX, scaleY);

    // Draw QSO data text at configured positions (layer 5)
    _drawQsoData(canvas, size, scaleX, scaleY);

    // Draw checkmarks for PSE/TNX QSL (layer 6)
    _drawCheckmarks(canvas, size, scaleX, scaleY);
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

  void _drawLogo(Canvas canvas, Size size, double scaleX, double scaleY) {
    if (logoImage == null) return;

    // Logo should be 2.6x the callsign height (callsign is 380px)
    const callsignHeight = 380.0;
    const targetLogoHeight = callsignHeight * 2.6;  // 988px at full resolution

    // Available space with minimal margins (just 40px from edges)
    const smallMargin = 40.0;
    final maxWidth = (logoZoneWidth - smallMargin * 2) * scaleX;
    final maxHeight = (logoZoneHeight - smallMargin * 2) * scaleY;

    final logoWidth = logoImage!.width.toDouble();
    final logoHeight = logoImage!.height.toDouble();
    final aspectRatio = logoWidth / logoHeight;

    // Start with target height (2.6x callsign), maintaining aspect ratio
    var scaledHeight = targetLogoHeight * scaleY;
    var scaledWidth = scaledHeight * aspectRatio;

    // Constrain to fit within card boundaries
    if (scaledWidth > maxWidth) {
      scaledWidth = maxWidth;
      scaledHeight = scaledWidth / aspectRatio;
    }
    if (scaledHeight > maxHeight) {
      scaledHeight = maxHeight;
      scaledWidth = scaledHeight * aspectRatio;
    }

    // Left-align the logo with small margin, vertically centered in top band
    final logoX = smallMargin * scaleX;
    final logoY = (logoZoneHeight * scaleY - scaledHeight) / 2;

    final paint = Paint();
    canvas.drawImageRect(
      logoImage!,
      Rect.fromLTWH(0, 0, logoWidth, logoHeight),
      Rect.fromLTWH(logoX, logoY, scaledWidth, scaledHeight),
      paint,
    );
  }

  void _drawSignature(Canvas canvas, Size size, double scaleX, double scaleY) {
    if (signatureImage == null) return;

    // Signature area (Row 5 in grid layout)
    // Position: right portion of signature row, above the signature line
    final sigAreaLeft = (gridLeft + gridWidth * 0.3) * scaleX;
    final sigAreaWidth = (gridWidth * 0.7 - 40) * scaleX;
    final sigAreaTop = row5Y * scaleY + 25 * scaleY;
    final sigAreaHeight = (signatureHeight - 60) * scaleY;

    // Calculate scale to fit signature
    final imgWidth = signatureImage!.width.toDouble();
    final imgHeight = signatureImage!.height.toDouble();

    final scaleToFit = (sigAreaWidth / imgWidth).clamp(0.0, sigAreaHeight / imgHeight);
    final scaledWidth = imgWidth * scaleToFit;
    final scaledHeight = imgHeight * scaleToFit;

    // Center signature in available area
    final sigX = sigAreaLeft + (sigAreaWidth - scaledWidth) / 2;
    final sigY = sigAreaTop + (sigAreaHeight - scaledHeight) / 2;

    final paint = Paint();
    canvas.drawImageRect(
      signatureImage!,
      Rect.fromLTWH(0, 0, imgWidth, imgHeight),
      Rect.fromLTWH(sigX, sigY, scaledWidth, scaledHeight),
      paint,
    );
  }

  void _drawQsoData(Canvas canvas, Size size, double scaleX, double scaleY) {
    final positions = cardConfig.textPositions;
    const dataFontSize = 50.0;  // Reduced to fit field height
    const smallFontSize = 42.0;

    // Contact callsign in "To Radio:" box (header)
    if (qsoData.contactCallsign.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.contactCallsign.toUpperCase(),
        Offset(positions.toRadioCallsign.x * scaleX, positions.toRadioCallsign.y * scaleY),
        70 * scaleX,
        const Color(0xFF1e293b),
        align: TextAlign.center,
        fontWeight: FontWeight.bold,
      );
    }

    // Date
    _drawText(
      canvas,
      qsoData.formattedDate,
      Offset(positions.date.x * scaleX, positions.date.y * scaleY),
      dataFontSize * scaleX,
      Colors.black,
      align: TextAlign.center,
    );

    // Time (UTC)
    _drawText(
      canvas,
      qsoData.formattedTime,
      Offset(positions.time.x * scaleX, positions.time.y * scaleY),
      dataFontSize * scaleX,
      Colors.black,
      align: TextAlign.center,
    );

    // Frequency
    if (qsoData.frequency.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.frequency,
        Offset(positions.frequency.x * scaleX, positions.frequency.y * scaleY),
        dataFontSize * scaleX,
        Colors.black,
        align: TextAlign.center,
      );
    }

    // Band
    if (qsoData.band.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.band,
        Offset(positions.band.x * scaleX, positions.band.y * scaleY),
        dataFontSize * scaleX,
        Colors.black,
        align: TextAlign.center,
      );
    }

    // Mode
    if (qsoData.mode.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.mode.toUpperCase(),
        Offset(positions.mode.x * scaleX, positions.mode.y * scaleY),
        dataFontSize * scaleX,
        Colors.black,
        align: TextAlign.center,
      );
    }

    // RST Sent
    if (qsoData.rstSent.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.rstSent,
        Offset(positions.rstSent.x * scaleX, positions.rstSent.y * scaleY),
        dataFontSize * scaleX,
        Colors.black,
        align: TextAlign.center,
      );
    }

    // RST Received
    if (qsoData.rstRcvd.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.rstRcvd,
        Offset(positions.rstRcvd.x * scaleX, positions.rstRcvd.y * scaleY),
        dataFontSize * scaleX,
        Colors.black,
        align: TextAlign.center,
      );
    }

    // Note: 2-Way, PSE QSL, TNX QSL checkmarks are drawn in _drawCheckmarks()

    // Power
    if (qsoData.power.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.power,
        Offset(positions.power.x * scaleX, positions.power.y * scaleY),
        smallFontSize * scaleX,
        Colors.black,
        align: TextAlign.center,
      );
    }

    // Remarks (left-aligned to fit in the field)
    if (qsoData.remarks.isNotEmpty) {
      _drawText(
        canvas,
        qsoData.remarks,
        Offset(positions.remarks.x * scaleX, positions.remarks.y * scaleY),
        smallFontSize * scaleX,
        Colors.black,
        align: TextAlign.left,
      );
    }
  }

  void _drawCheckmarks(Canvas canvas, Size size, double scaleX, double scaleY) {
    // Checkbox positions from grid-based template_generator (Row 3)
    // Checkbox layout: 2-WAY at gridLeft, PSE QSL at +280, TNX QSL at +560
    const checkboxSize = 40.0;
    const checkboxSpacing = 280.0;  // spacing + 100 from template

    // 2-WAY checkbox center (first checkbox)
    final twoWayCheckX = (gridLeft + checkboxSize / 2) * scaleX;
    final checkY = (row3Y + checkboxSize / 2) * scaleY;

    // PSE QSL checkbox center (second checkbox)
    final pseCheckX = (gridLeft + checkboxSpacing + checkboxSize / 2) * scaleX;

    // TNX QSL checkbox center (third checkbox)
    final tnxCheckX = (gridLeft + checkboxSpacing * 2 + checkboxSize / 2) * scaleX;

    const checkSize = 36.0;
    const checkColor = Color(0xFF22c55e);

    if (qsoData.twoWay) {
      _drawText(
        canvas,
        '\u2713',
        Offset(twoWayCheckX, checkY),
        checkSize * scaleX,
        checkColor,
        align: TextAlign.center,
        fontWeight: FontWeight.bold,
      );
    }

    if (qsoData.pseQsl) {
      _drawText(
        canvas,
        '\u2713',
        Offset(pseCheckX, checkY),
        checkSize * scaleX,
        checkColor,
        align: TextAlign.center,
        fontWeight: FontWeight.bold,
      );
    }

    if (qsoData.tnxQsl) {
      _drawText(
        canvas,
        '\u2713',
        Offset(tnxCheckX, checkY),
        checkSize * scaleX,
        checkColor,
        align: TextAlign.center,
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
        oldDelegate.logoImage != logoImage ||
        oldDelegate.signatureImage != signatureImage ||
        oldDelegate.qsoData != qsoData ||
        oldDelegate.cardConfig != cardConfig ||
        oldDelegate.scaleFactor != scaleFactor;
  }
}
