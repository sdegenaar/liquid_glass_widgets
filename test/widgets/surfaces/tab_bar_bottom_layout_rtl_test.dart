import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

/// Regression tests for RTL handling in [GlassTabBar.bottom].
///
/// The indicator/gesture coordinate system operates in physical, left-anchored
/// alignment space, while the tab [Row]s honour the ambient [Directionality]
/// and visually reverse under RTL. Before the fix those two disagreed, so under
/// RTL the pill and the tap hit-testing landed on the mirror-image tab — e.g.
/// tapping the first tab (rendered on the trailing/right edge) reported the
/// last index instead of the first.
///
/// Finder note: with [MaskingQuality.off] every label is drawn twice — once in
/// the base (unselected) row and once in the vibrant selected-overlay row — so
/// each label matches two hit-testable widgets. `.hitTestable().first` keeps the
/// occlusion-safe filtering while deterministically resolving to the base row,
/// whose text sits at the tab's real on-screen position.
void main() {
  const tabs = [
    GlassTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
    GlassTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
    GlassTab(label: 'Profile', icon: Icon(CupertinoIcons.person)),
  ];

  Widget rtlBar({required ValueChanged<int> onTabSelected}) {
    return createTestApp(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: GlassTabBar.bottom(
          tabs: tabs,
          selectedIndex: 1,
          onTabSelected: onTabSelected,
          // Avoid the dual-layer jelly clipping path in tests.
          maskingQuality: MaskingQuality.off,
        ),
      ),
    );
  }

  group('GlassTabBar.bottom RTL', () {
    testWidgets('tapping a tab reports its logical index', (tester) async {
      var selected = -1;
      await tester.pumpWidget(rtlBar(onTabSelected: (i) => selected = i));

      // 'Home' is logical index 0; under RTL it renders on the trailing (right)
      // edge. Tapping it must still report index 0 — before the fix the
      // LTR-only hit-testing mirrored this to the last index.
      await tester.tap(find.text('Home').hitTestable().first);
      await tester.pumpAndSettle();
      expect(selected, 0);

      // 'Profile' is logical index 2; under RTL it renders on the leading
      // (left) edge. It must still report index 2.
      await tester.tap(find.text('Profile').hitTestable().first);
      await tester.pumpAndSettle();
      expect(selected, 2);
    });

    testWidgets('first tab renders on the trailing (right) edge', (
      tester,
    ) async {
      await tester.pumpWidget(rtlBar(onTabSelected: (_) {}));

      final screenWidth = tester.getSize(find.byType(GlassTabBar)).width;
      final homeCenter = tester.getCenter(find.text('Home').hitTestable().first);
      final profileCenter =
          tester.getCenter(find.text('Profile').hitTestable().first);

      // RTL ordering: the first tab sits to the right of the last tab.
      expect(homeCenter.dx, greaterThan(profileCenter.dx));
      expect(homeCenter.dx, greaterThan(screenWidth / 2));
    });
  });
}
