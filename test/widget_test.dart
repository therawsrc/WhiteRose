import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The package name must exactly match the 'name:' field in your pubspec.yaml
import 'package:whiterose/main.dart';

void main() {
  testWidgets('White Rose UI Branding Test', (WidgetTester tester) async {
    // The class name here must exactly match the class defined in main.dart
    await tester.pumpWidget(const whiterose());

    // Verify that the title "WHITE ROSE" is present in the widget tree.
    expect(find.text('WHITE ROSE'), findsOneWidget);

    // Verify the background uses the specified off-white hex color.
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFFFDFDFD));
  });
}
