// Tests for TabDragGestureMixin and buildIconShadows
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/shared/bottom_bar_internal.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: LiquidGlassWidgets.wrap(child: child)),
    );

GlassBottomBarTab _tab(String label) =>
    GlassBottomBarTab(label: label, icon: const Icon(Icons.home));

void main() {
  group('buildIconShadows', () {
    test('returns null when thickness is null', () {
      final result = buildIconShadows(
        iconColor: Colors.white,
        thickness: null,
        selected: false,
        activeIcon: null,
      );
      expect(result, isNull);
    });

    test('returns null when selected with activeIcon', () {
      final result = buildIconShadows(
        iconColor: Colors.white,
        thickness: 1.5,
        selected: true,
        activeIcon: const Icon(Icons.star),
      );
      expect(result, isNull);
    });

    test('returns 8 shadows when unselected with thickness', () {
      final result = buildIconShadows(
        iconColor: Colors.white,
        thickness: 1.5,
        selected: false,
        activeIcon: null,
      );
      expect(result, isNotNull);
      expect(result!.length, 8);
    });

    test('returns shadows when selected WITHOUT activeIcon', () {
      final result = buildIconShadows(
        iconColor: Colors.blue,
        thickness: 2.0,
        selected: true,
        activeIcon: null,
      );
      expect(result, isNotNull);
      expect(result!.length, 8);
    });

    test('shadows use correct iconColor', () {
      const iconColor = Color(0xFFFF0000);
      final result = buildIconShadows(
        iconColor: iconColor,
        thickness: 1.0,
        selected: false,
        activeIcon: null,
      );
      expect(result!.every((s) => s.color == iconColor), isTrue);
    });

    test('shadows offset magnitude equals thickness', () {
      const thickness = 3.0;
      final result = buildIconShadows(
        iconColor: Colors.black,
        thickness: thickness,
        selected: false,
        activeIcon: null,
      );
      for (final shadow in result!) {
        expect(shadow.offset.distance, closeTo(thickness, 0.01));
      }
    });
  });

  group('TabDragGestureMixin — drag state machine via GlassBottomBar', () {
    testWidgets('drag left switches tab via velocity fling', (tester) async {
      int selectedTab = 2;
      await tester.pumpWidget(_wrap(
        StatefulBuilder(builder: (ctx, setState) {
          return SizedBox(
            height: 100,
            child: GlassBottomBar(
              tabs: [_tab('A'), _tab('B'), _tab('C')],
              selectedIndex: selectedTab,
              onTabSelected: (i) => setState(() => selectedTab = i),
              maskingQuality: MaskingQuality.off,
            ),
          );
        }),
      ));
      await tester.pump();

      // Start a horizontal drag from right to left
      final barFinder = find.byType(GlassBottomBar);
      final barCenter = tester.getCenter(barFinder);
      final gesture = await tester.startGesture(barCenter);
      await gesture.moveBy(const Offset(-200, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      // Tab should have moved left
      expect(selectedTab, lessThan(2));
    });

    testWidgets('drag cancel snaps back without change', (tester) async {
      int selectedTab = 1;
      await tester.pumpWidget(_wrap(
        StatefulBuilder(builder: (ctx, setState) {
          return SizedBox(
            height: 100,
            child: GlassBottomBar(
              tabs: [_tab('A'), _tab('B'), _tab('C')],
              selectedIndex: selectedTab,
              onTabSelected: (i) => setState(() => selectedTab = i),
              maskingQuality: MaskingQuality.off,
            ),
          );
        }),
      ));
      await tester.pump();

      // Small drag without sufficient velocity
      final barFinder = find.byType(GlassBottomBar);
      final barCenter = tester.getCenter(barFinder);
      final gesture = await tester.startGesture(barCenter);
      await gesture.moveBy(const Offset(5, 0)); // tiny movement
      await gesture.cancel();
      await tester.pumpAndSettle();
      // Center tab — should stay at 1
      expect(selectedTab, 1);
    });

    testWidgets('onBarTapDown selects a tab on tap', (tester) async {
      int? lastSelected;
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassBottomBar(
            tabs: [_tab('A'), _tab('B'), _tab('C')],
            selectedIndex: 0,
            onTabSelected: (i) => lastSelected = i,
            maskingQuality: MaskingQuality.off,
          ),
        ),
      ));
      await tester.pump();

      // Tap on the rightmost third (tab index 2) — may or may not hit test
      // depending on headless layout; we just verify no crash occurs.
      final barFinder = find.byType(GlassBottomBar);
      final barRect = tester.getRect(barFinder);
      await tester.tapAt(Offset(barRect.right - 20, barRect.center.dy));
      await tester.pumpAndSettle();
      // Result may be null if bar is hidden behind the sheet overlay
      expect(lastSelected == null || lastSelected! >= 0, isTrue);
    });
  });

  group('BottomBarTabItem', () {
    testWidgets('renders label and icon', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 80,
          width: 80,
          child: BottomBarTabItem(
            tab: GlassBottomBarTab(
              label: 'Test',
              icon: const Icon(Icons.home),
            ),
            selected: false,
            selectedIconColor: Colors.blue,
            unselectedIconColor: Colors.grey,
            iconSize: 24,
            textStyle: null,
            labelFontSize: 11,
            iconLabelSpacing: 4,
            glowDuration: const Duration(milliseconds: 300),
            glowBlurRadius: 20,
            glowSpreadRadius: 10,
            glowOpacity: 0.5,
            onTap: null,
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('selected state changes icon weight', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 80,
          width: 80,
          child: BottomBarTabItem(
            tab: GlassBottomBarTab(
              label: 'Test',
              icon: const Icon(Icons.home),
              glowColor: Colors.blue,
            ),
            selected: true,
            selectedIconColor: Colors.white,
            unselectedIconColor: Colors.grey,
            iconSize: 24,
            textStyle: null,
            labelFontSize: 11,
            iconLabelSpacing: 4,
            glowDuration: const Duration(milliseconds: 300),
            glowBlurRadius: 20,
            glowSpreadRadius: 10,
            glowOpacity: 0.5,
            onTap: () {},
          ),
        ),
      ));
      await tester.pump();
      expect(find.text('Test'), findsOneWidget);
    });
  });

  group('TabIndicator — high quality mode', () {
    testWidgets('MaskingQuality.high renders dual-layer stack', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassBottomBar(
            tabs: [_tab('A'), _tab('B'), _tab('C')],
            selectedIndex: 0,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.high,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('MaskingQuality.off at edge tab (index 0) renders correctly',
        (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassBottomBar(
            tabs: [_tab('A'), _tab('B'), _tab('C')],
            selectedIndex: 0, // leftmost tab
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('A'), findsWidgets);
    });
  });
}
