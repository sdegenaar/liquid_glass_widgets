import 'package:liquid_glass_widgets/types/glass_quality.dart';
import 'package:liquid_glass_widgets/widgets/interactive/glass_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassIconButton', () {
    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icons.favorite,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(GlassIconButton), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icons.add,
              onPressed: () => pressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassIconButton));
      await tester.pump();

      expect(pressed, isTrue);
    });

    testWidgets('does not call onPressed when null (disabled)', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icons.add,
              onPressed: null,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassIconButton));
      await tester.pump();

      // Should not throw, just ignore tap
      expect(find.byType(GlassIconButton), findsOneWidget);
    });

    testWidgets('renders circle shape by default', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icons.star,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(GlassIconButton), findsOneWidget);
    });

    testWidgets('renders rounded square shape when specified', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icons.star,
              onPressed: () {},
              shape: GlassIconButtonShape.roundedSquare,
            ),
          ),
        ),
      );

      expect(find.byType(GlassIconButton), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      const customSize = 60.0;

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icons.star,
              onPressed: () {},
              size: customSize,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(GlassIconButton),
              matching: find.byType(SizedBox),
            )
            .first,
      );

      expect(sizedBox.width, equals(customSize));
      expect(sizedBox.height, equals(customSize));
    });

    testWidgets('has proper semantics', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(GlassIconButton),
              matching: find.byType(Semantics),
            )
            .first,
      );

      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.enabled, isTrue);
    });

    testWidgets('works in standalone mode', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassIconButton(
            icon: Icons.star,
            onPressed: () {},
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
          ),
        ),
      );

      expect(find.byType(GlassIconButton), findsOneWidget);
    });

    test('defaults are correct', () {
      final button = GlassIconButton(
        icon: Icons.star,
        onPressed: () {},
      );

      expect(button.size, equals(44));
      expect(button.shape, equals(GlassIconButtonShape.circle));
      expect(button.useOwnLayer, isFalse);
      expect(button.quality, equals(GlassQuality.standard));
      expect(button.interactionScale, equals(0.95));
    });
  });
}
