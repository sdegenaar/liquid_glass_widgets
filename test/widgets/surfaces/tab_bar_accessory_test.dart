import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  group('GlassTabBar Accessory iOS 26 Layout', () {
    testWidgets('searchable placement uses TweenAnimationBuilder',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassTabBar.searchable(
              isSearchActive: false,
              tabs: const [GlassTab(label: '1'), GlassTab(label: '2')],
              selectedIndex: 0,
              onTabSelected: (_) {},
              searchConfig: GlassSearchBarConfig(
                onSearchToggle: (_) {},
              ),
              bottomAccessory:
                  const SizedBox(height: 50, width: 100, key: Key('acc')),
              bottomAccessoryHeight: 50,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('acc')), findsOneWidget);
      // In searchable mode, TweenAnimationBuilder is used for the accessory animation.
      expect(find.byType(TweenAnimationBuilder<double>), findsWidgets);

      // Test the preferredSize computation.
      var tabBar = tester.widget<GlassTabBar>(find.byType(GlassTabBar));
      // isSearchActive: false → effectivePillH = barHeight(64) + vertPad(20*2) = 104
      // gapAdjustment = 0 (not searching)
      // total = 104 + spacing(6) + accessory(50) = 160
      expect(tabBar.preferredSize.height, 160.0);

      // Rebuild in inline mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassTabBar.searchable(
              isSearchActive: true,
              tabs: const [GlassTab(label: '1'), GlassTab(label: '2')],
              selectedIndex: 0,
              onTabSelected: (_) {},
              searchBarHeight: 36, // Explicitly match my mental calculation
              searchConfig: GlassSearchBarConfig(
                onSearchToggle: (_) {},
              ),
              bottomAccessory:
                  const SizedBox(height: 50, width: 100, key: Key('acc')),
              bottomAccessoryHeight: 50,
            ),
          ),
        ),
      );

      tabBar = tester.widget<GlassTabBar>(find.byType(GlassTabBar));
      // isSearchActive: true, no explicit placement → stays expanded (no auto-collapse)
      // effectivePillH = searchBarHeight(36) + vertPad(40) = 76
      // gapAdjustment = barHeight(64) - searchBarHeight(36) = 28
      // total = 76 - 28 + spacing(6) + accessory(50) = 104
      expect(tabBar.preferredSize.height, 104.0);
    });

    testWidgets(
        'searchable placement can be overridden by bottomAccessoryPlacement',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GlassTabBar.searchable(
              isSearchActive: true, // Tabs collapsed
              bottomAccessoryPlacement: GlassTabBarAccessoryPlacement
                  .expanded, // But accessory above!
              tabs: const [GlassTab(label: '1'), GlassTab(label: '2')],
              selectedIndex: 0,
              onTabSelected: (_) {},
              searchBarHeight: 36,
              searchConfig: GlassSearchBarConfig(
                onSearchToggle: (_) {},
              ),
              bottomAccessory:
                  const SizedBox(height: 50, width: 100, key: Key('acc')),
              bottomAccessoryHeight: 50,
            ),
          ),
        ),
      );

      final tabBar = tester.widget<GlassTabBar>(find.byType(GlassTabBar));
      // Base search bar height (36) + vertical padding (20) * 2 = 76
      // Gap adjustment: barHeight (64) - searchBarHeight (36) = 28
      // PLUS accessory height (50) + spacing (6)
      // Total = 76 - 28 + 6 + 50 = 104.0
      expect(tabBar.preferredSize.height, 104.0);
    });
  });

  group('GlassTabBar.bottom accessory & scaffolding', () {
    testWidgets('provides correct placement and sizes scaffolding',
        (tester) async {
      final scrollController = ScrollController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              controller: scrollController,
              children: List.generate(
                  100, (i) => SizedBox(height: 50, child: Text('Item $i'))),
            ),
            bottomNavigationBar: GlassTabBar.bottom(
              tabs: const [GlassTab(label: '1')],
              selectedIndex: 0,
              scrollController: scrollController,
              onTabSelected: (_) {},
              extraButton: GlassTabBarExtraButton(
                icon: const Icon(Icons.add),
                onTap: () {},
                label: 'Add',
              ),
              collapseConfig: const GlassTabBarCollapseConfig(),
              bottomAccessory: Builder(builder: (context) {
                final placement =
                    GlassTabBarAccessoryPlacementScope.of(context);
                return Text(
                  placement.name,
                  textDirection: TextDirection.ltr,
                );
              }),
              bottomAccessoryHeight: 50,
            ),
          ),
        ),
      );

      // Verify the scope resolves to expanded
      expect(find.text('expanded'), findsOneWidget);

      // Trigger collapse via scroll
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify the scope resolves to inline when collapsed
      expect(find.text('inline'), findsOneWidget);
    });

    testWidgets('GlassScaffold safely resolves PreferredSizeWidget bottomBar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlassScaffold(
            body: const SizedBox(),
            bottomBar: GlassTabBar.bottom(
              tabs: const [GlassTab(label: '1')],
              selectedIndex: 0,
              onTabSelected: (_) {},
              bottomAccessory: const SizedBox(height: 50),
              bottomAccessoryHeight: 50,
            ),
          ),
        ),
      );

      // If GlassScaffold doesn't crash on layout, the PreferredSizeWidget
      // resolution path was covered successfully.
      expect(find.byType(GlassScaffold), findsOneWidget);
    });
  });
}
