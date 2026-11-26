// `minDetentResistance` replaces `resistance` below the smallest detent only.
// `null` (the default) keeps the rubber band; `0` stops the drag at the floor,
// for persistent sheets that are always-visible chrome.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _grabber = Key('grabber');

Widget _makeSheet(
  GlassModalSheetController controller, {
  double? minDetentResistance,
}) =>
    MaterialApp(
      home: Scaffold(
        body: LiquidGlassWidgets.wrap(
          child: GlassModalSheetScaffold(
            body: const ColoredBox(
              color: Colors.blue,
              child: SizedBox.expand(),
            ),
            sheet: const Align(
              alignment: Alignment.topCenter,
              child: SizedBox(key: _grabber, width: 200, height: 40),
            ),
            mode: GlassSheetMode.persistent,
            resistance: 0.5,
            minDetentResistance: minDetentResistance,
            controller: controller,
          ),
        ),
      ),
    );

/// Rests the sheet on [state] and returns that position.
Future<double> _restAt(
  WidgetTester tester,
  GlassModalSheetController controller,
  GlassSheetState state,
) async {
  await tester.pumpAndSettle();
  controller.snapToState(state);
  await tester.pumpAndSettle();
  return controller.value;
}

/// Drags the sheet by [dy] from its grabber and returns the live position
/// with the finger still down.
Future<(TestGesture, double)> _dragBy(
  WidgetTester tester,
  GlassModalSheetController controller,
  double dy,
) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(_grabber)),
  );
  await gesture.moveBy(Offset(0, dy.sign * 30));
  await gesture.moveBy(Offset(0, dy));
  await tester.pump();
  return (gesture, controller.value);
}

void main() {
  group('GlassModalSheet minDetentResistance', () {
    testWidgets('null keeps the rubber band below the smallest detent',
        (tester) async {
      final controller = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(controller));
      final floor = await _restAt(tester, controller, GlassSheetState.peek);

      final (gesture, dragged) = await _dragBy(tester, controller, 80);
      expect(dragged, lessThan(floor));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.value, closeTo(floor, 1e-3));
    });

    testWidgets('0 stops a downward drag at the smallest detent',
        (tester) async {
      final controller = GlassModalSheetController();
      await tester.pumpWidget(
        _makeSheet(controller, minDetentResistance: 0),
      );
      final floor = await _restAt(tester, controller, GlassSheetState.peek);

      final (gesture, dragged) = await _dragBy(tester, controller, 300);
      expect(dragged, closeTo(floor, 1e-6));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(controller.value, closeTo(floor, 1e-6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a value in between scales the overflow below the detent',
        (tester) async {
      final controller = GlassModalSheetController();
      await tester.pumpWidget(
        _makeSheet(controller, minDetentResistance: 0.1),
      );
      final floor = await _restAt(tester, controller, GlassSheetState.peek);
      final height = tester.getSize(find.byType(Scaffold)).height;

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_grabber)),
      );
      await gesture.moveBy(const Offset(0, 30));
      final start = controller.value;
      await gesture.moveBy(const Offset(0, 120));
      await tester.pump();

      // 120 px further down, damped by 0.1 instead of `resistance` (0.5).
      expect(controller.value, closeTo(start - 120 / height * 0.1, 1e-3));
      expect(controller.value, lessThan(floor));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('resistance above the largest detent is unaffected',
        (tester) async {
      Future<double> overshootAboveFull(double? minDetentResistance) async {
        final controller = GlassModalSheetController();
        await tester.pumpWidget(
          _makeSheet(controller, minDetentResistance: minDetentResistance),
        );
        final full = await _restAt(tester, controller, GlassSheetState.full);
        final (gesture, dragged) = await _dragBy(tester, controller, -80);
        await gesture.up();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        return dragged - full;
      }

      final withDefault = await overshootAboveFull(null);
      final withZero = await overshootAboveFull(0);

      expect(withDefault, greaterThan(0));
      expect(withZero, closeTo(withDefault, 1e-6));
    });

    testWidgets('GlassModalSheet.show forwards it to the sheet',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LiquidGlassWidgets.wrap(
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () => GlassModalSheet.show<void>(
                    context: context,
                    minDetentResistance: 0,
                    builder: (context) => const SizedBox(height: 200),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final sheet = tester.widget<GlassModalSheet>(
        find.byType(GlassModalSheet),
      );
      expect(sheet.minDetentResistance, 0);
    });
  });
}
