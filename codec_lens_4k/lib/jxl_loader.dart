import 'jxl_loader_stub.dart'
    if (dart.library.js_interop) 'jxl_loader_web.dart';

Future<String> loadJxlWithFallback({
  required String jxlPath,
  required String fallbackPath,
}) {
  return loadJxlWithFallbackImpl(jxlPath: jxlPath, fallbackPath: fallbackPath);
}
