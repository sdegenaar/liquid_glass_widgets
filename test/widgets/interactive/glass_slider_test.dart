import 'package:liquid_glass_widgets/types/glass_quality.dart';
import 'package:liquid_glass_widgets/widgets/interactive/glass_slider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/widgets/shared/adaptive_liquid_glass_layer.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassSlider', () {
    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSlider(
              value: 0.5,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(GlassSlider), findsOneWidget);
    });

    testWidgets('calls onChanged when dragged', (tester) async {
      var value = 0.5;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSlider(
              value: value,
              onChanged: (newValue) => value = newValue,
            ),
          ),
        ),
      );

      // Start drag at center
      final sliderFinder = find.byType(GlassSlider);
      await tester.drag(sliderFinder, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Value should have changed
      expect(value, isNot(equals(0.5)));
    });

    testWidgets('calls onChangeStart and onChangeEnd', (tester) async {
      var started = false;
      var ended = false;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSlider(
              value: 0.5,
              onChanged: (_) {},
              onChangeStart: (_) => started = true,
              onChangeEnd: (_) => ended = true,
            ),
          ),
        ),
      );

      await tester.drag(find.byType(GlassSlider), const Offset(50, 0));
      await tester.pumpAndSettle();

      expect(started, isTrue);
      expect(ended, isTrue);
    });

    testWidgets('respects min and max values', (tester) async {
      const min = 10.0;
      const max = 100.0;
      var value = 50.0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSlider(
              value: value,
              min: min,
              max: max,
              onChanged: (newValue) => value = newValue,
            ),
          ),
        ),
      );

      expect(find.byType(GlassSlider), findsOneWidget);
    });

    testWidgets('respects divisions for discrete values', (tester) async {
      var value = 2.0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSlider(
              value: value,
              min: 0,
              max: 5,
              divisions: 5,
              onChanged: (newValue) => value = newValue,
            ),
          ),
        ),
      );

      expect(find.byType(GlassSlider), findsOneWidget);
    });

    testWidgets('works in standalone mode', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSlider(
            value: 0.5,
            onChanged: (_) {},
            useOwnLayer: true,
            settings: defaultTestGlassSettings,
          ),
        ),
      );

      expect(find.byType(GlassSlider), findsOneWidget);
    });

    test('defaults are correct', () {
      final slider = GlassSlider(
        value: 0.5,
        onChanged: (_) {},
      );

      expect(slider.min, equals(0.0));
      expect(slider.max, equals(1.0));
      expect(slider.trackHeight, equals(4.0));
      expect(slider.thumbRadius, equals(15.0));
      expect(slider.useOwnLayer, isFalse);
      expect(slider.quality, equals(GlassQuality.standard));
    });
  });
}
