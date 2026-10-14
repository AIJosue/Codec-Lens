import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

/// CustomClipper that molds a smooth 60fps Gaussian wave around the user's
/// cursor or touch position for side-by-side 4K codec visual inspection.
///
/// Mathematical formulation:
///   x(y) = splitX + amplitude * exp( -((y - cursorY)^2) / (2 * sigma^2) )
class MoldedWaveClipper extends CustomClipper<Path> {
  final double splitRatio; // 0.0 to 1.0 horizontal split position
  final double cursorYRatio; // 0.0 to 1.0 vertical touch/mouse focus position
  final double waveAmplitude; // Peak horizontal bulge in logical pixels
  final double waveSigma; // Gaussian standard deviation in logical pixels

  const MoldedWaveClipper({
    required this.splitRatio,
    required this.cursorYRatio,
    this.waveAmplitude = 44.0,
    this.waveSigma = 92.0,
  });

  double sampleWaveX(double y, Size size) {
    final baseSplitX = (splitRatio * size.width).clamp(0.0, size.width);
    final cursorY = (cursorYRatio * size.height).clamp(0.0, size.height);
    final dy = y - cursorY;
    final gaussian = math.exp(-(dy * dy) / (2.0 * waveSigma * waveSigma));
    return (baseSplitX + waveAmplitude * gaussian).clamp(0.0, size.width);
  }

  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(sampleWaveX(0, size), 0);

    // High-density sampling (every 4 logical pixels) for silky 60fps Gaussian curve
    const double step = 4.0;
    for (double y = step; y <= size.height; y += step) {
      path.lineTo(sampleWaveX(y, size), y);
    }
    path.lineTo(sampleWaveX(size.height, size), size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant MoldedWaveClipper oldClipper) {
    return oldClipper.splitRatio != splitRatio ||
        oldClipper.cursorYRatio != cursorYRatio ||
        oldClipper.waveAmplitude != waveAmplitude ||
        oldClipper.waveSigma != waveSigma;
  }
}

/// Renders the glowing specular frosted-glass wave divider line and floating
/// tactile glass pill handle anchored at the Gaussian wave apex.
class MoldedWaveDividerPainter extends CustomPainter {
  final MoldedWaveClipper clipper;
  final Color leftAccent;
  final Color rightAccent;
  final bool isInteracting;

  const MoldedWaveDividerPainter({
    required this.clipper,
    required this.leftAccent,
    required this.rightAccent,
    required this.isInteracting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final wavePath = Path();
    wavePath.moveTo(clipper.sampleWaveX(0, size), 0);
    const double step = 4.0;
    for (double y = step; y <= size.height; y += step) {
      wavePath.lineTo(clipper.sampleWaveX(y, size), y);
    }

    // Outer ambient neon glow blending left and right codec accents
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = isInteracting ? 8.0 : 5.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0)
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          leftAccent.withOpacity(0.55),
          Colors.white.withOpacity(0.9),
          rightAccent.withOpacity(0.65),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(wavePath, glowPaint);

    // Crisp 1.5px specular glass core line
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.35),
          Colors.white.withOpacity(0.95),
          Colors.white.withOpacity(0.35),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(wavePath, corePaint);

    // Draw glowing frosted-glass handle at the Gaussian apex
    final apexY = (clipper.cursorYRatio * size.height).clamp(48.0, size.height - 48.0);
    final apexX = clipper.sampleWaveX(apexY, size);
    final handleCenter = Offset(apexX, apexY);

    final haloPaint = Paint()
      ..color = rightAccent.withOpacity(isInteracting ? 0.42 : 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14.0);
    canvas.drawCircle(handleCenter, isInteracting ? 26.0 : 21.0, haloPaint);

    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: handleCenter, width: 34.0, height: 54.0),
      const Radius.circular(17.0),
    );
    final fillPaint = Paint()
      ..color = const Color(0xAA161922);
    canvas.drawRRect(pillRect, fillPaint);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.85),
          rightAccent.withOpacity(0.55),
          Colors.white.withOpacity(0.18),
        ],
      ).createShader(pillRect.outerRect);
    canvas.drawRRect(pillRect, borderPaint);

    // Draw left/right comparison chevrons inside handle
    final chevronPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = Colors.white.withOpacity(0.92);

    final leftChevron = Path()
      ..moveTo(handleCenter.dx - 3, handleCenter.dy - 5)
      ..lineTo(handleCenter.dx - 8, handleCenter.dy)
      ..lineTo(handleCenter.dx - 3, handleCenter.dy + 5);
    final rightChevron = Path()
      ..moveTo(handleCenter.dx + 3, handleCenter.dy - 5)
      ..lineTo(handleCenter.dx + 8, handleCenter.dy)
      ..lineTo(handleCenter.dx + 3, handleCenter.dy + 5);

    canvas.drawPath(leftChevron, chevronPaint);
    canvas.drawPath(rightChevron, chevronPaint);
  }

  @override
  bool shouldRepaint(covariant MoldedWaveDividerPainter oldDelegate) {
    return oldDelegate.clipper.splitRatio != clipper.splitRatio ||
        oldDelegate.clipper.cursorYRatio != clipper.cursorYRatio ||
        oldDelegate.clipper.waveAmplitude != clipper.waveAmplitude ||
        oldDelegate.isInteracting != isInteracting ||
        oldDelegate.leftAccent != leftAccent ||
        oldDelegate.rightAccent != rightAccent;
  }
}
