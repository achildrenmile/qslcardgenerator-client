import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../widgets/qsl_card_painter.dart';

class ExportService {
  /// Export QSL card as PNG image
  Future<File?> exportCard({
    required ui.Image? backgroundImage,
    required ui.Image? templateImage,
    required QsoData qsoData,
    required TextPositions textPositions,
    required int width,
    required int height,
    String? suggestedFileName,
  }) async {
    // Create a picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Create the painter with scale factor 1.0 for full resolution
    final painter = QslCardPainter(
      backgroundImage: backgroundImage,
      templateImage: templateImage,
      qsoData: qsoData,
      textPositions: textPositions,
      scaleFactor: 1.0,
    );

    // Paint to the canvas
    painter.paint(canvas, Size(width.toDouble(), height.toDouble()));

    // End recording and convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);

    // Convert to PNG bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final pngBytes = byteData.buffer.asUint8List();

    // Get save location from user
    final fileName =
        suggestedFileName ?? '${qsoData.contactCallsign.toUpperCase()}.png';

    String? outputPath;

    if (Platform.isAndroid || Platform.isIOS) {
      // On mobile, save to downloads or documents
      final directory = await getApplicationDocumentsDirectory();
      outputPath = '${directory.path}/$fileName';
    } else {
      // On desktop, show save dialog
      outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save QSL Card',
        fileName: fileName,
        type: FileType.image,
        allowedExtensions: ['png'],
      );
    }

    if (outputPath == null) return null;

    // Write file
    final file = File(outputPath);
    await file.writeAsBytes(pngBytes);

    return file;
  }

  /// Load an image from file
  Future<ui.Image?> loadImage(File file) async {
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Load an image from asset
  Future<ui.Image?> loadAssetImage(
      BuildContext context, String assetPath) async {
    final data = await DefaultAssetBundle.of(context).load(assetPath);
    final bytes = data.buffer.asUint8List();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }
}
