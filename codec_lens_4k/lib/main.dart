import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/codec_metadata.dart';
import 'widgets/glass_bento_card.dart';
import 'widgets/liquid_split_comparator.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CodecLens4KApp());
}

class CodecLens4KApp extends StatefulWidget {
  const CodecLens4KApp({super.key});

  @override
  State<CodecLens4KApp> createState() => _CodecLens4KAppState();
}

class _CodecLens4KAppState extends State<CodecLens4KApp> {
  bool _isDarkGlass = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CodecLens: Netflix AVIF Test Suite Visual Comparator',
      debugShowCheckedModeBanner: false,
      themeMode: _isDarkGlass ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFE2E8F0),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFF07090E),
        useMaterial3: true,
      ),
      home: CodecLensBentoDashboard(
        isDark: _isDarkGlass,
        onToggleTheme: () => setState(() => _isDarkGlass = !_isDarkGlass),
      ),
    );
  }
}

class CodecLensBentoDashboard extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;

  const CodecLensBentoDashboard({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<CodecLensBentoDashboard> createState() =>
      _CodecLensBentoDashboardState();
}

class _CodecLensBentoDashboardState extends State<CodecLensBentoDashboard> {
  TestSuiteCatalog? _catalog;
  WallpaperBundleMetadata? _bundle;
  String _selectedSceneId = 'aomedia_parrot';
  String _leftCodecId = 'jpg';
  String _rightCodecId = 'avif';
  double _zoomLevel = 1.0;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final jsonStr =
        await rootBundle.loadString('assets/wallpapers/metadata.json');
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    if (mounted) {
      final catalog = TestSuiteCatalog.fromJson(map);
      setState(() {
        _catalog = catalog;
        _updateActiveBundle();
      });
    }
  }

  void _updateActiveBundle() {
    final cat = _catalog;
    if (cat == null || cat.scenes.isEmpty) return;
    final matched = cat.scenes.firstWhere(
      (s) => s.sceneId == _selectedSceneId,
      orElse: () => cat.scenes.first,
    );
    _bundle = matched;

    // Ensure left and right codec IDs match available formats in this bundle
    if (!matched.formats.any((f) => f.id == _leftCodecId)) {
      _leftCodecId = matched.formats.first.id;
    }
    if (!matched.formats.any((f) => f.id == _rightCodecId)) {
      _rightCodecId = matched.formats.length > 1
          ? matched.formats[1].id
          : matched.formats.last.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundle = _bundle;
    if (bundle == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final leftCodec = bundle.formats.firstWhere(
      (c) => c.id == _leftCodecId,
      orElse: () => bundle.formats.first,
    );
    final rightCodec = bundle.formats.firstWhere(
      (c) => c.id == _rightCodecId,
      orElse: () => bundle.formats.length > 4 ? bundle.formats[4] : bundle.formats.last,
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient Wallpaper Background Bleed Layer for True Frosted Glass
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
            child: Opacity(
              opacity: widget.isDark ? 0.62 : 0.45,
              child: Image.asset(
                bundle.formats
                    .firstWhere((f) => f.id == 'png',
                        orElse: () => bundle.formats.first)
                    .assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
          ),
          // Ambient Vignette
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.35,
                colors: widget.isDark
                    ? [
                        const Color(0xFF0B0F19).withOpacity(0.35),
                        const Color(0xFF06080E).withOpacity(0.86),
                      ]
                    : [
                        const Color(0xFFF8FAFC).withOpacity(0.45),
                        const Color(0xFFE2E8F0).withOpacity(0.82),
                      ],
              ),
            ),
          ),
          // Main Scrollable Bento Grid inside macOS Terminal Window Chrome
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMacOsTerminalHeader(bundle),
                      const SizedBox(height: 12),
                      _buildSampleSceneSelector(bundle),
                      const SizedBox(height: 14),
                      // Primary 4K Liquid Split Comparator Bento Stage
                      AppleGlassContainer(
                        isDark: widget.isDark,
                        blurSigma: 32,
                        borderRadius: 26,
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _buildComparatorToolbar(bundle, leftCodec, rightCodec),
                            const SizedBox(height: 12),
                            AspectRatio(
                              aspectRatio: bundle.resolution.aspectRatio,
                              child: LiquidSplitComparator(
                                leftCodec: leftCodec,
                                rightCodec: rightCodec,
                                fallbackPngAssetPath: bundle.formats
                                    .firstWhere((f) => f.id == 'png',
                                        orElse: () => bundle.formats.first)
                                    .assetPath,
                                isDark: widget.isDark,
                                zoomLevel: _zoomLevel,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Frosted-Glass Codec Bento Cards for All Available Formats
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          final crossAxisCount = width > 1180
                              ? 5
                              : width > 860
                                  ? 3
                                  : width > 560
                                      ? 2
                                      : 1;
                          return GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: bundle.formats.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                              mainAxisExtent: 236,
                            ),
                            itemBuilder: (context, index) {
                              final fmt = bundle.formats[index];
                              return CodecBentoCard(
                                codec: fmt,
                                isDark: widget.isDark,
                                isSelectedLeft: fmt.id == _leftCodecId,
                                isSelectedRight: fmt.id == _rightCodecId,
                                onSelectLeft: () =>
                                    setState(() => _leftCodecId = fmt.id),
                                onSelectRight: () =>
                                    setState(() => _rightCodecId = fmt.id),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacOsTerminalHeader(WallpaperBundleMetadata bundle) {
    final textPrimary =
        widget.isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary =
        widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return AppleGlassContainer(
      isDark: widget.isDark,
      blurSigma: 30,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          // Traffic light window controls + Terminal title
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _TrafficLightDot(color: Color(0xFFFF5F56)),
              const SizedBox(width: 8),
              const _TrafficLightDot(color: Color(0xFFFFBD2E)),
              const SizedBox(width: 8),
              const _TrafficLightDot(color: Color(0xFF27C93F)),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CodecLens · AVIF vs PNG, JPEG, GIF & JPEG XL Visual Comparator',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    'zsh ~/codec_lens_4k — ${bundle.wallpaperTitle} · AOMedia Netflix Test Suite',
                    style: TextStyle(
                      fontFamily: 'Fira Code',
                      fontSize: 11,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Right controls: Zoom Pills + Dark/Light Frosted Glass Toggle
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final z in [1.0, 2.0, 4.0])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _zoomLevel = z),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _zoomLevel == z
                            ? const Color(0xFF00E5FF).withOpacity(0.24)
                            : Colors.white.withOpacity(widget.isDark ? 0.07 : 0.4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _zoomLevel == z
                              ? const Color(0xFF00E5FF)
                              : Colors.white.withOpacity(0.22),
                          width: 0.75,
                        ),
                      ),
                      child: Text(
                        '${z.toInt()}× UHD',
                        style: TextStyle(
                          fontFamily: 'Fira Code',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: widget.onToggleTheme,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(widget.isDark ? 0.09 : 0.55),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.32),
                      width: 0.75,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isDark
                            ? Icons.dark_mode_rounded
                            : Icons.light_mode_rounded,
                        size: 14,
                        color: textPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.isDark ? 'Dark Glass' : 'Light Glass',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparatorToolbar(
    WallpaperBundleMetadata bundle,
    CodecFormatInfo leftCodec,
    CodecFormatInfo rightCodec,
  ) {
    final textPrimary =
        widget.isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary =
        widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            '${bundle.wallpaperTitle} (${bundle.bingDate})',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
        ),
        Text(
          '${leftCodec.label} (${leftCodec.fileSizeFormatted})  ⇄  ${rightCodec.label} (${rightCodec.fileSizeFormatted})',
          style: TextStyle(
            fontFamily: 'Fira Code',
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSampleSceneSelector(WallpaperBundleMetadata bundle) {
    final textPrimary =
        widget.isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final textSecondary =
        widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    final scenes = [
      {
        'id': 'aomedia_parrot',
        'icon': '🦜',
        'label': 'Scarlet Macaw',
        'sub': 'AOMedia Blog Sample',
        'badge': 'AOMedia Blog',
        'badgeColor': const Color(0xFFFF9F0A),
      },
      {
        'id': 'aomedia_bridge',
        'icon': '🌉',
        'label': 'Night Bridge',
        'sub': 'AOMedia Blog Sample',
        'badge': 'AOMedia Blog',
        'badgeColor': const Color(0xFF30D158),
      },
      {
        'id': 'cosmos01000',
        'icon': '🐑',
        'label': 'Cosmos 01000',
        'sub': 'Sheep & Meadow',
        'badge': 'SDR',
        'badgeColor': const Color(0xFF00E5FF),
      },
      {
        'id': 'cosmos01650',
        'icon': '⚡',
        'label': 'Cosmos 01650',
        'sub': 'Victor & Sky',
        'badge': 'SDR',
        'badgeColor': const Color(0xFF00E5FF),
      },
      {
        'id': 'cosmos07296',
        'icon': '⚙️',
        'label': 'Cosmos 07296',
        'sub': 'Machine & Glass',
        'badge': 'SDR',
        'badgeColor': const Color(0xFF00E5FF),
      },
      {
        'id': 'cosmos12920',
        'icon': '🌅',
        'label': 'Cosmos 12920',
        'sub': 'Sunset Panorama',
        'badge': 'SDR',
        'badgeColor': const Color(0xFF00E5FF),
      },
      {
        'id': 'cosmos01650_hdr',
        'icon': '✨',
        'label': 'Cosmos HDR',
        'sub': 'Victor in Storm (10-bit)',
        'badge': 'HDR 10-bit',
        'badgeColor': const Color(0xFFBF5AF2),
      },
    ];

    return AppleGlassContainer(
      isDark: widget.isDark,
      blurSigma: 24,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          // Scene Selection Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'SAMPLE SCENE:',
                style: TextStyle(
                  fontFamily: 'Fira Code',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: textSecondary,
                ),
              ),
              for (final scene in scenes)
                Builder(
                  builder: (context) {
                    final isSelected = _selectedSceneId == scene['id'];
                    final badgeColor = scene['badgeColor'] as Color;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSceneId = scene['id'] as String;
                          _updateActiveBundle();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? badgeColor.withOpacity(0.22)
                              : Colors.white.withOpacity(widget.isDark ? 0.06 : 0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? badgeColor : Colors.white.withOpacity(0.18),
                            width: isSelected ? 1.4 : 0.75,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(scene['icon'] as String, style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 7),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      scene['label'] as String,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? badgeColor : textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withOpacity(0.18),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: badgeColor.withOpacity(0.55),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Text(
                                        scene['badge'] as String,
                                        style: TextStyle(
                                          fontFamily: 'Fira Code',
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w700,
                                          color: badgeColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  scene['sub'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 9.5,
                                    color: textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
          // Format legend indicator pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(widget.isDark ? 0.08 : 0.45),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: Colors.white.withOpacity(0.22),
                width: 0.75,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.compare_rounded, size: 14, color: Color(0xFF00E5FF)),
                const SizedBox(width: 6),
                Text(
                  '5 Formats: AVIF · JXL · JPG · GIF · PNG',
                  style: TextStyle(
                    fontFamily: 'Fira Code',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrafficLightDot extends StatelessWidget {
  final Color color;
  const _TrafficLightDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black.withOpacity(0.22),
          width: 0.5,
        ),
      ),
    );
  }
}
