import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Generates QSL card templates with clean, print-ready layout.
///
/// Layout zones (4961 x 3189 pixels):
/// ┌─────────────────┬─────────────────┐
/// │  LOGO ZONE      │   CALLSIGN      │  <- Top row (900px)
/// │  (left 40%)     │   (right side)  │
/// ├─────────────────┼─────────────────┤
/// │  ADDRESS BOX    │   QSO DATA      │  <- Content area
/// │                 │   (grid layout) │
/// │                 ├─────────────────┤
/// │                 │   SIGNATURE     │  <- Below QSO data
/// └─────────────────┴─────────────────┘
class TemplateGenerator {
  // === CARD DIMENSIONS ===
  static const double cardWidth = 4961;
  static const double cardHeight = 3189;

  // === LAYOUT ZONES ===
  static const double leftZoneEnd = cardWidth * 0.40;
  static const double rightZoneStart = cardWidth * 0.42;
  static const double topBandHeight = 900;
  static const double contentStartY = 980;

  // === QSO BOX DIMENSIONS ===
  static const double qsoBoxLeft = rightZoneStart;
  static const double qsoBoxWidth = cardWidth - rightZoneStart - 80;
  static const double qsoBoxTop = contentStartY;

  // === GRID SYSTEM ===
  static const double padding = 40.0;
  static const double rowHeight = 100.0;
  static const double labelFontSize = 32.0;
  static const double valueFontSize = 48.0;
  static const double headerFontSize = 50.0;

  // === COLORS (print-friendly) ===
  static const Color labelColor = Color(0xFF64748b);
  static const Color valueColor = Color(0xFF1e293b);
  static const Color headerColor = Color(0xFF1e3a5f);
  static const Color borderColor = Color(0xFFcbd5e1);
  static const Color bgColor = Color(0xFFFAFAFA);
  static const Color headerBgColor = Color(0xFFf1f5f9);

  Future<File> generateTemplate({
    required String callsign,
    required String operatorName,
    required String street,
    required String city,
    required String country,
    required String locator,
    required String email,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    _drawTemplate(
      canvas,
      callsign: callsign,
      operatorName: operatorName,
      street: street,
      city: city,
      country: country,
      locator: locator,
      email: email,
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(cardWidth.toInt(), cardHeight.toInt());

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to generate template');

    final pngBytes = byteData.buffer.asUint8List();

    final appDir = await getApplicationDocumentsDirectory();
    final templatesDir = Directory('${appDir.path}/qsl_templates');
    if (!await templatesDir.exists()) {
      await templatesDir.create(recursive: true);
    }

    final file = File('${templatesDir.path}/${callsign.toLowerCase()}.png');
    await file.writeAsBytes(pngBytes);

    return file;
  }

  void _drawTemplate(
    Canvas canvas, {
    required String callsign,
    required String operatorName,
    required String street,
    required String city,
    required String country,
    required String locator,
    required String email,
  }) {
    // Transparent background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cardWidth, cardHeight),
      Paint()..color = Colors.transparent,
    );

    // Draw callsign in top-right area
    _drawCallsign(canvas, callsign);

    // Draw address section on the left
    _drawAddressSection(canvas, operatorName, street, city, country, locator, email);

    // Draw QSO data grid on the right
    _drawQsoDataGrid(canvas);
  }

  void _drawCallsign(Canvas canvas, String callsign) {
    // Position callsign to the right, ~100px from right edge (right-aligned)
    const callsignX = cardWidth - 100;
    const callsignY = topBandHeight / 2;

    _drawText(
      canvas,
      callsign.toUpperCase(),
      const Offset(callsignX, callsignY),
      380,
      const Color(0xFFDC2626),
      fontWeight: FontWeight.bold,
      align: TextAlign.right,
    );
  }

  void _drawAddressSection(
    Canvas canvas,
    String operatorName,
    String street,
    String city,
    String country,
    String locator,
    String email,
  ) {
    const boxLeft = 80.0;
    const boxWidth = leftZoneEnd - 160;
    const headerHeight = 70.0;
    const lineHeight = 85.0;

    int lineCount = 1;
    if (street.isNotEmpty) lineCount++;
    if (city.isNotEmpty) lineCount++;
    if (country.isNotEmpty) lineCount++;
    if (locator.isNotEmpty) lineCount++;
    if (email.isNotEmpty) lineCount++;

    final boxHeight = headerHeight + (lineCount * lineHeight) + padding * 2;
    final boxRect = Rect.fromLTWH(boxLeft, contentStartY, boxWidth, boxHeight);

    // Box background
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(12)),
      Paint()..color = bgColor.withValues(alpha: 0.85),
    );

