import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/codec_metadata.dart';
import '../services/jxl_decoder_bridge.dart';
import 'glass_bento_card.dart';
import 'molded_wave_clipper.dart';

/// 60fps Touch- and Mouse-Responsive Before/After 4K Wallpaper Comparator
/// powered by `MoldedWaveClipper` and `JxlDecoderBridge`.
class LiquidSplitComparator extends StatefulWidget {
  final CodecFormatInfo leftCodec;
  final CodecFormatInfo rightCodec;
  final String? fallbackPngAssetPath;
  final bool isDark;
  final double zoomLevel;

  const LiquidSplitComparator({
    super.key,
    required this.leftCodec,
    required this.rightCodec,
    this.fallbackPngAssetPath,
    required this.isDark,
    required this.zoomLevel,
  });

  @override
  State<LiquidSplitComparator> createState() => _LiquidSplitComparatorState();
}

class _LiquidSplitComparatorState extends State<LiquidSplitComparator>
    with SingleTickerProviderStateMixin {
  double _splitRatio = 0.50;
  double _cursorYRatio = 0.50;
  double _waveAmplitude = 42.0;
  bool _isInteracting = false;

  Uint8List? _leftJxlBytes;
  Uint8List? _rightJxlBytes;

  @override
  void initState() {
    super.initState();
    _prepareCodecs();
  }

  @override
  void didUpdateWidget(covariant LiquidSplitComparator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.leftCodec.id != widget.leftCodec.id ||
        oldWidget.rightCodec.id != widget.rightCodec.id ||
        oldWidget.leftCodec.assetPath != widget.leftCodec.assetPath ||
        oldWidget.rightCodec.assetPath != widget.rightCodec.assetPath) {
      _prepareCodecs();
    }
  }

  Future<void> _prepareCodecs() async {
    if (widget.leftCodec.id == 'jxl') {
      final bytes =
          await JxlDecoderBridge.decodeJxlAsset(widget.leftCodec.assetPath);
      if (mounted) setState(() => _leftJxlBytes = bytes);
    } else {
      if (_leftJxlBytes != null && mounted) {
        setState(() => _leftJxlBytes = null);
      }
    }

    if (widget.rightCodec.id == 'jxl') {
      final bytes =
          await JxlDecoderBridge.decodeJxlAsset(widget.rightCodec.assetPath);
      if (mounted) setState(() => _rightJxlBytes = bytes);
    } else {
      if (_rightJxlBytes != null && mounted) {
        setState(() => _rightJxlBytes = null);
      }
    }
  }

  void _updatePosition(Offset localPosition, Size size) {
    setState(() {
      final newSplit = (localPosition.dx / size.width).clamp(0.04, 0.96);
      final dx = (newSplit - _splitRatio) * size.width;
      _splitRatio = newSplit;
      _cursorYRatio = (localPosition.dy / size.height).clamp(0.05, 0.95);
      // Dynamic Gaussian bulge responsive to pointer velocity and direction
      _waveAmplitude = (44.0 + dx.clamp(-28.0, 28.0)).clamp(24.0, 72.0);
    });
  }

  Widget _buildCodecLayer(CodecFormatInfo codec, Uint8List? jxlBytes) {
    if (codec.id == 'jxl' && jxlBytes != null) {
      return Image.memory(
        jxlBytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.high,
      );
    }
    return Image.asset(
      codec.assetPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stackTrace) {
        if (widget.fallbackPngAssetPath != null) {
          return Image.asset(
            widget.fallbackPngAssetPath!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            filterQuality: FilterQuality.high,
          );
        }
        return const Center(child: Icon(Icons.broken_image, color: Colors.white54));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final clipper = MoldedWaveClipper(
      splitRatio: _splitRatio,
      cursorYRatio: _cursorYRatio,
      waveAmplitude: _waveAmplitude,
      waveSigma: 96.0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return MouseRegion(
          cursor: SystemMouseCursors.resizeLeftRight,
          onEnter: (_) => setState(() => _isInteracting = true),
          onExit: (_) => setState(() {
            _isInteracting = false;
            _waveAmplitude = 38.0;
          }),
          onHover: (event) => _updatePosition(event.localPosition, size),
          child: GestureDetector(
            onPanStart: (details) {
              setState(() => _isInteracting = true);
              _updatePosition(details.localPosition, size);
            },
            onPanUpdate: (details) =>
                _updatePosition(details.localPosition, size),
            onPanEnd: (_) => setState(() {
              _isInteracting = false;
              _waveAmplitude = 38.0;
            }),
            onTapDown: (details) =>
                _updatePosition(details.localPosition, size),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // RIGHT LAYER (Next-Gen Codec: e.g. AVIF / JPEG XL)
                  Transform.scale(
                    scale: widget.zoomLevel,
                    child: _buildCodecLayer(widget.rightCodec, _rightJxlBytes),
                  ),

                  // LEFT LAYER (Legacy Codec: e.g. JPG / PNG / WebP) clipped by MoldedWaveClipper
                  ClipPath(
                    clipper: clipper,
                    child: Transform.scale(
                      scale: widget.zoomLevel,
                      child: _buildCodecLayer(widget.leftCodec, _leftJxlBytes),
                    ),
                  ),

                  // MOLDED GAUSSIAN WAVE DIVIDER & GLOWING FROSTED HANDLE
                  IgnorePointer(
                    child: CustomPaint(
                      painter: MoldedWaveDividerPainter(
                        clipper: clipper,
                        leftAccent: widget.leftCodec.accentColor,
                        rightAccent: widget.rightCodec.accentColor,
                        isInteracting: _isInteracting,
                      ),
                    ),
                  ),

                  // FLOATING TOP-LEFT PILL (BEFORE / LEFT CODEC)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _FloatingOverlayPill(
                      sideLabel: 'BEFORE · LEFT',
                      codec: widget.leftCodec,
                      isDark: widget.isDark,
                    ),
                  ),

                  // FLOATING TOP-RIGHT PILL (AFTER / RIGHT CODEC)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _FloatingOverlayPill(
                      sideLabel: 'AFTER · RIGHT',
                      codec: widget.rightCodec,
                      isDark: widget.isDark,
                    ),
                  ),

                  // FLOATING BOTTOM TELEMETRY BAR
                  Positioned(
                    bottom: 14,
                    left: 16,
                    right: 16,
                    child: Center(
                      child: AppleGlassContainer(
                        isDark: widget.isDark,
                        blurSigma: 24,
                        borderRadius: 999,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'MoldedWaveClipper 60fps · Split ${(_splitRatio * 100).toStringAsFixed(1)}% · '
                          'Δ Size: ${_computeDeltaText(widget.leftCodec, widget.rightCodec)} · '
                          'Zoom: ${widget.zoomLevel.toStringAsFixed(1)}×',
                          style: const TextStyle(
                            fontFamily: 'Fira Code',
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _computeDeltaText(CodecFormatInfo left, CodecFormatInfo right) {
    if (left.fileSizeBytes == 0) return '0%';
    final diffRatio =
        ((right.fileSizeBytes - left.fileSizeBytes) / left.fileSizeBytes) * 100.0;
    final sign = diffRatio > 0 ? '+' : '';
    return '$sign${diffRatio.toStringAsFixed(1)}%';
  }
}

class _FloatingOverlayPill extends StatelessWidget {
  final String sideLabel;
  final CodecFormatInfo codec;
  final bool isDark;

  const _FloatingOverlayPill({
    required this.sideLabel,
    required this.codec,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return AppleGlassContainer(
      isDark: true,
      tintColor: codec.accentColor,
      isHighlighted: true,
      blurSigma: 22,
      borderRadius: 999,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: codec.accentColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sideLabel: ${codec.label} (${codec.extension})',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${codec.fileSizeFormatted} · ${codec.psnrDb} dB',
            style: TextStyle(
              fontFamily: 'Fira Code',
              fontSize: 11,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }
}
