import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:codec_lens_4k/models/codec_metadata.dart';

void main() {
  group('CodecLens Netflix AVIF Test Suite Assets Tests', () {
    test('Old Bing wallpaper test files must be deleted', () {
      final wallpapersDir = Directory('assets/wallpapers');
      if (wallpapersDir.existsSync()) {
        final bingFiles = wallpapersDir
            .listSync()
            .where((entity) => entity.path.contains('bing_alpine_sunrise_4k'))
            .toList();
        expect(bingFiles, isEmpty, reason: 'All old Bing test files should be replaced/removed');
      }
    });

    test('testFiles/Netflix/avif folder must contain all 121 files from AOMediaCodec repo', () {
      final testFilesDir = Directory('testFiles/Netflix/avif');
      expect(testFilesDir.existsSync(), isTrue, reason: 'testFiles/Netflix/avif folder must exist');

      final files = testFilesDir
          .listSync()
          .whereType<File>()
          .toList();
      // 121 files from repo + metadata.json = 122 files
      expect(files.length, greaterThanOrEqualTo(121));

      // Key sample files check
      final expectedKeys = [
        'README.md',
        'original_sdr_cosmos01000.png',
        'sdr_cosmos01000_cicp1-13-0_lossless.avif',
        'sdr_cosmos01000_cicp1-13-0_lossless.png',
        'sdr_cosmos01000_cicp1-13-6_yuv420_limited_qp10.avif',
        'sdr_cosmos01000_cicp1-13-6_yuv420_limited_qp10.png',
        'sdr_cosmos01000_cicp1-13-6_yuv420_limited_qp20.avif',
        'sdr_cosmos01000_cicp1-13-6_yuv420_limited_qp20.png',
        'sdr_cosmos01000_cicp1-13-6_yuv420_limited_qp40.avif',
        'sdr_cosmos01000_cicp1-13-6_yuv420_limited_qp40.png',
        'sdr_cosmos01000_cicp1-13-6_yuv444_full_qp10.avif',
        'sdr_cosmos01000_cicp1-13-6_yuv444_full_qp10.png',
        'sdr_cosmos01000_cicp1-13-6_yuv444_full_qp20.avif',
        'sdr_cosmos01000_cicp1-13-6_yuv444_full_qp20.png',
        'sdr_cosmos01000_cicp1-13-6_yuv444_full_qp40.avif',
        'sdr_cosmos01000_cicp1-13-6_yuv444_full_qp40.png',
      ];

      for (final key in expectedKeys) {
        expect(
          File('testFiles/Netflix/avif/$key').existsSync(),
          isTrue,
          reason: 'Expected file $key to exist in testFiles/Netflix/avif',
        );
      }
    });

    test('metadata.json parses correctly into WallpaperBundleMetadata and all formats point to existing files', () {
      final metaFile = File('assets/wallpapers/metadata.json');
      expect(metaFile.existsSync(), isTrue);

      final jsonMap = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      final bundle = WallpaperBundleMetadata.fromJson(jsonMap);

      expect(bundle.wallpaperTitle, isNotEmpty);
      expect(bundle.formats, isNotEmpty);

      for (final fmt in bundle.formats) {
        final assetFile = File(fmt.assetPath);
        expect(assetFile.existsSync(), isTrue, reason: '${fmt.assetPath} should exist on disk');
      }
    });

    test('TestSuiteCatalog contains 7 scenes (4 SDR Netflix + 1 HDR Netflix + 2 AOMedia Blog) with all 5 formats', () {
      final metaFile = File('assets/wallpapers/metadata.json');
      final jsonMap = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      final catalog = TestSuiteCatalog.fromJson(jsonMap);

      expect(catalog.scenes.length, equals(7));
      expect(catalog.scenes.first.sceneId, equals('aomedia_parrot'));
      expect(catalog.scenes[1].sceneId, equals('aomedia_bridge'));
      expect(catalog.scenes.last.sceneId, equals('cosmos01650_hdr'));

      final expectedSceneIds = {
        'cosmos01000',
        'cosmos01650',
        'cosmos07296',
        'cosmos12920',
        'cosmos01650_hdr',
        'aomedia_parrot',
        'aomedia_bridge',
      };
      final foundIds = catalog.scenes.map((s) => s.sceneId).toSet();
      expect(foundIds, equals(expectedSceneIds));

      final expectedFormatIds = {'avif', 'jxl', 'jpg', 'gif', 'png'};

      for (final s in catalog.scenes) {
        expect(s.formats.length, equals(5));
        final formatIds = s.formats.map((f) => f.id).toSet();
        expect(formatIds, equals(expectedFormatIds));

        for (final fmt in s.formats) {
          final file = File(fmt.assetPath);
          expect(file.existsSync(), isTrue, reason: 'File ${fmt.assetPath} must exist');

          if (fmt.id == 'jxl') {
            final decodedWebp = File('${fmt.assetPath}.decoded.webp');
            expect(decodedWebp.existsSync(), isTrue,
                reason: 'Decoded webp proxy must exist for cross-browser JXL rendering: ${decodedWebp.path}');
          }
        }
      }
    });
  });
}
