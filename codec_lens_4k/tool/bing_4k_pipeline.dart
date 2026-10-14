import 'dart:convert';
import 'dart:io';

/// Automated 4K UHD (3840x2160) Bing Daily Wallpaper Fetch & 5-Codec Conversion Pipeline.
/// Fetches the latest Bing UHD daily wallpaper and converts it into:
///   - .avif (AV1 Image File Format)
///   - .jxl  (JPEG XL ISO/IEC 18181)
///   - .webp (VP8 Intra-Frame WebP)
///   - .jpg  (ITU-T T.81 JPEG)
///   - .png  (Lossless PNG Reference)
Future<void> main(List<String> args) async {
  final outDir = Directory('assets/wallpapers');
  if (!outDir.existsSync()) {
    outDir.createSync(recursive: true);
  }

  stdout.writeln('=== CodecLens 4K: Bing UHD Wallpaper Pipeline ===');
  const bingApiUrl =
      'https://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=en-US';

  String baseName = 'bing_alpine_sunrise_4k';
  String title = 'Dolomites Alpine Sunrise & Glacial Lake Reflection';
  String copyright = '© Bing Daily Wallpaper Archive / UHD 3840×2160 Master';
  final masterPng = '${outDir.path}/$baseName.png';

  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(bingApiUrl));
    final response = await request.close();
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final jsonMap = jsonDecode(body) as Map<String, dynamic>;
      final images = jsonMap['images'] as List<dynamic>;
      if (images.isNotEmpty) {
        final img = images.first as Map<String, dynamic>;
        final urlBase = img['urlbase'] as String;
        title = (img['title'] as String?) ?? title;
        copyright = (img['copyright'] as String?) ?? copyright;
        final uhdUrl = 'https://www.bing.com${urlBase}_UHD.jpg';
        stdout.writeln('Fetching 4K UHD source: $uhdUrl');

        final imgReq = await client.getUrl(Uri.parse(uhdUrl));
        final imgRes = await imgReq.close();
        final rawJpg = '${outDir.path}/${baseName}_source.jpg';
        await imgRes.pipe(File(rawJpg).openWrite());

        // Normalize to exact 3840x2160 lossless PNG master
        await Process.run('ffmpeg', [
          '-y',
          '-i',
          rawJpg,
          '-vf',
          'scale=3840:2160:flags=lanczos',
          masterPng,
        ]);
      }
    }
    client.close();
  } catch (e) {
    stdout.writeln('Using local 4K UHD master asset ($masterPng): $e');
  }

  final targets = <String, List<String>>{
    'avif': ['-c:v', 'libsvtav1', '-crf', '26', '-preset', '8', '-pix_fmt', 'yuv420p'],
    'jxl': ['-c:v', 'libjxl', '-distance', '1.2', '-effort', '5'],
    'webp': ['-c:v', 'libwebp', '-q:v', '84', '-compression_level', '4'],
    'jpg': ['-c:v', 'mjpeg', '-q:v', '3'],
  };

  for (final entry in targets.entries) {
    final ext = entry.key;
    final outPath = '${outDir.path}/$baseName.$ext';
    stdout.writeln('Encoding 3840x2160 .$ext -> $outPath ...');
    await Process.run('ffmpeg', [
      '-y',
      '-hide_banner',
      '-loglevel',
      'error',
      '-i',
      masterPng,
      ...entry.value,
      outPath,
    ]);
  }

  stdout.writeln('4K UHD 5-codec pipeline complete.');
}
