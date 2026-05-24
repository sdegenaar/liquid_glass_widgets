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
}
