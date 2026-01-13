import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class TemplateGenerator {
  // Template dimensions (matches web version)
  static const double width = 4961;
  static const double height = 3189;

  /// Generate a QSL card template PNG with user's station info
  Future<File> generateTemplate({
    required String callsign,
    required String operatorName,
    required String street,
    required String city,
    required String country,
    required String email,
  }) async {
    // Create a picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw the template
    _drawTemplate(
      canvas,
      Size(width, height),
      callsign: callsign,
      operatorName: operatorName,
      street: street,
      city: city,
      country: country,
      email: email,
    );

    // End recording and convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.toInt(), height.toInt());

    // Convert to PNG bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to generate template');

    final pngBytes = byteData.buffer.asUint8List();

    // Save to templates directory
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
    Canvas canvas,
    Size size, {
    required String callsign,
    required String operatorName,
    required String street,
    required String city,
    required String country,
    required String email,
  }) {
    // Transparent/white background for overlay
    final bgPaint = Paint()..color = Colors.transparent;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // === LEFT SIDE - Station Info ===

    // Address box background
    final addressBoxPaint = Paint()..color = Colors.white;
    final addressBoxBorder = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const addressBoxLeft = 120.0;
    const addressBoxTop = 800.0;
    const addressBoxWidth = 1400.0;
    const addressBoxHeight = 700.0;

    final addressRect = Rect.fromLTWH(addressBoxLeft, addressBoxTop, addressBoxWidth, addressBoxHeight);
    canvas.drawRect(addressRect, addressBoxPaint);
    canvas.drawRect(addressRect, addressBoxBorder);

    // Address text
    double addressY = addressBoxTop + 100;
    const addressX = addressBoxLeft + 60.0;
    const addressLineHeight = 110.0;

    _drawText(canvas, operatorName, Offset(addressX, addressY), 90, const Color(0xFF1a1a1a), fontWeight: FontWeight.w600);
    addressY += addressLineHeight;

    if (street.isNotEmpty) {
      _drawText(canvas, street, Offset(addressX, addressY), 80, const Color(0xFF333333));
      addressY += addressLineHeight;
    }

    _drawText(canvas, city, Offset(addressX, addressY), 80, const Color(0xFF333333));
    addressY += addressLineHeight;

    _drawText(canvas, country.toUpperCase(), Offset(addressX, addressY), 80, const Color(0xFF333333), fontWeight: FontWeight.w600);
    addressY += addressLineHeight + 30;

    if (email.isNotEmpty) {
      _drawText(canvas, email, Offset(addressX, addressY), 70, const Color(0xFF3b82f6));
    }

    // === RIGHT SIDE - Callsign & QSO Data ===

    // Large callsign (red, top right)
    _drawText(
      canvas,
      callsign.toUpperCase(),
      Offset(size.width - 300, 400),
      450,
      const Color(0xFFDC2626),
      fontWeight: FontWeight.bold,
      align: TextAlign.right,
    );

    // QSO DATA section
    const qsoSectionLeft = 1800.0;
    const qsoSectionTop = 1100.0;
    const qsoSectionWidth = 2900.0;

    // "QSO DATA" header
    _drawText(
      canvas,
      'QSO DATA',
      Offset(qsoSectionLeft + qsoSectionWidth / 2, qsoSectionTop),
      120,
      const Color(0xFF1a1a1a),
      fontWeight: FontWeight.bold,
      align: TextAlign.center,
    );

    // Contact callsign box (large)
    const callsignBoxTop = qsoSectionTop + 200;
    const callsignBoxHeight = 220.0;
    _drawLabeledBox(
      canvas,
      'Your callsign',
      Rect.fromLTWH(qsoSectionLeft + 200, callsignBoxTop, qsoSectionWidth - 400, callsignBoxHeight),
    );

    // QSO fields row
    const fieldsTop = callsignBoxTop + callsignBoxHeight + 250;
    const fieldHeight = 180.0;
    const fieldSpacing = 40.0;

    // Calculate field widths
    const totalWidth = qsoSectionWidth - 100;
    const dateWidth = totalWidth * 0.30;
    const freqWidth = totalWidth * 0.25;
    const modeWidth = totalWidth * 0.22;
    const rstWidth = totalWidth * 0.20;

    var fieldX = qsoSectionLeft + 50;

    // UTC DATE/TIME
    _drawLabeledBox(
      canvas,
      'UTC DATE/TIME',
      Rect.fromLTWH(fieldX, fieldsTop, dateWidth, fieldHeight),
      sublabel: 'DD.MM.YYYY HH:MM',
    );
    fieldX += dateWidth + fieldSpacing;

    // Frequency MHz
    _drawLabeledBox(
      canvas,
      'Frequency MHz',
      Rect.fromLTWH(fieldX, fieldsTop, freqWidth, fieldHeight),
    );
    fieldX += freqWidth + fieldSpacing;

    // Mode
    _drawLabeledBox(
      canvas,
      'Mode',
      Rect.fromLTWH(fieldX, fieldsTop, modeWidth, fieldHeight),
    );
    fieldX += modeWidth + fieldSpacing;

    // R-S-T
    _drawLabeledBox(
      canvas,
      'R-S-T',
      Rect.fromLTWH(fieldX, fieldsTop, rstWidth, fieldHeight),
    );

    // Remarks/signature area
    const remarksTop = fieldsTop + fieldHeight + 300;
    const remarksHeight = 400.0;

    final remarksBoxPaint = Paint()..color = Colors.white;
    final remarksBorder = Paint()
      ..color = const Color(0xFFcccccc)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final remarksRect = Rect.fromLTWH(
      qsoSectionLeft + 50,
      remarksTop,
      qsoSectionWidth - 100,
      remarksHeight,
    );
    canvas.drawRect(remarksRect, remarksBoxPaint);
    canvas.drawRect(remarksRect, remarksBorder);

    // Signature line
    final signatureY = remarksTop + remarksHeight - 80;
    final signaturePaint = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 2;
    canvas.drawLine(
      Offset(qsoSectionLeft + qsoSectionWidth - 900, signatureY),
      Offset(qsoSectionLeft + qsoSectionWidth - 100, signatureY),
      signaturePaint,
    );
  }

  void _drawLabeledBox(
    Canvas canvas,
    String label,
    Rect rect, {
    String? sublabel,
  }) {
    // Box background (dark)
    final boxPaint = Paint()..color = const Color(0xFF2d2d2d);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(12));
    canvas.drawRRect(rrect, boxPaint);

    // Label above box
    _drawText(
      canvas,
      label,
      Offset(rect.center.dx, rect.top - 50),
      60,
      const Color(0xFF666666),
      align: TextAlign.center,
      fontWeight: FontWeight.w500,
    );

    // Sublabel inside box (if provided)
    if (sublabel != null) {
      _drawText(
        canvas,
        sublabel,
        Offset(rect.center.dx, rect.center.dy),
        50,
        const Color(0xFF888888),
        align: TextAlign.center,
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

    if (align == TextAlign.center) {
      x -= textPainter.width / 2;
    } else if (align == TextAlign.right) {
      x -= textPainter.width;
    }
    y -= textPainter.height / 2;

    textPainter.paint(canvas, Offset(x, y));
  }
}
