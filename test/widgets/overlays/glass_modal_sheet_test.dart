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
                child: Builder(
                  builder: (context) {
                    final scrollController =
                        ScrollControllerProvider.of(context)?.controller;
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: 100,
                      itemBuilder: (context, i) => ListTile(
                        title: Text('Item $i'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.currentState, SheetState.half);

      // In half state, dragging should NOT scroll the list
      final listFinder = find.byType(Scrollable);
      final initialOffset =
          tester.state<ScrollableState>(listFinder).position.pixels;

      await tester.drag(find.text('Item 0'), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(tester.state<ScrollableState>(listFinder).position.pixels,
          initialOffset,
          reason: 'List should NOT scroll in half state');

      // Now expand to full
      controller.snapToState(SheetState.full);
      await tester.pumpAndSettle();
      expect(controller.currentState, SheetState.full);

      // In full state, dragging should scroll the list
      await tester.drag(find.text('Item 0'), const Offset(0, -300));
      await tester.pumpAndSettle();

      final finalOffset =
          tester.state<ScrollableState>(listFinder).position.pixels;
      expect(finalOffset, greaterThan(initialOffset),
          reason: 'List should scroll in full state');
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

      // At half (0.45), it should be transparent/glass
      // We look for the DecoratedBox that handles the background color
      final decoratedBoxFinder = find.byType(DecoratedBox);

      DecoratedBox getSheetBackground() {
        return tester
            .widgetList<DecoratedBox>(decoratedBoxFinder)
            .firstWhere((db) => db.decoration is ShapeDecoration);
      }

      final decoration = getSheetBackground().decoration as ShapeDecoration;
      expect(decoration.color?.a,
          lessThan(0.1)); // Should be almost transparent in half state

      // Move slightly above half but below threshold (0.5)
      controller.value = 0.49;
      await tester.pump();

      final decorationMid = getSheetBackground().decoration as ShapeDecoration;
      expect(decorationMid.color?.a, lessThan(0.1));

      // Move above 0.5
      controller.value = 0.51;
      await tester.pump();

      // In instant mode, it should flip to expandedColor immediately after 0.5
      final decorationFull = getSheetBackground().decoration as ShapeDecoration;
      expect(decorationFull.color?.withValues(alpha: 1.0),
          Colors.blue.withValues(alpha: 1.0));
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

      DecoratedBox getSheetBackground() {
        return tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .firstWhere((db) => db.decoration is ShapeDecoration);
      }

      // In half state, it should have high blur and be glass-like
      final decorationHalf = getSheetBackground().decoration as ShapeDecoration;
      expect(decorationHalf.color?.a, lessThan(0.1));

      // Expand to full
      controller.snapToState(SheetState.full, animate: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // In full state, blur is 0, so it should be solid color
      final decorationFull = getSheetBackground().decoration as ShapeDecoration;

      expect(decorationFull.color?.withValues(alpha: 1.0),
          Colors.red.withValues(alpha: 1.0));
      expect(decorationFull.color?.a, greaterThan(0.9));
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
  });
}
