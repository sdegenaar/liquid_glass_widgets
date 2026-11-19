import 'package:flutter/cupertino.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

/// A tab has to be activatable by assistive technology, not only by a finger.
///
/// [GlassTabBar.bottom] and [GlassTabBar.searchable] own selection on the
/// indicator's own `onTapDown`, so every tab is built with a null `onTap` and
/// its [GestureDetector] is excluded from semantics. Without an explicit tap
/// action the tab's node is a button with a selected state that TalkBack and
/// VoiceOver can read and cannot activate, and that a focused tab does not
/// answer Enter or Space on either (WCAG 2.1.1).
void main() {
  const tabs = [
    GlassTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
    GlassTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
    GlassTab(label: 'Profile', icon: Icon(CupertinoIcons.person)),
  ];

  Widget bottomBar({
    required ValueChanged<int> onTabSelected,
    TextDirection textDirection = TextDirection.ltr,
    int selectedIndex = 0,
  }) {
    return createTestApp(
      child: Directionality(
        textDirection: textDirection,
        child: GlassTabBar.bottom(
          tabs: tabs,
          selectedIndex: selectedIndex,
          onTabSelected: onTabSelected,
          maskingQuality: MaskingQuality.off,
        ),
      ),
    );
  }

  group('GlassTabBar.bottom semantics actions', () {
    testWidgets('every tab exposes a tap action', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(bottomBar(onTabSelected: (_) {}));

      for (final label in ['Home', 'Search', 'Profile']) {
        final node = tester.getSemantics(find.bySemanticsLabel(label));
        expect(
          node.getSemanticsData().hasAction(SemanticsAction.tap),
          isTrue,
          reason: '\$label can be read but not activated',
        );
      }

      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('performing the tap action selects that tab', (tester) async {
      final handle = tester.ensureSemantics();
      var selected = -1;
      await tester.pumpWidget(bottomBar(onTabSelected: (i) => selected = i));

      tester.semantics.performAction(
        find.semantics.byLabel('Search'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(selected, 1);

      tester.semantics.performAction(
        find.semantics.byLabel('Profile'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(selected, 2);

      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('under RTL the tap action reports the logical index', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var selected = -1;
      await tester.pumpWidget(
        bottomBar(
          onTabSelected: (i) => selected = i,
          textDirection: TextDirection.rtl,
        ),
      );

      // 'Home' renders on the trailing (right) edge under RTL and is still
      // logical index 0 — the bar reverses its tab data and mirrors the
      // callback, and the semantics action rides that same wrapper.
      tester.semantics.performAction(
        find.semantics.byLabel('Home'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(selected, 0);

      tester.semantics.performAction(
        find.semantics.byLabel('Profile'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(selected, 2);

      await tester.pumpAndSettle();
      handle.dispose();
    });
  });

  group('GlassTabBar.searchable semantics actions', () {
    testWidgets('performing the tap action selects that tab', (tester) async {
      final handle = tester.ensureSemantics();
      var selected = -1;
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.searchable(
            tabs: tabs,
            selectedIndex: 0,
            onTabSelected: (i) => selected = i,
            maskingQuality: MaskingQuality.off,
            searchConfig: GlassSearchBarConfig(onSearchToggle: (_) {}),
          ),
        ),
      );
      await tester.pump();

      // The collapsed search pill is a 'Search' button as well (named by the
      // config's hint text), so pick the tab: the node with a selected state.
      tester.semantics.performAction(
        find.semantics.byPredicate(
          (node) =>
              node.label == 'Search' &&
              // ignore: deprecated_member_use
              node.hasFlag(SemanticsFlag.hasSelectedState),
        ),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(selected, 1);

      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets('under RTL the tap action reports the logical index', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var selected = -1;
      await tester.pumpWidget(
        createTestApp(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: GlassTabBar.searchable(
              tabs: tabs,
              selectedIndex: 1,
              onTabSelected: (i) => selected = i,
              maskingQuality: MaskingQuality.off,
              searchConfig: GlassSearchBarConfig(onSearchToggle: (_) {}),
            ),
          ),
        ),
      );
      await tester.pump();

      tester.semantics.performAction(
        find.semantics.byLabel('Home'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(selected, 0);

      tester.semantics.performAction(
        find.semantics.byLabel('Profile'),
        SemanticsAction.tap,
      );
      await tester.pump();
      expect(selected, 2);

      await tester.pumpAndSettle();
      handle.dispose();
    });
  });

  group('GlassTabBarExtraButton selection & keyboard focus traversal', () {
    testWidgets(
        'extraButton.selected announces extra button as selected and clears pill selection',
        (tester) async {
      final handle = tester.ensureSemantics();

      bool? extraSelected;
      late StateSetter updateBar;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setBarState) {
              updateBar = setBarState;
              return GlassTabBar.bottom(
                tabs: const [
                  GlassTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
                  GlassTab(label: 'Profile', icon: Icon(CupertinoIcons.person)),
                ],
                selectedIndex: 0,
                selectedIconColor: CupertinoColors.activeBlue,
                unselectedIconColor: CupertinoColors.systemGrey,
                onTabSelected: (_) {},
                extraButton: GlassTabBarExtraButton(
                  icon: const Icon(CupertinoIcons.search),
                  label: 'Discover',
                  selected: extraSelected,
                  onTap: () {},
                ),
              );
            },
          ),
        ),
      );

      SemanticsData dataFor(String label) =>
          tester.getSemantics(find.bySemanticsLabel(label)).getSemanticsData();

      // 1. Default (selected: null) -> extra button is a plain action button (no selected state), Home is selected.
      // ignore: deprecated_member_use
      expect(
          dataFor('Discover').hasFlag(SemanticsFlag.hasSelectedState), isFalse);
      // ignore: deprecated_member_use
      expect(dataFor('Home').hasFlag(SemanticsFlag.isSelected), isTrue);

      // 2. selected: false -> extra button participates in selection as unselected; Home stays selected.
      updateBar(() => extraSelected = false);
      await tester.pump();
      // ignore: deprecated_member_use
      expect(
          dataFor('Discover').hasFlag(SemanticsFlag.hasSelectedState), isTrue);
      // ignore: deprecated_member_use
      expect(dataFor('Discover').hasFlag(SemanticsFlag.isSelected), isFalse);
      // ignore: deprecated_member_use
      expect(dataFor('Home').hasFlag(SemanticsFlag.isSelected), isTrue);

      // 3. selected: true -> extra button is selected with selectedIconColor; ALL pill tabs report unselected!
      updateBar(() => extraSelected = true);
      await tester.pumpAndSettle();
      // ignore: deprecated_member_use
      expect(dataFor('Discover').hasFlag(SemanticsFlag.isSelected), isTrue);
      // ignore: deprecated_member_use
      expect(dataFor('Home').hasFlag(SemanticsFlag.isSelected), isFalse);
      // ignore: deprecated_member_use
      expect(dataFor('Profile').hasFlag(SemanticsFlag.isSelected), isFalse);

      final extraBtn = tester.widget<GlassButton>(find.byType(GlassButton));
      expect(extraBtn.iconColor, CupertinoColors.activeBlue);

      await tester.pumpAndSettle();
      handle.dispose();
    });

    testWidgets(
        'Tab key visits each tab once (no duplicate lens stops) in MaskingQuality.high and searchable',
        (tester) async {
      var activated = <int>[];
      await tester.pumpWidget(
        createTestApp(
          child: GlassTabBar.bottom(
            tabs: tabs,
            selectedIndex: 1,
            onTabSelected: activated.add,
            maskingQuality: MaskingQuality.high,
          ),
        ),
      );
      await tester.pump();

      // Three Tab presses must visit Home (0), Search (1), Profile (2) in order,
      // and a 4th Tab press wraps back to Home (0) — proving zero duplicate lens stops!
      for (final expected in [0, 1, 2, 0]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(activated.last, expected);
      }
    });

    testWidgets(
        'under RTL, Tab key starts at first logical tab (rightmost) and traverses right-to-left',
        (tester) async {
      final activated = <int>[];
      await tester.pumpWidget(
        createTestApp(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: GlassTabBar.bottom(
              tabs: tabs,
              selectedIndex: 0,
              onTabSelected: activated.add,
              maskingQuality: MaskingQuality.high,
            ),
          ),
        ),
      );
      await tester.pump();

      for (final expected in [0, 1, 2]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(activated.last, expected);
      }
    });

    testWidgets(
        'activating previously selected tab from extraButton.selected == true via keyboard or tap fires onTabSelected and retains keyboard focus',
        (tester) async {
      var selectedIndex = 0;
      var extraSelected = true;
      final selectedEvents = <int>[];
      late StateSetter updateBar;

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setBarState) {
              updateBar = setBarState;
              return GlassTabBar.bottom(
                tabs: tabs,
                selectedIndex: selectedIndex,
                maskingQuality: MaskingQuality.high,
                onTabSelected: (index) {
                  selectedEvents.add(index);
                  updateBar(() {
                    selectedIndex = index;
                    extraSelected = false;
                  });
                },
                extraButton: GlassTabBarExtraButton(
                  icon: const Icon(CupertinoIcons.compass),
                  label: 'Explore',
                  selected: extraSelected,
                  onTap: () => updateBar(() => extraSelected = true),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // At rest with extraSelected == true, no AnimatedGlassIndicator is painted.
      expect(find.byType(AnimatedGlassIndicator), findsNothing);

      // 1. Tab to Home (index 0 — ALREADY the bar's selectedIndex!) and press Enter:
      //    must fire onTabSelected(0), restore the pill indicator, AND preserve primaryFocus!
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final focusedBeforeEnter = FocusManager.instance.primaryFocus;
      expect(focusedBeforeEnter, isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(selectedEvents, [0]);
      expect(extraSelected, isFalse);
      expect(find.byType(AnimatedGlassIndicator), findsWidgets);
      expect(
        identical(FocusManager.instance.primaryFocus, focusedBeforeEnter),
        isTrue,
        reason:
            'FocusNode must not be torn down when indicator transitions from hidden to visible',
      );

      // 2. Switch back to Explore extraButton, then pointer-tap Home (index 0):
      //    must also fire onTabSelected(0) and re-select Home!
      updateBar(() => extraSelected = true);
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedGlassIndicator), findsNothing);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(selectedEvents, [0, 0]);
      expect(extraSelected, isFalse);
      expect(find.byType(AnimatedGlassIndicator), findsWidgets);
    });

    testWidgets(
        'GlassTabBar.searchable supports extraButton.selected, single-stop Tab focus, and RTL Tab reading order',
        (tester) async {
      final handle = tester.ensureSemantics();
      final activated = <int>[];
      var extraTaps = 0;

      await tester.pumpWidget(
        createTestApp(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: GlassTabBar.searchable(
              tabs: tabs,
              selectedIndex: 0,
              onTabSelected: activated.add,
              maskingQuality: MaskingQuality.high,
              searchConfig: GlassSearchBarConfig(
                showPill: false,
                onSearchToggle: (_) {},
              ),
              extraButton: GlassTabBarExtraButton(
                icon: const Icon(CupertinoIcons.sparkles),
                label: 'AI',
                position: GlassExtraButtonPosition.afterSearch,
                selected: true,
                onTap: () => extraTaps++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      SemanticsData dataFor(String label) =>
          tester.getSemantics(find.bySemanticsLabel(label)).getSemanticsData();

      // ignore: deprecated_member_use
      expect(dataFor('AI').hasFlag(SemanticsFlag.isSelected), isTrue);
      // ignore: deprecated_member_use
      expect(dataFor('Home').hasFlag(SemanticsFlag.isSelected), isFalse);
      expect(find.byType(AnimatedGlassIndicator), findsNothing);

      // Under RTL, ReadingOrderTraversalPolicy traverses right-to-left:
      // first the rightmost AI extra button, then Home (0), Search (1), Profile (2)
      // with zero duplicate lens stops.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(extraTaps, 1);

      for (final expected in [0, 1, 2]) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(activated.last, expected);
      }

      await tester.pumpAndSettle();
      handle.dispose();
    });
  });
}
