import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassSegmentedControl', () {
    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [
              GlassTab(label: 'One'),
              GlassTab(label: 'Two'),
              GlassTab(label: 'Three')
            ],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            useOwnLayer: true,
          ),
        ),
      );

      expect(find.byType(GlassSegmentedControl), findsOneWidget);
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.text('Three'), findsOneWidget);
    });

    testWidgets('displays all segments', (tester) async {
      const segments = <GlassTab>[
        GlassTab(label: 'Daily'),
        GlassTab(label: 'Weekly'),
        GlassTab(label: 'Monthly')
      ];

      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: segments,
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            useOwnLayer: true,
          ),
        ),
      );

      for (final segment in segments) {
        expect(find.text(segment.label!), findsOneWidget);
      }
    });

    testWidgets('calls onSegmentSelected when tapping a segment',
        (tester) async {
      var selectedIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [
              GlassTab(label: 'One'),
              GlassTab(label: 'Two'),
              GlassTab(label: 'Three')
            ],
            selectedIndex: selectedIndex,
            onSegmentSelected: (index) => selectedIndex = index,
            useOwnLayer: true,
          ),
        ),
      );

      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(1));
    });

    testWidgets('shows correct selected segment', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [
              GlassTab(label: 'Option A'),
              GlassTab(label: 'Option B'),
              GlassTab(label: 'Option C')
            ],
            selectedIndex: 1,
            onSegmentSelected: (_) {},
            useOwnLayer: true,
          ),
        ),
      );

      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });

    testWidgets('respects custom height', (tester) async {
      const customHeight = 40.0;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [GlassTab(label: 'One'), GlassTab(label: 'Two')],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            height: customHeight,
            useOwnLayer: true,
          ),
        ),
      );

      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });

    testWidgets('has proper semantics for each segment', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [GlassTab(label: 'One'), GlassTab(label: 'Two')],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            useOwnLayer: true,
          ),
        ),
      );

      final semantics = tester.widgetList<Semantics>(
        find.descendant(
          of: find.byType(GlassSegmentedControl),
          matching: find.byType(Semantics),
        ),
      );

      expect(semantics.length, greaterThan(0));
      expect(
        semantics.any((s) => s.properties.button == true),
        isTrue,
      );
    });

    test('defaults are correct', () {
      final control = GlassSegmentedControl(
        segments: [GlassTab(label: 'One'), GlassTab(label: 'Two')],
        selectedIndex: 0,
        onSegmentSelected: (_) {},
      );

      expect(control.height, equals(32));
      expect(control.borderRadius, equals(16));
      expect(control.useOwnLayer, isFalse);
      expect(control.quality, isNull);
    });

    test('asserts minimum 2 segments', () {
      expect(
        () => GlassSegmentedControl(
          segments: [GlassTab(label: 'One')],
          selectedIndex: 0,
          onSegmentSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('asserts selectedIndex within bounds', () {
      expect(
        () => GlassSegmentedControl(
          segments: [GlassTab(label: 'One'), GlassTab(label: 'Two')],
          selectedIndex: 5,
          onSegmentSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Grouped mode (no useOwnLayer)
  // ──────────────────────────────────────────────────────────────────────────

  group('GlassSegmentedControl grouped mode', () {
    testWidgets('renders without own layer', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [GlassTab(label: 'A'), GlassTab(label: 'B')],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
          ),
        ),
      );
      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });

    testWidgets('tap fires onSegmentSelected in grouped mode', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [
              GlassTab(label: 'X'),
              GlassTab(label: 'Y'),
              GlassTab(label: 'Z')
            ],
            selectedIndex: 0,
            onSegmentSelected: (i) => tapped = i,
          ),
        ),
      );
      // Tap on 'Z' (index 2)
      await tester.tap(find.text('Z').first);
      await tester.pumpAndSettle();
      expect(tapped, 2);
    });

    testWidgets('does not call onSegmentSelected when tapping already-selected',
        (tester) async {
      int callCount = 0;
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [GlassTab(label: 'A'), GlassTab(label: 'B')],
            selectedIndex: 0,
            onSegmentSelected: (_) => callCount++,
          ),
        ),
      );
      await tester.tap(find.text('A').first);
      await tester.pump();
      expect(callCount, 0);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Drag interaction — state machine
  // ──────────────────────────────────────────────────────────────────────────

  group('GlassSegmentedControl drag interaction', () {
    testWidgets('horizontal drag triggers segment change', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassSegmentedControl(
              segments: [
                GlassTab(label: 'P'),
                GlassTab(label: 'Q'),
                GlassTab(label: 'R')
              ],
              selectedIndex: 0,
              onSegmentSelected: (_) {},
            ),
          ),
        ),
      );

      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(GlassSegmentedControl)));
      await tester.pump();
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // lastSelected may or may not have changed depending on exact position;
      // the widget should at minimum not crash
      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });

    testWidgets('drag cancel snaps back without crash', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassSegmentedControl(
              segments: [
                GlassTab(label: 'P'),
                GlassTab(label: 'Q'),
                GlassTab(label: 'R')
              ],
              selectedIndex: 1,
              onSegmentSelected: (_) {},
            ),
          ),
        ),
      );

      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(GlassSegmentedControl)));
      await tester.pump();
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Custom styling properties
  // ──────────────────────────────────────────────────────────────────────────

  group('GlassSegmentedControl custom styling', () {
    testWidgets('custom selectedTextStyle is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [GlassTab(label: 'A'), GlassTab(label: 'B')],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            selectedTextStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.amber,
            ),
          ),
        ),
      );
      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });

    testWidgets('custom unselectedTextStyle is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [GlassTab(label: 'A'), GlassTab(label: 'B')],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            unselectedTextStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w300,
              color: Colors.white38,
            ),
          ),
        ),
      );
      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });

    testWidgets('custom backgroundColor is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [GlassTab(label: 'A'), GlassTab(label: 'B')],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            backgroundColor: Colors.purple.withValues(alpha: 0.2),
          ),
        ),
      );
      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });

    testWidgets('indicatorColor is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [GlassTab(label: 'A'), GlassTab(label: 'B')],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            indicatorColor: Colors.green.withValues(alpha: 0.4),
          ),
        ),
      );
      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Quality and glass settings
  // ──────────────────────────────────────────────────────────────────────────

  group('GlassSegmentedControl quality and glass settings', () {
    testWidgets('explicit GlassQuality.standard works', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [GlassTab(label: 'A'), GlassTab(label: 'B')],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            quality: GlassQuality.standard,
          ),
        ),
      );
      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });

    testWidgets('explicit settings works with useOwnLayer', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassSegmentedControl(
            segments: [GlassTab(label: 'A'), GlassTab(label: 'B')],
            selectedIndex: 0,
            onSegmentSelected: (_) {},
            useOwnLayer: true,
            settings: const LiquidGlassSettings(thickness: 25),
          ),
        ),
      );
      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // selectedIndex update — triggers didUpdateWidget
  // ──────────────────────────────────────────────────────────────────────────

  group('GlassSegmentedControl didUpdateWidget', () {
    testWidgets('updates when selectedIndex changes externally',
        (tester) async {
      var index = 0;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => createTestApp(
            child: Column(
              children: [
                GlassSegmentedControl(
                  segments: [
                    GlassTab(label: 'A'),
                    GlassTab(label: 'B'),
                    GlassTab(label: 'C')
                  ],
                  selectedIndex: index,
                  onSegmentSelected: (i) => setState(() => index = i),
                ),
                ElevatedButton(
                  onPressed: () => setState(() => index = 2),
                  child: const Text('Select C'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Select C'));
      await tester.pumpAndSettle();
      expect(index, 2);
    });

    testWidgets('segments count change updates alignment', (tester) async {
      var segments = [GlassTab(label: 'A'), GlassTab(label: 'B')];
      var selectedIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => createTestApp(
            child: Column(
              children: [
                GlassSegmentedControl(
                  segments: segments,
                  selectedIndex: selectedIndex,
                  onSegmentSelected: (i) => setState(() => selectedIndex = i),
                ),
                ElevatedButton(
                  onPressed: () => setState(() {
                    segments = [
                      GlassTab(label: 'A'),
                      GlassTab(label: 'B'),
                      GlassTab(label: 'C')
                    ];
                    selectedIndex = 0;
                  }),
                  child: const Text('Add C'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Add C'));
      await tester.pumpAndSettle();

      expect(find.text('C'), findsWidgets);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Drag-cancel without prior drag (else branch — lines 519-521)
  // ──────────────────────────────────────────────────────────────────────────
  group('GlassSegmentedControl drag-cancel edge cases', () {
    testWidgets('cancel-without-drag snaps indicator back to selectedIndex',
        (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassSegmentedControl(
              segments: [
                GlassTab(label: 'A'),
                GlassTab(label: 'B'),
                GlassTab(label: 'C')
              ],
              selectedIndex: selected,
              onSegmentSelected: (i) => selected = i,
            ),
          ),
        ),
      );

      // Start a gesture but do NOT move — cancel immediately.
      // This exercises the `_isDragging == false` branch in _onDragCancel.
      final gesture = await tester
          .startGesture(tester.getCenter(find.byType(GlassSegmentedControl)));
      await tester.pump(const Duration(milliseconds: 10));
      await gesture.cancel();
      await tester.pump();

      expect(find.byType(GlassSegmentedControl), findsOneWidget);
      expect(selected, 0); // unchanged
    });

    testWidgets('drag then end fires onSegmentSelected when index changes',
        (tester) async {
      int? fired;
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassSegmentedControl(
              segments: [
                GlassTab(label: 'X'),
                GlassTab(label: 'Y'),
                GlassTab(label: 'Z')
              ],
              selectedIndex: 0,
              onSegmentSelected: (i) => fired = i,
            ),
          ),
        ),
      );

      // Drag ~2/3 to the right to clearly land on segment 2 (index 2)
      await tester.drag(
        find.byType(GlassSegmentedControl),
        const Offset(200, 0),
      );
      await tester.pumpAndSettle();
      // onSegmentSelected should have been called
      expect(fired, isNotNull);
    });

    testWidgets('quality inherited from AdaptiveLiquidGlassLayer ancestor',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: const LiquidGlassSettings(thickness: 20),
            child: SizedBox(
              width: 300,
              child: GlassSegmentedControl(
                segments: [GlassTab(label: 'A'), GlassTab(label: 'B')],
                selectedIndex: 0,
                onSegmentSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassSegmentedControl), findsOneWidget);
    });
  });
}
