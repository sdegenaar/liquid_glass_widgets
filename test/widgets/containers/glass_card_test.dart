// GlassCard is deprecated (use GlassContainer.card) but stays covered here
// until its removal in 2.0.0.
// ignore_for_file: deprecated_member_use_from_same_package, deprecated_member_use
import 'package:liquid_glass_widgets/widgets/containers/glass_card.dart';
import 'package:liquid_glass_widgets/widgets/containers/glass_container.dart';
import 'package:liquid_glass_widgets/src/renderer/liquid_glass_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/widgets/shared/adaptive_liquid_glass_layer.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassCard', () {
    testWidgets('can be instantiated with default parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassCard(),
          ),
        ),
      );

      expect(find.byType(GlassCard), findsOneWidget);
    });

    testWidgets('displays child widget', (tester) async {
      const testText = 'Card Content';

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassCard(
              child: Text(testText),
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('has default padding of 16', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassCard), findsOneWidget);
    });

    testWidgets('respects custom padding', (tester) async {
      const customPadding = EdgeInsets.all(32);

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassCard(
              padding: customPadding,
              child: Text('Custom Padding'),
            ),
          ),
        ),
      );

      expect(find.byType(GlassCard), findsOneWidget);
    });

    testWidgets('works in standalone mode', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassCard(
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
            child: Text('Standalone Card'),
          ),
        ),
      );

      expect(find.byType(GlassCard), findsOneWidget);
    });

    test('defaults are correct', () {
      const card = GlassCard();

      expect(card.padding, equals(const EdgeInsets.all(16)));
      expect(card.useOwnLayer, isFalse);
      expect(card.quality, isNull);
    });

    testWidgets('forwards every property to GlassContainer.card',
        (tester) async {
      const shape = LiquidRoundedSuperellipse(borderRadius: 20);

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassCard(
              width: 120,
              height: 80,
              padding: EdgeInsets.all(4),
              margin: EdgeInsets.all(2),
              shape: shape,
              clipBehavior: Clip.antiAlias,
              child: Text('x'),
            ),
          ),
        ),
      );

      final container =
          tester.widget<GlassContainer>(find.byType(GlassContainer));
      expect(container.width, 120);
      expect(container.height, 80);
      expect(container.padding, const EdgeInsets.all(4));
      expect(container.margin, const EdgeInsets.all(2));
      expect(container.shape, shape);
      expect(container.clipBehavior, Clip.antiAlias);
    });

    testWidgets('default GlassCard matches default GlassContainer.card',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassCard(),
          ),
        ),
      );
      final fromCard =
          tester.widget<GlassContainer>(find.byType(GlassContainer));

      const direct = GlassContainer.card();
      expect(fromCard.padding, direct.padding);
      expect(fromCard.shape, direct.shape);
      expect(fromCard.clipBehavior, direct.clipBehavior);
      expect(fromCard.useOwnLayer, direct.useOwnLayer);
    });
  });
}
