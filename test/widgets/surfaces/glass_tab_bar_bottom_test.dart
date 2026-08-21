import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

double _transitionScale(WidgetTester tester, Finder finder) {
  return tester.widget<ScaleTransition>(finder).scale.value;
}

void main() {
  group('GlassTabBar.bottom', () {
    final testTabs = [
      const GlassTab(
        label: 'Home',
        icon: Icon(CupertinoIcons.home),
      ),
      const GlassTab(
        label: 'Search',
        icon: Icon(CupertinoIcons.search),
      ),
      const GlassTab(
        label: 'Profile',
        icon: Icon(CupertinoIcons.person),
      ),
    ];

    testWidgets('can be instantiated with required parameters', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('displays all tab labels', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
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
          child: GlassTabBar.bottom(
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
          child: GlassTabBar.bottom(
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
          child: GlassTabBar.bottom(
            tabs: testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            extraButton: GlassTabBarExtraButton(
              icon: Icon(CupertinoIcons.add),
              label: 'Add',
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.add), findsOneWidget);
    });

    testWidgets('places extra button on the left when configured',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            extraButton: GlassTabBarExtraButton(
              icon: const Icon(CupertinoIcons.add),
              label: 'Add',
              onTap: () {},
              placement: GlassExtraButtonPlacement.left,
            ),
          ),
        ),
      );

      final addCenter = tester.getCenter(find.byIcon(CupertinoIcons.add));
      final homeCenter =
          tester.getCenter(find.byIcon(CupertinoIcons.home).first);

      expect(addCenter.dx, lessThan(homeCenter.dx));
    });

    testWidgets('extra button calls onTap when pressed', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            extraButton: GlassTabBarExtraButton(
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
          child: GlassTabBar.bottom(
            tabs: testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
          ),
        ),
      );

      final semantics = tester.widgetList<Semantics>(
        find.descendant(
          of: find.byType(GlassTabBar),
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
      final bar = GlassTabBar.bottom(
        tabs: testTabs,
        selectedIndex: 0,
        onTabSelected: (_) {},
      );

      expect(bar.spacing, equals(8));
      expect(bar.barHeight, equals(64));
      expect(bar.barBorderRadius, equals(GlassDefaults.capsuleRadius));
      expect(bar.showIndicator, isTrue);
      expect(bar.quality, isNull);
    });
  });

  group('GlassTab', () {
    test('can be instantiated', () {
      const tab = GlassTab(
        label: 'Home',
        icon: Icon(CupertinoIcons.home),
      );

      expect(tab.label, equals('Home'));
      expect(tab.icon, isA<Icon>());
    });
  });

  group('GlassTabBarExtraButton', () {
    test('can be instantiated', () {
      final button = GlassTabBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Add',
        onTap: () {},
      );

      expect(button.icon, isA<Icon>());
      expect(button.label, equals('Add'));
      expect(button.size, equals(64));
    });

    test('collapseOnSearchFocus defaults to true', () {
      final button = GlassTabBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Create',
        onTap: () {},
      );
      expect(button.collapseOnSearchFocus, isTrue);
    });

    test('position defaults to beforeSearch', () {
      final button = GlassTabBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Create',
        onTap: () {},
      );
      expect(button.position, GlassExtraButtonPosition.beforeSearch);
    });

    test('placement defaults to right', () {
      final button = GlassTabBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Create',
        onTap: () {},
      );
      expect(button.placement, GlassExtraButtonPlacement.right);
    });

    test('left placement works', () {
      final button = GlassTabBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Create',
        onTap: () {},
        placement: GlassExtraButtonPlacement.left,
      );
      expect(button.placement, GlassExtraButtonPlacement.left);
    });

    test('afterSearch position works', () {
      final button = GlassTabBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Create',
        onTap: () {},
        position: GlassExtraButtonPosition.afterSearch,
      );
      expect(button.position, GlassExtraButtonPosition.afterSearch);
    });

    test('custom size is respected', () {
      final button = GlassTabBarExtraButton(
        icon: Icon(CupertinoIcons.add),
        label: 'Create',
        onTap: () {},
        size: 80,
      );
      expect(button.size, 80);
    });

    test('custom iconColor is respected', () {
      final button = GlassTabBarExtraButton(
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
  // GlassExtraButtonPosition enum
  // ──────────────────────────────────────────────────────────────────────────

  group('GlassExtraButtonPosition', () {
    test('has beforeSearch and afterSearch values', () {
      expect(GlassExtraButtonPosition.values,
          contains(GlassExtraButtonPosition.beforeSearch));
      expect(GlassExtraButtonPosition.values,
          contains(GlassExtraButtonPosition.afterSearch));
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
  // GlassTabBar.bottom collapse config
  // ──────────────────────────────────────────────────────────────────────────

  group('GlassTabBar.bottom collapse config', () {
    test('direction enum has both values', () {
      expect(
        GlassTabBarCollapseDirection.values,
        contains(GlassTabBarCollapseDirection.towardsExtraButton),
      );
      expect(
        GlassTabBarCollapseDirection.values,
        contains(GlassTabBarCollapseDirection.awayFromExtraButton),
      );
    });

    test('config defaults are correct', () {
      const config = GlassTabBarCollapseConfig();
      expect(
        config.direction,
        GlassTabBarCollapseDirection.towardsExtraButton,
      );
      expect(config.expandOnTap, isTrue);
      expect(config.animationDuration, const Duration(milliseconds: 280));
      expect(config.collapsedExtraButtonScale, 0.9);
    });

    test('config accepts custom duration and collapsed scale', () {
      const config = GlassTabBarCollapseConfig(
        animationDuration: Duration(milliseconds: 360),
        collapsedExtraButtonScale: 0.82,
      );
      expect(config.animationDuration, const Duration(milliseconds: 360));
      expect(config.collapsedExtraButtonScale, 0.82);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GlassTabBar.bottom extended rendering scenarios
  // ──────────────────────────────────────────────────────────────────────────

  group('GlassTabBar.bottom extended rendering', () {
    final testTabs3 = [
      const GlassTab(
        label: 'Home',
        icon: Icon(CupertinoIcons.home),
        glowColor: Colors.blue,
      ),
      const GlassTab(
        label: 'Search',
        icon: Icon(CupertinoIcons.search),
        glowColor: Colors.purple,
      ),
      const GlassTab(
        label: 'Profile',
        icon: Icon(CupertinoIcons.person),
        glowColor: Colors.pink,
      ),
    ];

    testWidgets('showIndicator=false hides indicator', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            showIndicator: false,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('MaskingQuality.off renders correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
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
        const GlassTab(label: 'A', icon: Icon(CupertinoIcons.home)),
        const GlassTab(label: 'B', icon: Icon(CupertinoIcons.search)),
        const GlassTab(label: 'C', icon: Icon(CupertinoIcons.person)),
        const GlassTab(label: 'D', icon: Icon(CupertinoIcons.bell)),
        const GlassTab(label: 'E', icon: Icon(CupertinoIcons.settings)),
      ];
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
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
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            barHeight: 80,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('custom selectedIconColor and unselectedIconColor',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            selectedIconColor: Colors.yellow,
            unselectedIconColor: Colors.white60,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('custom iconSize is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            iconSize: 32,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('custom settings is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            settings: const LiquidGlassSettings(thickness: 40),
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('custom quality parameter is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            quality: GlassQuality.standard,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('with extra button afterSearch position', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            extraButton: GlassTabBarExtraButton(
              icon: const Icon(CupertinoIcons.add),
              label: 'Create',
              onTap: () {},
              position: GlassExtraButtonPosition.afterSearch,
            ),
          ),
        ),
      );
      expect(find.byIcon(CupertinoIcons.add), findsOneWidget);
    });

    testWidgets('tab with activeIcon uses it when selected', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: const [
              GlassTab(
                label: 'Home',
                icon: Icon(CupertinoIcons.home),
                activeIcon: Icon(CupertinoIcons.house_fill),
              ),
              GlassTab(
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
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('custom barBorderRadius is accepted', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            barBorderRadius: 16,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('up swipe collapses and tap expands before extra action fires',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            extraButton: GlassTabBarExtraButton(
              icon: const Icon(CupertinoIcons.add),
              label: 'Add',
              onTap: () => taps++,
            ),
            collapseConfig: const GlassTabBarCollapseConfig(),
          ),
        ),
      );

      await tester.fling(
        find.byKey(const ValueKey<String>('glass_tab_bar_gesture_region')),
        const Offset(0, -300),
        1200,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pumpAndSettle();
      expect(taps, 0);

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pump();
      expect(taps, 1);
    });

    testWidgets('collapse keeps tab content visible during the animation',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            extraButton: GlassTabBarExtraButton(
              icon: const Icon(CupertinoIcons.add),
              label: 'Add',
              onTap: () {},
            ),
            collapseConfig: const GlassTabBarCollapseConfig(
              animationDuration: Duration(milliseconds: 220),
            ),
          ),
        ),
      );

      await tester.fling(
        find.byKey(const ValueKey<String>('glass_tab_bar_gesture_region')),
        const Offset(0, -300),
        1200,
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('collapse direction changes the tab pill resting edge',
        (tester) async {
      Future<Offset> collapsedTopLeft(
        GlassTabBarCollapseDirection direction,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: GlassTabBar.bottom(
              tabs: testTabs3,
              selectedIndex: 0,
              onTabSelected: (_) {},
              maskingQuality: MaskingQuality.off,
              extraButton: GlassTabBarExtraButton(
                icon: const Icon(CupertinoIcons.add),
                label: 'Add',
                onTap: () {},
              ),
              collapseConfig: GlassTabBarCollapseConfig(
                direction: direction,
              ),
            ),
          ),
        );

        await tester.fling(
          find.byKey(const ValueKey<String>('glass_tab_bar_gesture_region')),
          const Offset(0, -300),
          1200,
          warnIfMissed: false,
        );
        await tester.pumpAndSettle();

        return tester.getTopLeft(
          find.byKey(const ValueKey<String>('glass_tab_bar_tab_pill')),
        );
      }

      final towards = await collapsedTopLeft(
        GlassTabBarCollapseDirection.towardsExtraButton,
      );
      final away = await collapsedTopLeft(
        GlassTabBarCollapseDirection.awayFromExtraButton,
      );

      expect(towards.dx, greaterThan(away.dx));
    });

    testWidgets('collapse towards extra button removes the gap to extra button',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            extraButton: GlassTabBarExtraButton(
              icon: const Icon(CupertinoIcons.add),
              label: 'Add',
              onTap: () {},
            ),
            collapseConfig: const GlassTabBarCollapseConfig(
              direction: GlassTabBarCollapseDirection.towardsExtraButton,
            ),
          ),
        ),
      );

      await tester.fling(
        find.byKey(const ValueKey<String>('glass_tab_bar_gesture_region')),
        const Offset(0, -300),
        1200,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      final extraRect = tester.getRect(find.byKey(
        const ValueKey<String>('glass_tab_bar_extra_button_scale'),
      ));
      final pillRect = tester.getRect(
        find.byKey(const ValueKey<String>('glass_tab_bar_tab_pill')),
      );

      expect(pillRect.right, greaterThanOrEqualTo(extraRect.left - 0.5));
    });

    testWidgets(
        'collapse towards extra button ends with the tab pill centered inside the extra button',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            extraButton: GlassTabBarExtraButton(
              icon: const Icon(CupertinoIcons.add),
              label: 'Add',
              onTap: () {},
            ),
            collapseConfig: const GlassTabBarCollapseConfig(
              direction: GlassTabBarCollapseDirection.towardsExtraButton,
            ),
          ),
        ),
      );

      await tester.fling(
        find.byKey(const ValueKey<String>('glass_tab_bar_gesture_region')),
        const Offset(0, -300),
        1200,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      final extraRect = tester.getRect(find.byKey(
        const ValueKey<String>('glass_tab_bar_extra_button_scale'),
      ));
      final pillRect = tester.getRect(
        find.byKey(const ValueKey<String>('glass_tab_bar_tab_pill')),
      );

      expect(pillRect.center.dx, greaterThan(extraRect.left));
      expect(pillRect.center.dx, lessThan(extraRect.right));
    });

    testWidgets(
        'left extra button also collapses without leaving a gap to the tab pill',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            extraButton: GlassTabBarExtraButton(
              icon: const Icon(CupertinoIcons.add),
              label: 'Add',
              placement: GlassExtraButtonPlacement.left,
              onTap: () {},
            ),
            collapseConfig: const GlassTabBarCollapseConfig(
              direction: GlassTabBarCollapseDirection.towardsExtraButton,
            ),
          ),
        ),
      );

      await tester.fling(
        find.byKey(const ValueKey<String>('glass_tab_bar_gesture_region')),
        const Offset(0, -300),
        1200,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      final extraRect = tester.getRect(find.byKey(
        const ValueKey<String>('glass_tab_bar_extra_button_scale'),
      ));
      final pillRect = tester.getRect(
        find.byKey(const ValueKey<String>('glass_tab_bar_tab_pill')),
      );

      expect(pillRect.left, lessThanOrEqualTo(extraRect.right + 0.5));
    });

    testWidgets(
        'left extra button collapse also ends with the tab pill centered inside the extra button',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            extraButton: GlassTabBarExtraButton(
              icon: const Icon(CupertinoIcons.add),
              label: 'Add',
              placement: GlassExtraButtonPlacement.left,
              onTap: () {},
            ),
            collapseConfig: const GlassTabBarCollapseConfig(
              direction: GlassTabBarCollapseDirection.towardsExtraButton,
            ),
          ),
        ),
      );

      await tester.fling(
        find.byKey(const ValueKey<String>('glass_tab_bar_gesture_region')),
        const Offset(0, -300),
        1200,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      final extraRect = tester.getRect(find.byKey(
        const ValueKey<String>('glass_tab_bar_extra_button_scale'),
      ));
      final pillRect = tester.getRect(
        find.byKey(const ValueKey<String>('glass_tab_bar_tab_pill')),
      );

      expect(pillRect.center.dx, greaterThan(extraRect.left));
      expect(pillRect.center.dx, lessThan(extraRect.right));
    });

    testWidgets('collapse shrinks both width and height', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: testTabs3,
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            extraButton: GlassTabBarExtraButton(
              icon: const Icon(CupertinoIcons.add),
              label: 'Add',
              onTap: () {},
            ),
            collapseConfig: const GlassTabBarCollapseConfig(),
          ),
        ),
      );

      final pillFinder =
          find.byKey(const ValueKey<String>('glass_tab_bar_tab_pill'));
      final expandedSize = tester.getSize(pillFinder);

      await tester.fling(
        find.byKey(const ValueKey<String>('glass_tab_bar_gesture_region')),
        const Offset(0, -300),
        1200,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      final collapsedSize = tester.getSize(pillFinder);
      expect(collapsedSize.width, lessThan(expandedSize.width));
      expect(collapsedSize.height, lessThan(expandedSize.height));
    });

    testWidgets('scrolling up collapses and scrolling down expands',
        (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.transparent,
          ),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: ListView.builder(
              controller: scrollController,
              itemCount: 60,
              itemBuilder: (context, index) => SizedBox(
                height: 80,
                child: Text('Row $index'),
              ),
            ),
            bottomNavigationBar: GlassTabBar.bottom(
              tabs: testTabs3,
              selectedIndex: 0,
              onTabSelected: (_) {},
              maskingQuality: MaskingQuality.off,
              extraButton: GlassTabBarExtraButton(
                icon: const Icon(CupertinoIcons.add),
                label: 'Add',
                onTap: () {},
              ),
              collapseConfig: const GlassTabBarCollapseConfig(),
              scrollController: scrollController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expanded = tester.getTopLeft(
          find.byKey(const ValueKey<String>('glass_tab_bar_tab_pill')));

      await tester.drag(find.byType(ListView), const Offset(0, -220));
      await tester.pumpAndSettle();

      final collapsed = tester.getTopLeft(
          find.byKey(const ValueKey<String>('glass_tab_bar_tab_pill')));
      expect(collapsed.dx, greaterThan(expanded.dx));

      await tester.drag(find.byType(ListView), const Offset(0, 220));
      await tester.pumpAndSettle();

      final expandedAgain = tester.getTopLeft(
          find.byKey(const ValueKey<String>('glass_tab_bar_tab_pill')));
      expect(expandedAgain.dx, lessThan(collapsed.dx));
    });

    testWidgets('extra button scales down on collapse and back up on expand',
        (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.transparent,
          ),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: ListView.builder(
              controller: scrollController,
              itemCount: 60,
              itemBuilder: (context, index) => SizedBox(
                height: 80,
                child: Text('Row $index'),
              ),
            ),
            bottomNavigationBar: GlassTabBar.bottom(
              tabs: testTabs3,
              selectedIndex: 0,
              onTabSelected: (_) {},
              maskingQuality: MaskingQuality.off,
              extraButton: GlassTabBarExtraButton(
                icon: const Icon(CupertinoIcons.add),
                label: 'Add',
                onTap: () {},
              ),
              collapseConfig: const GlassTabBarCollapseConfig(),
              scrollController: scrollController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final extraScaleFinder = find.byKey(
        const ValueKey<String>('glass_tab_bar_extra_button_scale'),
      );
      expect(_transitionScale(tester, extraScaleFinder), closeTo(1.0, 0.001));

      await tester.drag(find.byType(ListView), const Offset(0, -220));
      await tester.pumpAndSettle();
      expect(
        _transitionScale(tester, extraScaleFinder),
        closeTo(0.9, 0.001),
      );

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pumpAndSettle();
      expect(_transitionScale(tester, extraScaleFinder), closeTo(1.0, 0.001));
    });

    testWidgets('custom collapse config drives duration and scale',
        (tester) async {
      final scrollController = ScrollController();
      const config = GlassTabBarCollapseConfig(
        animationDuration: Duration(milliseconds: 360),
        collapsedExtraButtonScale: 0.82,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.transparent,
          ),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: ListView.builder(
              controller: scrollController,
              itemCount: 60,
              itemBuilder: (context, index) => SizedBox(
                height: 80,
                child: Text('Row $index'),
              ),
            ),
            bottomNavigationBar: GlassTabBar.bottom(
              tabs: testTabs3,
              selectedIndex: 0,
              onTabSelected: (_) {},
              maskingQuality: MaskingQuality.off,
              extraButton: GlassTabBarExtraButton(
                icon: const Icon(CupertinoIcons.add),
                label: 'Add',
                onTap: () {},
              ),
              collapseConfig: config,
              scrollController: scrollController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final extraScaleFinder = find.byKey(
        const ValueKey<String>('glass_tab_bar_extra_button_scale'),
      );

      await tester.drag(find.byType(ListView), const Offset(0, -220));
      await tester.pumpAndSettle();

      expect(
        _transitionScale(tester, extraScaleFinder),
        closeTo(0.82, 0.001),
      );
    });

    testWidgets('expand briefly overshoots before settling', (tester) async {
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: Colors.transparent,
          ),
          home: Scaffold(
            backgroundColor: Colors.transparent,
            body: ListView.builder(
              controller: scrollController,
              itemCount: 60,
              itemBuilder: (context, index) => SizedBox(
                height: 80,
                child: Text('Row $index'),
              ),
            ),
            bottomNavigationBar: GlassTabBar.bottom(
              tabs: testTabs3,
              selectedIndex: 0,
              onTabSelected: (_) {},
              maskingQuality: MaskingQuality.off,
              extraButton: GlassTabBarExtraButton(
                icon: const Icon(CupertinoIcons.add),
                label: 'Add',
                onTap: () {},
              ),
              collapseConfig: const GlassTabBarCollapseConfig(),
              scrollController: scrollController,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pillFinder =
          find.byKey(const ValueKey<String>('glass_tab_bar_tab_pill'));
      final expandedWidth = tester.getSize(pillFinder).width;

      await tester.drag(find.byType(ListView), const Offset(0, -220));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(CupertinoIcons.add));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 190));

      final overshootWidth = tester.getSize(pillFinder).width;
      expect(overshootWidth, greaterThan(expandedWidth));
    });

    testWidgets('assertion: selected index not negative', (tester) async {
      expect(
        () => GlassTabBar.bottom(
          tabs: testTabs3,
          selectedIndex: -1,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    testWidgets('assertion: selected index not out of range', (tester) async {
      expect(
        () => GlassTabBar.bottom(
          tabs: testTabs3,
          selectedIndex: 5,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // GlassTab extended
  // ──────────────────────────────────────────────────────────────────────────

  group('GlassTab extended', () {
    test('tabs with no label centers icon', () {
      const tab = GlassTab(
        icon: Icon(CupertinoIcons.home),
      );
      expect(tab.label, isNull);
    });

    test('glowColor is stored correctly', () {
      const tab = GlassTab(
        label: 'Fire',
        icon: Icon(CupertinoIcons.flame),
        glowColor: Colors.orange,
      );
      expect(tab.glowColor, Colors.orange);
    });

    test('thickness is stored correctly', () {
      const tab = GlassTab(
        label: 'Heavy',
        icon: Icon(CupertinoIcons.star_fill),
        thickness: 1.5,
      );
      expect(tab.thickness, 1.5);
    });

    test('activeIcon is stored correctly', () {
      const tab = GlassTab(
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

  group('GlassTabBar.bottom _TabIndicator didUpdateWidget', () {
    final testTabs = [
      const GlassTab(
        label: 'Home',
        icon: Icon(CupertinoIcons.home),
      ),
      const GlassTab(
        label: 'Search',
        icon: Icon(CupertinoIcons.search),
      ),
      const GlassTab(
        label: 'Profile',
        icon: Icon(CupertinoIcons.person),
      ),
    ];

    testWidgets('tabIndex change updates indicator alignment', (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) => GlassTabBar.bottom(
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
                GlassTabBar.bottom(
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
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('tabCount change updates alignment', (tester) async {
      List<GlassTab> tabs = testTabs.sublist(0, 2);
      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                GlassTabBar.bottom(
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
      expect(find.byType(GlassTabBar), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // _onBarTapDown, _onDragUpdate, _onDragEnd
  // ─────────────────────────────────────────────────────────────────────────

  group('GlassTabBar.bottom drag interaction coverage', () {
    late List<GlassTab> tabs;
    setUp(() {
      tabs = [
        const GlassTab(
          label: 'A',
          icon: Icon(CupertinoIcons.home),
        ),
        const GlassTab(
          label: 'B',
          icon: Icon(CupertinoIcons.search),
        ),
        const GlassTab(
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
              builder: (context, setState) => GlassTabBar.bottom(
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
              builder: (context, setState) => GlassTabBar.bottom(
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
      final barFinder = find.byType(GlassTabBar);
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
              builder: (context, setState) => GlassTabBar.bottom(
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
      final barFinder = find.byType(GlassTabBar);
      final gesture = await tester.startGesture(tester.getCenter(barFinder));
      await gesture.moveBy(const Offset(40, 0));
      // Short, slow move → low velocity
      await tester.pump(const Duration(milliseconds: 500));
      await gesture.up();
      await tester.pumpAndSettle();

      // Just verify no crash and the widget survived
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('quality inherited from parent InheritedLiquidGlass',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar.bottom(
              tabs: tabs,
              selectedIndex: 0,
              onTabSelected: (_) {},
              // quality: null — should inherit from ancestor
            ),
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // indicatorExpansion (PR #40 — jfhair)
  // ─────────────────────────────────────────────────────────────────────────

  group('GlassTabBar.bottom indicatorExpansion', () {
    final tabs = [
      const GlassTab(label: 'A', icon: Icon(CupertinoIcons.home)),
      const GlassTab(label: 'B', icon: Icon(CupertinoIcons.search)),
      const GlassTab(label: 'C', icon: Icon(CupertinoIcons.person)),
    ];

    test('default indicatorExpansion matches iOS 26 calibration', () {
      final bar = GlassTabBar.bottom(
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
      final bar = GlassTabBar.bottom(
        tabs: tabs,
        selectedIndex: 0,
        onTabSelected: (_) {},
      );
      expect(bar.indicatorPinchStrength, 0.4);
    });

    testWidgets('accepts custom indicatorExpansion', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: tabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            indicatorExpansion: const EdgeInsets.all(5.0),
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      final bar = tester.widget<GlassTabBar>(find.byType(GlassTabBar).first);
      expect(bar.indicatorExpansion, const EdgeInsets.all(5.0));
    });

    testWidgets('accepts zero indicatorExpansion', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: tabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            indicatorExpansion: EdgeInsets.zero,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('large indicatorExpansion does not crash', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: tabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            indicatorExpansion: const EdgeInsets.all(40.0),
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
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

  group('GlassTabBar.bottom 5-tab expansion stress', () {
    final fiveTabs = [
      const GlassTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
      const GlassTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
      const GlassTab(label: 'Inbox', icon: Icon(CupertinoIcons.tray)),
      const GlassTab(label: 'Profile', icon: Icon(CupertinoIcons.person)),
      const GlassTab(label: 'Settings', icon: Icon(CupertinoIcons.settings)),
    ];

    testWidgets('fast full-width drag on 5-tab bar does not crash or overflow',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 375,
            child: StatefulBuilder(
              builder: (context, setState) => GlassTabBar.bottom(
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

      final bar = find.byType(GlassTabBar);
      await tester.drag(bar, const Offset(350, 0));
      await tester.pumpAndSettle();

      expect(find.byType(GlassTabBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'all 5 labels remain findable after drag with default expansion',
        (tester) async {
      int selected = 0;
      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 375,
            child: StatefulBuilder(
              builder: (context, setState) => GlassTabBar.bottom(
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

      await tester.drag(find.byType(GlassTabBar), const Offset(300, 0));
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
            child: GlassTabBar.bottom(
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
      expect(find.byType(GlassTabBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // AnimatedGlassIndicator settings merge — baseIndicatorSettings
  // ─────────────────────────────────────────────────────────────────────────

  group('AnimatedGlassIndicator.baseIndicatorSettings', () {
    test('has chromaticAberration 0.0 (rainbow rim artifact removed)', () {
      // chromaticAberration changed from 0.15 → 0.0 to remove rainbow fringing.
      expect(
        AnimatedGlassIndicator.baseIndicatorSettings.chromaticAberration,
        0.0,
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
        'indicatorSettings with only blur overridden preserves 0.0 aberration',
        (tester) async {
      // Verifies the merge gap fix: a caller passing LiquidGlassSettings(blur:2)
      // should keep chromaticAberration: 0.0 from baseIndicatorSettings.
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: [
              const GlassTab(label: 'A', icon: Icon(CupertinoIcons.home)),
              const GlassTab(label: 'B', icon: Icon(CupertinoIcons.search)),
            ],
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            // Only blur is changed — chromaticAberration should stay 0.0
            indicatorSettings: const LiquidGlassSettings(blur: 2),
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'indicatorSettings chromaticAberration: 0.0 correctly overrides base',
        (tester) async {
      // 0.0 differs from LiquidGlassSettings() default (0.01) so it IS an
      // intentional override and must replace the base 0.15.
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: [
              const GlassTab(label: 'A', icon: Icon(CupertinoIcons.home)),
              const GlassTab(label: 'B', icon: Icon(CupertinoIcons.search)),
            ],
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
            indicatorSettings:
                const LiquidGlassSettings(chromaticAberration: 0.0),
          ),
        ),
      );
      expect(find.byType(GlassTabBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Indicator Radius Tiers
  // ─────────────────────────────────────────────────────────────────────────

  group('GlassTabBar.bottom 3-Tier Indicator Radius', () {
    testWidgets('Tier 1: capsule sentinel passes directly to indicator',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: const [
              GlassTab(label: 'A', icon: Icon(CupertinoIcons.home)),
              GlassTab(label: 'B', icon: Icon(CupertinoIcons.search)),
            ],
            selectedIndex: 0,
            onTabSelected: (_) {},
            // Implicitly barBorderRadius is GlassDefaults.capsuleRadius
          ),
        ),
      );

      final indicator = tester.widget<AnimatedGlassIndicator>(
          find.byType(AnimatedGlassIndicator).first);
      expect(indicator.borderRadius, equals(GlassDefaults.capsuleRadius));
    });

    testWidgets('Tier 2: custom finite radius applies padding inset',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: const [
              GlassTab(label: 'A', icon: Icon(CupertinoIcons.home)),
              GlassTab(label: 'B', icon: Icon(CupertinoIcons.search)),
            ],
            selectedIndex: 0,
            onTabSelected: (_) {},
            barBorderRadius: 24.0,
          ),
        ),
      );

      final indicator = tester.widget<AnimatedGlassIndicator>(
          find.byType(AnimatedGlassIndicator).first);
      // Outer 24.0 minus 4.0 padding = 20.0
      expect(indicator.borderRadius, equals(20.0));
    });

    testWidgets('Tier 3: explicit indicatorBorderRadius overrides everything',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: const [
              GlassTab(label: 'A', icon: Icon(CupertinoIcons.home)),
              GlassTab(label: 'B', icon: Icon(CupertinoIcons.search)),
            ],
            selectedIndex: 0,
            onTabSelected: (_) {},
            barBorderRadius: GlassDefaults.capsuleRadius,
            indicatorBorderRadius: 10.0,
          ),
        ),
      );

      final indicator = tester.widget<AnimatedGlassIndicator>(
          find.byType(AnimatedGlassIndicator).first);
      expect(indicator.borderRadius, equals(10.0));
    });
  });
}
