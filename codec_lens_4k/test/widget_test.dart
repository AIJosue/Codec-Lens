import 'package:codec_lens_4k/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App shows loading indicator initially', (tester) async {
    await tester.pumpWidget(const CodecLensApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
