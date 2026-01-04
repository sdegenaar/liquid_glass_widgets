import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  group('Glass Input Widgets', () {
    testWidgets('GlassPasswordField toggles visibility', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLiquidGlassLayer(
            settings: const LiquidGlassSettings(),
            child: const Scaffold(
              body: GlassPasswordField(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially obscured
      expect(find.byIcon(CupertinoIcons.eye_slash_fill), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);

      // Tap toggle
      await tester.tap(find.byIcon(CupertinoIcons.eye_slash_fill));
      await tester.pumpAndSettle();

      // Now visible
      expect(find.byIcon(CupertinoIcons.eye_fill), findsOneWidget);
      final textFieldVisible = tester.widget<TextField>(find.byType(TextField));
      expect(textFieldVisible.obscureText, isFalse);
    });

    testWidgets('GlassTextArea renders multi-line', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLiquidGlassLayer(
            settings: const LiquidGlassSettings(),
            child: const Scaffold(
              body: GlassTextArea(minLines: 3, maxLines: 5),
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.minLines, 3);
      expect(textField.maxLines, 5);
      expect(textField.keyboardType, TextInputType.multiline);
    });

    testWidgets('GlassFormField displays label and error', (tester) async {
      const label = 'Username';
      const error = 'Invalid username';

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLiquidGlassLayer(
            settings: const LiquidGlassSettings(),
            child: const Scaffold(
              body: GlassFormField(
                label: label,
                errorText: error,
                child: GlassTextField(),
              ),
            ),
          ),
        ),
      );

      expect(find.text(label), findsOneWidget);
      expect(find.text(error), findsOneWidget);
    });

    testWidgets('GlassPicker displays selected value', (tester) async {
      const value = 'Option 1';

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptiveLiquidGlassLayer(
            settings: const LiquidGlassSettings(),
            child: Scaffold(
              body: GlassPicker(
                value: value,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Pump to ensure layout effects settle
      await tester.pumpAndSettle();

      expect(find.text(value), findsOneWidget);
    });
  });
}
