import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets('GlassMenu toggles and renders items',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              trigger: Container(
                width: 50,
                height: 50,
                color: Colors.blue,
                child: const Center(child: Text('Open Menu')),
              ),
              items: [
                GlassMenuItem(
                  title: 'Option 1',
                  onTap: () {},
                ),
                GlassMenuItem(
                  title: 'Option 2',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Initial state: Menu closed
    expect(find.text('Option 1'), findsNothing);

    // Tap trigger
    await tester.tap(find.text('Open Menu'));
    await tester.pump(); // Start animation
    await tester
        .pumpAndSettle(); // Wait for animation to complete (content appears at 65%+)

    // Menu should be present (portal shown)
    expect(find.text('Option 1'), findsOneWidget);

    // Close menu (tap outside)
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    // Menu closed
    expect(find.text('Option 1'), findsNothing);
  });

  testWidgets('GlassMenu works with triggerBuilder (interactive trigger)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              triggerBuilder: (context, toggle) => GlassButton.custom(
                onTap: toggle,
                useOwnLayer: true,
                child: const Text('Interactive Menu'),
              ),
              items: [
                GlassMenuItem(
                  title: 'Action',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Action'), findsNothing);

    await tester.tap(find.text('Interactive Menu'));
    await tester.pump();
    await tester.pumpAndSettle(); // Wait for animation to complete

    expect(find.text('Action'), findsOneWidget);
  });

  testWidgets('GlassMenu aligns correctly when on right side of screen',
      (WidgetTester tester) async {
    // Set a wide screen
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                right: 20,
                top: 20,
                child: GlassMenu(
                  trigger: const SizedBox(
                      width: 50, height: 50, child: Text('RightBtn')),
                  items: [
                    GlassMenuItem(title: 'RightItem', onTap: () {}),
                  ],
                  menuWidth: 200,
                ),
              )
            ],
          ),
        ),
      ),
    );

    // Open menu
    await tester.tap(find.text('RightBtn'));
    await tester.pump();
    await tester.pumpAndSettle(); // Wait for animation to complete

    // Verify 'RightItem' is visible
    expect(find.text('RightItem'), findsOneWidget);

    addTearDown(tester.view.resetPhysicalSize);
  });

  // ── GlassMenuItem tap-cancel (line 77) ──────────────────────────────────────
  testWidgets('GlassMenuItem onTapCancel resets pressed state (line 77)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassMenu(
            trigger: const SizedBox(
              width: 60,
              height: 40,
              child: Text('Open'),
            ),
            items: [
              GlassMenuItem(
                title: 'Action',
                icon: Icon(Icons.star),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );

    // Open the menu to make item visible
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Action'), findsOneWidget);

    // Tap-down then cancel — exercises onTapDown (line 75) and onTapCancel (line 77)
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Action')),
    );
    await tester.pump();
    await gesture.cancel();
    await tester.pump();

    // Item still present — state reset silently
    expect(find.text('Action'), findsOneWidget);
  });

  // ── _toggleMenu close path (line 186) ───────────────────────────────────────
  testWidgets('GlassMenu second tap closes menu via _toggleMenu (line 186)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              trigger: const SizedBox(
                width: 60,
                height: 40,
                child: Text('Toggle'),
              ),
              items: [
                GlassMenuItem(title: 'Close Test', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    // First tap — opens menu
    await tester.tap(find.text('Toggle'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Close Test'), findsOneWidget);

    // Second tap — closes menu via _toggleMenu (line 186: _closeMenu)
    await tester.tap(find.text('Toggle'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Close Test'), findsNothing);
  });

  // ── shouldFlipVertical bottom-of-screen path (line 228) ─────────────────────
  testWidgets(
      'GlassMenu at bottom of screen flips vertical alignment (line 228)',
      (tester) async {
    tester.view.physicalSize = const Size(400, 600);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                bottom: 10, // Near bottom — triggers shouldFlipVertical
                left: 20,
                child: GlassMenu(
                  trigger: const SizedBox(
                      width: 60, height: 40, child: Text('BottomMenu')),
                  items: [
                    GlassMenuItem(title: 'FlipItem', onTap: () {}),
                  ],
                  menuWidth: 150,
                ),
              )
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('BottomMenu'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('FlipItem'), findsOneWidget);
    addTearDown(tester.view.resetPhysicalSize);
  });

  // ── GlassMenuAlignment enum (PR #55) ─────────────────────────────────────────
  test('GlassMenuAlignment enum has all expected values', () {
    const values = GlassMenuAlignment.values;
    expect(values, contains(GlassMenuAlignment.none));
    expect(values, contains(GlassMenuAlignment.topLeft));
    expect(values, contains(GlassMenuAlignment.topCenter));
    expect(values, contains(GlassMenuAlignment.topRight));
    expect(values, contains(GlassMenuAlignment.centerLeft));
    expect(values, contains(GlassMenuAlignment.center));
    expect(values, contains(GlassMenuAlignment.centerRight));
    expect(values, contains(GlassMenuAlignment.bottomLeft));
    expect(values, contains(GlassMenuAlignment.bottomCenter));
    expect(values, contains(GlassMenuAlignment.bottomRight));
    expect(values.length, 10);
  });

  testWidgets('GlassMenu opens with explicit menuAlignment.topRight',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              menuAlignment: GlassMenuAlignment.topRight,
              trigger: const SizedBox(
                  width: 60, height: 40, child: Text('AlignMenu')),
              items: [
                GlassMenuItem(title: 'AlignedItem', onTap: () {}),
              ],
              menuWidth: 180,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('AlignMenu'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('AlignedItem'), findsOneWidget);
  });

  testWidgets('GlassMenu autoAdjustToScreen with menuPadding does not crash',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomRight,
            child: GlassMenu(
              autoAdjustToScreen: true,
              menuPadding: const EdgeInsets.all(12),
              trigger: const SizedBox(
                  width: 60, height: 40, child: Text('PaddedMenu')),
              items: [
                GlassMenuItem(title: 'PaddedItem', onTap: () {}),
              ],
              menuWidth: 200,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('PaddedMenu'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('PaddedItem'), findsOneWidget);
    expect(tester.takeException(), isNull);
    addTearDown(tester.view.resetPhysicalSize);
  });

  testWidgets('GlassMenu respects itemBorderRadius parameter', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              itemBorderRadius: 8.0,
              trigger:
                  const SizedBox(width: 60, height: 40, child: Text('Open')),
              items: [
                GlassMenuItem(title: 'RoundedItem', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('RoundedItem'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // ── onClose callback (PR #67) ────────────────────────────────────────────────
  test('GlassMenu.onClose defaults to null', () {
    const menu = GlassMenu(
      trigger: SizedBox(width: 40, height: 40),
      items: [],
    );
    expect(menu.onClose, isNull);
  });

  testWidgets('GlassMenu onClose fires when tapping outside the barrier',
      (tester) async {
    // Regression: onClose must fire on the barrier tap-to-close path
    // (GestureDetector Positioned.fill, glass_menu_internal.dart line 369).
    int closeCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              onClose: () => closeCalls++,
              trigger:
                  const SizedBox(width: 60, height: 40, child: Text('Open')),
              items: [
                GlassMenuItem(title: 'Item', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    // Open the menu.
    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Item'), findsOneWidget);
    expect(closeCalls, 0); // Opening must NOT call onClose.

    // Tap outside (top-left corner — well outside the menu body).
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(closeCalls, 1);
  });

  testWidgets('GlassMenu onClose fires when closed via trigger re-tap',
      (tester) async {
    // Regression: onClose must fire on the _toggleMenu → _closeMenu path
    // (glass_menu_internal.dart line 188).
    int closeCalls = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              onClose: () => closeCalls++,
              trigger:
                  const SizedBox(width: 60, height: 40, child: Text('Toggle2')),
              items: [
                GlassMenuItem(title: 'Item2', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    // Open.
    await tester.tap(find.text('Toggle2'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(closeCalls, 0);

    // Re-tap trigger to close. The trigger widget is behind the overlay at this
    // point (opacity=0, IgnorePointer when menu open), so warnIfMissed is
    // suppressed — _toggleMenu is still invoked via the GestureDetector.
    await tester.tap(find.text('Toggle2'), warnIfMissed: false);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(closeCalls, 1);
  });

  testWidgets('GlassMenu onClose not called when not provided', (tester) async {
    // Safety: widget with no onClose must not throw when menu closes.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              // onClose intentionally omitted.
              trigger: const SizedBox(
                  width: 60, height: 40, child: Text('NoCallback')),
              items: [
                GlassMenuItem(title: 'SafeItem', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('NoCallback'));
    await tester.pump();
    await tester.pumpAndSettle();

    // Close via outside tap — must not throw.
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  // ── morphFromZero (point bloom) ───────────────────────────────────────────
  test('GlassMenu.morphFromZero defaults to false', () {
    final menu = GlassMenu(
      trigger: const SizedBox(width: 8, height: 8),
      items: [GlassMenuItem(title: 'Item', onTap: () {})],
    );
    expect(menu.morphFromZero, isFalse);
  });

  testWidgets('GlassMenu morphFromZero opens and closes without crashing',
      (tester) async {
    // morphFromZero lerps Blob B's size from 0 → full and suppresses Blob A,
    // exercising the radius-0 / 0-area degenerate path the default-false tests
    // never hit. The zero-size render guard must keep this from throwing.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              morphFromZero: true,
              trigger: const SizedBox(width: 8, height: 8, child: Text('Zero')),
              items: [
                GlassMenuItem(title: 'ZeroItem', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Zero'));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('ZeroItem'), findsOneWidget);

    // Close via outside tap — the collapse-to-point tail must not throw.
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('ZeroItem'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // ── GlassMenuController (PR #88 / #89) ──────────────────────────────────────
  test('GlassMenuController defaults to detached (isOpen is false)', () {
    final controller = GlassMenuController();
    expect(controller.isOpen, isFalse);
  });

  testWidgets('GlassMenuController.open() opens the menu imperatively',
      (tester) async {
    final controller = GlassMenuController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              controller: controller,
              trigger:
                  const SizedBox(width: 60, height: 40, child: Text('Ctrl')),
              items: [
                GlassMenuItem(title: 'CtrlItem', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    expect(controller.isOpen, isFalse);
    expect(find.text('CtrlItem'), findsNothing);

    // Open via controller (not via trigger tap)
    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.isOpen, isTrue);
    expect(find.text('CtrlItem'), findsOneWidget);
  });

  testWidgets('GlassMenuController.close() closes the menu imperatively',
      (tester) async {
    final controller = GlassMenuController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              controller: controller,
              trigger:
                  const SizedBox(width: 60, height: 40, child: Text('Ctrl2')),
              items: [
                GlassMenuItem(title: 'CtrlItem2', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    // Open via controller
    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('CtrlItem2'), findsOneWidget);

    // Close via controller
    controller.close();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(controller.isOpen, isFalse);
    expect(find.text('CtrlItem2'), findsNothing);
  });

  // ── showDismissBarrier (PR #88 / #89) ───────────────────────────────────────
  test('GlassMenu.showDismissBarrier defaults to true', () {
    final menu = GlassMenu(
      trigger: const SizedBox(width: 40, height: 40),
      items: [GlassMenuItem(title: 'Item', onTap: () {})],
    );
    expect(menu.showDismissBarrier, isTrue);
  });

  testWidgets(
      'GlassMenu showDismissBarrier=false renders without barrier crash',
      (tester) async {
    final controller = GlassMenuController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              controller: controller,
              showDismissBarrier: false,
              trigger: const SizedBox(
                  width: 60, height: 40, child: Text('NoBarrier')),
              items: [
                GlassMenuItem(title: 'BarrierItem', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('BarrierItem'), findsOneWidget);

    // Close via controller since there's no barrier to tap
    controller.close();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('BarrierItem'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  // ── setFollowOffset (PR #89) ────────────────────────────────────────────────
  testWidgets('GlassMenuController.setFollowOffset does not crash',
      (tester) async {
    final controller = GlassMenuController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              controller: controller,
              trigger:
                  const SizedBox(width: 60, height: 40, child: Text('Follow')),
              items: [
                GlassMenuItem(title: 'FollowItem', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    controller.open();
    await tester.pump();
    await tester.pumpAndSettle();

    // Nudge the menu position — must not crash
    controller.setFollowOffset(const Offset(10, 5));
    await tester.pump();

    expect(find.text('FollowItem'), findsOneWidget);

    // Reset offset
    controller.setFollowOffset(Offset.zero);
    await tester.pump();

    expect(tester.takeException(), isNull);

    controller.close();
    await tester.pump();
    await tester.pumpAndSettle();
  });

  // ── GlassIconButton quality null pass-through (PR #90) ──────────────────────
  testWidgets('GlassIconButton passes null quality to let theme chain resolve',
      (tester) async {
    // Exercises the fix: quality must NOT be coerced to GlassQuality.standard
    // before reaching GlassButton.custom(), so the theme chain can resolve it.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassIconButton(
              icon: const Icon(Icons.star),
              onPressed: () {},
              // quality intentionally omitted — must resolve through theme
            ),
          ),
        ),
      ),
    );

    expect(find.byType(GlassIconButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
