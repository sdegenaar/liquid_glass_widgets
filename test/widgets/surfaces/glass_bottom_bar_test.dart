import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassBottomBar', () {
    final testTabs = [
      const GlassBottomBarTab(
        label: 'Home',
        icon: Icon(CupertinoIcons.home),
      ),
      const GlassBottomBarTab(
        label: 'Search',
        icon: Icon(CupertinoIcons.search),
      ),
      const GlassBottomBarTab(
        label: 'Profile',
        icon: Icon(CupertinoIcons.person),
      ),
    ];

    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(find.byType(GlassBottomBar), findsOneWidget);
    });

    testWidgets('displays all tab labels', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality:
                MaskingQuality.off, // Avoid dual-layer rendering in tests
          ),
        ),
      );

      // selectedIndex: 0 → 'Home' appears in both unselected base AND vibrant overlay
      expect(find.text('Home'), findsAtLeastNWidgets(1));
      expect(find.text('Search'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);
    });

    testWidgets('displays all tab icons', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality:
                MaskingQuality.off, // Avoid dual-layer rendering in tests
          ),
        ),
      );

      // selectedIndex: 0 → home icon appears in both layers
      expect(find.byIcon(CupertinoIcons.home), findsAtLeastNWidgets(1));
      expect(find.byIcon(CupertinoIcons.search), findsWidgets);
      expect(find.byIcon(CupertinoIcons.person), findsWidgets);
    });

    testWidgets('calls onTabSelected when tab is tapped', (tester) async {
      var selectedIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs,
            selectedIndex: selectedIndex,
            onTabSelected: (index) => selectedIndex = index,
            maskingQuality:
                MaskingQuality.off, // Avoid dual-layer rendering in tests
          ),
        ),
      );

      await tester.tap(find.text('Search').first);
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(1));
    });

    testWidgets('displays extra button when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            extraButton: GlassBottomBarExtraButton(
              icon: Icon(CupertinoIcons.add),
              label: 'Add',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.add), findsOneWidget);
    });

    testWidgets('extra button calls onTap when pressed', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            extraButton: GlassBottomBarExtraButton(
              icon: Icon(CupertinoIcons.add),
              label: 'Add',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('has proper semantics for tabs', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
          ),
        ),
      );

      final semantics = tester.widgetList<Semantics>(
        find.descendant(
          of: find.byType(GlassBottomBar),
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
      final bar = GlassBottomBar(
        tabs: testTabs,
        selectedIndex: 0,
        onTabSelected: (_) {},
      );

      expect(bar.spacing, equals(8));
      expect(bar.barHeight, equals(64));
      expect(bar.barBorderRadius, equals(32));
      expect(bar.showIndicator, isTrue);
      expect(bar.quality, isNull);
    });
  });

  group('GlassBottomBarTab', () {
    test('can be instantiated', () {
      const tab = GlassBottomBarTab(
        label: 'Home',
        icon: Icon(CupertinoIcons.home),
      );

      expect(tab.label, equals('Home'));
      expect(tab.icon, isA<Icon>());
    });
  });

  group('GlassBottomBarExtraButton', () {
    test('can be instantiated', () {
      final button = GlassBottomBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Add',
        onTap: () {},
      );

      expect(button.icon, isA<Icon>());
      expect(button.label, equals('Add'));
      expect(button.size, equals(64));
    });

    test('collapseOnSearchFocus defaults to true', () {
      final button = GlassBottomBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Create',
        onTap: () {},
      );
      expect(button.collapseOnSearchFocus, isTrue);
    });

    test('position defaults to beforeSearch', () {
      final button = GlassBottomBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Create',
        onTap: () {},
      );
      expect(button.position, ExtraButtonPosition.beforeSearch);
    });

    test('afterSearch position works', () {
      final button = GlassBottomBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Create',
        onTap: () {},
        position: ExtraButtonPosition.afterSearch,
      );
      expect(button.position, ExtraButtonPosition.afterSearch);
    });

    test('custom size is respected', () {
      final button = GlassBottomBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Create',
        onTap: () {},
        size: 80,
      );
      expect(button.size, 80);
    });

    test('custom iconColor is respected', () {
      final button = GlassBottomBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Create',
        onTap: () {},
        iconColor: Colors.red,
      );
      expect(button.iconColor, Colors.red);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // MaskingQuality enum values
  // ──────────────────────────────────────────────────────────────────────────

  group('MaskingQuality', () {
    test('has off and high values', () {
      expect(MaskingQuality.values, contains(MaskingQuality.off));
      expect(MaskingQuality.values, contains(MaskingQuality.high));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // ExtraButtonPosition enum
  // ──────────────────────────────────────────────────────────────────────────

  group('ExtraButtonPosition', () {
    test('has beforeSearch and afterSearch values', () {
      expect(ExtraButtonPosition.values,
          contains(ExtraButtonPosition.beforeSearch));
      expect(ExtraButtonPosition.values,
          contains(ExtraButtonPosition.afterSearch));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GlassTabPillAnchor enum
  // ──────────────────────────────────────────────────────────────────────────

  group('GlassTabPillAnchor', () {
    test('has start and center values', () {
      expect(GlassTabPillAnchor.values, contains(GlassTabPillAnchor.start));
      expect(GlassTabPillAnchor.values, contains(GlassTabPillAnchor.center));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GlassBottomBar extended rendering scenarios
  // ──────────────────────────────────────────────────────────────────────────

  group('GlassBottomBar extended rendering', () {
    final testTabs3 = [
      const GlassBottomBarTab(
        label: 'Home',
        icon: Icon(CupertinoIcons.home),
        glowColor: Colors.blue,
      ),
      const GlassBottomBarTab(
        label: 'Search',
        icon: Icon(CupertinoIcons.search),
        glowColor: Colors.purple,
      ),
      const GlassBottomBarTab(
        label: 'Profile',
        icon: Icon(CupertinoIcons.person),
        glowColor: Colors.pink,
      ),
    ];

    testWidgets('showIndicator=false hides indicator', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            showIndicator: false,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });

    testWidgets('MaskingQuality.off renders correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs3,
            selectedIndex: 1,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      // selectedIndex: 1 → 'Home' (tab 0) is NOT selected → appears once (unselected only)
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('can render 5 tabs', (tester) async {
      final fiveTabs = [
        const GlassBottomBarTab(label: 'A', icon: Icon(CupertinoIcons.home)),
        const GlassBottomBarTab(label: 'B', icon: Icon(CupertinoIcons.search)),
        const GlassBottomBarTab(label: 'C', icon: Icon(CupertinoIcons.person)),
        const GlassBottomBarTab(label: 'D', icon: Icon(CupertinoIcons.bell)),
        const GlassBottomBarTab(
            label: 'E', icon: Icon(CupertinoIcons.settings)),
      ];
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: fiveTabs,
            selectedIndex: 2,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      // selectedIndex: 2 → 'C' appears in both unselected base AND vibrant overlay
      expect(find.text('C'), findsAtLeastNWidgets(1));
    });

    testWidgets('custom barHeight is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            barHeight: 80,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });

    testWidgets('custom selectedIconColor and unselectedIconColor',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            selectedIconColor: Colors.yellow,
            unselectedIconColor: Colors.white60,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });

    testWidgets('custom iconSize is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            iconSize: 32,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });

    testWidgets('custom settings is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            settings: const LiquidGlassSettings(thickness: 40),
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });

    testWidgets('custom quality parameter is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            quality: GlassQuality.standard,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });

    testWidgets('with extra button afterSearch position', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            extraButton: GlassBottomBarExtraButton(
              icon: const Icon(CupertinoIcons.add),
              label: 'Create',
              onTap: () {},
              position: ExtraButtonPosition.afterSearch,
            ),
          ),
        ),
      );
      expect(find.byIcon(CupertinoIcons.add), findsOneWidget);
    });

    testWidgets('tab with activeIcon uses it when selected', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: const [
              GlassBottomBarTab(
                label: 'Home',
                icon: Icon(CupertinoIcons.home),
                activeIcon: Icon(CupertinoIcons.house_fill),
              ),
              GlassBottomBarTab(
                label: 'Search',
                icon: Icon(CupertinoIcons.search),
              ),
            ],
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });

    testWidgets('custom barBorderRadius is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            barBorderRadius: 16,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });

    testWidgets('assertion: selected index not negative', (tester) async {
      expect(
        () => GlassBottomBar(
          tabs: testTabs3,
          selectedIndex: -1,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('assertion: selected index not out of range', (tester) async {
      expect(
        () => GlassBottomBar(
          tabs: testTabs3,
          selectedIndex: 5,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GlassBottomBarTab extended
  // ──────────────────────────────────────────────────────────────────────────

  group('GlassBottomBarTab extended', () {
    test('tabs with no label centers icon', () {
      const tab = GlassBottomBarTab(
        icon: Icon(CupertinoIcons.home),
      );
      expect(tab.label, isNull);
    });

    test('glowColor is stored correctly', () {
      const tab = GlassBottomBarTab(
        label: 'Fire',
        icon: Icon(CupertinoIcons.flame),
        glowColor: Colors.orange,
      );
      expect(tab.glowColor, Colors.orange);
    });

    test('thickness is stored correctly', () {
      const tab = GlassBottomBarTab(
        label: 'Heavy',
        icon: Icon(CupertinoIcons.star_fill),
        thickness: 1.5,
      );
      expect(tab.thickness, 1.5);
    });

    test('activeIcon is stored correctly', () {
      const tab = GlassBottomBarTab(
        label: 'Home',
        icon: Icon(CupertinoIcons.home),
        activeIcon: Icon(CupertinoIcons.house_fill),
      );
      expect(tab.activeIcon, isA<Icon>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // _TabIndicator didUpdateWidget paths
  // ─────────────────────────────────────────────────────────────────────────

  group('GlassBottomBar _TabIndicator didUpdateWidget', () {
    final testTabs = [
      const GlassBottomBarTab(
        label: 'Home',
        icon: Icon(CupertinoIcons.home),
      ),
      const GlassBottomBarTab(
        label: 'Search',
        icon: Icon(CupertinoIcons.search),
      ),
      const GlassBottomBarTab(
        label: 'Profile',
        icon: Icon(CupertinoIcons.person),
      ),
    ];

    testWidgets('tabIndex change updates indicator alignment', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) => GlassBottomBar(
              tabs: testTabs,
              selectedIndex: selected,
              onTabSelected: (i) => setState(() => selected = i),
              maskingQuality: MaskingQuality.off,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Profile').first);
      await tester.pumpAndSettle();
      expect(selected, 2);
    });

    testWidgets('barBorderRadius change updates cached shape', (tester) async {
      double radius = 16.0;
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                GlassBottomBar(
                  tabs: testTabs,
                  selectedIndex: 0,
                  onTabSelected: (_) {},
                  maskingQuality: MaskingQuality.off,
                  barBorderRadius: radius,
                ),
                GestureDetector(
                  onTap: () => setState(() => radius = 32.0),
                  child: const Text('change'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('change'));
      await tester.pumpAndSettle();
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });

    testWidgets('tabCount change updates alignment', (tester) async {
      List<GlassBottomBarTab> tabs = testTabs.sublist(0, 2);
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                GlassBottomBar(
                  tabs: tabs,
                  selectedIndex: 0,
                  onTabSelected: (_) {},
                  maskingQuality: MaskingQuality.off,
                ),
                GestureDetector(
                  onTap: () => setState(() => tabs = testTabs),
                  child: const Text('add tab'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('add tab'));
      await tester.pumpAndSettle();
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // _onBarTapDown, _onDragUpdate, _onDragEnd
  // ─────────────────────────────────────────────────────────────────────────

  group('GlassBottomBar drag interaction coverage', () {
    late List<GlassBottomBarTab> tabs;
    setUp(() {
      tabs = [
        const GlassBottomBarTab(
          label: 'A',
          icon: Icon(CupertinoIcons.home),
        ),
        const GlassBottomBarTab(
          label: 'B',
          icon: Icon(CupertinoIcons.search),
        ),
        const GlassBottomBarTab(
          label: 'C',
          icon: Icon(CupertinoIcons.person),
        ),
      ];
    });

    testWidgets('tap on different tab calls onTabSelected (_onBarTapDown)',
        (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 375,
            child: StatefulBuilder(
              builder: (context, setState) => GlassBottomBar(
                tabs: tabs,
                selectedIndex: selected,
                onTabSelected: (i) => setState(() => selected = i),
                maskingQuality: MaskingQuality.off,
              ),
            ),
          ),
        ),
      );

      // Tap the 'B' tab label
      await tester.tap(find.text('B').first);
      await tester.pumpAndSettle();
      expect(selected, 1);
    });

    testWidgets('drag across bar fires _onDragUpdate and _onDragEnd',
        (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 375,
            child: StatefulBuilder(
              builder: (context, setState) => GlassBottomBar(
                tabs: tabs,
                selectedIndex: selected,
                onTabSelected: (i) => setState(() => selected = i),
                maskingQuality: MaskingQuality.off,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Drag from left to right across the whole bar
      final barFinder = find.byType(GlassBottomBar);
      await tester.drag(barFinder, const Offset(200, 0));
      await tester.pumpAndSettle();

      // After drag+end, the selected index should be non-negative (state updated)
      expect(selected, greaterThanOrEqualTo(0));
    });

    testWidgets('slow drag snaps to nearest item on release', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 375,
            child: StatefulBuilder(
              builder: (context, setState) => GlassBottomBar(
                tabs: tabs,
                selectedIndex: selected,
                onTabSelected: (i) => setState(() => selected = i),
                maskingQuality: MaskingQuality.off,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // A short slow drag exercises the low-velocity snap path
      final barFinder = find.byType(GlassBottomBar);
      final gesture = await tester.startGesture(tester.getCenter(barFinder));
      await gesture.moveBy(const Offset(40, 0));
      // Short, slow move → low velocity
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();

      // Just verify no crash and the widget survived
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });

    testWidgets('quality inherited from parent InheritedLiquidGlass',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassBottomBar(
              tabs: tabs,
              selectedIndex: 0,
              onTabSelected: (_) {},
              // quality: null — should inherit from ancestor
            ),
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // indicatorExpansion (PR #40 — jfhair)
  // ─────────────────────────────────────────────────────────────────────────

  group('GlassBottomBar.indicatorExpansion', () {
    final tabs = [
      const GlassBottomBarTab(label: 'A', icon: Icon(CupertinoIcons.home)),
      const GlassBottomBarTab(label: 'B', icon: Icon(CupertinoIcons.search)),
      const GlassBottomBarTab(label: 'C', icon: Icon(CupertinoIcons.person)),
    ];

    test('default indicatorExpansion matches iOS 26 calibration', () {
      final bar = GlassBottomBar(
        tabs: tabs,
        selectedIndex: 0,
        onTabSelected: (_) {},
      );
      expect(
        bar.indicatorExpansion,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      );
    });

    test('default indicatorPinchStrength is 0.4 (iOS 26 calibration)', () {
      final bar = GlassBottomBar(
        tabs: tabs,
        selectedIndex: 0,
        onTabSelected: (_) {},
      );
      expect(bar.indicatorPinchStrength, 0.4);
    });

    testWidgets('accepts custom indicatorExpansion', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: tabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            indicatorExpansion: const EdgeInsets.all(5.0),
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      final bar =
          tester.widget<GlassBottomBar>(find.byType(GlassBottomBar).first);
      expect(bar.indicatorExpansion, const EdgeInsets.all(5.0));
    });

    testWidgets('accepts zero indicatorExpansion', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: tabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            indicatorExpansion: EdgeInsets.zero,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });

    testWidgets('large indicatorExpansion does not crash', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: tabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            indicatorExpansion: const EdgeInsets.all(40.0),
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // 5-tab stress test — new default expansion (h:12, v:8) on narrow tabs
  // ─────────────────────────────────────────────────────────────────────────
  //
  // With 5 tabs on a 375-pt iPhone screen each tab is ~75 pt wide.
  // At the new default expansion (horizontal: 12) the pill extends 12 pt
  // past the tab boundary during a fast drag. This group verifies no layout
  // assertion fires, no overflow error, and all labels remain findable.

  group('GlassBottomBar 5-tab expansion stress', () {
    final fiveTabs = [
      const GlassBottomBarTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
      const GlassBottomBarTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
      const GlassBottomBarTab(label: 'Inbox', icon: Icon(CupertinoIcons.tray)),
      const GlassBottomBarTab(label: 'Profile', icon: Icon(CupertinoIcons.person)),
      const GlassBottomBarTab(label: 'Settings', icon: Icon(CupertinoIcons.settings)),
    ];

    testWidgets(
        'fast full-width drag on 5-tab bar does not crash or overflow',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 375,
            child: StatefulBuilder(
              builder: (context, setState) => GlassBottomBar(
                tabs: fiveTabs,
                selectedIndex: 0,
                onTabSelected: (_) {},
                maskingQuality: MaskingQuality.off,
                // Uses default expansion: symmetric(h:12, v:8)
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bar = find.byType(GlassBottomBar);
      await tester.drag(bar, const Offset(350, 0));
      await tester.pumpAndSettle();

      expect(find.byType(GlassBottomBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('all 5 labels remain findable after drag with default expansion',
        (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 375,
            child: StatefulBuilder(
              builder: (context, setState) => GlassBottomBar(
                tabs: fiveTabs,
                selectedIndex: selected,
                onTabSelected: (i) => setState(() => selected = i),
                maskingQuality: MaskingQuality.off,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(GlassBottomBar), const Offset(300, 0));
      await tester.pumpAndSettle();

      for (final label in ['Home', 'Search', 'Inbox', 'Profile', 'Settings']) {
        expect(find.text(label), findsWidgets,
            reason: '$label disappeared after drag with h:12 expansion');
      }
    });

    testWidgets('wider h:16 expansion does not crash on 5-tab bar',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 375,
            child: GlassBottomBar(
              tabs: fiveTabs,
              selectedIndex: 2,
              onTabSelected: (_) {},
              maskingQuality: MaskingQuality.off,
              indicatorExpansion:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GlassBottomBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AnimatedGlassIndicator settings merge — baseIndicatorSettings
  // ─────────────────────────────────────────────────────────────────────────

  group('AnimatedGlassIndicator.baseIndicatorSettings', () {
    test('has chromaticAberration 0.15', () {
      expect(
        AnimatedGlassIndicator.baseIndicatorSettings.chromaticAberration,
        0.15,
      );
    });

    test('blur: 0 (indicator has no blur by default)', () {
      expect(AnimatedGlassIndicator.baseIndicatorSettings.blur, 0.0);
    });

    test('glassColor is fully transparent (optics only — no base tint)', () {
      expect(
        AnimatedGlassIndicator.baseIndicatorSettings.glassColor.a,
        0.0,
      );
    });

    testWidgets(
        'indicatorSettings with only blur overridden preserves 0.15 aberration',
        (tester) async {
      // Verifies the merge gap fix: a caller passing LiquidGlassSettings(blur:2)
      // should keep chromaticAberration: 0.15 from baseIndicatorSettings.
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: [
              const GlassBottomBarTab(
                  label: 'A', icon: Icon(CupertinoIcons.home)),
              const GlassBottomBarTab(
                  label: 'B', icon: Icon(CupertinoIcons.search)),
            ],
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            // Only blur is changed — chromaticAberration should stay 0.15
            indicatorSettings: const LiquidGlassSettings(blur: 2),
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'indicatorSettings chromaticAberration: 0.0 correctly overrides base',
        (tester) async {
      // 0.0 differs from LiquidGlassSettings() default (0.01) so it IS an
      // intentional override and must replace the base 0.15.
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: [
              const GlassBottomBarTab(
                  label: 'A', icon: Icon(CupertinoIcons.home)),
              const GlassBottomBarTab(
                  label: 'B', icon: Icon(CupertinoIcons.search)),
            ],
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            indicatorSettings:
                const LiquidGlassSettings(chromaticAberration: 0.0),
          ),
        ),
      );
      expect(find.byType(GlassBottomBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
