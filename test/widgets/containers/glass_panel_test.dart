import 'package:liquid_glass_widgets/types/glass_quality.dart';
import 'package:liquid_glass_widgets/widgets/containers/glass_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassPanel', () {
    testWidgets('can be instantiated with default parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassPanel(),
          ),
        ),
      );

      expect(find.byType(GlassPanel), findsOneWidget);
    });

    testWidgets('displays child widget', (tester) async {
      const testText = 'Panel Content';

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassPanel(
              child: Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('has default padding of 24', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassPanel(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassPanel), findsOneWidget);
    });

    testWidgets('respects custom padding', (tester) async {
      const customPadding = EdgeInsets.all(40);

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassPanel(
              padding: customPadding,
              child: Text('Custom Padding'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassPanel), findsOneWidget);
    });

    testWidgets('works in standalone mode', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassPanel(
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
            child: Text('Standalone Panel'),
          ),
        ),
      );

      expect(find.byType(GlassPanel), findsOneWidget);
    });

    test('defaults are correct', () {
      const panel = GlassPanel();

      expect(panel.padding, equals(const EdgeInsets.all(24)));
      expect(panel.useOwnLayer, isFalse);
      expect(panel.quality, equals(GlassQuality.standard));
    });
  });
}