    // Subtle border
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(12)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Header background
    final headerRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(boxLeft, contentStartY, boxWidth, headerHeight),
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
    );
    canvas.drawRRect(headerRect, Paint()..color = headerBgColor);

    // Header text
    _drawText(
      canvas,
      'ADDRESS',
      Offset(boxRect.center.dx, contentStartY + headerHeight / 2),
      headerFontSize,
      headerColor,
      fontWeight: FontWeight.bold,
      align: TextAlign.center,
    );

    // Content
    final contentX = boxLeft + padding;
    var contentY = contentStartY + headerHeight + padding + 20;

    _drawText(canvas, operatorName, Offset(contentX, contentY), 65,
        valueColor, fontWeight: FontWeight.bold);
    contentY += lineHeight;

    if (street.isNotEmpty) {
      _drawText(canvas, street, Offset(contentX, contentY), 52, valueColor);
      contentY += lineHeight;
    }
    if (city.isNotEmpty) {
      _drawText(canvas, city, Offset(contentX, contentY), 52, valueColor);
      contentY += lineHeight;
    }
    if (country.isNotEmpty) {
      _drawText(canvas, country.toUpperCase(), Offset(contentX, contentY), 52,
          valueColor, fontWeight: FontWeight.bold);
      contentY += lineHeight;
    }
    if (locator.isNotEmpty) {
      _drawText(canvas, 'LOC: $locator', Offset(contentX, contentY), 48, labelColor);
      contentY += lineHeight;
    }
    if (email.isNotEmpty) {
      _drawText(canvas, email, Offset(contentX, contentY), 44,
          const Color(0xFF2563eb));
    }
  }

  /// Draws QSO data section with a clean grid layout.
  ///
  /// Grid Structure:
  /// ┌─────────────────────────────────────────────────────┐
  /// │                    QSO DATA                         │ Header
  /// ├─────────────────────────────────────────────────────┤
  /// │  CONFIRMING QSO WITH:  [________________]           │ TO RADIO
  /// ├───────────┬───────────┬───────────┬─────────────────┤
  /// │ DATE(UTC) │ TIME(UTC) │   BAND    │      MODE       │ Row 1
  /// ├───────────┼───────────┼───────────┼─────────────────┤
  /// │ FREQ(MHz) │ POWER(W)  │ RST SENT  │    RST RCVD     │ Row 2
  /// ├───────────┴───────────┼───────────┴─────────────────┤
  /// │  □ 2-WAY    □ PSE QSL │ □ TNX QSL                   │ Row 3
  /// ├───────────────────────┴─────────────────────────────┤
  /// │  REMARKS: _________________________________________ │ Row 4
  /// ├─────────────────────────────────────────────────────┤
  /// │  SIGNATURE: [                                     ] │ Row 5
  /// └─────────────────────────────────────────────────────┘
  void _drawQsoDataGrid(Canvas canvas) {
    // Calculate box dimensions (with larger signature area)
    const boxHeight = 950.0;
    const boxTop = cardHeight - boxHeight - 100;
    final boxRect = Rect.fromLTWH(qsoBoxLeft, boxTop, qsoBoxWidth, boxHeight);

    // Draw main container
    _drawQsoContainer(canvas, boxRect);

    // Draw header
    const headerHeight = 65.0;
    _drawQsoHeader(canvas, boxRect, headerHeight);

    // Grid layout starts after header (compact vertical spacing)
    final gridTop = boxTop + headerHeight + 25;
    final gridWidth = qsoBoxWidth - padding * 2 - 20;  // Side margin
    final gridLeft = qsoBoxLeft + padding + 10;  // Centered with margin

    // === TO RADIO ROW ===
    final toRadioY = gridTop;
    _drawToRadioRow(canvas, gridLeft, toRadioY, gridWidth);

    // === DATA ROWS (4 columns each) ===
    const dataRowHeight = 110.0;
    final col1Width = gridWidth * 0.25;
    final col2Width = gridWidth * 0.25;
    final col3Width = gridWidth * 0.25;
    final col4Width = gridWidth * 0.25;

    // Row 1: DATE, TIME, BAND, MODE (adjusted for taller TO RADIO box)
    final row1Y = toRadioY + 120;
    _drawGridCell(canvas, 'DATE (UTC)', gridLeft, row1Y, col1Width, dataRowHeight);
    _drawGridCell(canvas, 'TIME (UTC)', gridLeft + col1Width, row1Y, col2Width, dataRowHeight);
    _drawGridCell(canvas, 'BAND', gridLeft + col1Width + col2Width, row1Y, col3Width, dataRowHeight);
    _drawGridCell(canvas, 'MODE', gridLeft + col1Width + col2Width + col3Width, row1Y, col4Width, dataRowHeight);

    // Row 2: FREQ, POWER, RST SENT, RST RCVD
    final row2Y = row1Y + dataRowHeight;
    _drawGridCell(canvas, 'FREQ (MHz)', gridLeft, row2Y, col1Width, dataRowHeight);
    _drawGridCell(canvas, 'POWER (W)', gridLeft + col1Width, row2Y, col2Width, dataRowHeight);
    _drawGridCell(canvas, 'RST SENT', gridLeft + col1Width + col2Width, row2Y, col3Width, dataRowHeight);
    _drawGridCell(canvas, 'RST RCVD', gridLeft + col1Width + col2Width + col3Width, row2Y, col4Width, dataRowHeight);

    // === ROW 3: CHECKBOXES ===
    final row3Y = row2Y + dataRowHeight + 15;
    _drawCheckboxRow(canvas, gridLeft, row3Y, gridWidth);

    // === ROW 4: REMARKS ===
    final row4Y = row3Y + 80;
    _drawRemarksRow(canvas, gridLeft, row4Y, gridWidth);

    // === ROW 5: SIGNATURE ===
    final row5Y = row4Y + 160;  // Compact spacing
    _drawSignatureArea(canvas, gridLeft, row5Y, gridWidth);
  }

  void _drawQsoContainer(Canvas canvas, Rect rect) {
    // White background
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()..color = bgColor.withValues(alpha: 0.90),
    );

    // Subtle border
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawQsoHeader(Canvas canvas, Rect boxRect, double headerHeight) {
    final headerRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(boxRect.left, boxRect.top, boxRect.width, headerHeight),
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
    );
    canvas.drawRRect(headerRect, Paint()..color = headerBgColor);

    _drawText(
      canvas,
      'QSO DATA',
      Offset(boxRect.center.dx, boxRect.top + headerHeight / 2),
      headerFontSize,
      headerColor,
      fontWeight: FontWeight.bold,
      align: TextAlign.center,
    );

    // Header bottom line
    canvas.drawLine(
      Offset(boxRect.left, boxRect.top + headerHeight),
      Offset(boxRect.right, boxRect.top + headerHeight),
      Paint()..color = borderColor..strokeWidth = 1,
    );
  }

  void _drawToRadioRow(Canvas canvas, double left, double top, double width) {
    // Label
    _drawText(
      canvas,
      'CONFIRMING QSO WITH:',
      Offset(left, top + 25),
      labelFontSize,
      labelColor,
      fontWeight: FontWeight.w600,
    );

    // Value box (taller to fit callsign)
    final valueBoxLeft = left + 480;
    final valueBoxWidth = width - 500;
    final valueRect = Rect.fromLTWH(valueBoxLeft, top, valueBoxWidth, 90);

    canvas.drawRRect(
      RRect.fromRectAndRadius(valueRect, const Radius.circular(6)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(valueRect, const Radius.circular(6)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Underline for value (adjusted for taller box)
    canvas.drawLine(
      Offset(valueBoxLeft + 15, top + 70),
      Offset(valueBoxLeft + valueBoxWidth - 15, top + 70),
      Paint()..color = const Color(0xFF3b82f6)..strokeWidth = 2,
    );
  }

  void _drawGridCell(Canvas canvas, String label, double left, double top, double width, double height) {
    final cellRect = Rect.fromLTWH(left, top, width, height);

    // Cell background
    canvas.drawRect(cellRect, Paint()..color = Colors.white.withValues(alpha: 0.5));

    // Cell border
    canvas.drawRect(
      cellRect,
      Paint()
        ..color = borderColor.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Label (top of cell)
    _drawText(
      canvas,
      label,
      Offset(left + width / 2, top + 22),
      labelFontSize,
      labelColor,
      fontWeight: FontWeight.w600,
      align: TextAlign.center,
    );

    // Value underline
    canvas.drawLine(
      Offset(left + 20, top + height - 20),
      Offset(left + width - 20, top + height - 20),
      Paint()..color = const Color(0xFF3b82f6).withValues(alpha: 0.6)..strokeWidth = 2,
    );
  }

  void _drawCheckboxRow(Canvas canvas, double left, double top, double width) {
    const boxSize = 40.0;
    const spacing = 180.0;

    // 2-WAY checkbox
    _drawCheckbox(canvas, left, top, '2-WAY');

    // PSE QSL checkbox
    _drawCheckbox(canvas, left + spacing + 100, top, 'PSE QSL');

    // TNX QSL checkbox
    _drawCheckbox(canvas, left + spacing * 2 + 200, top, 'TNX QSL');
  }

  void _drawCheckbox(Canvas canvas, double left, double top, String label) {
    const boxSize = 40.0;
    final boxRect = Rect.fromLTWH(left, top, boxSize, boxSize);

    // Checkbox background
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(4)),
      Paint()..color = Colors.white,
    );

    // Checkbox border
    canvas.drawRRect(
      RRect.fromRectAndRadius(boxRect, const Radius.circular(4)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Label
    _drawText(
      canvas,
      label,
      Offset(left + boxSize + 15, top + boxSize / 2),
      36,
      valueColor,
      fontWeight: FontWeight.w500,
    );
  }

  void _drawRemarksRow(Canvas canvas, double left, double top, double width) {
    // Label
    _drawText(
      canvas,
      'REMARKS:',
      Offset(left, top + 15),
      labelFontSize,
      labelColor,
      fontWeight: FontWeight.w600,
    );

    // Remarks area (compact height)
    final remarksRect = Rect.fromLTWH(left + 220, top, width - 240, 130);

    canvas.drawRRect(
      RRect.fromRectAndRadius(remarksRect, const Radius.circular(6)),
      Paint()..color = Colors.white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(remarksRect, const Radius.circular(6)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _drawSignatureArea(Canvas canvas, double left, double top, double width) {
    const sigHeight = 180.0;  // 1.8x original size
    final sigRect = Rect.fromLTWH(left, top, width, sigHeight);

    // Light background
    canvas.drawRRect(
      RRect.fromRectAndRadius(sigRect, const Radius.circular(8)),
      Paint()..color = headerBgColor.withValues(alpha: 0.5),
    );

    // Border
    canvas.drawRRect(
      RRect.fromRectAndRadius(sigRect, const Radius.circular(8)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Label
    _drawText(
      canvas,
      'SIGNATURE',
      Offset(left + 20, top + 20),
      28,
      labelColor,
      fontWeight: FontWeight.w500,
    );

    // Signature line
    canvas.drawLine(
      Offset(left + width * 0.3, top + sigHeight - 35),
      Offset(left + width - 40, top + sigHeight - 35),
      Paint()..color = borderColor..strokeWidth = 1.5,
    );
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
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'Arial',
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: align,
    )..layout();

    var x = position.dx;
    var y = position.dy - textPainter.height / 2;

    if (align == TextAlign.center) {
      x -= textPainter.width / 2;
    } else if (align == TextAlign.right) {
      x -= textPainter.width;
    }

    textPainter.paint(canvas, Offset(x, y));
  }
}
