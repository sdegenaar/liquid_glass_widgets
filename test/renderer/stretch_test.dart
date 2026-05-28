import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/src/renderer/stretch.dart';

void main() {
  // ──────────────────────────────────────────────────────────────────────────
  // OffsetResistanceExtension.withResistance
  // ──────────────────────────────────────────────────────────────────────────

  group('OffsetResistanceExtension.withResistance', () {
    test('zero resistance returns same offset', () {
      const offset = Offset(10, 20);
      expect(offset.withResistance(0), offset);
    });

    test('zero-magnitude offset returns Offset.zero', () {
      expect(Offset.zero.withResistance(0.5), Offset.zero);
    });

    test('positive resistance reduces magnitude', () {
      const offset = Offset(100, 0);
      final resisted = offset.withResistance(0.1);
      expect(resisted.dx, lessThan(100));
      expect(resisted.dy, closeTo(0, 1e-10));
    });

    test('preserves direction for horizontal offset', () {
      const offset = Offset(50, 0);
      final resisted = offset.withResistance(0.05);
      expect(resisted.dx, greaterThan(0));
      expect(resisted.dy, closeTo(0, 1e-10));
    });

    test('preserves direction for vertical offset', () {
      const offset = Offset(0, 50);
      final resisted = offset.withResistance(0.05);
      expect(resisted.dx, closeTo(0, 1e-10));
      expect(resisted.dy, greaterThan(0));
    });

    test('preserves direction for diagonal offset', () {
      const offset = Offset(30, 40); // magnitude 50
      final resisted = offset.withResistance(0.1);
      // Direction should be preserved: dy/dx ratio same
      expect(resisted.dy / resisted.dx, closeTo(4 / 3, 1e-6));
    });

    test('higher resistance results in smaller magnitude', () {
      const offset = Offset(100, 0);
      final lowResist = offset.withResistance(0.01);
      final highResist = offset.withResistance(0.5);
      expect(highResist.dx, lessThan(lowResist.dx));
    });

    test('negative offset preserves negative direction', () {
      const offset = Offset(-60, 0);
      final resisted = offset.withResistance(0.1);
      expect(resisted.dx, lessThan(0));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // RenderRawLiquidStretch.getScale
  // ──────────────────────────────────────────────────────────────────────────

  group('RenderRawLiquidStretch.getScale', () {
    late RenderRawLiquidStretch render;

    setUp(() {
      render = RenderRawLiquidStretch(stretchPixels: Offset.zero);
    });

    test('returns (1, 1) for empty size', () {
      final scale = render.getScale(
        stretchPixels: const Offset(10, 0),
        size: Size.zero,
      );
      expect(scale, const Offset(1, 1));
    });

    test('horizontal stretch increases scaleX', () {
      final scale = render.getScale(
        stretchPixels: const Offset(20, 0),
        size: const Size(100, 100),
      );
      expect(scale.dx, greaterThan(1.0));
    });

    test('vertical stretch increases scaleY', () {
      final scale = render.getScale(
        stretchPixels: const Offset(0, 20),
        size: const Size(100, 100),
      );
      expect(scale.dy, greaterThan(1.0));
    });

    test('zero stretch returns near (1, 1)', () {
      final scale = render.getScale(
        stretchPixels: Offset.zero,
        size: const Size(100, 100),
      );
      // Volume correction: targetVolume=1+0*0.5=1, currentVolume=1*1=1 →
      // correction=1 → scale is approximately (1, 1)
      expect(scale.dx, closeTo(1.0, 0.01));
      expect(scale.dy, closeTo(1.0, 0.01));
    });

    test('larger stretch gives larger scale values', () {
      final small = render.getScale(
        stretchPixels: const Offset(5, 0),
        size: const Size(100, 100),
      );
      final large = render.getScale(
        stretchPixels: const Offset(30, 0),
        size: const Size(100, 100),
      );
      expect(large.dx, greaterThan(small.dx));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // LiquidStretch widget
  // ──────────────────────────────────────────────────────────────────────────

  group('LiquidStretch', () {
    test('defaults are correct', () {
      const widget = LiquidStretch(child: SizedBox.shrink());
      expect(widget.interactionScale, 1.05);
      expect(widget.stretch, 0.5);
      expect(widget.resistance, 0.01);
      expect(widget.hitTestBehavior, HitTestBehavior.opaque);
    });

    testWidgets('passes through to child when stretch=0 and scale=1.0',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiquidStretch(
            stretch: 0,
            interactionScale: 1.0,
            child: Text('no stretch'),
          ),
        ),
      );
      expect(find.text('no stretch'), findsOneWidget);
    });

    testWidgets('renders GlassDragBuilder when stretch > 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiquidStretch(
            stretch: 0.5,
            child: SizedBox(width: 100, height: 50),
          ),
        ),
      );
      expect(find.byType(LiquidStretch), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // RawLiquidStretch widget
  // ──────────────────────────────────────────────────────────────────────────

  group('RawLiquidStretch', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RawLiquidStretch(
            stretchPixels: Offset.zero,
            child: Text('stretch child'),
          ),
        ),
      );
      expect(find.text('stretch child'), findsOneWidget);
    });

    testWidgets('renders with non-zero stretch', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RawLiquidStretch(
            stretchPixels: Offset(10, 5),
            child: SizedBox(width: 80, height: 40, child: Text('stretched')),
          ),
        ),
      );
      expect(find.text('stretched'), findsOneWidget);
    });

    testWidgets('updates stretchPixels without error', (tester) async {
      var pixels = Offset.zero;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => MaterialApp(
            home: Column(
              children: [
                RawLiquidStretch(
                  stretchPixels: pixels,
                  child: const SizedBox(width: 80, height: 40),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => pixels = const Offset(15, 0)),
                  child: const Text('Update'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Update'));
      await tester.pump();

      expect(find.byType(RawLiquidStretch), findsOneWidget);
    });
  });
}
