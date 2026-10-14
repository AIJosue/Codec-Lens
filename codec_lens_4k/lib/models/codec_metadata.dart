import 'package:flutter/material.dart';

class CodecFormatInfo {
  final String id;
  final String extension;
  final String label;
  final String description;
  final String mimeType;
  final Color accentColor;
  final String fileName;
  final String assetPath;
  final String resolution;
  final String aspectRatio;
  final int fileSizeBytes;
  final String fileSizeFormatted;
  final double savingsVsPngPercent;
  final double savingsVsRawPercent;
  final double bitsPerPixel;
  final double encodeTimeMs;
  final double decodeTimeMs;
  final double psnrDb;
  final String chromaSubsampling;
  final String bitDepth;

  const CodecFormatInfo({
    required this.id,
    required this.extension,
    required this.label,
    required this.description,
    required this.mimeType,
    required this.accentColor,
    required this.fileName,
    required this.assetPath,
    required this.resolution,
    required this.aspectRatio,
    required this.fileSizeBytes,
    required this.fileSizeFormatted,
    required this.savingsVsPngPercent,
    required this.savingsVsRawPercent,
    required this.bitsPerPixel,
    required this.encodeTimeMs,
    required this.decodeTimeMs,
    required this.psnrDb,
    required this.chromaSubsampling,
    required this.bitDepth,
  });

  static Color _parseHex(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  factory CodecFormatInfo.fromJson(Map<String, dynamic> json) {
    return CodecFormatInfo(
      id: json['id'] as String,
      extension: json['extension'] as String,
      label: json['label'] as String,
      description: json['description'] as String,
      mimeType: json['mimeType'] as String,
      accentColor: _parseHex(json['accentHex'] as String),
      fileName: json['fileName'] as String,
      assetPath: json['assetPath'] as String,
      resolution: json['resolution'] as String,
      aspectRatio: json['aspectRatio'] as String,
      fileSizeBytes: (json['fileSizeBytes'] as num).toInt(),
      fileSizeFormatted: json['fileSizeFormatted'] as String,
      savingsVsPngPercent: (json['savingsVsPngPercent'] as num).toDouble(),
      savingsVsRawPercent: (json['savingsVsRawPercent'] as num).toDouble(),
      bitsPerPixel: (json['bitsPerPixel'] as num).toDouble(),
      encodeTimeMs: (json['encodeTimeMs'] as num).toDouble(),
      decodeTimeMs: (json['decodeTimeMs'] as num).toDouble(),
      psnrDb: (json['psnrDb'] as num).toDouble(),
      chromaSubsampling: json['chromaSubsampling'] as String,
      bitDepth: json['bitDepth'] as String,
    );
  }
}

class ResolutionMetadata {
  final int width;
  final int height;
  final String label;

  const ResolutionMetadata({
    required this.width,
    required this.height,
    required this.label,
  });

  double get aspectRatio => width / height;

  factory ResolutionMetadata.fromJson(Map<String, dynamic> json) {
    return ResolutionMetadata(
      width: (json['width'] as num?)?.toInt() ?? 2048,
      height: (json['height'] as num?)?.toInt() ?? 858,
      label: (json['label'] as String?) ?? '2048 × 858 (2.39:1 CinemaScope)',
    );
  }
}

class WallpaperBundleMetadata {
  final String wallpaperTitle;
  final String bingCopyright;
  final String bingDate;
  final String resolutionLabel;
  final ResolutionMetadata resolution;
  final int uncompressedRgbBytes;
  final int baselinePngBytes;
  final List<CodecFormatInfo> formats;
  final String? sceneId;
  final String? sceneNumber;
  final String? mode;
  final String? sceneDescription;
  final String? icon;

  const WallpaperBundleMetadata({
    required this.wallpaperTitle,
    required this.bingCopyright,
    required this.bingDate,
    required this.resolutionLabel,
    required this.resolution,
    required this.uncompressedRgbBytes,
    required this.baselinePngBytes,
    required this.formats,
    this.sceneId,
    this.sceneNumber,
    this.mode,
    this.sceneDescription,
    this.icon,
  });

  factory WallpaperBundleMetadata.fromJson(Map<String, dynamic> json) {
    final resMap = (json['resolution'] as Map<String, dynamic>?) ??
        {'width': 2048, 'height': 858, 'label': '2048 × 858 (2.39:1 CinemaScope)'};
    final res = ResolutionMetadata.fromJson(resMap);
    final list = (json['formats'] as List<dynamic>)
        .map((e) => CodecFormatInfo.fromJson(e as Map<String, dynamic>))
        .toList();
    return WallpaperBundleMetadata(
      wallpaperTitle: json['wallpaperTitle'] as String,
      bingCopyright: json['bingCopyright'] as String,
      bingDate: json['bingDate'] as String,
      resolutionLabel: res.label,
      resolution: res,
      uncompressedRgbBytes: (json['uncompressedRgbBytes'] as num).toInt(),
      baselinePngBytes: (json['BaselinePngBytes'] as num).toInt(),
      formats: list,
      sceneId: json['sceneId'] as String?,
      sceneNumber: json['sceneNumber'] as String?,
      mode: json['mode'] as String?,
      sceneDescription: json['sceneDescription'] as String?,
      icon: json['icon'] as String?,
    );
  }
}

class TestSuiteCatalog {
  final List<WallpaperBundleMetadata> scenes;
  final int defaultIndex;

  const TestSuiteCatalog({
    required this.scenes,
    this.defaultIndex = 0,
  });

  factory TestSuiteCatalog.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('scenes') && json['scenes'] is List) {
      final list = (json['scenes'] as List<dynamic>)
          .map((e) => WallpaperBundleMetadata.fromJson(e as Map<String, dynamic>))
          .toList();
      final idx = (json['currentSceneIndex'] as num?)?.toInt() ?? 0;
      return TestSuiteCatalog(scenes: list, defaultIndex: idx);
    }
    return TestSuiteCatalog(
      scenes: [WallpaperBundleMetadata.fromJson(json)],
      defaultIndex: 0,
    );
  }
}
