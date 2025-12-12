import 'package:liquid_glass_widgets/types/glass_quality.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/glass_bottom_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassBottomBar', () {
    final testTabs = [
      const GlassBottomBarTab(
        label: 'Home',
        icon: CupertinoIcons.home,
      ),
      const GlassBottomBarTab(
        label: 'Search',
        icon: CupertinoIcons.search,
      ),
      const GlassBottomBarTab(
        label: 'Profile',
        icon: CupertinoIcons.person,
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
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('displays all tab icons', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs,
            selectedIndex: 0,
            onTabSelected: (_) {},
          ),
        ),
      );

      expect(find.byIcon(CupertinoIcons.home), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.search), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.person), findsOneWidget);
    });

    testWidgets('calls onTabSelected when tab is tapped', (tester) async {
      var selectedIndex = 0;

      await tester.pumpWidget(
        createTestApp(
          child: GlassBottomBar(
            tabs: testTabs,
            selectedIndex: selectedIndex,
            onTabSelected: (index) => selectedIndex = index,
          ),
        ),
      );

      await tester.tap(find.text('Search'));
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
              icon: CupertinoIcons.add,
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
              icon: CupertinoIcons.add,
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
      expect(bar.quality, equals(GlassQuality.premium));
    });
  });

  group('GlassBottomBarTab', () {
    test('can be instantiated', () {
      const tab = GlassBottomBarTab(
        label: 'Home',
        icon: CupertinoIcons.home,
      );

      expect(tab.label, equals('Home'));
      expect(tab.icon, equals(CupertinoIcons.home));
    });
  });

  group('GlassBottomBarExtraButton', () {
    test('can be instantiated', () {
      final button = GlassBottomBarExtraButton(
        icon: CupertinoIcons.add,
        label: 'Add',
        onTap: () {},
      );

      expect(button.icon, equals(CupertinoIcons.add));
      expect(button.label, equals('Add'));
      expect(button.size, equals(64));
    });
  });
}
