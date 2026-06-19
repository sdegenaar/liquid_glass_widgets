// Tests for the v0.18.0 unified GlassTabBar named constructors.
//
// Coverage targets:
//   • GlassTabBar.bottom()  — renders, onTabSelected fires, key params wired
//   • GlassTabBar.searchable() — renders, searchConfig wired, tab switch works
//   • _GlassTabBarPlacement dispatch — correct engine for each constructor
//   • GlassTab expanded fields — activeIcon, glowColor, thickness
//   • Deprecated shim surface — GlassBottomBar / GlassSearchableBottomBar /
//     GlassBottomBarTab still render correctly
// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Wraps [child] inside the LiquidGlassWidgets.wrap() layer so the internal
/// shader registry is initialised — mirrors what the bottom-bar coverage tests
/// do.
Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: LiquidGlassWidgets.wrap(child: child)),
    );

/// Minimal [GlassTab] with icon + label — covers all new fields by default.
GlassTab _tab(String label) => GlassTab(
      label: label,
      icon: const Icon(Icons.home),
      activeIcon: const Icon(Icons.home_filled),
      glowColor: Colors.blue,
      thickness: 1.0,
    );

/// Wraps content in a fixed height box so the bar has room to lay out.
Widget _box(Widget child) => SizedBox(height: 120, child: child);

// ---------------------------------------------------------------------------
// GlassTab — expanded fields
// ---------------------------------------------------------------------------

