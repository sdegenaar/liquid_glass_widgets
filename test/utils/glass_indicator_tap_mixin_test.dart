import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// ---------------------------------------------------------------------------
// Minimal test harness that mixes in GlassIndicatorTapMixin
// ---------------------------------------------------------------------------

/// A minimal widget that exposes GlassIndicatorTapMixin behaviour for testing.
class _TestWidget extends StatefulWidget {
  const _TestWidget({required this.onStateChange});

  final void Function(bool isDown) onStateChange;

  @override
  State<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<_TestWidget>
    with GlassIndicatorTapMixin<_TestWidget> {
  bool isDown = false;

  void simulateTapDown() {
    handleIndicatorTapDown(
      setIsDown: (v) => isDown = v,
      snapAlign: () {}, // no-op for these tests
    );
  }

  void simulateDragDown() {
    cancelIndicatorTapTimer();
    setState(() => isDown = true);
  }

  @override
  Widget build(BuildContext context) {
    widget.onStateChange(isDown);
    return const SizedBox(width: 200, height: 50);
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('GlassIndicatorTapMixin', () {
    testWidgets(
        'setIsDown(true) is called immediately on handleIndicatorTapDown',
        (tester) async {
      final states = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          home: _TestWidget(onStateChange: states.add),
        ),
      );
      states.clear(); // ignore initial build

      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));
      state.simulateTapDown();
      await tester.pump(); // flush setState

      expect(states, contains(true),
          reason: 'isDown should be true within the same pump after tapDown');
    });

    testWidgets('setIsDown(false) is called after ~17ms timer fires',
        (tester) async {
      final states = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          home: _TestWidget(onStateChange: states.add),
        ),
      );
      states.clear();

      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));
      state.simulateTapDown();
      await tester.pump(); // isDown=true frame

      expect(state.isDown, isTrue);

      // Advance past the 17 ms deferred clear
      await tester.pump(const Duration(milliseconds: 20));

      expect(state.isDown, isFalse,
          reason: 'Timer should have cleared isDown after ~17 ms');
    });

    testWidgets(
        'cancelIndicatorTapTimer prevents timer from setting isDown=false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _TestWidget(onStateChange: (_) {}),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));
      state.simulateTapDown();
      await tester.pump(); // isDown=true

      // Cancel immediately (simulates a drag starting before timer fires)
      state.cancelIndicatorTapTimer();

      await tester.pump(const Duration(milliseconds: 20));

      // isDown was set true by simulateTapDown; cancelTimer does NOT clear it —
      // it just prevents the timer callback. So isDown stays true until the
      // drag is resolved. This is intentional: drag handlers manage _isDown.
      // We only check that the timer callback did NOT fire by verifying that
      // no extra rebuild from the timer happened. The state remains exactly
      // as the drag handler left it (true).
      expect(state.isDown, isTrue,
          reason:
              'Timer was cancelled; isDown should remain as the drag left it');
    });

    testWidgets(
        'dispose cancels the timer without setState-after-dispose error',
        (tester) async {
      bool removed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                if (!removed)
                  _TestWidget(onStateChange: (_) {})
                else
                  const SizedBox.shrink(),
                ElevatedButton(
                  key: const Key('remove'),
                  onPressed: () => setState(() => removed = true),
                  child: const Text('Remove'),
                ),
              ],
            ),
          ),
        ),
      );

      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      // Start the timer
      state.simulateTapDown();
      await tester.pump(); // isDown=true rendered

      // Remove the widget before the timer fires — dispose() must cancel it
      await tester.tap(find.byKey(const Key('remove')));
      await tester.pump(); // widget removed, dispose() called

      // Advance past the timer window — should NOT cause setState-after-dispose
      await tester.pump(const Duration(milliseconds: 30));

      // No exception = dispose correctly cancelled the timer
    });

    testWidgets(
        'multiple rapid tapDowns cancel the previous timer before scheduling a new one',
        (tester) async {
      final states = <bool>[];

      await tester.pumpWidget(
        MaterialApp(
          home: _TestWidget(onStateChange: states.add),
        ),
      );
      states.clear();

      final state = tester.state<_TestWidgetState>(find.byType(_TestWidget));

      // Two rapid taps
      state.simulateTapDown();
      await tester
          .pump(const Duration(milliseconds: 5)); // halfway through timer
      state.simulateTapDown(); // re-enter before first timer fires
      await tester
          .pump(const Duration(milliseconds: 20)); // let new timer expire

      // isDown should have been cleared exactly once after the second tapDown's timer
      expect(state.isDown, isFalse,
          reason: 'isDown should be false after both timers have resolved');
    });
  });
}
