import 'package:liquid_glass_widgets/widgets/interactive/glass_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/widgets/shared/adaptive_liquid_glass_layer.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassSwitch', () {
    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSwitch(
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(GlassSwitch), findsOneWidget);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      var value = false;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSwitch(
              value: value,
              onChanged: (newValue) => value = newValue,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassSwitch));
      await tester.pump();

      expect(value, isTrue);
    });

    testWidgets('shows thumb in correct position when value is false',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSwitch(
              value: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(GlassSwitch), findsOneWidget);
    });

    testWidgets('shows thumb in correct position when value is true',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSwitch(
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(GlassSwitch), findsOneWidget);
    });

    testWidgets('respects custom colors', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSwitch(
              value: true,
              onChanged: (_) {},
              activeColor: Colors.blue,
              inactiveColor: Colors.grey,
              thumbColor: Colors.red,
            ),
          ),
        ),
      );

      expect(find.byType(GlassSwitch), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      const customWidth = 64.0;
      const customHeight = 32.0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSwitch(
              value: false,
              onChanged: (_) {},
              width: customWidth,
              height: customHeight,
            ),
          ),
        ),
      );

      expect(find.byType(GlassSwitch), findsOneWidget);
    });

    testWidgets('works in standalone mode', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSwitch(
            value: false,
            onChanged: (_) {},
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
          ),
        ),
      );

      expect(find.byType(GlassSwitch), findsOneWidget);
    });

    test('defaults are correct', () {
      final glassSwitch = GlassSwitch(
        value: false,
        onChanged: (_) {},
      );

      expect(glassSwitch.width, equals(58.0));
      expect(glassSwitch.height, equals(26.0));
      expect(glassSwitch.thumbColor, equals(Colors.white));
      expect(glassSwitch.useOwnLayer, isFalse);
      expect(glassSwitch.quality, isNull);
    });
  });
}
