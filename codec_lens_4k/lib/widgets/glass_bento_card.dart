import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/codec_metadata.dart';

/// Procedural subtle film/glass grain painter for authentic Apple visionOS/macOS
/// multi-layered frosted glass depth.
class FrostedNoiseGrainPainter extends CustomPainter {
  final double opacity;
  const FrostedNoiseGrainPainter({this.opacity = 0.032});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;
    const int grainCount = 420;
    for (int i = 0; i < grainCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final isLight = rng.nextBool();
      paint.color = (isLight ? Colors.white : Colors.black).withOpacity(opacity);
      canvas.drawRect(Rect.fromLTWH(x, y, 1.2, 1.2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant FrostedNoiseGrainPainter oldDelegate) =>
      oldDelegate.opacity != opacity;
}

/// Reusable Apple visionOS/macOS Glassmorphic container with BackdropFilter,
/// top-left specular gradient border (0.5px-1px), subtle noise grain, and codec tint.
class AppleGlassContainer extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? tintColor;
  final bool isDark;
  final bool isHighlighted;

  const AppleGlassContainer({
    super.key,
    required this.child,
    this.blurSigma = 28.0,
    this.borderRadius = 22.0,
    this.padding = const EdgeInsets.all(18.0),
    this.tintColor,
    required this.isDark,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseSurface = isDark
        ? const Color(0xFF121621).withOpacity(0.56)
        : const Color(0xFFF8FAFC).withOpacity(0.64);
    final accent = tintColor ?? (isDark ? Colors.white : Colors.black);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.42 : 0.12),
            blurRadius: 32.0,
            spreadRadius: -4.0,
            offset: const Offset(0, 14),
          ),
          if (isHighlighted && tintColor != null)
            BoxShadow(
              color: tintColor!.withOpacity(isDark ? 0.24 : 0.18),
              blurRadius: 24.0,
              spreadRadius: 0.0,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: CustomPaint(
            painter: FrostedNoiseGrainPainter(opacity: isDark ? 0.035 : 0.022),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.alphaBlend(
                      accent.withOpacity(isHighlighted ? 0.16 : 0.07),
                      baseSurface,
                    ),
                    Color.alphaBlend(
                      accent.withOpacity(isHighlighted ? 0.08 : 0.02),
                      baseSurface.withOpacity(isDark ? 0.42 : 0.50),
                    ),
                  ],
                ),
                border: Border.all(
                  width: isHighlighted ? 1.1 : 0.75,
                  color: isHighlighted
                      ? accent.withOpacity(0.72)
                      : (isDark
                          ? Colors.white.withOpacity(0.24)
                          : Colors.white.withOpacity(0.68)),
                ),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dedicated Frosted-Glass Bento Card for each of the 5 4K UHD wallpaper codecs
/// (.avif, .jxl, .webp, .jpg, .png).
class CodecBentoCard extends StatelessWidget {
  final CodecFormatInfo codec;
  final bool isDark;
  final bool isSelectedLeft;
  final bool isSelectedRight;
  final VoidCallback onSelectLeft;
  final VoidCallback onSelectRight;

  const CodecBentoCard({
    super.key,
    required this.codec,
    required this.isDark,
    required this.isSelectedLeft,
    required this.isSelectedRight,
    required this.onSelectLeft,
    required this.onSelectRight,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary =
        isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final isActive = isSelectedLeft || isSelectedRight;

    return AppleGlassContainer(
      isDark: isDark,
      tintColor: codec.accentColor,
      isHighlighted: isActive,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header Row: Format Badge + Active Comparison Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: codec.accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: codec.accentColor.withOpacity(0.75),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    codec.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: codec.accentColor.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: codec.accentColor.withOpacity(0.42),
                        width: 0.6,
                      ),
                    ),
                    child: Text(
                      codec.extension,
                      style: TextStyle(
                        fontFamily: 'Fira Code',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: codec.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              // Quick-select pill toggles for Left (Before) and Right (After)
              Row(
                children: [
                  _PillToggleButton(
                    label: 'L · BEFORE',
                    isActive: isSelectedLeft,
                    accentColor: codec.accentColor,
                    isDark: isDark,
                    onTap: onSelectLeft,
                  ),
                  const SizedBox(width: 6),
                  _PillToggleButton(
                    label: 'R · AFTER',
                    isActive: isSelectedRight,
                    accentColor: codec.accentColor,
                    isDark: isDark,
                    onTap: onSelectRight,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            codec.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          // Primary File Size & Savings Hero Metric
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                codec.fileSizeFormatted,
                style: TextStyle(
                  fontFamily: 'Fira Code',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: codec.savingsVsPngPercent > 0
                      ? const Color(0xFF10B981).withOpacity(0.16)
                      : codec.accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  codec.savingsVsPngPercent > 0
                      ? '−${codec.savingsVsPngPercent.toStringAsFixed(1)}% vs PNG'
                      : 'Lossless Ref',
                  style: TextStyle(
                    fontFamily: 'Fira Code',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: codec.savingsVsPngPercent > 0
                        ? const Color(0xFF34D399)
                        : codec.accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Technical Metadata Grid (Fira Code)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black : Colors.white).withOpacity(0.24),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.08 : 0.4),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                _MetaRow(
                  label: 'RESOLUTION',
                  value: codec.resolution,
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                _MetaRow(
                  label: 'DECODE TIME',
                  value: '${codec.decodeTimeMs.toStringAsFixed(1)} ms',
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                _MetaRow(
                  label: 'PSNR / BPP',
                  value: '${codec.psnrDb.toStringAsFixed(1)} dB · ${codec.bitsPerPixel} bpp',
                  isDark: isDark,
                ),
                const SizedBox(height: 4),
                _MetaRow(
                  label: 'CHROMA / DEPTH',
                  value: '${codec.chromaSubsampling} · ${codec.bitDepth}',
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MetaRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Fira Code',
            fontSize: 10,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Fira Code',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}

class _PillToggleButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _PillToggleButton({
    required this.label,
    required this.isActive,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive
              ? accentColor.withOpacity(0.28)
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05)),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            width: 0.75,
            color: isActive
                ? accentColor
                : Colors.white.withOpacity(isDark ? 0.16 : 0.4),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Fira Code',
            fontSize: 9.5,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive
                ? (isDark ? Colors.white : Colors.black)
                : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
