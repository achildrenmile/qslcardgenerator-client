import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Generates signature PNG images from typed text using a handwriting font.
///
/// Canvas size: 1800 x 300 pixels (6:1 aspect ratio)
/// - Text is auto-sized to fit the height
/// - White background
/// - Text color: #1e293b (dark gray to match card style)
class SignatureGenerator {
  static const double canvasWidth = 1800;
  static const double canvasHeight = 300;
  static const Color textColor = Color(0xFF1e293b);

  /// Generates a signature PNG from the given text.
  ///
  /// [text] - The name/text to render as a signature
  /// [fontFamily] - The font family to use (defaults to 'DancingScript')
  /// [callsign] - Used for the output filename
  ///
  /// Returns the generated PNG file.
  Future<File> generateSignature({
    required String text,
    required String callsign,
    String fontFamily = 'DancingScript',
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasWidth, canvasHeight),
      Paint()..color = Colors.white,
    );

    // Calculate optimal font size to fit the height
    final targetHeight = canvasHeight * 0.6;
    double fontSize = targetHeight;

    // Create text painter and measure
    TextPainter textPainter;
    do {
      textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontFamily: fontFamily,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // If text is too wide, reduce font size
      if (textPainter.width > canvasWidth * 0.9) {
        fontSize -= 5;
      } else {
        break;
      }
    } while (fontSize > 20);

    // Center the text vertically and align left with padding
    final x = canvasWidth * 0.05;
    final y = (canvasHeight - textPainter.height) / 2;

    textPainter.paint(canvas, Offset(x, y));

    // Convert to image - same approach as TemplateGenerator
    final picture = recorder.endRecording();
    final image = await picture.toImage(canvasWidth.toInt(), canvasHeight.toInt());

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) throw Exception('Failed to generate signature image');

    final pngBytes = byteData.buffer.asUint8List();

    // Save to signatures directory
    final appDir = await getApplicationDocumentsDirectory();
    final signaturesDir = Directory('${appDir.path}/qsl_signatures');
    if (!await signaturesDir.exists()) {
      await signaturesDir.create(recursive: true);
    }

    final file = File('${signaturesDir.path}/${callsign.toLowerCase()}.png');
    await file.writeAsBytes(pngBytes);

    return file;
  }
}
