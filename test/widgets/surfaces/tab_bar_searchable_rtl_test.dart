import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/widgets/surfaces/tab_bar_bottom_internal.dart';
import 'package:liquid_glass_widgets/src/widgets/surfaces/tab_bar_searchable_internal.dart';

import '../../shared/test_helpers.dart';

void main() {
  const tabs = [
    GlassTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
    GlassTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
    GlassTab(label: 'Profile', icon: Icon(CupertinoIcons.person)),
  ];

  Widget rtlBar({
    required ValueChanged<int> onTabSelected,
    int selectedIndex = 0,
  }) {
    return createTestApp(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: GlassTabBar.searchable(
          tabs: tabs,
          selectedIndex: selectedIndex,
          onTabSelected: onTabSelected,
          searchConfig: GlassSearchBarConfig(onSearchToggle: (_) {}),
          maskingQuality: MaskingQuality.off,
        ),
      ),
    );
  }

  group('GlassTabBar.searchable RTL', () {
    testWidgets('first tab renders on the trailing (right) edge',
        (tester) async {
      await tester.pumpWidget(rtlBar(onTabSelected: (_) {}));

      final screenWidth = tester.getSize(find.byType(GlassTabBar)).width;
      final homeCenter =
          tester.getCenter(find.text('Home').hitTestable().first);
      final profileCenter =
          tester.getCenter(find.text('Profile').hitTestable().first);

      // RTL ordering: the first tab sits to the right of the last tab.
      expect(homeCenter.dx, greaterThan(profileCenter.dx));
      expect(homeCenter.dx, greaterThan(screenWidth / 2));
    });

    testWidgets('tapping a tab reports its logical index', (tester) async {
      var selected = -1;
      await tester.pumpWidget(rtlBar(onTabSelected: (i) => selected = i));

      // 'Home' is logical index 0; under RTL it renders on the trailing (right) edge.
      await tester.tap(find.text('Home').hitTestable().first);
      await tester.pumpAndSettle();
      expect(selected, 0);

      // 'Profile' is logical index 2; under RTL it renders on the leading (left) edge.
      await tester.tap(find.text('Profile').hitTestable().first);
      await tester.pumpAndSettle();
      expect(selected, 2);
    });

    testWidgets('a drag reports the tab under the finger, not its mirror', (
      tester,
    ) async {
      var selected = -1;
      await tester.pumpWidget(
          rtlBar(onTabSelected: (i) => selected = i, selectedIndex: 1));

      // Visual order under RTL is Profile | Search | Home, left to right.
      final home = tester.getCenter(find.text('Home').hitTestable().first);
      final search = tester.getCenter(find.text('Search').hitTestable().first);
      expect(home.dx, greaterThan(search.dx));

      await dragAcross(tester, from: search, to: home);

      expect(selected, 0);
    });

    testWidgets('LTR dragging is unchanged', (tester) async {
      var selected = -1;
      await tester.pumpWidget(
        createTestApp(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: GlassTabBar.searchable(
              tabs: tabs,
              selectedIndex: 1,
              onTabSelected: (i) => selected = i,
              searchConfig: GlassSearchBarConfig(onSearchToggle: (_) {}),
              maskingQuality: MaskingQuality.off,
            ),
          ),
        ),
      );

      final profile =
          tester.getCenter(find.text('Profile').hitTestable().first);
      final search = tester.getCenter(find.text('Search').hitTestable().first);
      expect(profile.dx, greaterThan(search.dx));

      await dragAcross(tester, from: search, to: profile);

      expect(selected, 2);
    });
  });

  // The pills' placement mirrors under RTL, as a native tab bar's does: the
  // tab pill sits on the leading (right) edge and the trailing capsule on the
  // left. Each case lays the bar out in both directions and checks every
  // surface lands at the mirror image of its LTR position.
  group('GlassTabBar.minimizable RTL placement', () {
    const accessoryKey = ValueKey('accessory');

    Widget minimizable(
      TextDirection direction, {
      bool minimized = false,
      bool trailing = true,
      double? tabWidth,
      bool accessory = false,
    }) {
      return createTestApp(
        child: Directionality(
          textDirection: direction,
          child: GlassTabBar.minimizable(
            tabs: tabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            minimized: minimized,
            onMinimizedTabTap: () {},
            trailingButton: trailing
                ? GlassTabBarTrailingButton(
                    icon: const Icon(CupertinoIcons.square_pencil),
                    onTap: () {},
                  )
                : null,
            tabWidth: tabWidth,
            bottomAccessory:
                accessory ? const SizedBox.expand(key: accessoryKey) : null,
            bottomAccessoryHeight: accessory ? 48 : null,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
    }

    Future<Map<String, Rect>> rects(
      WidgetTester tester,
      Widget bar, {
      bool trailing = true,
      bool accessory = false,
    }) async {
      await tester.pumpWidget(bar);
      await tester.pumpAndSettle();
      return {
        'bar': tester.getRect(find.byType(GlassTabBar)),
        'tabs': tester.getRect(find.byType(SearchableTabIndicator)),
        if (trailing)
          'trailing': tester.getRect(find.byType(MinimizableTrailingPill)),
        if (accessory) 'accessory': tester.getRect(find.byKey(accessoryKey)),
      };
    }

    Future<void> expectMirrored(
      WidgetTester tester,
      Widget Function(TextDirection direction) build, {
      bool trailing = true,
      bool accessory = false,
    }) async {
      final ltr = await rects(tester, build(TextDirection.ltr),
          trailing: trailing, accessory: accessory);
      final rtl = await rects(tester, build(TextDirection.rtl),
          trailing: trailing, accessory: accessory);
      final bar = ltr['bar']!;
      expect(rtl['bar'], bar);
      for (final key in ltr.keys.where((k) => k != 'bar')) {
        final l = ltr[key]!;
        final r = rtl[key]!;
        expect(r.left - bar.left, moreOrLessEquals(bar.right - l.right),
            reason: '$key left');
        expect(r.width, moreOrLessEquals(l.width), reason: '$key width');
        expect(r.top, moreOrLessEquals(l.top), reason: '$key top');
        expect(r.height, moreOrLessEquals(l.height), reason: '$key height');
      }
    }

    testWidgets('LTR keeps the tab pill on the left, the trailing pill right',
        (tester) async {
      final r = await rects(tester, minimizable(TextDirection.ltr));
      expect(r['tabs']!.right, lessThan(r['trailing']!.left));
      expect(r['trailing']!.center.dx, greaterThan(r['bar']!.center.dx));
    });

    testWidgets('RTL puts the trailing pill on the left edge', (tester) async {
      final r = await rects(tester, minimizable(TextDirection.rtl));
      expect(r['trailing']!.right, lessThan(r['tabs']!.left));
      expect(r['trailing']!.center.dx, lessThan(r['bar']!.center.dx));
    });

    testWidgets('expanded bar mirrors', (tester) async {
      await expectMirrored(tester, (d) => minimizable(d));
    });

    testWidgets('a content-sized tab pill hugs the leading edge',
        (tester) async {
      await expectMirrored(tester, (d) => minimizable(d, tabWidth: 90));
      final r =
          await rects(tester, minimizable(TextDirection.rtl, tabWidth: 90));
      expect(r['tabs']!.width, moreOrLessEquals(270));
      expect(r['tabs']!.right, moreOrLessEquals(r['bar']!.right - 20));
    });

    testWidgets('minimized circles mirror', (tester) async {
      await expectMirrored(tester, (d) => minimizable(d, minimized: true));
    });

    testWidgets('the inline accessory reserves the mirrored slots',
        (tester) async {
      await expectMirrored(
        tester,
        (d) => minimizable(d, minimized: true, accessory: true),
        accessory: true,
      );
      // No trailing pill: only the collapsed tab's slot is reserved.
      await expectMirrored(
        tester,
        (d) =>
            minimizable(d, minimized: true, accessory: true, trailing: false),
        trailing: false,
        accessory: true,
      );
    });

    testWidgets('the expanded accessory mirrors', (tester) async {
      await expectMirrored(
        tester,
        (d) => minimizable(d, accessory: true),
        accessory: true,
      );
    });
  });

  group('GlassTabBar.searchable RTL placement', () {
    Widget searchable(TextDirection direction, {bool extra = false}) {
      return createTestApp(
        child: Directionality(
          textDirection: direction,
          child: GlassTabBar.searchable(
            tabs: tabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
            searchConfig: GlassSearchBarConfig(onSearchToggle: (_) {}),
            extraButton: extra
                ? GlassTabBarExtraButton(
                    icon: const Icon(CupertinoIcons.add),
                    onTap: () {},
                    label: 'Add',
                  )
                : null,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      );
    }

    Future<Map<String, Rect>> rects(
      WidgetTester tester,
      Widget bar, {
      bool extra = false,
    }) async {
      await tester.pumpWidget(bar);
      await tester.pumpAndSettle();
      return {
        'bar': tester.getRect(find.byType(GlassTabBar)),
        'tabs': tester.getRect(find.byType(SearchableTabIndicator)),
        'search': tester.getRect(find.byType(SearchPill)),
        if (extra) 'extra': tester.getRect(find.byType(BottomBarExtraBtn)),
      };
    }

    for (final extra in [false, true]) {
      testWidgets('search pill${extra ? ' and extra button' : ''} mirror',
          (tester) async {
        final ltr = await rects(
            tester, searchable(TextDirection.ltr, extra: extra),
            extra: extra);
        final rtl = await rects(
            tester, searchable(TextDirection.rtl, extra: extra),
            extra: extra);
        final bar = ltr['bar']!;
        for (final key in ltr.keys.where((k) => k != 'bar')) {
          expect(rtl[key]!.left - bar.left,
              moreOrLessEquals(bar.right - ltr[key]!.right),
              reason: '$key left');
          expect(rtl[key]!.width, moreOrLessEquals(ltr[key]!.width),
              reason: '$key width');
        }
        expect(rtl['search']!.center.dx, lessThan(bar.center.dx));
      });
    }
  });
}

Future<void> dragAcross(
  WidgetTester tester, {
  required Offset from,
  required Offset to,
}) async {
  final gesture = await tester.startGesture(from);
  await tester.pump(const Duration(milliseconds: 16));
  await gesture.moveTo(Offset.lerp(from, to, 0.5)!);
  await tester.pump(const Duration(milliseconds: 16));
  await gesture.moveTo(to);
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.moveTo(to);
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.up();
  await tester.pumpAndSettle();
}
