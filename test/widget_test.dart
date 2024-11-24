// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:subtitle_editor/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Find and tap 3 icons under player
    await tester.tap(find.byIcon(Icons.access_time_outlined));
    await tester.tap(find.byIcon(Icons.video_call_rounded));
    await tester.tap(find.byIcon(Icons.text_snippet_rounded));

  });
}
