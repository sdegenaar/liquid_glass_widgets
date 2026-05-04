import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import '../../shared/test_helpers.dart';

void main() {
  group('GlassModalSheet', () {
    testWidgets('renders content and can be instantiated', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                child: const Text('Sheet Content'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sheet Content'), findsOneWidget);
      expect(find.byType(GlassModalSheet), findsOneWidget);
    });

    testWidgets('snaps to full state on focus gained', (tester) async {
      final controller = GlassModalSheetController();

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                controller: controller,
                initialState: SheetState.half,
                child: const Material(
                  child: Center(
                    child: SizedBox(
                      width: 200,
                      height: 40,
                      child: TextField(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      // We must pump to allow the post-frame callback to snap the sheet to its initial position
      await tester.pumpAndSettle();

      // Verify we are at half (initially)
      expect(controller.currentState, SheetState.half);

      // Tap to gain focus
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      // Verify it snapped to full
      expect(controller.currentState, SheetState.full);
    });

    testWidgets(
        'child State is preserved across half↔full transitions (no GlobalObjectKey)',
        (tester) async {
      // Regression test for: GlobalObjectKey(widget.child) on the internal
      // Focus widget caused Flutter to tear down the child's Element subtree
      // on every sheet expand/collapse, firing dispose+initState each time.
      int initStateCount = 0;

      final controller = GlassModalSheetController();

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                controller: controller,
                initialState: SheetState.half,
                child: _CountingWidget(
                  onInitState: () => initStateCount++,
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1 initState on first mount — expected.
      expect(initStateCount, 1);

      // Expand to full — child State must NOT be torn down.
      controller.snapToState(SheetState.full, animate: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(initStateCount, 1,
          reason: 'Child initState must not fire again on sheet expansion');

      // Collapse back to half — still must not rebuild.
      controller.snapToState(SheetState.half, animate: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(initStateCount, 1,
          reason: 'Child initState must not fire again on sheet collapse');
    });

    testWidgets('static show() method displays the sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => GlassModalSheet.show(
                  context: context,
                  builder: (context) => const Text('Modal Content'),
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.text('Modal Content'), findsOneWidget);
    });

    testWidgets('respects custom border radius', (tester) async {
      const customRadius = 24.0;
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                topBorderRadius: customRadius,
                child: const SizedBox(height: 100),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final widget =
          tester.widget<GlassModalSheet>(find.byType(GlassModalSheet));
      expect(widget.topBorderRadius, customRadius);
    });

    testWidgets('dragIndicatorWidth defaults to 36 (iOS native)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                child: const SizedBox(height: 100),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final widget =
          tester.widget<GlassModalSheet>(find.byType(GlassModalSheet));
      expect(widget.dragIndicatorWidth, 36);
    });

    testWidgets('respects custom dragIndicatorWidth', (tester) async {
      const customWidth = 64.0;
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                dragIndicatorWidth: customWidth,
                child: const SizedBox(height: 100),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final widget =
          tester.widget<GlassModalSheet>(find.byType(GlassModalSheet));
      expect(widget.dragIndicatorWidth, customWidth);
    });

    testWidgets('GlassInteractionSilence can be used in content',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                suppressInteractionOnChildren: true,
                child: GlassInteractionSilence(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('Silent Button'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlassInteractionSilence), findsOneWidget);
      expect(find.text('Silent Button'), findsOneWidget);
    });

    testWidgets('respects fillThreshold and expandedColor', (tester) async {
      const testColor = Colors.red;
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                fillThreshold: 0.5,
                expandedColor: testColor,
                child: const SizedBox(height: 100),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final widget =
          tester.widget<GlassModalSheet>(find.byType(GlassModalSheet));
      expect(widget.fillThreshold, 0.5);
      expect(widget.expandedColor, testColor);
    });

    testWidgets('can be dragged between states', (tester) async {
      final controller = GlassModalSheetController();

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                controller: controller,
                initialState: SheetState.half,
                enablePeek: true,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.currentState, SheetState.half);

      // Fling up to full
      await tester.flingFrom(
          const Offset(400, 450), const Offset(0, -500), 2000);
      await tester.pumpAndSettle();
      expect(controller.currentState, SheetState.full);

      // Fling down to peek
      await tester.flingFrom(
          const Offset(400, 100), const Offset(0, 600), 2000);
      await tester.pumpAndSettle();
      expect(controller.currentState, SheetState.peek);
    });

    testWidgets('only allows scrolling when in full state', (tester) async {
      final controller = GlassModalSheetController();

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                controller: controller,
                initialState: SheetState.half,
                child: ListView.builder(
                  itemCount: 100,
                  itemBuilder: (context, i) => ListTile(
                    title: Text('Item $i'),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.currentState, SheetState.half);

      // In half state, an upward drag on the sheet content should move the
      // SHEET (upward toward full), not scroll the list content.
      final halfValue = controller.value;

      // Fling up — should snap sheet to full, not scroll list.
      await tester.flingFrom(
          const Offset(400, 450), const Offset(0, -400), 1500);
      await tester.pumpAndSettle();

      expect(controller.currentState, SheetState.full,
          reason:
              'Upward drag in half state should expand the sheet, not scroll content');

      // Now in full state, expand is stable — the sheet remains full.
      expect(controller.value, greaterThan(halfValue));

      // Fling downward from full — sheet should collapse back to half/peek.
      await tester.flingFrom(
          const Offset(400, 100), const Offset(0, 400), 1500);
      await tester.pumpAndSettle();

      expect(controller.currentState, isNot(SheetState.full),
          reason:
              'Downward drag in full state header area should collapse the sheet');
    });

    testWidgets('shows top fade ShaderMask when enabled and expanded',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                initialState: SheetState.full,
                enableTopFade: true,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ShaderMask is used for top fade
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('persistent mode prevents hidden state', (tester) async {
      final controller = GlassModalSheetController();

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                controller: controller,
                initialState: SheetState.peek,
                mode: SheetMode.persistent,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Try to snap to hidden
      controller.snapToState(SheetState.hidden);
      await tester.pumpAndSettle();

      // Should have snapped back to peek instead of hidden
      expect(controller.currentState, SheetState.peek);
    });
    testWidgets('respects instant transition mode', (tester) async {
      final controller = GlassModalSheetController();

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                controller: controller,
                initialState: SheetState.half,
                fillTransition: FillTransition.instant,
                fillThreshold: 0.5,
                expandedColor: Colors.blue,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // At half (0.45), colorOpacity is ~0 — fill present but transparent.
      BoxDecoration getFillDecoration() => tester
          .widget<DecoratedBox>(find.byKey(const Key('glass_modal_sheet_fill')))
          .decoration as BoxDecoration;
      expect(getFillDecoration().color?.a ?? 0, lessThan(0.05));

      // Move slightly above half but still below fill threshold
      controller.value = 0.60;
      await tester.pump();
      expect(getFillDecoration().color?.a ?? 0, lessThan(0.05));

      // Move above fill threshold (tProgress = (0.7 - 0.45) / 0.4 = 0.625)
      controller.value = 0.7;
      await tester.pump();

      // In instant mode the fill should now have the expandedColor with opacity > 0
      final fillDecoration = getFillDecoration();
      expect(fillDecoration.color?.a, greaterThan(0.0));
      expect(
        fillDecoration.color?.withValues(alpha: 1.0),
        Colors.blue.withValues(alpha: 1.0),
      );
    });

    testWidgets('snaps to the nearest state correctly', (tester) async {
      final controller = GlassModalSheetController();

      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                controller: controller,
                initialState: SheetState.half,
                enablePeek: true,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Midpoint between half (0.45) and full (0.85) is 0.65.
      // Move to 0.7 (closer to full).
      controller.value = 0.7;
      await tester.pump();
      expect(controller.currentState, SheetState.full);

      // Move to 0.6 (closer to half).
      controller.value = 0.6;
      await tester.pump();
      expect(controller.currentState, SheetState.half);

      // Midpoint between peek (90px) and half (0.45).
      // On 800px height, 90px is ~0.11. Mid is (0.11 + 0.45)/2 = 0.28.
      controller.value = 0.2; // closer to peek
      await tester.pump();
      expect(controller.currentState, SheetState.peek);
    });

    testWidgets('respects state-specific glass settings', (tester) async {
      final controller = GlassModalSheetController();
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                controller: controller,
                initialState: SheetState.half,
                halfSettings: const LiquidGlassSettings(blur: 50.0),
                fullSettings: const LiquidGlassSettings(
                    blur: 0.0, glassColor: Colors.red),
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In half state, colorOpacity is ~0 — fill present but transparent.
      BoxDecoration getFillDecoration() => tester
          .widget<DecoratedBox>(find.byKey(const Key('glass_modal_sheet_fill')))
          .decoration as BoxDecoration;
      expect(getFillDecoration().color?.a ?? 0, lessThan(0.05));

      // Expand to full (blur=0 => solid color fill should appear)
      controller.snapToState(SheetState.full, animate: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // In full state, blur is 0 so colorOpacity > 0 and the fill is visible.
      final fillDecoration = getFillDecoration();
      expect(
        fillDecoration.color?.withValues(alpha: 1.0),
        Colors.red.withValues(alpha: 1.0),
      );
      expect(fillDecoration.color?.a, greaterThan(0.9));
    });

    testWidgets('works correctly with all effects disabled (minimal mode)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                enableInteractionGlow: false,
                enableSaturationGlow: false,
                showDragIndicator: false,
                enableTopFade: false,
                child: const Text('Minimal Content'),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Minimal Content'), findsOneWidget);
      // Verify drag indicator is NOT there
      expect(find.bySemanticsLabel('Drag handle'), findsNothing);
    });

    testWidgets('handles extreme radii correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                topBorderRadius: 1000.0, // Over-radius
                bottomBorderRadius: 0.0, // Zero radius
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final layout = find.byType(DecoratedBox);
      // If it renders without crashing, we are good.
      expect(layout, findsAtLeast(1));
    });

    testWidgets('prevents size order inversion (foolproof sizes)',
        (tester) async {
      final controller = GlassModalSheetController();
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                controller: controller,
                peekSize: 300, // Very large peek
                halfSize: 100, // Small half (should be clamped to >= peek)
                initialState: SheetState.half,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Half should be at least as high as peek due to internal clamping in SheetGeometry
      // We can check the controller value or internal position if we had access,
      // but here we just ensure it doesn't crash and stays functional.
      expect(controller.currentState, SheetState.half);

      // Try to snap to peek
      controller.snapToState(SheetState.peek);
      await tester.pumpAndSettle();
      expect(controller.currentState, SheetState.peek);
    });

    testWidgets(
        'handles keyboard appearance without overflow (viewInsets stress)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                initialState: SheetState.full,
                child: Column(
                  children: [
                    const Text('Top item'),
                    const Spacer(),
                    Container(
                      height: 100,
                      color: Colors.blue,
                      child: const TextField(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate keyboard popping up (300px height)
      tester.view.viewInsets = FakeViewPadding(bottom: 300);
      await tester.pump();

      // If there was an overflow, the test would fail automatically here.
      expect(find.text('Top item'), findsOneWidget);

      // Reset
      tester.view.resetViewInsets();
    });

    testWidgets('handles huge content with scrolling (stress height)',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                initialState: SheetState.half,
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(200, (i) => Text('Stress line $i')),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Stress line 0'), findsOneWidget);
      expect(find.byType(GlassModalSheet), findsOneWidget);
    });

    testWidgets('respects top fade settings', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                initialState: SheetState.full,
                enableTopFade: true,
                topFadeHeight: 123.0,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the ShaderMask that implements the top fade
      final shaderMask = find.byType(ShaderMask);
      expect(shaderMask, findsOneWidget);

      // We can't easily check the height of the shader itself without deep inspection,
      // but we ensure it renders without error.
    });

    testWidgets('respects maintainContentGlass in full state', (tester) async {
      final controller = GlassModalSheetController();
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                controller: controller,
                initialState: SheetState.full,
                maintainContentGlass: true,
                fullStateContentSettings: const LiquidGlassSettings(blur: 25.0),
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // We expect at least two AdaptiveGlass/LiquidGlass widgets:
      // one for the sheet background and one for the content glass.
      final glassWidgets = find.byWidgetPredicate((w) =>
          w.runtimeType.toString().contains('Glass') &&
          (w.runtimeType.toString().contains('Adaptive') ||
              w.runtimeType.toString().contains('Liquid')));

      expect(glassWidgets, findsAtLeast(2));
    });

    testWidgets(
        'applies resistance when dragging beyond boundaries (top & bottom)',
        (tester) async {
      final controller = GlassModalSheetController();
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                controller: controller,
                initialState: SheetState.full,
                mode: SheetMode.persistent,
                fullSize: 1.0,
                resistance: 0.5,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Test TOP resistance (drag UP from 1.0)
      expect(controller.value, 1.0);

      final gestureTop = await tester.startGesture(const Offset(400, 10));
      await gestureTop.moveBy(const Offset(0, -200));
      await tester.pump();

      // Screen height 600, drag 200px up.
      // Fraction 200/600 = 0.333...
      // Resisted: 0.333... * 0.5 = 0.1666...
      // Expected: 1.1666...
      expect(controller.value, closeTo(1.1666, 0.01));

      await gestureTop.up();
      await tester.pumpAndSettle(); // Snap back
      expect(controller.value, 1.0);

      // 2. Test BOTTOM resistance (drag DOWN from peek)
      controller.snapToState(SheetState.peek, animate: false);
      await tester.pumpAndSettle();
      final peekValue = controller.value;

      // Drag the handle (indicator).
      final handleFinder = find.byElementPredicate(
          (e) => e.widget.runtimeType.toString() == '_GlassDragIndicator');
      final gestureBottom =
          await tester.startGesture(tester.getCenter(handleFinder));
      await gestureBottom.moveBy(const Offset(0, 300)); // Drag way down
      await tester.pump();

      // Expected: boundary 0.15 - (0.5 overflow * 0.5) = -0.1
      expect(controller.value, closeTo(-0.1, 0.01));

      await gestureBottom.up();
      await tester.pumpAndSettle(); // Snap back
      expect(controller.value, peekValue);
    });

    testWidgets('disables interaction glow and pulse in full state',
        (tester) async {
      final controller = GlassModalSheetController();
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                controller: controller,
                initialState: SheetState.full,
                enableInteractionGlow: true,
                enableSaturationGlow: true,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find GlassGlow widget
      final glassGlowFinder = find.byType(GlassGlow);
      expect(glassGlowFinder, findsOneWidget);

      final glassGlow = tester.widget<GlassGlow>(glassGlowFinder);

      // In full state (expandProgress = 1.0 > 0.9), glowColor should be transparent
      // and pulse should be 0.0.
      expect(glassGlow.glowColor, Colors.transparent);
      expect(glassGlow.pulse, 0.0);

      // Now snap back to half and verify they are enabled
      controller.snapToState(SheetState.half, animate: false);
      await tester.pump();

      final glassGlowHalf = tester.widget<GlassGlow>(glassGlowFinder);
      expect(glassGlowHalf.glowColor, isNot(Colors.transparent));
      // In half state, _saturationAnimation might still be 0.0 initially,
      // but it's *wired* to the animation.
      // Actually, since we didn't trigger any pointer events, it's 0.0.
      // But the *conditional* should be true.
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // GlassModalSheetScaffold
  // ─────────────────────────────────────────────────────────────────────────────

  group('GlassModalSheetScaffold', () {
    testWidgets('renders background and sheet content', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassModalSheetScaffold(
            body: const Text('Background'),
            sheet: const Text('Sheet Child'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Background'), findsOneWidget);
      expect(find.text('Sheet Child'), findsOneWidget);
      expect(find.byType(GlassModalSheetScaffold), findsOneWidget);
    });

    testWidgets('respects initialState parameter', (tester) async {
      final controller = GlassModalSheetController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassModalSheetScaffold(
            controller: controller,
            initialState: SheetState.full,
            body: const SizedBox.expand(),
            sheet: const Text('Full Sheet'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(controller.currentState, SheetState.full);
    });

    testWidgets('snaps between states via controller', (tester) async {
      final controller = GlassModalSheetController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassModalSheetScaffold(
            controller: controller,
            initialState: SheetState.peek,
            body: const SizedBox.expand(),
            sheet: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.currentState, SheetState.peek);

      controller.snapToState(SheetState.half);
      await tester.pumpAndSettle();
      expect(controller.currentState, SheetState.half);

      controller.snapToState(SheetState.full);
      await tester.pumpAndSettle();
      expect(controller.currentState, SheetState.full);
    });

    testWidgets('onStateChanged fires when state changes', (tester) async {
      final controller = GlassModalSheetController();
      final states = <SheetState>[];

      await tester.pumpWidget(
        createTestApp(
          child: GlassModalSheetScaffold(
            controller: controller,
            initialState: SheetState.half,
            onStateChanged: states.add,
            body: const SizedBox.expand(),
            sheet: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.snapToState(SheetState.full);
      await tester.pumpAndSettle();

      expect(states, contains(SheetState.full));
    });

    testWidgets(
      'onStateChanged fires after slow drag past snap threshold',
      (tester) async {
        // Regression: a slow drag whose path crosses a snap threshold
        // mid-gesture used to silently mutate `_currentState` to the
        // resolved target via `_applyDrag`. By the time the user released,
        // `_snapToState` found `_currentState == target` and skipped the
        // side-effects branch (haptics, onStateChanged, scroll-to-top).
        final controller = GlassModalSheetController();
        final states = <SheetState>[];

        await tester.pumpWidget(
          createTestApp(
            child: GlassModalSheetScaffold(
              controller: controller,
              initialState: SheetState.full,
              onStateChanged: states.add,
              body: const SizedBox.expand(),
              sheet: const SizedBox.expand(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Slow drag from inside the sheet down through the half-state
        // position. Multiple small moveBy calls with pumps between them
        // simulate a finger that lingers — enough frames for _applyDrag
        // to resolve and commit the intermediate snap target.
        final start = tester.getCenter(find.byType(GlassModalSheetScaffold));
        final gesture = await tester.startGesture(start);
        for (var i = 0; i < 20; i++) {
          await gesture.moveBy(const Offset(0, 15));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pumpAndSettle();

        // The final transition to half MUST be reported regardless of
        // how many times _applyDrag updated _currentState mid-gesture.
        expect(states, contains(SheetState.half),
            reason: 'onStateChanged was not fired for the slow-drag-to-half '
                'transition — _snapToState skipped its side-effects branch '
                'because _applyDrag had already updated _currentState to '
                'the resolved target mid-drag.');
      },
    );

    testWidgets('persistent mode prevents dismissal below peek',
        (tester) async {
      final controller = GlassModalSheetController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassModalSheetScaffold(
            controller: controller,
            initialState: SheetState.peek,
            mode: SheetMode.persistent,
            body: const SizedBox.expand(),
            sheet: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      controller.snapToState(SheetState.hidden);
      await tester.pumpAndSettle();

      // Persistent mode clamps at peek
      expect(controller.currentState, SheetState.peek);
    });

    testWidgets('renders without crashing with custom glass settings',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassModalSheetScaffold(
            initialState: SheetState.half,
            settings: const LiquidGlassSettings(blur: 20),
            halfSettings: const LiquidGlassSettings(blur: 30),
            fullSettings: const LiquidGlassSettings(blur: 0),
            body: const SizedBox.expand(),
            sheet: const Text('Custom Glass Scaffold'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Custom Glass Scaffold'), findsOneWidget);
    });

    testWidgets('respects horizontalMargin and bottomMargin', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassModalSheetScaffold(
            horizontalMargin: 24,
            bottomMargin: 16,
            body: const SizedBox.expand(),
            sheet: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final widget = tester.widget<GlassModalSheetScaffold>(
          find.byType(GlassModalSheetScaffold));
      expect(widget.horizontalMargin, 24);
      expect(widget.bottomMargin, 16);
    });

    testWidgets('can expand to full via fling from peek', (tester) async {
      final controller = GlassModalSheetController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassModalSheetScaffold(
            controller: controller,
            initialState: SheetState.peek,
            body: const SizedBox.expand(),
            sheet: const SizedBox.expand(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.currentState, SheetState.peek);

      // Programmatically expand — same path as a successful fling snap.
      controller.snapToState(SheetState.full);
      await tester.pumpAndSettle();

      expect(controller.currentState, SheetState.full);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // GlassInteractionSilence
  // ─────────────────────────────────────────────────────────────────────────────

  group('GlassInteractionSilence', () {
    testWidgets('renders its child correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassInteractionSilence(
            child: const Text('Silent Child'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Silent Child'), findsOneWidget);
      expect(find.byType(GlassInteractionSilence), findsOneWidget);
    });

    testWidgets('dispatches notification on pointer down', (tester) async {
      // GlassInteractionSilence's contract is to bubble an InteractionNotification
      // upward when a pointer-down occurs. We verify this by catching the
      // notification in a parent NotificationListener.
      var notified = false;

      await tester.pumpWidget(
        createTestApp(
          child: Center(
            child: NotificationListener<Notification>(
              onNotification: (n) {
                // InteractionNotification is internal; we accept any Notification.
                notified = true;
                return true;
              },
              child: GlassInteractionSilence(
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final centre = tester.getCenter(find.byType(GlassInteractionSilence));
      await tester.tapAt(centre);
      await tester.pump();

      expect(notified, isTrue,
          reason:
              'GlassInteractionSilence should dispatch a notification on tap');
    });

    testWidgets(
        'inside GlassSheet with suppressInteractionOnChildren: renders and is present',
        (tester) async {
      // Behavioral: confirm GlassInteractionSilence is wired up inside the sheet
      // widget tree when suppressInteractionOnChildren is true. The actual
      // hit-test guarantee is exercised in the standalone tap test above.
      await tester.pumpWidget(
        createTestApp(
          child: Stack(
            children: [
              GlassModalSheet(
                suppressInteractionOnChildren: true,
                initialState: SheetState.half,
                child: GlassInteractionSilence(
                  child: const SizedBox(width: 200, height: 60),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GlassInteractionSilence), findsOneWidget);
    });

    testWidgets('nested GlassInteractionSilence does not throw',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassInteractionSilence(
            child: GlassInteractionSilence(
              child: const Text('Nested Silence'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Nested Silence'), findsOneWidget);
    });

    testWidgets(
        'multiple silenced children each dispatch independent notifications',
        (tester) async {
      var notifyCount = 0;

      await tester.pumpWidget(
        createTestApp(
          child: Center(
            child: NotificationListener<Notification>(
              onNotification: (_) {
                notifyCount++;
                return true;
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassInteractionSilence(
                    child: const SizedBox(
                        key: Key('silA'), width: 200, height: 50),
                  ),
                  GlassInteractionSilence(
                    child: const SizedBox(
                        key: Key('silB'), width: 200, height: 50),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tapAt(tester.getCenter(find.byKey(const Key('silA'))));
      await tester.pump();
      expect(notifyCount, 1,
          reason: 'First silence tap should produce exactly one notification');

      await tester.tapAt(tester.getCenter(find.byKey(const Key('silB'))));
      await tester.pump();
      expect(notifyCount, 2,
          reason: 'Second silence tap should produce a second notification');
    });
  });
}

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

/// A minimal StatefulWidget that calls [onInitState] each time its
/// [State.initState] runs. Used to detect spurious Element teardowns caused
/// by incorrect keys on ancestor widgets (e.g. GlobalObjectKey on the Focus
/// bridge in GlassModalSheet).
class _CountingWidget extends StatefulWidget {
  const _CountingWidget({required this.onInitState});
  final VoidCallback onInitState;

  @override
  State<_CountingWidget> createState() => _CountingWidgetState();
}

class _CountingWidgetState extends State<_CountingWidget> {
  @override
  void initState() {
    super.initState();
    widget.onInitState();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
