import 'package:liquid_glass_widgets/src/renderer/liquid_glass_renderer.dart';
import 'package:liquid_glass_widgets/src/engine/stretch.dart';
import 'package:liquid_glass_widgets/widgets/interactive/glass_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/widgets/shared/adaptive_liquid_glass_layer.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassIconButton', () {
    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.favorite),
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
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.add),
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
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.add),
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
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.star),
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
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.star),
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
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.star),
              onPressed: () {},
              size: customSize,
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byType(GlassIconButton));

      expect(size.width, equals(customSize));
      expect(size.height, equals(customSize));
    });

    testWidgets('has proper semantics', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: Icon(Icons.add),
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
            icon: Icon(Icons.star),
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
        icon: Icon(Icons.star),
        onPressed: () {},
      );

      expect(button.size, equals(44));
      expect(button.shape, equals(GlassIconButtonShape.circle));
      expect(button.useOwnLayer, isFalse);
      expect(button.quality, isNull);
      expect(button.interactionScale, equals(0.95));
      expect(button.anchorStretchSettings, isNull);
    });
  });

  // ── interaction resolution ────────────────────────────────────────────────
  // GlassIconButton always uses a fixed factor (0.95 shrink), never the native
  // point-based sizing path. These tests pin that contract so a future change
  // to the delegation in build() is caught immediately.
  group('GlassIconButton interaction resolution', () {
    /// The LiquidStretch the icon button delegates to via GlassButton.
    LiquidStretch stretchOf(WidgetTester tester) =>
        tester.widget<LiquidStretch>(
          find.descendant(
            of: find.byType(GlassIconButton),
            matching: find.byType(LiquidStretch),
          ),
        );

    testWidgets('always uses a fixed factor — never the native sizing path',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: const Icon(Icons.star),
              onPressed: () {},
            ),
          ),
        ),
      );

      final stretch = stretchOf(tester);
      // A fixed 0.95 factor: pressGrowth must be null so the button shrinks
      // uniformly rather than inflating by a point-growth amount.
      expect(stretch.interactionScale, equals(0.95));
      expect(stretch.pressGrowth, isNull,
          reason:
              'GlassIconButton must never use the native point-sizing path');
    });

    testWidgets('forwards explicit anchorStretchSettings to GlassButton',
        (tester) async {
      const settings = AnchorStretchSettings(intensity: 0.5);
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassIconButton(
              icon: const Icon(Icons.star),
              onPressed: () {},
              anchorStretchSettings: settings,
            ),
          ),
        ),
      );

      expect(stretchOf(tester).anchorStretchSettings.intensity, equals(0.5));
    });
  });
}
