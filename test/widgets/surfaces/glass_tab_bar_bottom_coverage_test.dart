// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: LiquidGlassWidgets.wrap(child: child)),
    );

GlassTab _tab(String label) =>
    GlassTab(label: label, icon: const Icon(Icons.home));

GlassTab _tabWithGlow(String label) => GlassTab(
      label: label,
      icon: const Icon(Icons.star),
      activeIcon: const Icon(Icons.star_border),
      glowColor: Colors.amber,
      thickness: 1.5,
    );

void main() {
  group('GlassTabBar.bottom — rendering variants', () {
    testWidgets('basic 2-tab bar renders without crash', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassTabBar.bottom(
            tabs: [_tab('Home'), _tab('Profile')],
            selectedIndex: 0,
            onTabSelected: (_) {},
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('tab with glowColor and thickness renders', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassTabBar.bottom(
            tabs: [_tabWithGlow('Glow'), _tab('Normal')],
            selectedIndex: 0,
            onTabSelected: (_) {},
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Glow'), findsWidgets);
    });

    testWidgets('MaskingQuality.off renders simple mode', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassTabBar.bottom(
            tabs: [_tab('A'), _tab('B'), _tab('C')],
            selectedIndex: 1,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('A'), findsWidgets);
    });

    testWidgets('bar with extraButton renders extra btn', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassTabBar.bottom(
            tabs: [_tab('Home'), _tab('Profile')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            extraButton: GlassTabBarExtraButton(
              icon: const Icon(Icons.add),
              onTap: () {},
              label: 'Add',
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('non-default barBorderRadius passed to extra btn',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassTabBar.bottom(
            tabs: [_tab('Home'), _tab('Profile')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            barBorderRadius: 10, // not the default 32
            extraButton: GlassTabBarExtraButton(
              icon: const Icon(Icons.add),
              onTap: () {},
              label: 'Add',
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('standard quality bar renders', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassTabBar.bottom(
            tabs: [_tab('Home'), _tab('Settings')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            quality: GlassQuality.standard,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('enableBlend defaults to true', (tester) async {
      final bar = GlassTabBar.bottom(
        tabs: [_tab('Home'), _tab('Profile')],
        selectedIndex: 0,
        onTabSelected: (_) {},
      );
      expect(bar.enableBlend, isTrue);
    });

    testWidgets('enableBlend: false renders without crash', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassTabBar.bottom(
            tabs: [_tab('Home'), _tab('Profile')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            enableBlend: false,
            extraButton: GlassTabBarExtraButton(
              icon: const Icon(Icons.add),
              onTap: () {},
              label: 'Add',
            ),
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Home'), findsWidgets);
    });
  });

  group('GlassTabBar.bottom — interaction behavior', () {
    testWidgets('GlassInteractionBehavior.none disables glow and scale',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassTabBar.bottom(
            tabs: [_tab('X'), _tab('Y')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            interactionBehavior: GlassInteractionBehavior.none,
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('GlassInteractionBehavior.glowOnly renders', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassTabBar.bottom(
            tabs: [_tab('X'), _tab('Y')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            interactionBehavior: GlassInteractionBehavior.glowOnly,
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  group('GlassTabBar.bottom — tabWidth compact mode', () {
    testWidgets('tabWidth=88 limits pill width', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassTabBar.bottom(
            tabs: [_tab('H'), _tab('P'), _tab('S')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            tabWidth: 88,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('H'), findsWidgets);
    });

    testWidgets('tabWidth=null fills all space', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassTabBar.bottom(
            tabs: [_tab('H'), _tab('P')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            tabWidth: null,
          ),
        ),
      ));
      await tester.pump();
      expect(find.byType(SizedBox), findsWidgets);
    });
  });

  group('JellyClipper', () {
    test('shouldReclip returns false for sub-pixel changes', () {
      final c1 = JellyClipper(
        itemCount: 3,
        alignment: const Alignment(0.1, 0),
        thickness: 1.0,
        expansion: const EdgeInsets.all(14.0),
        transform: Matrix4.identity(),
        borderRadius: 32.0,
      );
      final c2 = JellyClipper(
        itemCount: 3,
        alignment: const Alignment(0.1 + 0.0001, 0), // sub-pixel
        thickness: 1.0,
        expansion: const EdgeInsets.all(14.0),
        transform: Matrix4.identity(),
        borderRadius: 32.0,
      );
      expect(c1.shouldReclip(c2), isFalse);
    });

    test('shouldReclip returns true for significant alignment change', () {
      final c1 = JellyClipper(
        itemCount: 3,
        alignment: const Alignment(0.0, 0),
        thickness: 1.0,
        expansion: const EdgeInsets.all(14.0),
        transform: Matrix4.identity(),
        borderRadius: 32.0,
      );
      final c2 = JellyClipper(
        itemCount: 3,
        alignment: const Alignment(0.5, 0),
        thickness: 1.0,
        expansion: const EdgeInsets.all(14.0),
        transform: Matrix4.identity(),
        borderRadius: 32.0,
      );
      expect(c1.shouldReclip(c2), isTrue);
    });

    test('getClip inverse=true produces evenOdd path', () {
      final clipper = JellyClipper(
        itemCount: 2,
        alignment: Alignment.center,
        thickness: 0.5,
        expansion: const EdgeInsets.all(10.0),
        transform: Matrix4.identity(),
        borderRadius: 20.0,
        inverse: true,
      );
      final path = clipper.getClip(const Size(300, 60));
      expect(path.fillType, PathFillType.evenOdd);
    });
  });
}
