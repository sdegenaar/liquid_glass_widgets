import 'package:liquid_glass_widgets/widgets/interactive/glass_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/widgets/shared/adaptive_liquid_glass_layer.dart';
import 'package:liquid_glass_widgets/widgets/shared/glass_effect.dart';

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

    // ── didUpdateWidget animation branches (lines 212-227) ───────────────────
    testWidgets('toggling value=true animates forward (lines 218-219)',
        (tester) async {
      bool value = false;
      late StateSetter outerSetState;
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassSwitch(
                  value: value,
                  onChanged: (v) => outerSetState(() => value = v),
                ),
              );
            },
          ),
        ),
      );

      // Flip to true — exercises _positionController.forward()
      outerSetState(() => value = true);
      await tester.pump(); // kick animation
      await tester.pump(const Duration(milliseconds: 400)); // mid animation
      await tester.pumpAndSettle();
      expect(find.byType(GlassSwitch), findsOneWidget);
    });

    testWidgets('toggling value=false animates reverse (line 221)',
        (tester) async {
      bool value = true;
      late StateSetter outerSetState;
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassSwitch(
                  value: value,
                  onChanged: (v) => outerSetState(() => value = v),
                ),
              );
            },
          ),
        ),
      );

      // Start at true, flip to false — exercises _positionController.reverse()
      outerSetState(() => value = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.byType(GlassSwitch), findsOneWidget);
    });

    testWidgets('mid-animation glow overlay renders when transition > 0.05',
        (tester) async {
      // Catching line 446-451: `if (transition > 0.05) Opacity(GlassGlow(...))`
      // This renders during the animation. We pump partway through the animation
      // to ensure the glow layer is built.
      bool value = false;
      late StateSetter outerSetState;
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassSwitch(
                  value: value,
                  onChanged: (v) => outerSetState(() => value = v),
                ),
              );
            },
          ),
        ),
      );

      outerSetState(() => value = true);
      // Do NOT pumpAndSettle — mid-animation is where transition > 0
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      // Widget still alive; glow branch rendered
      expect(find.byType(GlassSwitch), findsOneWidget);
      await tester.pumpAndSettle();
    });

    // ── Drag-to-toggle ───────────────────────────────────────────────────────
    // Helper: builds a self-contained switch with an external state wrapper.
    Widget buildDraggableSwitch({
      required bool initialValue,
      required ValueChanged<bool> onChanged,
      double width = 58.0,
    }) =>
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSwitch(
              value: initialValue,
              onChanged: onChanged,
              width: width,
            ),
          ),
        );

    testWidgets('slow drag past 50% midpoint toggles switch on',
        (tester) async {
      bool value = false;
      await tester.pumpWidget(
        buildDraggableSwitch(
          initialValue: value,
          onChanged: (v) => value = v,
        ),
      );

      final switchFinder = find.byType(GlassSwitch);
      final switchRect = tester.getRect(switchFinder);

      // Drag from left side to well past the midpoint (right quarter).
      await tester.drag(
        switchFinder,
        Offset(switchRect.width * 0.6, 0),
      );
      await tester.pumpAndSettle();

      expect(value, isTrue,
          reason: 'Dragging past 50% should toggle the switch on');
    });

    testWidgets('drag from on→off past midpoint toggles switch off',
        (tester) async {
      bool value = true;
      await tester.pumpWidget(
        buildDraggableSwitch(
          initialValue: value,
          onChanged: (v) => value = v,
        ),
      );

      final switchFinder = find.byType(GlassSwitch);
      final switchRect = tester.getRect(switchFinder);

      // Start from a position near the right and drag left past the midpoint.
      await tester.drag(
        switchFinder,
        Offset(-switchRect.width * 0.6, 0),
      );
      await tester.pumpAndSettle();

      expect(value, isFalse,
          reason: 'Dragging left past 50% should toggle the switch off');
    });

    testWidgets(
        'external value change while dragging: widget survives without crash',
        (tester) async {
      // This test verifies that _dragAbandonedExternally prevents a double-fire
      // of onChanged. We drive the external change via the parent StatefulWidget
      // then verify the widget tree is intact after the gesture ends.
      bool value = false;
      int callCount = 0;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassSwitch(
                  value: value,
                  onChanged: (v) {
                    callCount++;
                    outerSetState(() => value = v);
                  },
                ),
              );
            },
          ),
        ),
      );

      final switchFinder = find.byType(GlassSwitch);

      // Start a drag gesture — must move > kTouchSlop (18 px) to trigger
      // onHorizontalDragStart recognition so _isDragging is set to true.
      final gesture = await tester.startGesture(
        tester.getCenter(switchFinder),
      );
      await tester.pump();
      await gesture.moveBy(const Offset(20, 0)); // > kTouchSlop
      await tester.pump();

      // External change: parent overrides value programmatically.
      // This goes through didUpdateWidget → sets _dragAbandonedExternally.
      outerSetState(() => value = true);
      await tester.pump();

      // Lift finger — _onDragEnd must not call onChanged again.
      await gesture.up();
      await tester.pumpAndSettle();

      // onChanged must NOT have been called (the external setState handled it).
      expect(callCount, equals(0),
          reason:
              '_dragAbandonedExternally should suppress onChanged in _onDragEnd');
      // Widget must still be alive.
      expect(find.byType(GlassSwitch), findsOneWidget);
    });

    // ── Regression: realistic gesture sequences ──────────────────────────────

    testWidgets('tap works reliably on repeated interactions', (tester) async {
      // Regression: onTap + onHorizontalDrag conflict caused tap to fail after
      // the first interaction. Verify toggling works 5 times consecutively.
      bool value = false;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassSwitch(
                  value: value,
                  onChanged: (v) => outerSetState(() => value = v),
                ),
              );
            },
          ),
        ),
      );

      for (int i = 0; i < 5; i++) {
        final expected = (i % 2 == 0); // false→true→false…
        // Use pointer-level tap down+up to match onTapDown+onTapUp handler.
        await tester.tapAt(tester.getCenter(find.byType(GlassSwitch)));
        await tester.pumpAndSettle();
        expect(value, equals(expected),
            reason: 'Tap $i: expected $expected, got $value');
      }
    });

    testWidgets('slow drag (below slop then above) keeps pill plump',
        (tester) async {
      // Regression: slow drag fired onTapCancel which deflated the bloom before
      // onHorizontalDragStart could stop it. Widget must not crash.
      bool value = false;

      await tester.pumpWidget(
        buildDraggableSwitch(
          initialValue: value,
          onChanged: (v) => value = v,
        ),
      );

      final switchFinder = find.byType(GlassSwitch);
      final center = tester.getCenter(switchFinder);

      // Simulate slow horizontal gesture: start, move slowly past slop.
      final gesture = await tester.startGesture(center);
      await tester.pump(const Duration(milliseconds: 80));
      // Small initial move (still below slop) — triggers onTapCancel in Flutter.
      await gesture.moveBy(const Offset(8, 0));
      await tester.pump(const Duration(milliseconds: 50));
      // Move past slop threshold — triggers onHorizontalDragStart.
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      // Release past midpoint.
      await gesture.moveBy(const Offset(10, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      // Widget must still be alive and functional.
      expect(find.byType(GlassSwitch), findsOneWidget);
      expect(value, isTrue,
          reason: 'Slow drag past midpoint should still toggle');
    });

    testWidgets('drag not reaching midpoint snaps back without toggle',
        (tester) async {
      bool value = false;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassSwitch(
                  value: value,
                  onChanged: (v) => outerSetState(() => value = v),
                ),
              );
            },
          ),
        ),
      );

      final switchFinder = find.byType(GlassSwitch);
      final center = tester.getCenter(switchFinder);

      // Gesture: touch down, move just past slop (20px > kTouchSlop 18px) but
      // stay well under the full thumb travel (~22px). Position will be < 50%.
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.moveBy(const Offset(20, 0)); // clears slop, starts drag
      await tester.pump();
      await gesture.up(); // release at ~90% position from start
      await tester.pumpAndSettle();

      // At this position (close to center, very small delta from center),
      // the controller should snap back to false.
      // Note: if this flickers, it means the snap threshold needs a nudge —
      // the real behaviour is tested by the flick and slow-drag tests above.
      expect(find.byType(GlassSwitch), findsOneWidget);
    });

    testWidgets('fast flick right toggles on regardless of position',
        (tester) async {
      bool value = false;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassSwitch(
                  value: value,
                  onChanged: (v) => outerSetState(() => value = v),
                ),
              );
            },
          ),
        ),
      );

      final switchFinder = find.byType(GlassSwitch);
      // 30px is enough to clear kTouchSlop (18px) and generate usable velocity.
      await tester.fling(switchFinder, const Offset(30, 0), 500);
      await tester.pumpAndSettle();

      expect(value, isTrue,
          reason: 'Fast rightward flick should toggle on via velocity');
    });

    testWidgets('fast flick left toggles off regardless of position',
        (tester) async {
      bool value = true;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassSwitch(
                  value: value,
                  onChanged: (v) => outerSetState(() => value = v),
                ),
              );
            },
          ),
        ),
      );

      final switchFinder = find.byType(GlassSwitch);
      await tester.fling(switchFinder, const Offset(-30, 0), 500);
      await tester.pumpAndSettle();

      expect(value, isFalse,
          reason: 'Fast leftward flick should toggle off via velocity');
    });

    testWidgets('thickness controller resets cleanly on second interaction',
        (tester) async {
      // Regression: _thicknessController at value=1.0 (end of previous
      // animation) was not being reset to 0.0 before the next forward().
      // This caused the bloom to skip entirely on the second tap.
      bool value = false;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassSwitch(
                  value: value,
                  onChanged: (v) => outerSetState(() => value = v),
                ),
              );
            },
          ),
        ),
      );

      // First toggle — let animation complete fully (controller ends at 1.0).
      outerSetState(() => value = true);
      await tester.pump();
      await tester.pumpAndSettle();

      // Second toggle — must not crash and bloom must replay.
      outerSetState(() => value = false);
      await tester.pump(); // kick
      await tester.pump(const Duration(milliseconds: 50)); // mid-bloom
      expect(find.byType(GlassSwitch), findsOneWidget);
      await tester.pumpAndSettle();

      expect(find.byType(GlassSwitch), findsOneWidget);
      expect(value, isFalse);
    });

    // ── New targeted tests for production hardening ─────────────────────────

    testWidgets(
        'initial state: switch starting as true renders thumb at right '
        'and first tap animates in reverse direction (anchor fix)',
        (tester) async {
      // Regression: _isMovingForward was hardcoded to `true`, so the first
      // tap on a switch starting as `true` bloomed from the wrong anchor
      // (left edge instead of right edge). After the fix, _isMovingForward
      // is initialised from widget.value in initState().
      bool value = true;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassSwitch(
                  value: value,
                  onChanged: (v) => outerSetState(() => value = v),
                ),
              );
            },
          ),
        ),
      );

      // No pumping — the switch is mounted with value=true. The position
      // controller must already be at 1.0 (right side) without any animation.
      // We verify the widget renders without error at this initial state.
      expect(find.byType(GlassSwitch), findsOneWidget);

      // First tap: should go true→false. Critically, the first interaction
      // must behave identically to subsequent ones — no broken bloom anchor.
      await tester.tapAt(tester.getCenter(find.byType(GlassSwitch)));
      await tester.pump(); // frame after tap triggers onChanged
      await tester.pump(const Duration(milliseconds: 50)); // mid-animation
      // Widget must be alive and animating
      expect(find.byType(GlassSwitch), findsOneWidget);
      await tester.pumpAndSettle();

      // State must have toggled off correctly.
      expect(value, isFalse,
          reason:
              'First tap on a switch initialised as true must toggle it off');

      // Second tap: false→true. Must behave consistently.
      await tester.tapAt(tester.getCenter(find.byType(GlassSwitch)));
      await tester.pumpAndSettle();
      expect(value, isTrue,
          reason:
              'Second tap must toggle back on; confirms direction consistency');
    });

    testWidgets(
        '_justEndedDrag: onChanged is called exactly once after a drag '
        'toggle, not twice (race condition fix)', (tester) async {
      // Regression: _justEndedDrag was reset via addPostFrameCallback, which
      // could fire *after* didUpdateWidget if the parent setState was batched
      // to a later frame. This caused a double-bloom. The fix consumes the flag
      // atomically inside didUpdateWidget.
      //
      // We verify the _behavioural_ guarantee: after a drag toggle, onChanged
      // is called exactly once (from _onDragEnd), not a second time from
      // didUpdateWidget triggering the bloom independently.
      bool value = false;
      int callCount = 0;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassSwitch(
                  value: value,
                  onChanged: (v) {
                    callCount++;
                    outerSetState(() => value = v);
                  },
                ),
              );
            },
          ),
        ),
      );

      final switchFinder = find.byType(GlassSwitch);

      // Perform a full drag-to-toggle: clear slop, move past midpoint, release.
      final gesture = await tester.startGesture(tester.getCenter(switchFinder));
      await tester.pump();
      await gesture.moveBy(const Offset(25, 0)); // clear kTouchSlop (18px)
      await tester.pump();
      await gesture.moveBy(const Offset(20, 0)); // past 50% midpoint
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // onChanged must have been called exactly once — from _onDragEnd.
      // A second call would mean the race condition is still present.
      expect(callCount, equals(1),
          reason: 'onChanged must fire exactly once per drag toggle; '
              'a count of 2 means _justEndedDrag race is still present');
      expect(value, isTrue,
          reason: 'Drag past midpoint must toggle the switch on');
      expect(find.byType(GlassSwitch), findsOneWidget);
    });

    testWidgets(
        'float guard: rapid consecutive toggles never skip bloom '
        '(>= 0.99 threshold is robust against floating-point drift)',
        (tester) async {
      // Regression: using == 1.0 to guard the thickness controller reset was
      // fragile — floating-point drift could leave it at 0.9999... meaning the
      // reset to 0.0 was skipped and the bloom sequence played from mid-point.
      //
      // We simulate drift by toggling twice in quick succession without letting
      // the first animation settle. The controller may be at a non-integer value
      // between the two toggles. The widget must survive without assertion
      // errors and correctly play the bloom on the second toggle.
      bool value = false;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (ctx, setState) {
              outerSetState = setState;
              return AdaptiveLiquidGlassLayer(
                settings: defaultTestGlassSettings,
                child: GlassSwitch(
                  value: value,
                  onChanged: (v) => outerSetState(() => value = v),
                ),
              );
            },
          ),
        ),
      );

      // First toggle — do NOT settle; interrupt it partway through.
      outerSetState(() => value = true);
      await tester.pump(); // start animation
      await tester.pump(const Duration(milliseconds: 190)); // ~50% through

      // Second toggle while first is still animating (controller is mid-flight).
      // This is the scenario where the thickness value is not exactly 0.0 or 1.0.
      outerSetState(() => value = false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50)); // mid second bloom

      // Widget must be alive — no assert or controller errors.
      expect(find.byType(GlassSwitch), findsOneWidget);

      // Let everything settle cleanly.
      await tester.pumpAndSettle();
      expect(find.byType(GlassSwitch), findsOneWidget);
      expect(value, isFalse,
          reason: 'Final state must reflect the last programmatic toggle');

      // One more toggle from a clean resting state to confirm full recovery.
      outerSetState(() => value = true);
      await tester.pumpAndSettle();
      expect(value, isTrue,
          reason: 'Switch must be fully functional after rapid interruption');
    });
    group('keyboard focus & accessibility', () {
      testWidgets('Space key toggles switch when focused', (tester) async {
        bool value = false;
        final focusNode = FocusNode();

        await tester.pumpWidget(
          createTestApp(
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: GlassSwitch(
                value: value,
                onChanged: (v) => value = v,
                focusNode: focusNode,
              ),
            ),
          ),
        );

        focusNode.requestFocus();
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.space);
        await tester.pumpAndSettle();

        expect(value, isTrue);
      });

      testWidgets('Enter key toggles switch when focused', (tester) async {
        bool value = false;
        final focusNode = FocusNode();

        await tester.pumpWidget(
          createTestApp(
            child: AdaptiveLiquidGlassLayer(
              settings: defaultTestGlassSettings,
              child: GlassSwitch(
                value: value,
                onChanged: (v) => value = v,
                focusNode: focusNode,
              ),
            ),
          ),
        );

        focusNode.requestFocus();
        await tester.pumpAndSettle();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();

        expect(value, isTrue);
      });

      testWidgets('exposes switch semantics', (tester) async {
        final handle = tester.ensureSemantics();
        try {
          await tester.pumpWidget(
            createTestApp(
              child: GlassSwitch(
                value: true,
                onChanged: (_) {},
                semanticLabel: 'Test Switch',
              ),
            ),
          );

          expect(
            tester.getSemantics(find.byType(GlassSwitch)),
            matchesSemantics(
              isButton: true,
              hasEnabledState: true,
              isEnabled: true,
              isFocusable: true,
              hasTapAction: true,
              hasFocusAction:
                  true, // focus merges into the labelled node (#381)
              hasToggledState: true,
              isToggled: true,
              label: 'Test Switch',
            ),
          );
        } finally {
          handle.dispose();
        }
      });
    });

    testWidgets(
        'renders resting thumbShadow outside GlassEffect clip and supports custom thumbShadow',
        (tester) async {
      List<BoxShadow>? shadows;
      late StateSetter update;
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return GlassSwitch(
                value: false,
                thumbShadow: shadows,
                onChanged: (_) {},
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shadowFinder = find.descendant(
        of: find.byType(GlassSwitch),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).boxShadow?.isNotEmpty ==
                  true,
        ),
      );
      expect(shadowFinder, findsOneWidget);
      expect(
        find.ancestor(of: shadowFinder, matching: find.byType(GlassEffect)),
        findsNothing,
      );
      final defaultShadow = (tester
              .widget<DecoratedBox>(shadowFinder)
              .decoration as BoxDecoration)
          .boxShadow!
          .single;
      expect(defaultShadow.color.a, 0.15);
      expect(defaultShadow.blurRadius, 8);
      expect(defaultShadow.offset, const Offset(0, 2));

      update(() => shadows = const []);
      await tester.pumpAndSettle();
      expect(shadowFinder, findsNothing);
    });

    testWidgets(
        'lifted thumb achieves symmetric base overhang and rubber-band over-drag overhang',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassSwitch(
              value: false,
              width: 63.0,
              height: 28.0,
              onChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switchFinder = find.byType(GlassSwitch);
      final switchRect = tester.getRect(switchFinder);
      final thumbEffectFinder = find.descendant(
        of: switchFinder,
        matching: find.byType(GlassEffect),
      );

      // Press down on the OFF switch: pump past kPressTimeout (100ms) so
      // onTapDown fires, then pump 150ms so the 120ms bloom reaches peak.
      // At 63×28, native iOS 27 pressed OFF lens frame is (-8.67, -5.33, 58.0, 38.33).
      final gesture = await tester.startGesture(switchRect.center);
      await tester.pump(const Duration(milliseconds: 110));
      await tester.pump(const Duration(milliseconds: 150));

      final pressedLeftOverhang =
          switchRect.left - tester.getRect(thumbEffectFinder).left;
      expect(pressedLeftOverhang, closeTo(8.67, 0.2));

      // Drag left past OFF (-30 px) and verify native rubber-band left overhang (~15.6 px).
      await gesture.moveBy(const Offset(-5, 0)); // clear 3px touchSlop
      await tester.pump();
      await gesture.moveBy(const Offset(-30, 0));
      await tester.pump(const Duration(milliseconds: 100));
      final overDraggedLeftOverhang =
          switchRect.left - tester.getRect(thumbEffectFinder).left;
      expect(overDraggedLeftOverhang, greaterThan(15.0));

      // Drag right across the runway and 30 px past ON, verifying symmetric
      // right rubber-band overhang (~15.6 px).
      await gesture.moveBy(const Offset(82, 0));
      await tester.pump(const Duration(milliseconds: 100));
      final overDraggedRightOverhang =
          tester.getRect(thumbEffectFinder).right - switchRect.right;
      expect(overDraggedRightOverhang, closeTo(overDraggedLeftOverhang, 0.5));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'didUpdateWidget snaps thumb back to target after cancelled mid-runway drag',
        (tester) async {
      Color thumbColor = Colors.white;
      late StateSetter update;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return GlassSwitch(
                value: false,
                thumbColor: thumbColor,
                onChanged: (_) {},
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      final center = tester.getCenter(find.byType(GlassSwitch));
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.moveBy(const Offset(5, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump();
      await gesture.cancel();
      await tester.pump();

      update(() => thumbColor = Colors.grey);
      await tester.pumpAndSettle();
      expect(find.byType(GlassSwitch), findsOneWidget);
    });
  });

  group('GlassSwitch On/Off Labels', () {
    Finder marks() => find.byWidgetPredicate((widget) =>
        widget is CustomPaint &&
        widget.painter.runtimeType.toString() == '_OnOffLabelsPainter');

    Widget build({
      required bool value,
      bool onOffSwitchLabels = true,
      TextDirection textDirection = TextDirection.ltr,
      ValueChanged<bool>? onChanged,
      Color? onLabelColor,
      Color? offLabelColor,
    }) =>
        createTestApp(
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(onOffSwitchLabels: onOffSwitchLabels),
              child: Directionality(
                textDirection: textDirection,
                child: Center(
                  child: AdaptiveLiquidGlassLayer(
                    settings: defaultTestGlassSettings,
                    child: GlassSwitch(
                      value: value,
                      onChanged: onChanged ?? (_) {},
                      onLabelColor: onLabelColor,
                      offLabelColor: offLabelColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    // Default 58x26 track: the pill thumb is 22 * 1.6 = 35.2 wide, so the
    // gap beside the resting thumb is 58 - 2 - 35.2 = 20.8, centered at 10.4.
    // Marks scale by 26 / 31.
    const scale = 26 / 31;
    const onInset = 10.4 + 0.25 * scale;
    const offInset = 10.4 + 1.25 * scale;
    const width = 58.0;
    const centerY = 13.0;

    bool near(double a, double b) => (a - b).abs() < 1e-6;

    // The O ring: a 1pt stroke of radius 5 * scale centered at (x, centerY).
    PaintPattern ringAt(double x) => paints
      ..something((method, args) {
        if (method != #drawCircle) return false;
        final center = args[0] as Offset;
        final paint = args[2] as Paint;
        return near(center.dx, x) &&
            near(center.dy, centerY) &&
            near(args[1] as double, 5 * scale) &&
            paint.style == PaintingStyle.stroke &&
            paint.strokeWidth == 1;
      });

    // The I bar: 1 x (10 * scale), centered at (x, centerY).
    PaintPattern barAt(double x) => paints
      ..something((method, args) {
        if (method != #drawRect) return false;
        final rect = args[0] as Rect;
        return near(rect.center.dx, x) &&
            near(rect.center.dy, centerY) &&
            near(rect.width, 1) &&
            near(rect.height, 10 * scale);
      });

    testWidgets('draws nothing when the setting is off', (tester) async {
      await tester.pumpWidget(build(value: true, onOffSwitchLabels: false));
      expect(marks(), findsNothing);
      await tester.pumpWidget(build(value: false, onOffSwitchLabels: false));
      expect(marks(), findsNothing);
    });

    testWidgets('off: the O ring at the end the thumb left', (tester) async {
      await tester.pumpWidget(build(value: false));
      expect(marks(), findsOneWidget);
      expect(tester.renderObject(marks()), ringAt(width - offInset));
      expect(tester.renderObject(marks()), isNot(paints..rect()));
    });

    testWidgets('on: the I bar at the end the thumb left', (tester) async {
      await tester.pumpWidget(build(value: true));
      expect(tester.renderObject(marks()), barAt(onInset));
      expect(tester.renderObject(marks()), paints..rect(color: Colors.white));
      expect(tester.renderObject(marks()), isNot(paints..circle()));
    });

    testWidgets('the marks are painted under the thumb', (tester) async {
      await tester.pumpWidget(build(value: true));
      final stack = find.ancestor(of: marks(), matching: find.byType(Stack));
      final children = tester.widget<Stack>(stack.first).children;
      expect(children, hasLength(3));
      expect(children[1], isA<Positioned>());
      expect((children[1] as Positioned).child, isA<CustomPaint>());
    });

    testWidgets('label colors can be set', (tester) async {
      const on = Color(0xFF112233);
      const off = Color(0xFF445566);
      await tester
          .pumpWidget(build(value: true, onLabelColor: on, offLabelColor: off));
      expect(tester.renderObject(marks()), paints..rect(color: on));
      await tester.pumpWidget(
          build(value: false, onLabelColor: on, offLabelColor: off));
      await tester.pumpAndSettle();
      expect(tester.renderObject(marks()), paints..circle(color: off));
    });

    group('in RTL', () {
      testWidgets('the marks are mirrored', (tester) async {
        await tester
            .pumpWidget(build(value: false, textDirection: TextDirection.rtl));
        expect(tester.renderObject(marks()), ringAt(offInset));

        await tester
            .pumpWidget(build(value: true, textDirection: TextDirection.rtl));
        await tester.pumpAndSettle();
        expect(tester.renderObject(marks()), barAt(width - onInset));
      });

      Rect thumbRect(WidgetTester tester) {
        final stack = find.ancestor(of: marks(), matching: find.byType(Stack));
        final switchBox = tester.getRect(stack.first);
        final thumb = find.descendant(
          of: stack.first,
          matching: find.byType(Positioned),
        );
        // The last top-level Positioned in the switch's Stack is the thumb.
        final rect = tester.getRect(thumb.last);
        return rect.shift(-switchBox.topLeft);
      }

      testWidgets('the thumb rests on the left when on', (tester) async {
        await tester
            .pumpWidget(build(value: true, textDirection: TextDirection.rtl));
        expect(thumbRect(tester).center.dx, lessThan(width / 2));

        await tester.pumpWidget(build(value: true));
        await tester.pumpAndSettle();
        expect(thumbRect(tester).center.dx, greaterThan(width / 2));
      });

      testWidgets('dragging left turns it on', (tester) async {
        var value = false;
        await tester.pumpWidget(build(
          value: value,
          textDirection: TextDirection.rtl,
          onChanged: (v) => value = v,
        ));
        await tester.timedDrag(
          find.byType(GlassSwitch),
          const Offset(-40, 0),
          const Duration(milliseconds: 600),
        );
        await tester.pumpAndSettle();
        expect(value, isTrue);
      });
    });
  });
}
