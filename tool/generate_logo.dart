import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Generates the app logo as a PNG file
void main() {
  final size = 1024;
  final image = img.Image(width: size, height: size);

  // Colors
  final darkBlue = img.ColorRgba8(30, 58, 95, 255);
  final brightBlue = img.ColorRgba8(59, 130, 246, 255);
  final white = img.ColorRgba8(255, 255, 255, 255);
  final lightGray = img.ColorRgba8(226, 232, 240, 255);
  final amber = img.ColorRgba8(251, 191, 36, 255);
  final green = img.ColorRgba8(34, 197, 94, 255);
  final cardGray = img.ColorRgba8(203, 213, 225, 255);

  // Fill with gradient background (simplified as solid with slight gradient effect)
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      // Simple diagonal gradient
      final t = (x + y) / (size * 2);
      final r = (30 + (29 * t)).round();
      final g = (58 + (72 * t)).round();
      final b = (95 + (151 * t)).round();
      image.setPixel(x, y, img.ColorRgba8(r, g, b, 255));
    }
  }

  // Round the corners
  final cornerRadius = (size * 0.22).round();
  _roundCorners(image, cornerRadius);

  // Draw QSL card (white rounded rectangle)
  final cardWidth = (size * 0.65).round();
  final cardHeight = (size * 0.42).round();
  final cardX = (size - cardWidth) ~/ 2;
  final cardY = (size - cardHeight) ~/ 2;
  final cardRadius = (size * 0.03).round();

  // Card shadow (offset)
  _drawRoundedRect(image, cardX + 8, cardY + 8, cardWidth, cardHeight, cardRadius,
      img.ColorRgba8(0, 0, 0, 60));

  // Card fill
  _drawRoundedRect(image, cardX, cardY, cardWidth, cardHeight, cardRadius, white);

  // Card border
  _drawRoundedRectBorder(image, cardX, cardY, cardWidth, cardHeight, cardRadius, lightGray, 3);

  // Draw "QSL" text (simplified as block letters)
  _drawQSLText(image, size ~/ 2, size ~/ 2 - 20, size, darkBlue);

  // Draw decorative lines on card
  final lineY1 = cardY + cardHeight ~/ 2 + 40;
  final lineY2 = lineY1 + 25;
  final lineStartX = cardX + 50;
  final lineEndX = cardX + cardWidth - 50;

  _drawLine(image, lineStartX, lineY1, lineEndX, lineY1, cardGray, 6);
  _drawLine(image, lineStartX, lineY2, lineStartX + (lineEndX - lineStartX) ~/ 2, lineY2, cardGray, 6);

  // Draw radio wave arcs (top right)
  final waveX = (size * 0.78).round();
  final waveY = (size * 0.22).round();

  for (var i = 0; i < 3; i++) {
    final radius = (size * (0.08 + i * 0.06)).round();
    _drawArc(image, waveX, waveY, radius, -2.4, 1.2, amber, (size * 0.025).round());
  }

  // Antenna dot
  _drawFilledCircle(image, waveX, waveY, (size * 0.025).round(), amber);

  // Draw checkmark (bottom left)
  final checkX = (size * 0.22).round();
  final checkY = (size * 0.72).round();
  _drawCheckmark(image, checkX, checkY, size, green);

  // Save the image
  final outputDir = Directory('assets/icon');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final pngBytes = img.encodePng(image);
  File('assets/icon/app_icon.png').writeAsBytesSync(pngBytes);
  print('Logo saved to: assets/icon/app_icon.png');

  // Also create a foreground version (without background for adaptive icons)
  final foreground = img.Image(width: size, height: size);
  img.fill(foreground, color: img.ColorRgba8(0, 0, 0, 0)); // Transparent

  // Copy the card and elements to foreground
  _drawRoundedRect(foreground, cardX, cardY, cardWidth, cardHeight, cardRadius, white);
  _drawRoundedRectBorder(foreground, cardX, cardY, cardWidth, cardHeight, cardRadius, lightGray, 3);
  _drawQSLText(foreground, size ~/ 2, size ~/ 2 - 20, size, darkBlue);
  _drawLine(foreground, lineStartX, lineY1, lineEndX, lineY1, cardGray, 6);
  _drawLine(foreground, lineStartX, lineY2, lineStartX + (lineEndX - lineStartX) ~/ 2, lineY2, cardGray, 6);

  for (var i = 0; i < 3; i++) {
    final radius = (size * (0.08 + i * 0.06)).round();
    _drawArc(foreground, waveX, waveY, radius, -2.4, 1.2, amber, (size * 0.025).round());
  }
  _drawFilledCircle(foreground, waveX, waveY, (size * 0.025).round(), amber);
  _drawCheckmark(foreground, checkX, checkY, size, green);

  File('assets/icon/app_icon_foreground.png').writeAsBytesSync(img.encodePng(foreground));
  print('Foreground saved to: assets/icon/app_icon_foreground.png');
}

