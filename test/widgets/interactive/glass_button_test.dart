import 'package:liquid_glass_widgets/types/glass_quality.dart';
import 'package:liquid_glass_widgets/widgets/interactive/glass_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassButton', () {
    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: CupertinoIcons.heart,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(GlassButton), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
    });

    testWidgets('displays icon correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icons.star,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icons.add,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassButton));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not call onTap when disabled', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icons.add,
              onTap: () => tapped = true,
              enabled: false,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassButton));
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('renders with reduced opacity when disabled', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icons.add,
              onTap: () {},
              enabled: false,
            ),
          ),
        ),
      );

      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byType(LiquidStretch),
          matching: find.byType(Opacity),
        ),
      );

      expect(opacity.opacity, equals(0.5));
    });

    testWidgets('GlassButton.custom displays custom child', (tester) async {
      const testText = 'Custom Button';

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton.custom(
              onTap: () {},
              child: const Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('respects custom width and height', (tester) async {
      const customWidth = 100.0;
      const customHeight = 80.0;

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icons.star,
              onTap: () {},
              width: customWidth,
              height: customHeight,
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(GlassButton),
              matching: find.byType(SizedBox),
            )
            .first,
      );

      expect(sizedBox.width, equals(customWidth));
      expect(sizedBox.height, equals(customHeight));
    });

    testWidgets('has proper semantics', (tester) async {
      const semanticLabel = 'Add Item';

      await tester.pumpWidget(
        createTestApp(
          child: LiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassButton(
              icon: Icons.add,
              onTap: () {},
              label: semanticLabel,
            ),
          ),
        ),
      );

      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(GlassButton),
              matching: find.byType(Semantics),
            )
            .first,
      );

      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.label, equals(semanticLabel));
      expect(semantics.properties.enabled, isTrue);
    });

    testWidgets('works in standalone mode with useOwnLayer', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassButton(
            icon: Icons.star,
            onTap: () {},
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
          ),
        ),
      );

      expect(find.byType(GlassButton), findsOneWidget);
    });

    testWidgets('uses correct glass quality', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassButton(
            icon: Icons.star,
            onTap: () {},
            useOwnLayer: true,
            quality: GlassQuality.premium,
          ),
        ),
      );

      expect(find.byType(GlassButton), findsOneWidget);
    });

    test('defaults are correct', () {
      final button = GlassButton(
        icon: Icons.star,
        onTap: () {},
      );

      expect(button.width, equals(56));
      expect(button.height, equals(56));
      expect(button.iconSize, equals(24.0));
      expect(button.enabled, isTrue);
      expect(button.useOwnLayer, isFalse);
      expect(button.quality, equals(GlassQuality.standard));
      expect(button.interactionScale, equals(1.05));
      expect(button.stretch, equals(0.5));
    });
  });
}
