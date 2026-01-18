import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../widgets/qsl_card_painter.dart';

class ExportService {
  /// Get the QSL cards export directory (for desktop platforms)
  Future<Directory> getExportDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(docsDir.path, 'QSL Cards'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// Generate a unique filename for the callsign
  /// If OE8CDC.png exists, returns OE8CDC(1).png, OE8CDC(2).png, etc.
  Future<String> _getUniqueFilePath(Directory dir, String callsign) async {
    final baseCallsign = callsign.toUpperCase();
    var filePath = p.join(dir.path, '$baseCallsign.png');

    if (!await File(filePath).exists()) {
      return filePath;
    }

    // Find next available number
    int counter = 1;
    while (await File(p.join(dir.path, '$baseCallsign($counter).png')).exists()) {
      counter++;
    }

    return p.join(dir.path, '$baseCallsign($counter).png');
  }

  /// Save image to device gallery (Android/iOS)
  Future<String?> _saveToGallery(Uint8List pngBytes, String callsign) async {
    final fileName = '${callsign.toUpperCase()}_${DateTime.now().millisecondsSinceEpoch}.png';

    final result = await SaverGallery.saveImage(
      pngBytes,
      fileName: fileName,
      skipIfExists: false,
    );

    if (result.isSuccess) {
      return fileName;
    }
    return null;
  }

  /// Export QSL card as PNG image
  /// - On mobile (Android/iOS): Saves to Photos/Gallery
  /// - On desktop (Windows/Linux/macOS): Saves to Documents/QSL Cards folder
  Future<ExportResult> exportCard({
    required ui.Image? backgroundImage,
    required ui.Image? templateImage,
    ui.Image? logoImage,
    ui.Image? signatureImage,
    List<ui.Image> additionalLogos = const [],
    required QsoData qsoData,
    required CardConfig cardConfig,
    required int width,
    required int height,
  }) async {
    // Create a picture recorder
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Create the painter with scale factor 1.0 for full resolution
    final painter = QslCardPainter(
      backgroundImage: backgroundImage,
      templateImage: templateImage,
      logoImage: logoImage,
      signatureImage: signatureImage,
      additionalLogos: additionalLogos,
      qsoData: qsoData,
      cardConfig: cardConfig,
      scaleFactor: 1.0,
    );

    // Paint to the canvas
    painter.paint(canvas, Size(width.toDouble(), height.toDouble()));

    // End recording and convert to image
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);

    // Convert to PNG bytes
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return ExportResult(success: false);

    final pngBytes = byteData.buffer.asUint8List();

    // Save based on platform
    if (Platform.isAndroid || Platform.isIOS) {
      // Save to gallery on mobile
      final galleryPath = await _saveToGallery(pngBytes, qsoData.contactCallsign);
      if (galleryPath != null) {
        return ExportResult(
          success: true,
          fileName: '${qsoData.contactCallsign.toUpperCase()}.png',
          savedToGallery: true,
        );
      }
      return ExportResult(success: false);
    } else {
      // Save to Documents/QSL Cards on desktop
      final exportDir = await getExportDirectory();
      final outputPath = await _getUniqueFilePath(exportDir, qsoData.contactCallsign);

      final file = File(outputPath);
      await file.writeAsBytes(pngBytes);

      return ExportResult(
        success: true,
        file: file,
        fileName: p.basename(outputPath),
        savedToGallery: false,
      );
    }
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

/// Result of an export operation
class ExportResult {
  final bool success;
  final File? file;
  final String? fileName;
  final bool savedToGallery;

  ExportResult({
    required this.success,
    this.file,
    this.fileName,
    this.savedToGallery = false,
  });
}
