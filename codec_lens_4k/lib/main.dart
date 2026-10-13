import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'jxl_loader.dart';

void main() {
  runApp(const CodecLensApp());
}

class CodecLensApp extends StatelessWidget {
  const CodecLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true);
    return MaterialApp(
      title: 'CodecLens 4K',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: base.copyWith(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFE7EEF8),
        textTheme: GoogleFonts.interTextTheme(base.textTheme),
      ),
      darkTheme: base.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F1624),
        textTheme: GoogleFonts.interTextTheme(base.textTheme),
      ),
      home: const CodecLensHome(),
    );
  }
}

class CodecLensHome extends StatefulWidget {
  const CodecLensHome({super.key});

  @override
  State<CodecLensHome> createState() => _CodecLensHomeState();
}

class _CodecLensHomeState extends State<CodecLensHome> {
  late Future<Map<String, CodecRecord>> _recordsFuture;
  String _left = 'jpg';
  String _right = 'avif';
  double _split = 0.5;

  @override
  void initState() {
    super.initState();
    _recordsFuture = _loadRecords();
  }

  Future<Map<String, CodecRecord>> _loadRecords() async {
    final payload = await rootBundle.loadString(
      'assets/wallpapers/metadata.json',
    );
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    final formats = decoded['formats'] as Map<String, dynamic>;
    final Map<String, CodecRecord> records = {};

    for (final entry in formats.entries) {
      final map = entry.value as Map<String, dynamic>;
      final path = map['asset'] as String;
      final baselinePath =
          (formats['png'] as Map<String, dynamic>)['asset'] as String;
      final displayUrl = entry.key == 'jxl'
          ? await loadJxlWithFallback(
              jxlPath: 'assets/$path',
              fallbackPath: 'assets/$baselinePath',
            )
          : 'assets/$path';
      records[entry.key] = CodecRecord(
        id: entry.key,
        resolution: map['resolution'] as String,
        bytes: (map['bytes'] as num).toInt(),
        savings: (map['compressionSavingsPercent'] as num).toDouble(),
        decodeMs: (map['decodeMs'] as num).toDouble(),
        assetUrl: displayUrl,
      );
    }

    return records;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: FutureBuilder<Map<String, CodecRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final records = snapshot.data!;
          final wallpaper =
              records[_right]?.assetUrl ?? records.values.first.assetUrl;
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                wallpaper,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [const Color(0xAA0D1629), const Color(0x660A111E)]
                        : [const Color(0x66EFF6FF), const Color(0x55D9E6FF)],
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const _WindowChrome(),
                      const SizedBox(height: 18),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 1100;
                            return GridView.count(
                              crossAxisCount: isNarrow ? 1 : 2,
                              childAspectRatio: isNarrow ? 1.2 : 1.65,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              children: [
                                _GlassCard(
                                  child: _ComparatorCard(
                                    records: records,
                                    left: _left,
                                    right: _right,
                                    split: _split,
                                    onSplit: (v) => setState(
                                      () => _split = v.clamp(0.06, 0.94),
                                    ),
                                  ),
                                ),
                                _GlassCard(
                                  child: _CardStack(
                                    children: records.values
                                        .map(
                                          (r) => _CodecTile(
                                            record: r,
                                            selected:
                                                _left == r.id || _right == r.id,
                                            onLeft: () =>
                                                setState(() => _left = r.id),
                                            onRight: () =>
                                                setState(() => _right = r.id),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CodecRecord {
  CodecRecord({
    required this.id,
    required this.resolution,
    required this.bytes,
    required this.savings,
    required this.decodeMs,
    required this.assetUrl,
  });

  final String id;
  final String resolution;
  final int bytes;
  final double savings;
  final double decodeMs;
  final String assetUrl;
}

class _WindowChrome extends StatelessWidget {
  const _WindowChrome();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          ...const [
            Color(0xFFFF5F56),
            Color(0xFFFFBD2E),
            Color(0xFF27C93F),
          ].map(
            (c) => Container(
              margin: const EdgeInsets.only(right: 8),
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'CodecLens 4K · Bing Wallpaper Visual Comparator',
            style: GoogleFonts.firaCode(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ComparatorCard extends StatelessWidget {
  const _ComparatorCard({
    required this.records,
    required this.left,
    required this.right,
    required this.split,
    required this.onSplit,
  });

  final Map<String, CodecRecord> records;
  final String left;
  final String right;
  final double split;
  final ValueChanged<double> onSplit;

  @override
  Widget build(BuildContext context) {
    final leftRecord = records[left] ?? records.values.first;
    final rightRecord = records[right] ?? records.values.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liquid Split Comparator',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Left: ${leftRecord.id.toUpperCase()}  ·  Right: ${rightRecord.id.toUpperCase()}',
          style: GoogleFonts.firaCode(fontSize: 12),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) => GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) =>
                  onSplit(d.localPosition.dx / c.maxWidth),
              onTapDown: (d) => onSplit(d.localPosition.dx / c.maxWidth),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _image(rightRecord.assetUrl),
                  ClipPath(
                    clipper: MoldedWaveClipper(split: split),
                    child: _image(leftRecord.assetUrl),
                  ),
                  Align(
                    alignment: Alignment(split * 2 - 1, 0),
                    child: _GlassPill(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _image(String url) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.black26),
      filterQuality: FilterQuality.high,
    );
  }
}

class MoldedWaveClipper extends CustomClipper<Path> {
  MoldedWaveClipper({required this.split});

  final double split;

  @override
  Path getClip(Size size) {
    final x = split * size.width;
    final wave = min(32.0, size.width * 0.045);
    final mid = size.height / 2;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(x, 0);
    path.cubicTo(
      x + wave * 0.2,
      mid * 0.25,
      x + wave,
      mid * 0.35,
      x + wave,
      mid,
    );
    path.cubicTo(
      x + wave,
      mid * 1.65,
      x + wave * 0.2,
      mid * 1.75,
      x,
      size.height,
    );
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant MoldedWaveClipper oldClipper) =>
      oldClipper.split != split;
}

class _GlassPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 126,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.55),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Center(child: Icon(Icons.drag_indicator_rounded)),
    );
  }
}

class _CardStack extends StatelessWidget {
  const _CardStack({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Codec Bento Cards',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          'Quick toggle: assign each codec to Left or Right lane.',
          style: GoogleFonts.firaCode(fontSize: 12),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: Wrap(spacing: 10, runSpacing: 10, children: children),
          ),
        ),
      ],
    );
  }
}

class _CodecTile extends StatelessWidget {
  const _CodecTile({
    required this.record,
    required this.selected,
    required this.onLeft,
    required this.onRight,
  });

  final CodecRecord record;
  final bool selected;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    final tint = _tint(record.id);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: tint.withValues(alpha: 0.16),
        border: Border.all(
          color: selected
              ? tint.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.35),
          width: 0.9,
        ),
      ),
      child: DefaultTextStyle(
        style: GoogleFonts.firaCode(
          fontSize: 11,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              record.id.toUpperCase(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text('Resolution: ${record.resolution}'),
            Text(
              'Size: ${(record.bytes / (1024 * 1024)).toStringAsFixed(2)} MB',
            ),
            Text('Savings: ${record.savings.toStringAsFixed(2)}%'),
            Text('Decode: ${record.decodeMs.toStringAsFixed(2)} ms'),
            const SizedBox(height: 10),
            Row(
              children: [
                _smallButton('Left', onLeft),
                const SizedBox(width: 8),
                _smallButton('Right', onRight),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallButton(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.white.withValues(alpha: 0.16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.55),
            width: 0.8,
          ),
        ),
        child: Text(text),
      ),
    );
  }

  Color _tint(String id) {
    switch (id) {
      case 'avif':
        return const Color(0xFF5ED9FF);
      case 'jxl':
        return const Color(0xFFB68FFF);
      case 'webp':
        return const Color(0xFF70F5B0);
      case 'png':
        return const Color(0xFFFFC873);
      default:
        return const Color(0xFFFF8DA0);
    }
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.34),
                Colors.white.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(
              width: 0.8,
              color: Colors.white.withValues(alpha: 0.62),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 26,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
