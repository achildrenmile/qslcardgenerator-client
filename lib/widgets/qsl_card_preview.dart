import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/models.dart';
import 'qsl_card_painter.dart';

class QslCardPreview extends StatelessWidget {
  final ui.Image? backgroundImage;
  final ui.Image? templateImage;
  final ui.Image? logoImage;
  final ui.Image? signatureImage;
  final List<ui.Image> additionalLogos;
  final QsoData qsoData;
  final CardConfig cardConfig;
  final double scaleFactor;

  const QslCardPreview({
    super.key,
    this.backgroundImage,
    this.templateImage,
    this.logoImage,
    this.signatureImage,
    this.additionalLogos = const [],
    required this.qsoData,
    required this.cardConfig,
    this.scaleFactor = 0.4,
  });

  @override
  Widget build(BuildContext context) {
    // Standard QSL card aspect ratio (typically 5.5" x 3.5" = 1.57:1)
    const aspectRatio = 1.57;

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color.fromRGBO(0, 0, 0, 0.3),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CustomPaint(
            painter: QslCardPainter(
              backgroundImage: backgroundImage,
              templateImage: templateImage,
              logoImage: logoImage,
              signatureImage: signatureImage,
              additionalLogos: additionalLogos,
              qsoData: qsoData,
              cardConfig: cardConfig,
              scaleFactor: scaleFactor,
            ),
            size: Size.infinite,
          ),
        ),
      ),
    );
  }
}