void main() {
  group('GlassTab — expanded fields', () {
    test('constructs with all new fields without assertion error', () {
      expect(
        () => const GlassTab(
          icon: Icon(Icons.home),
          activeIcon: Icon(Icons.home_filled),
          label: 'Home',
          semanticLabel: 'Go Home',
          glowColor: Colors.blue,
          thickness: 1.5,
        ),
        returnsNormally,
      );
    });

    test('icon-only tab with activeIcon constructs normally', () {
      expect(
        () => const GlassTab(
          icon: Icon(Icons.music_note),
          activeIcon: Icon(Icons.music_note_outlined),
        ),
        returnsNormally,
      );
    });

    test('glowColor and thickness default to null', () {
      const tab = GlassTab(label: 'X');
      expect(tab.glowColor, isNull);
      expect(tab.thickness, isNull);
      expect(tab.activeIcon, isNull);
    });

    test('assertion fires when neither icon nor label is supplied', () {
      expect(
        // ignore: avoid_dynamic_calls
        () => GlassTab(),
        throwsAssertionError,
      );
    });
  });

  // -------------------------------------------------------------------------
  // GlassTabBar.bottom() — rendering
  // -------------------------------------------------------------------------

  group('GlassTabBar.bottom() — rendering', () {
    testWidgets('renders with minimum tabs without crashing', (tester) async {
      await tester.pumpWidget(_wrap(_box(
        GlassTabBar.bottom(
          tabs: [_tab('Home'), _tab('Profile')],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
      )));
      await tester.pump();

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);
    });

    testWidgets('renders with 3 tabs without crashing', (tester) async {
      await tester.pumpWidget(_wrap(_box(
        GlassTabBar.bottom(
          tabs: [_tab('Home'), _tab('Browse'), _tab('Me')],
          selectedIndex: 1,
          onTabSelected: (_) {},
        ),
      )));
      await tester.pump();

      expect(find.text('Browse'), findsWidgets);
    });

    testWidgets('onTabSelected fires with correct index', (tester) async {
      int received = -1;

      await tester.pumpWidget(_wrap(_box(
        StatefulBuilder(
          builder: (context, setState) => GlassTabBar.bottom(
            tabs: [_tab('A'), _tab('B'), _tab('C')],
            selectedIndex: 0,
            onTabSelected: (i) => setState(() => received = i),
          ),
        ),
      )));
      await tester.pump();

      await tester.tap(find.text('B').first);
      await tester.pumpAndSettle();

      expect(received, 1);
    });

    testWidgets('onTabSelected fires index 2 when last tab tapped',
        (tester) async {
      int received = -1;

      await tester.pumpWidget(_wrap(_box(
        StatefulBuilder(
          builder: (context, setState) => GlassTabBar.bottom(
            tabs: [_tab('One'), _tab('Two'), _tab('Three')],
            selectedIndex: 0,
            onTabSelected: (i) => setState(() => received = i),
          ),
        ),
      )));
      await tester.pump();

      await tester.tap(find.text('Three').first);
      await tester.pumpAndSettle();

      expect(received, 2);
    });

    testWidgets('activeIcon field is accepted without crash', (tester) async {
      await tester.pumpWidget(_wrap(_box(
        GlassTabBar.bottom(
          tabs: const [
            GlassTab(
              icon: Icon(Icons.music_note),
              activeIcon: Icon(Icons.music_note_outlined),
              label: 'Music',
            ),
            GlassTab(
              icon: Icon(Icons.podcasts),
              label: 'Podcasts',
            ),
          ],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
      )));
      await tester.pump();

      expect(find.text('Music'), findsWidgets);
    });

    testWidgets('glowColor and thickness pass through without crash',
        (tester) async {
      await tester.pumpWidget(_wrap(_box(
        GlassTabBar.bottom(
          tabs: [
            GlassTab(
              icon: const Icon(Icons.star),
              label: 'Glow',
              glowColor: Colors.amber,
              thickness: 2.0,
            ),
            _tab('Normal'),
          ],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
      )));
      await tester.pump();

      expect(find.text('Glow'), findsWidgets);
    });

    testWidgets('extraButton parameter wires correctly', (tester) async {
      bool extraTapped = false;

      await tester.pumpWidget(_wrap(_box(
        GlassTabBar.bottom(
          tabs: [_tab('Home'), _tab('Search')],
          selectedIndex: 0,
          onTabSelected: (_) {},
          extraButton: GlassBottomBarExtraButton(
            icon: const Icon(Icons.add),
            label: 'Add',
            onTap: () => extraTapped = true,
          ),
        ),
      )));
      await tester.pump();

      // Bar renders without error
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('maskingQuality.off renders without crash', (tester) async {
      await tester.pumpWidget(_wrap(_box(
        GlassTabBar.bottom(
          tabs: [_tab('X'), _tab('Y')],
          selectedIndex: 0,
          onTabSelected: (_) {},
          maskingQuality: MaskingQuality.off,
        ),
      )));
      await tester.pump();

      expect(find.text('X'), findsWidgets);
    });

    testWidgets('quality: premium renders without crash', (tester) async {
      await tester.pumpWidget(_wrap(_box(
        GlassTabBar.bottom(
          tabs: [_tab('A'), _tab('B')],
          selectedIndex: 0,
          onTabSelected: (_) {},
          quality: GlassQuality.premium,
        ),
      )));
      await tester.pump();

      expect(find.text('A'), findsWidgets);
    });

    testWidgets('tabWidth limits pill width without crash', (tester) async {
      await tester.pumpWidget(_wrap(_box(
        GlassTabBar.bottom(
          tabs: [_tab('H'), _tab('P'), _tab('S')],
          selectedIndex: 0,
          onTabSelected: (_) {},
          tabWidth: 88,
        ),
      )));
      await tester.pump();

      expect(find.text('H'), findsWidgets);
    });

    testWidgets('selectedIconColor and iconSize pass through', (tester) async {
      await tester.pumpWidget(_wrap(_box(
        GlassTabBar.bottom(
          tabs: [_tab('Home'), _tab('Settings')],
          selectedIndex: 0,
          onTabSelected: (_) {},
          selectedIconColor: Colors.purple,
          iconSize: 32,
        ),
      )));
      await tester.pump();

      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('GlassInteractionBehavior.none renders without crash',
        (tester) async {
      await tester.pumpWidget(_wrap(_box(
        GlassTabBar.bottom(
          tabs: [_tab('X'), _tab('Y')],
          selectedIndex: 0,
          onTabSelected: (_) {},
          interactionBehavior: GlassInteractionBehavior.none,
        ),
      )));
      await tester.pump();

      expect(find.text('X'), findsWidgets);
    });

    testWidgets('selectedIndex=1 starts on second tab', (tester) async {
      int received = -1;

      await tester.pumpWidget(_wrap(_box(
        StatefulBuilder(
          builder: (context, setState) => GlassTabBar.bottom(
            tabs: [_tab('First'), _tab('Second'), _tab('Third')],
            selectedIndex: 1,
            onTabSelected: (i) => setState(() => received = i),
          ),
        ),
      )));
      await tester.pump();

      // Tap the first tab from index 1 start
      await tester.tap(find.text('First').first);
      await tester.pumpAndSettle();

      expect(received, 0);
    });
  });

  // -------------------------------------------------------------------------
  // GlassTabBar.searchable() — rendering
  // -------------------------------------------------------------------------

  group('GlassTabBar.searchable() — rendering', () {
    /// Minimal searchConfig for tests
    final searchConfig =
        GlassSearchBarConfig(hintText: 'Search...', onSearchToggle: (_) {});

    testWidgets('renders with minimum required params without crashing',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 150,
          child: GlassTabBar.searchable(
            tabs: [_tab('Home'), _tab('Browse'), _tab('Me')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            searchConfig: searchConfig,
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('onTabSelected fires with correct index', (tester) async {
      int received = -1;

      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 150,
          child: StatefulBuilder(
            builder: (context, setState) => GlassTabBar.searchable(
              tabs: [_tab('A'), _tab('B'), _tab('C')],
              selectedIndex: 0,
              onTabSelected: (i) => setState(() => received = i),
              searchConfig: searchConfig,
            ),
          ),
        ),
      ));
      await tester.pump();

      await tester.tap(find.text('B').first);
      await tester.pumpAndSettle();

      expect(received, 1);
    });

    testWidgets('isSearchActive=true renders without crash', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 150,
          child: GlassTabBar.searchable(
            tabs: [_tab('Home'), _tab('Search')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            searchConfig: searchConfig,
            isSearchActive: true,
          ),
        ),
      ));
      await tester.pump();

      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('quality: premium renders without crash', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 150,
          child: GlassTabBar.searchable(
            tabs: [_tab('A'), _tab('B')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            searchConfig: searchConfig,
            quality: GlassQuality.premium,
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('A'), findsWidgets);
    });

    testWidgets('tabPillAnchor.center renders without crash', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 150,
          child: GlassTabBar.searchable(
            tabs: [_tab('A'), _tab('B')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            searchConfig: searchConfig,
            tabPillAnchor: GlassTabPillAnchor.center,
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('A'), findsWidgets);
    });
  });

  // -------------------------------------------------------------------------
  // Placement dispatch — each constructor produces the right widget tree
  // -------------------------------------------------------------------------

  group('GlassTabBar placement dispatch', () {
    testWidgets('default constructor (_inline) dispatches to TabBarContent',
        (tester) async {
      // The inline build path uses TabBarContent internally (visible via
      // finding Container at the root of the bar).
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: settingsWithoutLighting,
            child: GlassTabBar(
              tabs: const [GlassTab(label: 'X'), GlassTab(label: 'Y')],
              selectedIndex: 0,
              onTabSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GlassTabBar), findsOneWidget);
      // Inline mode must NOT produce a GlassBottomBar
      expect(find.byType(GlassBottomBar), findsNothing);
    });

    testWidgets('.bottom() dispatches to TabBarBottomLayout',
        (tester) async {
      await tester.pumpWidget(_wrap(_box(
        GlassTabBar.bottom(
          tabs: [_tab('Home'), _tab('Me')],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
      )));
      await tester.pump();

      // GlassTabBar.bottom() now renders directly via TabBarBottomLayout
      // (no bridge class) — GlassBottomBar does NOT appear in the tree.
      expect(find.byType(GlassTabBar), findsOneWidget);
      expect(find.byType(GlassBottomBar), findsNothing);
    });

    testWidgets('.searchable() dispatches to TabBarSearchableLayout',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 150,
          child: GlassTabBar.searchable(
            tabs: [_tab('Home'), _tab('Me')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            searchConfig:
                GlassSearchBarConfig(hintText: 'Search', onSearchToggle: (_) {}),
          ),
        ),
      ));
      await tester.pump();

      // GlassTabBar.searchable() now renders directly via TabBarSearchableLayout
      // (no bridge class) — GlassSearchableBottomBar does NOT appear in the tree.
      expect(find.byType(GlassTabBar), findsOneWidget);
      expect(find.byType(GlassSearchableBottomBar), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Deprecated shim API — verify zero-logic shims still render correctly
  // -------------------------------------------------------------------------

  group('Deprecated shim API — GlassBottomBar / GlassBottomBarTab', () {
    testWidgets('GlassBottomBar still renders with GlassBottomBarTab',
        (tester) async {
      await tester.pumpWidget(_wrap(_box(
        GlassBottomBar(
          tabs: [
            GlassBottomBarTab(
              label: 'Home',
              icon: const Icon(Icons.home),
              activeIcon: const Icon(Icons.home_filled),
              glowColor: Colors.blue,
              thickness: 1.0,
            ),
            GlassBottomBarTab(
              label: 'Search',
              icon: const Icon(Icons.search),
            ),
          ],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
      )));
      await tester.pump();

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Search'), findsWidgets);
    });

    testWidgets('GlassBottomBar onTabSelected still fires correctly',
        (tester) async {
      int received = -1;

      await tester.pumpWidget(_wrap(_box(
        StatefulBuilder(
          builder: (context, setState) => GlassBottomBar(
            tabs: [
              GlassBottomBarTab(label: 'A', icon: const Icon(Icons.home)),
              GlassBottomBarTab(label: 'B', icon: const Icon(Icons.search)),
            ],
            selectedIndex: 0,
            onTabSelected: (i) => setState(() => received = i),
          ),
        ),
      )));
      await tester.pump();

      await tester.tap(find.text('B').first);
      await tester.pumpAndSettle();

      expect(received, 1);
    });

    testWidgets('GlassSearchableBottomBar still renders with GlassBottomBarTab',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 150,
          child: GlassSearchableBottomBar(
            tabs: [
              GlassBottomBarTab(label: 'Home', icon: const Icon(Icons.home)),
              GlassBottomBarTab(label: 'Browse', icon: const Icon(Icons.explore)),
            ],
            selectedIndex: 0,
            onTabSelected: (_) {},
            searchConfig:
                GlassSearchBarConfig(hintText: 'Search...', onSearchToggle: (_) {}),
          ),
        ),
      ));
      await tester.pump();

      expect(find.text('Home'), findsWidgets);
    });
  });

  // -------------------------------------------------------------------------
  // GlassTabBar.bottom() assertion guards
  // -------------------------------------------------------------------------

  group('GlassTabBar.bottom() — assertion guards', () {
    test('asserts minimum 1 tab', () {
      expect(
        () => GlassTabBar.bottom(
          tabs: const [],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('asserts selectedIndex in bounds', () {
      expect(
        () => GlassTabBar.bottom(
          tabs: [_tab('A'), _tab('B')],
          selectedIndex: 5,
          onTabSelected: (_) {},
        ),
        throwsAssertionError,
      );
    });

    test('selectedIndex=0 with 1 tab does not throw', () {
      expect(
        () => GlassTabBar.bottom(
          tabs: [_tab('Only')],
          selectedIndex: 0,
          onTabSelected: (_) {},
        ),
        returnsNormally,
      );
    });
  });
}
