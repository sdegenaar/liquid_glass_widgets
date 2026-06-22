import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  group('TabBarSearchableLayout missing coverage', () {
    testWidgets('custom controller, dismiss pill, and focus callbacks',
        (tester) async {
      final searchCtrl = SearchableBottomBarController();
      int selectedIndex = 0;
      bool focusChangedFired = false;
      bool cancelTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            // Fake viewInsets to simulate keyboard presence to trigger dismiss pill
            body: MediaQuery(
              data: const MediaQueryData(
                  viewInsets: EdgeInsets.only(bottom: 200)),
              child: StatefulBuilder(
                builder: (context, setState) {
                  return GlassTabBar.searchable(
                    tabs: [GlassTab(label: 'A'), GlassTab(label: 'B')],
                    selectedIndex: selectedIndex,
                    onTabSelected: (i) => setState(() => selectedIndex = i),
                    controller: searchCtrl,
                    isSearchActive: true,
                    searchConfig: GlassSearchBarConfig(
                      showsCancelButton: true,
                      onSearchToggle: (_) {},
                      onSearchFocusChanged: (focused) =>
                          focusChangedFired = focused,
                      onCancelTap: () => cancelTapped = true,
                      cancelIcon: const Icon(Icons.close),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Tell controller search is focused
      searchCtrl.onFocusChanged(true);
      await tester.pumpAndSettle();

      // Find the DismissPill or the cancel button by icon
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Tap the cancel button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(cancelTapped, true);
    });
  });
}