void _roundCorners(img.Image image, int radius) {
  final size = image.width;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      // Check each corner
      bool inCorner = false;
      int cx = 0, cy = 0;

      if (x < radius && y < radius) {
        cx = radius;
        cy = radius;
        inCorner = true;
      } else if (x >= size - radius && y < radius) {
        cx = size - radius;
        cy = radius;
        inCorner = true;
      } else if (x < radius && y >= size - radius) {
        cx = radius;
        cy = size - radius;
        inCorner = true;
      } else if (x >= size - radius && y >= size - radius) {
        cx = size - radius;
        cy = size - radius;
        inCorner = true;
      }

      if (inCorner) {
        final dist = sqrt(pow(x - cx, 2) + pow(y - cy, 2));
        if (dist > radius) {
          image.setPixel(x, y, img.ColorRgba8(0, 0, 0, 0));
        }
      }
    }
  }
}

void _drawRoundedRect(img.Image image, int x, int y, int w, int h, int r, img.Color color) {
  for (var py = y; py < y + h; py++) {
    for (var px = x; px < x + w; px++) {
      if (_isInsideRoundedRect(px, py, x, y, w, h, r)) {
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          image.setPixel(px, py, color);
        }
      }
    }
  }
}

void _drawRoundedRectBorder(img.Image image, int x, int y, int w, int h, int r, img.Color color, int thickness) {
  for (var py = y - thickness; py < y + h + thickness; py++) {
    for (var px = x - thickness; px < x + w + thickness; px++) {
      final inside = _isInsideRoundedRect(px, py, x, y, w, h, r);
      final insideInner = _isInsideRoundedRect(px, py, x + thickness, y + thickness, w - thickness * 2, h - thickness * 2, max(0, r - thickness));
      if (inside && !insideInner) {
        if (px >= 0 && px < image.width && py >= 0 && py < image.height) {
          image.setPixel(px, py, color);
        }
      }
    }
  }
}

bool _isInsideRoundedRect(int px, int py, int x, int y, int w, int h, int r) {
  if (px < x || px >= x + w || py < y || py >= y + h) return false;

  // Check corners
  if (px < x + r && py < y + r) {
    return sqrt(pow(px - (x + r), 2) + pow(py - (y + r), 2)) <= r;
  }
  if (px >= x + w - r && py < y + r) {
    return sqrt(pow(px - (x + w - r), 2) + pow(py - (y + r), 2)) <= r;
  }
  if (px < x + r && py >= y + h - r) {
    return sqrt(pow(px - (x + r), 2) + pow(py - (y + h - r), 2)) <= r;
  }
  if (px >= x + w - r && py >= y + h - r) {
    return sqrt(pow(px - (x + w - r), 2) + pow(py - (y + h - r), 2)) <= r;
  }

  return true;
}

