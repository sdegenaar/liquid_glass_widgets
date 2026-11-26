// A persistent sheet is always-visible chrome: its smallest detent is a floor.
// The snap spring is seeded with the release velocity, so a fast downward
// fling used to carry the sheet below that floor — and, flung hard enough,
// below the screen edge — before it came back.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const _grabber = Key('grabber');

Widget _makeSheet(GlassModalSheetController controller) => MaterialApp(
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
            controller: controller,
          ),
        ),
      ),
    );

/// Rests the sheet on its smallest detent and returns that position.
Future<double> _restAtFloor(
  WidgetTester tester,
  GlassModalSheetController controller,
) async {
  await tester.pumpAndSettle();
  controller.snapToState(GlassSheetState.peek);
  await tester.pumpAndSettle();
  return controller.value;
}

/// Pumps one frame at a time until nothing animates, returning the lowest
/// sheet position seen on the way.
Future<double> _lowestWhileSettling(
  WidgetTester tester,
  GlassModalSheetController controller,
) async {
  var lowest = controller.value;
  for (var frame = 0; frame < 600 && tester.hasRunningAnimations; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    if (controller.value < lowest) lowest = controller.value;
  }
  return lowest;
}

void main() {
  group('GlassModalSheet persistent floor', () {
    testWidgets('a fast downward fling never dips below the smallest detent',
        (tester) async {
      final controller = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(controller));
      final floor = await _restAtFloor(tester, controller);

      controller.snapToState(GlassSheetState.half);
      await tester.pumpAndSettle();
      expect(controller.value, greaterThan(floor));

      // A short, fast flick: the finger lifts well above the floor, so any
      // dip below it comes from the spring alone.
      await tester.flingFrom(
        tester.getCenter(find.byKey(_grabber)),
        const Offset(0, 100),
        6000,
      );
      final lowest = await _lowestWhileSettling(tester, controller);

      expect(lowest, greaterThanOrEqualTo(floor - 1e-6));
      expect(controller.value, closeTo(floor, 1e-3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a rubber-band release below the floor still springs back',
        (tester) async {
      final controller = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(controller));
      final floor = await _restAtFloor(tester, controller);

      // Drag below the floor: the rubber band is unchanged.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_grabber)),
      );
      await gesture.moveBy(const Offset(0, 30));
      await gesture.moveBy(const Offset(0, 80));
      await tester.pump();
      final stretched = controller.value;
      expect(stretched, lessThan(floor));

      // On release the sheet travels back up; it does not jump to the floor
      // and it never goes further down than where it was let go.
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(controller.value, lessThan(floor));

      final lowest = await _lowestWhileSettling(tester, controller);
      expect(lowest, greaterThanOrEqualTo(stretched - 1e-6));
      expect(controller.value, closeTo(floor, 1e-3));
      expect(tester.takeException(), isNull);
    });
  });
}
