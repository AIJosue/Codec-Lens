@JS('loadJxlWithFallback')
library;

import 'dart:js_util' as js_util;

import 'package:js/js.dart';

Future<String> loadJxlWithFallbackImpl({
  required String jxlPath,
  required String fallbackPath,
}) async {
  final promise = loadJxlWithFallbackJs(jxlPath, fallbackPath);
  return js_util.promiseToFuture<String>(promise);
}

@JS('loadJxlWithFallback')
external Object loadJxlWithFallbackJs(String jxlPath, String fallbackPath);
