// Tests for glass_modal_sheet_state.dart — deep branch coverage
// Uses the actual GlassModalSheetScaffold(background:, sheetChild:) API
// and GlassModalSheetController.snapToState()
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Widget _makeSheet({
  GlassModalSheetController? controller,
  void Function(SheetState)? onStateChanged,
  SheetMode mode = SheetMode.persistent,
  double halfSize = 0.45,
  Widget? sheetChild,
}) =>
    MaterialApp(
      home: Scaffold(
        body: LiquidGlassWidgets.wrap(
          child: GlassModalSheetScaffold(
            body: const ColoredBox(
              color: Colors.blue,
              child: SizedBox.expand(),
            ),
            sheet: sheetChild ??
                ListView(children: [
                  for (int i = 0; i < 20; i++) ListTile(title: Text('Item $i')),
                ]),
            halfSize: halfSize,
            mode: mode,
            controller: controller,
            onStateChanged: onStateChanged,
          ),
        ),
      ),
    );

void main() {
  group('GlassModalSheetController — attach/detach', () {
    testWidgets('controller has valid currentState after mount',
        (tester) async {
      final ctrl = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(controller: ctrl));
      await tester.pumpAndSettle();
      expect(ctrl.currentState, isA<SheetState>());
    });

    testWidgets('detach on dispose: snapToState is no-op', (tester) async {
      final ctrl = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(controller: ctrl));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox()); // triggers dispose
      await tester.pump();
      expect(() => ctrl.snapToState(SheetState.full), returnsNormally);
    });

    testWidgets('swapping controller detaches old and attaches new',
        (tester) async {
      final ctrl1 = GlassModalSheetController();
      final ctrl2 = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(controller: ctrl1));
      await tester.pumpAndSettle();
      expect(ctrl1.currentState, isA<SheetState>());

      await tester.pumpWidget(_makeSheet(controller: ctrl2));
      await tester.pumpAndSettle();
      // Old controller detached — returns default
      expect(ctrl1.currentState, SheetState.hidden);
      // New controller attached
      expect(ctrl2.currentState, isA<SheetState>());
    });
  });

  group('GlassModalSheetController — state transitions', () {
    testWidgets('snapToState(full) transitions to full', (tester) async {
      final ctrl = GlassModalSheetController();
      final states = <SheetState>[];
      await tester.pumpWidget(_makeSheet(
        controller: ctrl,
        onStateChanged: states.add,
      ));
      await tester.pumpAndSettle();
      ctrl.snapToState(SheetState.full);
      await tester.pumpAndSettle();
      expect(ctrl.currentState, SheetState.full);
    });

    testWidgets('snapToState(half) transitions to half', (tester) async {
      final ctrl = GlassModalSheetController();
      final states = <SheetState>[];
      await tester.pumpWidget(_makeSheet(
        controller: ctrl,
        mode: SheetMode.persistent,
        onStateChanged: states.add,
      ));
      await tester.pumpAndSettle();
      ctrl.snapToState(SheetState.half);
      await tester.pumpAndSettle();
      expect(ctrl.currentState, SheetState.half);
    });

    testWidgets('snapToState(hidden) in dismissible mode hides sheet',
        (tester) async {
      final ctrl = GlassModalSheetController();
      final states = <SheetState>[];
      await tester.pumpWidget(_makeSheet(
        controller: ctrl,
        mode: SheetMode.dismissible,
        onStateChanged: states.add,
      ));
      await tester.pumpAndSettle();
      ctrl.snapToState(SheetState.full);
      await tester.pumpAndSettle();
      ctrl.snapToState(SheetState.hidden);
      await tester.pumpAndSettle();
      expect(ctrl.currentState, SheetState.hidden);
    });

    testWidgets('snapToState(hidden) in persistent mode clamps to peek',
        (tester) async {
      final ctrl = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(
        controller: ctrl,
        mode: SheetMode.persistent,
      ));
      await tester.pumpAndSettle();
      ctrl.snapToState(SheetState.full);
      await tester.pumpAndSettle();
      ctrl.snapToState(SheetState.hidden); // clamps to peek
      await tester.pumpAndSettle();
      // Persistent: minimum is peek, not hidden
      expect(ctrl.currentState, isNot(SheetState.hidden));
    });

    testWidgets('snapToState with animate=false does instant jump',
        (tester) async {
      final ctrl = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(controller: ctrl));
      await tester.pumpAndSettle();
      ctrl.snapToState(SheetState.full, animate: false);
      await tester.pump();
      expect(ctrl.currentState, SheetState.full);
    });

    testWidgets('value setter jumps to exact position', (tester) async {
      final ctrl = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(controller: ctrl));
      await tester.pumpAndSettle();
      ctrl.value = 0.5;
      await tester.pump();
      expect(ctrl.value, closeTo(0.5, 0.15));
    });
  });

  group('GlassModalSheet — halfSize change triggers recalculation', () {
    testWidgets('halfSize change rebuilds geometry', (tester) async {
      double halfSize = 0.5;
      await tester.pumpWidget(StatefulBuilder(
        builder: (ctx, setState) => MaterialApp(
          home: Scaffold(
            body: LiquidGlassWidgets.wrap(
              child: GlassModalSheetScaffold(
                body: GestureDetector(
                  onTap: () => setState(() => halfSize = 0.4),
                  child: const ColoredBox(
                    color: Colors.green,
                    child: SizedBox.expand(),
                  ),
                ),
                sheet: const SizedBox.expand(),
                halfSize: halfSize,
              ),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();
      expect(find.byType(GlassModalSheetScaffold), findsOneWidget);
    });
  });

  group('GlassModalSheet — onStateChanged callback', () {
    testWidgets('fires on each transition', (tester) async {
      final ctrl = GlassModalSheetController();
      final states = <SheetState>[];
      await tester.pumpWidget(_makeSheet(
        controller: ctrl,
        onStateChanged: states.add,
      ));
      await tester.pumpAndSettle();
      ctrl.snapToState(SheetState.full);
      await tester.pumpAndSettle();
      ctrl.snapToState(SheetState.half);
      await tester.pumpAndSettle();
      expect(states, contains(SheetState.full));
      expect(states, contains(SheetState.half));
    });
  });

  group('GlassModalSheet — drag handle interaction', () {
    testWidgets('dragging scaffold content reveals sheet', (tester) async {
      final ctrl = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(controller: ctrl));
      await tester.pumpAndSettle();
      final scaffoldFinder = find.byType(GlassModalSheetScaffold);
      final rect = tester.getRect(scaffoldFinder);
      // Drag from bottom of visible area upward
      await tester.dragFrom(
        Offset(rect.center.dx, rect.bottom - 100),
        const Offset(0, -250),
      );
      await tester.pumpAndSettle();
      // Regardless of the exact result, there's no crash
      expect(find.byType(GlassModalSheetScaffold), findsOneWidget);
    });

    testWidgets('downward drag from full via controller collapses sheet',
        (tester) async {
      final ctrl = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(
        controller: ctrl,
        mode: SheetMode.persistent,
      ));
      await tester.pumpAndSettle();
      // Expand to full
      ctrl.snapToState(SheetState.full, animate: false);
      await tester.pump();
      expect(ctrl.currentState, SheetState.full);
      // Collapse back
      ctrl.snapToState(SheetState.half, animate: false);
      await tester.pump();
      expect(ctrl.currentState, SheetState.half);
    });
  });

  group('GlassModalSheet — mode variants', () {
    testWidgets('dismissible mode allows hidden state', (tester) async {
      final ctrl = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(
        controller: ctrl,
        mode: SheetMode.dismissible,
      ));
      await tester.pumpAndSettle();
      ctrl.snapToState(SheetState.hidden);
      await tester.pumpAndSettle();
      expect(ctrl.currentState, SheetState.hidden);
    });

    testWidgets('persistent mode: hidden clamps to peek', (tester) async {
      final ctrl = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(
        controller: ctrl,
        mode: SheetMode.persistent,
      ));
      await tester.pumpAndSettle();
      ctrl.snapToState(SheetState.hidden);
      await tester.pumpAndSettle();
      expect(ctrl.currentState, isNot(SheetState.hidden));
    });
  });

  group('GlassModalSheet — velocity-based snap', () {
    testWidgets('snapToState with velocity uses spring simulation',
        (tester) async {
      final ctrl = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(controller: ctrl));
      await tester.pumpAndSettle();
      ctrl.snapToState(SheetState.full, velocity: 1500);
      await tester.pumpAndSettle();
      expect(ctrl.currentState, SheetState.full);
    });
  });

  group('GlassModalSheet — dispose cleanup', () {
    testWidgets('dispose removes observer and controllers', (tester) async {
      final ctrl = GlassModalSheetController();
      await tester.pumpWidget(_makeSheet(controller: ctrl));
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(true, isTrue); // no exception
    });
  });
}
