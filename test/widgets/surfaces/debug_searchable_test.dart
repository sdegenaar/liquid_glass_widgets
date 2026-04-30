import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/widgets/shared/animated_glass_indicator.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/shared/searchable_bottom_bar_internal.dart';

import '../../shared/test_helpers.dart';

void main() {
  testWidgets('debug: searchable bar state access', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        child: GlassSearchableBottomBar(
          tabs: const [
            GlassBottomBarTab(label: 'Home', icon: Icon(CupertinoIcons.home)),
            GlassBottomBarTab(label: 'Search', icon: Icon(CupertinoIcons.search)),
            GlassBottomBarTab(label: 'Profile', icon: Icon(CupertinoIcons.person)),
          ],
          selectedIndex: 1,
          onTabSelected: (_) {},
          maskingQuality: MaskingQuality.off,
          searchConfig: GlassSearchBarConfig(onSearchToggle: (_) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    
    print('SearchableTabIndicator count: ${find.byType(SearchableTabIndicator).evaluate().length}');
    print('AnimatedGlassIndicator count before: ${find.byType(AnimatedGlassIndicator).evaluate().length}');
    
    final stateFinder = find.byType(SearchableTabIndicator);
    if (stateFinder.evaluate().isNotEmpty) {
      final state = tester.state<SearchableTabIndicatorState>(stateFinder.first);
      print('tabIsDown before: ${state.tabIsDown}');
      state.setState(() => state.tabIsDown = true);
      await tester.pump(const Duration(milliseconds: 1));
      print('After 1ms: ${find.byType(AnimatedGlassIndicator).evaluate().length}');
      await tester.pump(const Duration(milliseconds: 50));
      print('After 51ms: ${find.byType(AnimatedGlassIndicator).evaluate().length}');
    } else {
      print('ERROR: SearchableTabIndicator not found!');
    }
  });
}