void _drawLine(img.Image image, int x1, int y1, int x2, int y2, img.Color color, int thickness) {
  final dx = (x2 - x1).abs();
  final dy = (y2 - y1).abs();
  final sx = x1 < x2 ? 1 : -1;
  final sy = y1 < y2 ? 1 : -1;
  var err = dx - dy;

  var x = x1;
  var y = y1;

  while (true) {
    _drawFilledCircle(image, x, y, thickness ~/ 2, color);

    if (x == x2 && y == y2) break;
    final e2 = 2 * err;
    if (e2 > -dy) {
      err -= dy;
      x += sx;
    }
    if (e2 < dx) {
      err += dx;
      y += sy;
    }
  }
}

void _drawFilledCircle(img.Image image, int cx, int cy, int r, img.Color color) {
  for (var y = cy - r; y <= cy + r; y++) {
    for (var x = cx - r; x <= cx + r; x++) {
      if (sqrt(pow(x - cx, 2) + pow(y - cy, 2)) <= r) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          image.setPixel(x, y, color);
        }
      }
    }
  }
}

void _drawArc(img.Image image, int cx, int cy, int r, double startAngle, double sweepAngle, img.Color color, int thickness) {
  final steps = (r * sweepAngle).abs().round();
  for (var i = 0; i <= steps; i++) {
    final angle = startAngle + (sweepAngle * i / steps);
    final x = cx + (r * cos(angle)).round();
    final y = cy + (r * sin(angle)).round();
    _drawFilledCircle(image, x, y, thickness ~/ 2, color);
  }
}

void _drawQSLText(img.Image image, int cx, int cy, int size, img.Color color) {
  // Draw simplified "QSL" letters
  final letterSize = (size * 0.12).round();
  final spacing = (size * 0.13).round();
  final thickness = (size * 0.025).round();

  // Q
  final qx = cx - spacing - letterSize ~/ 2;
  _drawQ(image, qx, cy, letterSize, color, thickness);

  // S
  final sx = cx;
  _drawS(image, sx, cy, letterSize, color, thickness);

  // L
  final lx = cx + spacing + letterSize ~/ 2;
  _drawL(image, lx, cy, letterSize, color, thickness);
}

void _drawQ(img.Image image, int cx, int cy, int size, img.Color color, int thickness) {
  final r = size ~/ 2;
  // Draw circle
  for (var angle = 0.0; angle < 2 * pi; angle += 0.05) {
    final x = cx + (r * cos(angle)).round();
    final y = cy + (r * sin(angle)).round();
    _drawFilledCircle(image, x, y, thickness ~/ 2, color);
  }
  // Draw tail
  _drawLine(image, cx + r ~/ 3, cy + r ~/ 3, cx + r, cy + r, color, thickness);
}

void _drawS(img.Image image, int cx, int cy, int size, img.Color color, int thickness) {
  final r = size ~/ 4;
  // Top arc
  for (var angle = -pi * 0.3; angle < pi * 0.9; angle += 0.05) {
    final x = cx + (r * cos(angle)).round();
    final y = cy - r + (r * sin(angle)).round();
    _drawFilledCircle(image, x, y, thickness ~/ 2, color);
  }
  // Bottom arc
  for (var angle = pi * 0.7; angle < pi * 1.9; angle += 0.05) {
    final x = cx + (r * cos(angle)).round();
    final y = cy + r + (r * sin(angle)).round();
    _drawFilledCircle(image, x, y, thickness ~/ 2, color);
  }
}

void _drawL(img.Image image, int cx, int cy, int size, img.Color color, int thickness) {
  final h = size ~/ 2;
  final w = (size * 0.35).round();
  // Vertical line
  _drawLine(image, cx - w ~/ 2, cy - h, cx - w ~/ 2, cy + h, color, thickness);
  // Horizontal line
  _drawLine(image, cx - w ~/ 2, cy + h, cx + w ~/ 2, cy + h, color, thickness);
}

void _drawCheckmark(img.Image image, int x, int y, int size, img.Color color) {
  final thickness = (size * 0.035).round();
  final seg1 = (size * 0.06).round();
  final seg2 = (size * 0.12).round();

  _drawLine(image, x, y, x + seg1, y + seg1, color, thickness);
  _drawLine(image, x + seg1, y + seg1, x + seg1 + seg2, y + seg1 - seg2, color, thickness);
}
