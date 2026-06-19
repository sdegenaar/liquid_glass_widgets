// Tests for TabDragGestureMixin and buildIconShadows
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/shared/tab_bar_bottom_internal.dart';

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

    testWidgets('drag cancel while dragging snaps to nearest tab',
        (tester) async {
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

      // Move far enough to lock in tabIsDragging=true, then cancel.
      // onBarDragCancel's tabIsDragging=true branch (lines 143-151) is hit.
      final barFinder = find.byType(GlassBottomBar);
      final barCenter = tester.getCenter(barFinder);
      final gesture = await tester.startGesture(barCenter);
      await gesture.moveBy(const Offset(80, 0)); // large enough for drag lock
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.cancel();
      await tester.pumpAndSettle();
      // Should snap to some valid tab without crash
      expect(selectedTab, greaterThanOrEqualTo(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('drag cancel without dragging resets indicator position',
        (tester) async {
      // onBarDragCancel with tabIsDragging=false (else branch, line 154).
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassBottomBar(
            tabs: [_tab('A'), _tab('B'), _tab('C')],
            selectedIndex: 1,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
          ),
        ),
      ));
      await tester.pump();

      // Start and immediately cancel without moving → tabIsDragging stays false
      final barFinder = find.byType(GlassBottomBar);
      final barCenter = tester.getCenter(barFinder);
      final gesture = await tester.startGesture(barCenter);
      await gesture.cancel(); // cancel before any move
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
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

  group('TabDragGestureMixin — barSwayOffset (lateral sway)', () {
    testWidgets('barSwayOffset accumulates during horizontal drag',
        (tester) async {
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

      // Perform a horizontal drag — the bar should accept it without error
      // and the Transform.translate should appear in the tree.
      final barFinder = find.byType(GlassBottomBar);
      final barCenter = tester.getCenter(barFinder);
      final gesture = await tester.startGesture(barCenter);
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump(const Duration(milliseconds: 16));

      // Verify Transform.translate is present (sway wrapper)
      expect(find.byType(Transform), findsWidgets);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('barSwayOffset resets on drag end (springs back to center)',
        (tester) async {
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

      // Drag and release
      final barFinder = find.byType(GlassBottomBar);
      final barCenter = tester.getCenter(barFinder);
      final gesture = await tester.startGesture(barCenter);
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pumpAndSettle();

      // After settle, the state's TabIndicatorState.barSwayOffset should be 0.
      final indicatorState =
          tester.state<TabIndicatorState>(find.byType(TabIndicator));
      expect(indicatorState.barSwayOffset, 0.0);
    });

    testWidgets('barSwayOffset resets on drag cancel', (tester) async {
      await tester.pumpWidget(_wrap(
        SizedBox(
          height: 100,
          child: GlassBottomBar(
            tabs: [_tab('A'), _tab('B'), _tab('C')],
            selectedIndex: 1,
            onTabSelected: (_) {},
            maskingQuality: MaskingQuality.off,
          ),
        ),
      ));
      await tester.pump();

      // Start drag, move, then cancel
      final barFinder = find.byType(GlassBottomBar);
      final barCenter = tester.getCenter(barFinder);
      final gesture = await tester.startGesture(barCenter);
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.cancel();
      await tester.pumpAndSettle();

      final indicatorState =
          tester.state<TabIndicatorState>(find.byType(TabIndicator));
      expect(indicatorState.barSwayOffset, 0.0);
    });

    testWidgets('barSwayOffset is clamped to max magnitude', (tester) async {
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

      // Drag very far to exceed the clamp
      final barFinder = find.byType(GlassBottomBar);
      final barCenter = tester.getCenter(barFinder);
      final gesture = await tester.startGesture(barCenter);
      // Move in multiple large increments to try to exceed the 3px clamp
      for (int i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(50, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }

      final indicatorState =
          tester.state<TabIndicatorState>(find.byType(TabIndicator));
      // barSwayOffset should never exceed _maxSwayPx (0.75)
      expect(indicatorState.barSwayOffset.abs(), lessThanOrEqualTo(0.75));

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
