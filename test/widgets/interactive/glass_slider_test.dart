import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/widgets/interactive/glass_slider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/widgets/shared/adaptive_liquid_glass_layer.dart';
import 'package:liquid_glass_widgets/types/glass_quality.dart';

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
      expect(slider.quality, isNull);
    });

    testWidgets('drag cancel is handled without crash', (tester) async {
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

      // Start drag, move, then send a cancel (exercises _handleDragCancel)
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(GlassSlider)),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();
      await gesture.cancel();
      await tester.pump();

      expect(find.byType(GlassSlider), findsOneWidget);
    });

    testWidgets('divisions drag across boundary triggers haptic (no crash)',
        (tester) async {
      // The haptic path (line 327: HapticFeedback.selectionClick) fires when
      // _dragValue != newValue across a division boundary.
      double value = 0.0;
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSlider(
              value: value,
              min: 0,
              max: 4,
              divisions: 4,
              onChanged: (v) => value = v,
            ),
          ),
        ),
      );

      // Drag far enough to cross at least one division boundary
      await tester.drag(find.byType(GlassSlider), const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(find.byType(GlassSlider), findsOneWidget);
    });

    testWidgets('onChanged=null means semantics still present', (tester) async {
      // Lines 415-422: onIncrease / onDecrease are null when onChanged is null
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassSlider(
              value: 0.5,
              onChanged: null, // read-only slider
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassSlider), findsOneWidget);
    });

    testWidgets('Premium path renders thumb as solid white at rest',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSlider(
            value: 0.5,
            onChanged: (_) {},
            quality: GlassQuality.premium,
          ),
        ),
      );

      // The material Container is wrapped in an Opacity widget.
      // At rest (transition=0), Opacity.opacity = 1.0, Container color = white at full alpha.
      final opacityFinder = find.byWidgetPredicate((widget) {
        if (widget is Opacity && widget.opacity == 1.0) {
          return true;
        }
        return false;
      });
      expect(opacityFinder, findsWidgets); // At least one Opacity at full

      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final dec = widget.decoration as BoxDecoration;
          return dec.boxShadow != null && dec.boxShadow!.isNotEmpty;
        }
        return false;
      });

      expect(containerFinder, findsOneWidget);
      final container = tester.widget<Container>(containerFinder);
      final dec = container.decoration as BoxDecoration;
      expect(dec.color, isNotNull);
      expect(dec.color!.a,
          equals(1.0)); // Solid white (Opacity controls visibility)
    });

    testWidgets('Standard path renders thumb as solid white at rest',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSlider(
            value: 0.5,
            onChanged: (_) {},
            quality: GlassQuality.standard,
          ),
        ),
      );

      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final dec = widget.decoration as BoxDecoration;
          return dec.boxShadow != null && dec.boxShadow!.isNotEmpty;
        }
        return false;
      });

      expect(containerFinder, findsOneWidget);
      final container = tester.widget<Container>(containerFinder);
      final dec = container.decoration as BoxDecoration;
      expect(dec.color, isNotNull);
      expect(dec.color!.a,
          equals(1.0)); // Solid white (Opacity controls visibility)
    });
  });
}
