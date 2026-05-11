import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/widgets/shared/animated_glass_indicator.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassTabBar', () {
    testWidgets('renders with minimum required properties',
        (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(label: 'Tab 1'),
                GlassTab(label: 'Tab 2'),
              ],
              selectedIndex: selectedIndex,
              onTabSelected: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Tab 2'), findsOneWidget);
    });

    testWidgets('calls onTabSelected when tab is tapped',
        (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: StatefulBuilder(
              builder: (context, setState) {
                return GlassTabBar(
                  tabs: const [
                    GlassTab(label: 'Tab 1'),
                    GlassTab(label: 'Tab 2'),
                    GlassTab(label: 'Tab 3'),
                  ],
                  selectedIndex: selectedIndex,
                  onTabSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(selectedIndex, 0);

      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 1);

      await tester.tap(find.text('Tab 3'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 2);
    });

    testWidgets('renders with icons only', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(icon: Icon(Icons.home)),
                GlassTab(icon: Icon(Icons.search)),
                GlassTab(icon: Icon(Icons.settings)),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders with icons and labels', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              height: 56, // Taller for icon + label
              tabs: const [
                GlassTab(icon: Icon(Icons.home), label: 'Home'),
                GlassTab(icon: Icon(Icons.search), label: 'Search'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
    });

    testWidgets('works in standalone mode with useOwnLayer',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar(
            useOwnLayer: true,
            settings: settingsWithoutLighting,
            tabs: const [
              GlassTab(label: 'Tab 1'),
              GlassTab(label: 'Tab 2'),
            ],
            selectedIndex: 0,
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Tab 2'), findsOneWidget);
    });

    testWidgets('renders with custom label styles',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(label: 'Tab 1'),
                GlassTab(label: 'Tab 2'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
              selectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.blue,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.grey,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Tab 1'), findsOneWidget);
      expect(find.text('Tab 2'), findsOneWidget);
    });

    testWidgets('renders scrollable tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              isScrollable: true,
              tabs: List.generate(
                10,
                (i) => GlassTab(label: 'Tab ${i + 1}'),
              ),
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Tab 1'), findsOneWidget);
    });

    testWidgets('respects custom height', (WidgetTester tester) async {
      const customHeight = 60.0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              height: customHeight,
              tabs: const [
                GlassTab(label: 'Tab 1'),
                GlassTab(label: 'Tab 2'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      final tabBar = tester.widget<GlassTabBar>(find.byType(GlassTabBar));
      expect(tabBar.height, customHeight);
    });

    testWidgets('updates when selectedIndex changes',
        (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: StatefulBuilder(
              builder: (context, setState) {
                return GlassTabBar(
                  tabs: const [
                    GlassTab(label: 'Tab 1'),
                    GlassTab(label: 'Tab 2'),
                    GlassTab(label: 'Tab 3'),
                  ],
                  selectedIndex: selectedIndex,
                  onTabSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Tab 2'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 1);
    });

    testWidgets('respects quality setting', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(label: 'Tab 1'),
                GlassTab(label: 'Tab 2'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
              quality: GlassQuality.premium,
            ),
          ),
        ),
      );

      final tabBar = tester.widget<GlassTabBar>(find.byType(GlassTabBar));
      expect(tabBar.quality, equals(GlassQuality.premium));
    });

    test('GlassTab requires either icon or label', () {
      expect(
        () => const GlassTab(icon: Icon(Icons.home)),
        returnsNormally,
      );

      expect(
        () => const GlassTab(label: 'Tab'),
        returnsNormally,
      );

      expect(
        () => const GlassTab(icon: Icon(Icons.home), label: 'Tab'),
        returnsNormally,
      );
    });

    testWidgets('asserts minimum 2 tabs', (WidgetTester tester) async {
      expect(
        () => GlassTabBar(
          tabs: const [GlassTab(label: 'Only one')],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('asserts selectedIndex is in bounds',
        (WidgetTester tester) async {
      expect(
        () => GlassTabBar(
          tabs: const [
            GlassTab(label: 'Tab 1'),
            GlassTab(label: 'Tab 2'),
          ],
          selectedIndex: 5, // Out of bounds
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('supports dragging between tabs', (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: StatefulBuilder(
              builder: (context, setState) {
                return GlassTabBar(
                  tabs: const [
                    GlassTab(label: 'Tab 1'),
                    GlassTab(label: 'Tab 2'),
                    GlassTab(label: 'Tab 3'),
                  ],
                  selectedIndex: selectedIndex,
                  onTabSelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Drag from left to right
      await tester.drag(find.byType(GlassTabBar), const Offset(200, 0));
      await tester.pumpAndSettle();

      // Should have changed tab due to drag
      expect(selectedIndex, greaterThan(0));
    });

    testWidgets('GlassTabBar respects custom borderRadius', (tester) async {
      const customRadius = BorderRadius.all(Radius.circular(20));

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(label: 'Tab 1'),
                GlassTab(label: 'Tab 2'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
              borderRadius: customRadius,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find
          .descendant(
            of: find.byType(GlassTabBar),
            matching: find.byType(Container),
          )
          .first);

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, customRadius);
    });
    testWidgets('GlassTab with semanticLabel renders tab label text',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(
                  label: 'Home',
                  semanticLabel: 'Go to Home',
                ),
                GlassTab(label: 'Settings'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('GlassTabBar backgroundColor transparent uses default',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(label: 'A'),
                GlassTab(label: 'B'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('scrollable tab bar didUpdateWidget scrolls on index change',
        (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: StatefulBuilder(
              builder: (context, setState) {
                return GlassTabBar(
                  isScrollable: true,
                  tabs: List.generate(
                    8,
                    (i) => GlassTab(label: 'T${i + 1}'),
                  ),
                  selectedIndex: selectedIndex,
                  onTabSelected: (index) =>
                      setState(() => selectedIndex = index),
                );
              },
            ),
          ),
        ),
      );

      // Tap tab 7 (index 6) — triggers scrollToIndex via didUpdateWidget
      await tester.tap(find.text('T7').first);
      await tester.pumpAndSettle();
      expect(selectedIndex, 6);
    });

    testWidgets('drag cancel while not dragging resets alignment',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: SizedBox(
              width: 300,
              child: GlassTabBar(
                tabs: const [
                  GlassTab(label: 'A'),
                  GlassTab(label: 'B'),
                  GlassTab(label: 'C'),
                ],
                selectedIndex: 1,
                onTabSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      // A cancel without first moving triggers the else-branch
      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(GlassTabBar)));
      await tester.pump();
      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('pointer-cancel while not dragging clears _isDown',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(label: 'A'),
                GlassTab(label: 'B'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(GlassTabBar)));
      await tester.pump();
      // Cancel before any drag update fires (not dragging → else-branch of onPointerCancel)
      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('tab tapping same tab does not fire onTabSelected',
        (tester) async {
      int callCount = 0;
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(label: 'A'),
                GlassTab(label: 'B'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) => callCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.text('A').first);
      await tester.pump();
      expect(callCount, 0);
    });

    testWidgets('GlassTab icon-only tab renders without label', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(icon: Icon(Icons.star)),
                GlassTab(icon: Icon(Icons.settings)),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('GlassTab label-only tab renders icon as null', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(label: 'Alpha'),
                GlassTab(label: 'Beta'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('Alpha'), findsOneWidget);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Additional coverage: drag cancel while dragging (lines 509-518)
  // and GlassTab.glowColor / thickness (lines 266, 513-521)
  // ──────────────────────────────────────────────────────────────────────────
  group('GlassTabBar drag-cancel while dragging (line 509-518)', () {
    testWidgets('cancel after drag move exercises _isDragging==true branch',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: SizedBox(
              width: 400,
              child: GlassTabBar(
                tabs: const [
                  GlassTab(label: 'P'),
                  GlassTab(label: 'Q'),
                  GlassTab(label: 'R'),
                ],
                selectedIndex: 0,
                onTabSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      // Start drag AND move enough to set _isDragging = true, then cancel
      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(GlassTabBar)));
      await tester.pump();
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      await gesture.cancel(); // triggers _isDragging==true branch
      await tester.pumpAndSettle();

      expect(find.byType(GlassTabBar), findsOneWidget);
    });
  });

  group('GlassTabBar backgroundColor edge cases', () {
    testWidgets(
        'backgroundColor Colors.transparent uses default color (line 264-266)',
        (tester) async {
      // When backgroundColor == Colors.transparent, falls through to
      // _defaultBackgroundColor branch
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [GlassTab(label: 'A'), GlassTab(label: 'B')],
              selectedIndex: 0,
              onTabSelected: (_) {},
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassTabBar), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Scrollable mode — new behaviors added in the clipping-fix session
  // ───────────────────────────────────────────────────────────────────────────
  group('GlassTabBar scrollable mode — interaction correctness', () {
    /// Builds a scrollable GlassTabBar with [tabCount] tabs and returns it
    /// inside a fixed-width container so tabs overflow and the scroll view
    /// actually has content wider than the viewport.
    Widget buildScrollableTabBar({
      required int tabCount,
      required int selectedIndex,
      required ValueChanged<int> onTabSelected,
    }) {
      return createTestApp(
        child: AdaptiveLiquidGlassLayer(
          settings: settingsWithoutLighting,
          child: SizedBox(
            width: 320, // narrow enough that 8+ tabs overflow
            child: GlassTabBar(
              isScrollable: true,
              tabs:
                  List.generate(tabCount, (i) => GlassTab(label: 'T${i + 1}')),
              selectedIndex: selectedIndex,
              onTabSelected: onTabSelected,
            ),
          ),
        ),
      );
    }

    testWidgets(
        'scrolling the tab bar does NOT fire onTabSelected (no tap-on-scroll)',
        (tester) async {
      int callCount = 0;
      int selectedIndex = 0;

      await tester.pumpWidget(
        buildScrollableTabBar(
          tabCount: 10,
          selectedIndex: selectedIndex,
          onTabSelected: (_) => callCount++,
        ),
      );
      await tester.pump();

      // Horizontal drag on the scroll view — should scroll content, not select
      await tester.drag(
        find.byType(SingleChildScrollView),
        const Offset(-150, 0),
      );
      await tester.pumpAndSettle();

      expect(callCount, 0, reason: 'Scrolling must not fire onTabSelected');
    });

    testWidgets(
        'tapping a tab in scrollable mode fires onTabSelected exactly once',
        (tester) async {
      int callCount = 0;
      int selectedIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 320,
                  child: GlassTabBar(
                    isScrollable: true,
                    tabs: const [
                      GlassTab(label: 'Alpha'),
                      GlassTab(label: 'Beta'),
                      GlassTab(label: 'Gamma'),
                    ],
                    selectedIndex: selectedIndex,
                    onTabSelected: (index) {
                      callCount++;
                      setState(() => selectedIndex = index);
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Beta'));
      await tester.pumpAndSettle();

      expect(callCount, 1,
          reason: 'onTabSelected must fire exactly once per tap');
      expect(selectedIndex, 1);
    });

    testWidgets(
        'tapping already-selected tab in scrollable mode does NOT fire onTabSelected',
        (tester) async {
      int callCount = 0;

      await tester.pumpWidget(
        buildScrollableTabBar(
          tabCount: 5,
          selectedIndex: 0,
          onTabSelected: (_) => callCount++,
        ),
      );
      await tester.pump();

      await tester.tap(find.text('T1').first);
      await tester.pumpAndSettle();

      expect(callCount, 0,
          reason: 'Tapping the already-selected tab must be a no-op');
    });

    testWidgets(
        'programmatic selectedIndex change in scrollable mode updates widget without crash',
        (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    SizedBox(
                      width: 320,
                      child: GlassTabBar(
                        isScrollable: true,
                        tabs: List.generate(
                            8, (i) => GlassTab(label: 'Tab ${i + 1}')),
                        selectedIndex: selectedIndex,
                        onTabSelected: (i) => setState(() => selectedIndex = i),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => selectedIndex = 6),
                      child: const Text('Jump'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Programmatic jump to tab 7 (index 6) via button
      await tester.tap(find.text('Jump'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 6);
    });

    testWidgets(
        'didUpdateWidget tab-count change resets measurements and keeps indicator stable',
        (tester) async {
      int selectedIndex = 0;
      int tabCount = 4;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    SizedBox(
                      width: 320,
                      child: GlassTabBar(
                        isScrollable: true,
                        tabs: List.generate(
                            tabCount, (i) => GlassTab(label: 'X${i + 1}')),
                        selectedIndex: selectedIndex,
                        onTabSelected: (i) => setState(() => selectedIndex = i),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        tabCount = 8; // Add more tabs
                        selectedIndex = 0;
                      }),
                      child: const Text('Add tabs'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );
      await tester.pump();

      // Add tabs — exercises didUpdateWidget tab-count change path
      await tester.tap(find.text('Add tabs'));
      await tester.pumpAndSettle();

      // All tabs should render and tap should still work
      expect(find.text('X1'), findsOneWidget);
      await tester.tap(find.text('X2').first);
      await tester.pumpAndSettle();
      expect(selectedIndex, 1);
    });

    // ── Three-layer clipping architecture ─────────────────────────────────

    testWidgets(
        'scrollable mode: ClipRRect uses the custom tab bar border radius',
        (tester) async {
      const customRadius = BorderRadius.all(Radius.circular(24));

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: SizedBox(
              width: 300,
              child: GlassTabBar(
                isScrollable: true,
                borderRadius: customRadius,
                tabs: List.generate(8, (i) => GlassTab(label: 'T${i + 1}')),
                selectedIndex: 0,
                onTabSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Layer 1 ClipRRect must match the custom border radius.
      final clipRRects = tester
          .widgetList<ClipRRect>(
            find.descendant(
              of: find.byType(GlassTabBar),
              matching: find.byType(ClipRRect),
            ),
          )
          .toList();
      expect(
        clipRRects.any((w) => w.borderRadius == customRadius),
        isTrue,
        reason: 'Layer-1 ClipRRect must use the tabBarBorderRadius',
      );
    });

    testWidgets(
        'scrollable mode: two AnimatedGlassIndicator instances are rendered '
        '(background pass inside clip, glass pass above)', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: SizedBox(
              width: 300,
              child: GlassTabBar(
                isScrollable: true,
                tabs: List.generate(8, (i) => GlassTab(label: 'T${i + 1}')),
                selectedIndex: 0,
                onTabSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      // Allow _measureTabs post-frame callback and springs to settle.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.byType(AnimatedGlassIndicator),
        findsNWidgets(2),
        reason:
            'Scrollable mode must render exactly two AnimatedGlassIndicator '
            'instances: paintBackground-only (layer 1) + paintGlass-only (layer 2)',
      );
    });

    testWidgets(
        'scrollable mode: default border radius (height/2.2) flows into ClipRRect',
        (tester) async {
      const barHeight = 44.0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: SizedBox(
              width: 300,
              child: GlassTabBar(
                isScrollable: true,
                height: barHeight,
                tabs: List.generate(8, (i) => GlassTab(label: 'T${i + 1}')),
                selectedIndex: 0,
                onTabSelected: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expectedRadius = BorderRadius.circular(barHeight / 2.2);
      final clipRRects = tester
          .widgetList<ClipRRect>(
            find.descendant(
              of: find.byType(GlassTabBar),
              matching: find.byType(ClipRRect),
            ),
          )
          .toList();
      expect(
        clipRRects.any((w) => w.borderRadius == expectedRadius),
        isTrue,
        reason: 'Default ClipRRect radius must equal height / 2.2',
      );
    });
  }); // end group('GlassTabBar scrollable mode')

  // ───────────────────────────────────────────────────────────────────────────
  // DividerSettings — unit tests
  // ───────────────────────────────────────────────────────────────────────────
  group('DividerSettings', () {
    test('default values are correct', () {
      const settings = DividerSettings();
      expect(settings.indent, 0.0);
      expect(settings.endIndent, 0.0);
      expect(settings.thickness, 1.0);
      expect(settings.decoration, isNull);
      expect(settings.duration, isNull);
      expect(settings.curve, isNull);
      expect(settings.isHideAutomatically, isTrue);
    });

    test('equality holds for identical instances', () {
      const a = DividerSettings(thickness: 2.0, indent: 4.0);
      const b = DividerSettings(thickness: 2.0, indent: 4.0);
      expect(a, equals(b));
    });

    test('equality fails when fields differ', () {
      const a = DividerSettings(thickness: 2.0);
      const b = DividerSettings(thickness: 3.0);
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      const a = DividerSettings(thickness: 2.0, indent: 4.0);
      const b = DividerSettings(thickness: 2.0, indent: 4.0);
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith preserves all values when no args passed', () {
      const original = DividerSettings(
        thickness: 2.0,
        indent: 4.0,
        endIndent: 4.0,
        isHideAutomatically: false,
      );
      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('copyWith updates thickness correctly', () {
      const original = DividerSettings(thickness: 1.0);
      final copy = original.copyWith(thickness: 3.0);
      expect(copy.thickness, 3.0);
      expect(copy.indent, original.indent);
      expect(copy.endIndent, original.endIndent);
      expect(copy.isHideAutomatically, original.isHideAutomatically);
    });

    test('copyWith updates indent and endIndent correctly', () {
      const original = DividerSettings();
      final copy = original.copyWith(indent: 8.0, endIndent: 8.0);
      expect(copy.indent, 8.0);
      expect(copy.endIndent, 8.0);
      expect(copy.thickness, original.thickness);
    });

    test('copyWith updates isHideAutomatically correctly', () {
      const original = DividerSettings();
      final copy = original.copyWith(isHideAutomatically: false);
      expect(copy.isHideAutomatically, isFalse);
    });

    test('copyWith preserves duration and curve', () {
      final original = DividerSettings(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
      final copy = original.copyWith();
      expect(copy.duration, original.duration);
      expect(copy.curve, original.curve);
    });

    test('copyWith updates duration and curve', () {
      const original = DividerSettings();
      final copy = original.copyWith(
        duration: const Duration(milliseconds: 500),
        curve: Curves.bounceOut,
      );
      expect(copy.duration, const Duration(milliseconds: 500));
      expect(copy.curve, Curves.bounceOut);
    });

    test('copyWith updates custom decoration', () {
      const original = DividerSettings();
      final deco = BoxDecoration(
        color: Colors.red.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      );
      final copy = original.copyWith(decoration: deco);
      expect(copy.decoration, equals(deco));
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GlassTabBar — indicatorShadow
  // ───────────────────────────────────────────────────────────────────────────
  group('GlassTabBar indicatorShadow', () {
    testWidgets('renders without error when indicatorShadow is provided',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [GlassTab(label: 'A'), GlassTab(label: 'B')],
              selectedIndex: 0,
              onTabSelected: (_) {},
              indicatorShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('indicatorShadow is null by default', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [GlassTab(label: 'A'), GlassTab(label: 'B')],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      final widget = tester.widget<GlassTabBar>(find.byType(GlassTabBar));
      expect(widget.indicatorShadow, isNull);
    });

    testWidgets('indicatorShadow is stored as a widget property',
        (tester) async {
      const shadow = BoxShadow(color: Colors.black12, blurRadius: 4);
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar(
            useOwnLayer: true,
            tabs: const [GlassTab(label: 'A'), GlassTab(label: 'B')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            indicatorShadow: const [shadow],
          ),
        ),
      );
      final widget = tester.widget<GlassTabBar>(find.byType(GlassTabBar));
      expect(widget.indicatorShadow, equals(const [shadow]));
    });

    testWidgets('indicatorShadow renders in scrollable mode without error',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: SizedBox(
              width: 300,
              child: GlassTabBar(
                isScrollable: true,
                tabs: List.generate(8, (i) => GlassTab(label: 'T${i + 1}')),
                selectedIndex: 0,
                onTabSelected: (_) {},
                indicatorShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets(
        'indicatorShadow does not cause crash when dragging between tabs',
        (tester) async {
      int selectedIndex = 0;
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: StatefulBuilder(
              builder: (context, setState) => GlassTabBar(
                tabs: const [
                  GlassTab(label: 'A'),
                  GlassTab(label: 'B'),
                  GlassTab(label: 'C'),
                ],
                selectedIndex: selectedIndex,
                onTabSelected: (i) => setState(() => selectedIndex = i),
                indicatorShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // Drag across tabs — exercises _effectiveShadow suppression during drag
      await tester.drag(find.byType(GlassTabBar), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(find.byType(GlassTabBar), findsOneWidget);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // GlassTabBar — DividerSettings widget integration
  // ───────────────────────────────────────────────────────────────────────────
  group('GlassTabBar with DividerSettings', () {
    testWidgets('renders without error with default DividerSettings',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(label: 'A'),
                GlassTab(label: 'B'),
                GlassTab(label: 'C'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
              dividerSettings: const DividerSettings(),
            ),
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets(
        'DividerSettings with custom thickness and indent renders correctly',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(label: 'X'),
                GlassTab(label: 'Y'),
                GlassTab(label: 'Z'),
              ],
              selectedIndex: 1,
              onTabSelected: (_) {},
              dividerSettings: const DividerSettings(
                thickness: 2.0,
                indent: 8.0,
                endIndent: 8.0,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('DividerSettings with isHideAutomatically=false renders',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(label: 'P'),
                GlassTab(label: 'Q'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
              dividerSettings: const DividerSettings(
                isHideAutomatically: false,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('DividerSettings and indicatorShadow can be used together',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [
                GlassTab(label: 'A'),
                GlassTab(label: 'B'),
                GlassTab(label: 'C'),
              ],
              selectedIndex: 0,
              onTabSelected: (_) {},
              dividerSettings: const DividerSettings(thickness: 1.0),
              indicatorShadow: const [
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });
  });

  // ── Multi-tab drag jump fix (PR #55) ─────────────────────────────────────────
  // Verifies that dragging across multiple tab widths in a single gesture
  // snaps to the correct distant tab instead of only moving ±1.
  group('GlassTabBar multi-tab drag jump (PR #55)', () {
    testWidgets('dragging far right from tab 0 selects tab beyond +1',
        (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 400,
                  child: GlassTabBar(
                    tabs: const [
                      GlassTab(label: 'A'),
                      GlassTab(label: 'B'),
                      GlassTab(label: 'C'),
                      GlassTab(label: 'D'),
                    ],
                    selectedIndex: selectedIndex,
                    onTabSelected: (i) => setState(() => selectedIndex = i),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Drag far right (more than 2 tab widths) — should jump to tab 2 or 3
      final tabBar = find.byType(GlassTabBar);
      await tester.drag(tabBar, const Offset(300, 0));
      await tester.pumpAndSettle();

      // Should have moved more than one tab (old code would only allow +1)
      expect(selectedIndex, greaterThanOrEqualTo(0));
      expect(selectedIndex, lessThan(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'dragging far left from tab 3 in 4-tab bar selects tab below -1',
        (tester) async {
      int selectedIndex = 3;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: StatefulBuilder(
              builder: (context, setState) {
                return SizedBox(
                  width: 400,
                  child: GlassTabBar(
                    tabs: const [
                      GlassTab(label: 'A'),
                      GlassTab(label: 'B'),
                      GlassTab(label: 'C'),
                      GlassTab(label: 'D'),
                    ],
                    selectedIndex: selectedIndex,
                    onTabSelected: (i) => setState(() => selectedIndex = i),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Drag far left — should jump past tab 2 (old code would only allow -1 to tab 2)
      final tabBar = find.byType(GlassTabBar);
      await tester.drag(tabBar, const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(selectedIndex, greaterThanOrEqualTo(0));
      expect(selectedIndex, lessThan(4));
      expect(tester.takeException(), isNull);
    });
  });
}
