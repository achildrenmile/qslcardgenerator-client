// Tool to generate the default background image
// Run with: dart run tool/generate_default_background.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

void main() {
  // QSL card dimensions at 300 DPI (5.5" x 3.5")
  const width = 4961;
  const height = 3189;

  // Create image
  final image = img.Image(width: width, height: height);

  // Create a subtle gradient from light blue-gray at top to slightly darker at bottom
  // This provides a professional, clean look that works well with text
  for (int y = 0; y < height; y++) {
    // Calculate gradient position (0.0 to 1.0)
    final t = y / height;

    // Top color: Light blue-gray (#e8f0f8)
    // Bottom color: Slightly darker blue-gray (#d0dce8)
    final r = (232 + (208 - 232) * t).round();
    final g = (240 + (220 - 240) * t).round();
    final b = (248 + (232 - 248) * t).round();

    for (int x = 0; x < width; x++) {
      image.setPixelRgb(x, y, r, g, b);
    }
  }

  // Save as PNG
  final outputDir = Directory('assets/backgrounds');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final outputFile = File('assets/backgrounds/default_gradient.png');
  final pngBytes = img.encodePng(image);
  outputFile.writeAsBytesSync(pngBytes);

  print('Default background generated: ${outputFile.path}');
  print('Size: $width x $height pixels');
  print('File size: ${(pngBytes.length / 1024).toStringAsFixed(1)} KB');
}
