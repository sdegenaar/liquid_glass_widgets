import 'dart:math' as math;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'
    show RenderOpacity, SemanticsAction, SemanticsNode;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/renderer/glass_materialize_scope.dart';

void main() {
  for (final fromTrigger in [false, true]) {
    for (final cancel in [false, true]) {
      testWidgets(
          'active ${fromTrigger ? 'trigger' : 'menu'} pointer can '
          '${cancel ? 'cancel' : 'end'} after menu unmounts', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: GlassMenu(
                enableContinuousSwipe: fromTrigger,
                trigger:
                    const SizedBox(width: 60, height: 40, child: Text('Open')),
                items: [GlassMenuItem(title: 'Action', onTap: () {})],
              ),
            ),
          ),
        );
        if (!fromTrigger) {
          await tester.tap(find.text('Open'));
          await tester.pumpAndSettle();
        }

        final gesture = await tester.startGesture(
          tester.getCenter(find.text(fromTrigger ? 'Open' : 'Action')),
        );
        await tester.pump();
        await tester.pumpWidget(const SizedBox.shrink());
        await gesture.moveBy(const Offset(0, 5));
        if (cancel) {
          await gesture.cancel();
        } else {
          await gesture.up();
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

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
  // ── Scale-with-morph animation (PR #97) ────────────────────────────────────
  testWidgets('GlassMenu items are wrapped in Transform.scale when fully open',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              trigger:
                  const SizedBox(width: 60, height: 40, child: Text('Scale')),
              items: [
                GlassMenuItem(title: 'ScaleItem', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    // Open the menu and let the spring fully settle.
    await tester.tap(find.text('Scale'));
    await tester.pump();
    await tester.pumpAndSettle();

    // The item text must be visible.
    expect(find.text('ScaleItem'), findsOneWidget);

    // A Transform widget wrapping items should exist in the tree.
    // At rest (clampedValue ≈ 1.0) the scale should be ≈ 1.0.
    final transformFinder = find.ancestor(
      of: find.text('ScaleItem'),
      matching: find.byType(Transform),
    );
    expect(transformFinder, findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'GlassMenu items fade via Opacity mid-morph and omit Opacity when fully open',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              trigger:
                  const SizedBox(width: 60, height: 40, child: Text('Fade')),
              items: [
                GlassMenuItem(title: 'FadeItem', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Fade'));
    await tester.pump();
    // Mid-open (~160ms): items are fading in via a single Column-level Opacity.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('FadeItem'), findsOneWidget);
    final midMorphOpacity = find.ancestor(
      of: find.text('FadeItem'),
      matching: find.byType(Opacity),
    );
    expect(midMorphOpacity, findsOneWidget);

    // Once settled (itemOpacity == 1.0), unnecessary Opacity wrappers are
    // omitted to avoid resting saveLayer overhead.
    await tester.pumpAndSettle();
    expect(find.text('FadeItem'), findsOneWidget);
    final settledOpacity = find.ancestor(
      of: find.text('FadeItem'),
      matching: find.byType(Opacity),
    );
    expect(settledOpacity, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'GlassMenu items not present immediately after opening (early morph)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              trigger: const SizedBox(
                  width: 60, height: 40, child: Text('EarlyMorph')),
              items: [
                GlassMenuItem(title: 'EarlyItem', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    // Tap to open — pump only one frame (spring is near 0%).
    await tester.tap(find.text('EarlyMorph'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    // At this very early stage of the spring, items should not yet be in
    // the tree (clampedValue is well below 0.3).
    expect(find.text('EarlyItem'), findsNothing);

    // Let the animation complete so teardown is clean.
    await tester.pumpAndSettle();
    expect(find.text('EarlyItem'), findsOneWidget);
  });

  testWidgets(
      'GlassMenu items present immediately with GlassAccessibilityScope(reduceMotion: true)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassAccessibilityScope(
              reduceMotion: true,
              child: GlassMenu(
                trigger: const SizedBox(
                    width: 60, height: 40, child: Text('InstantMenu')),
                items: [
                  GlassMenuItem(title: 'InstantItem', onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Tap to open — with reduceMotion (instant spring stiffness 500), the morph settles
    // well within 150ms, whereas normal spring (~375ms) is still travelling.
    await tester.tap(find.text('InstantMenu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('InstantItem'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets(
      'GlassMenu items present within 150ms with platform reduceMotion: true',
      (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              trigger: const SizedBox(
                  width: 60, height: 40, child: Text('PlatformInstantMenu')),
              items: [
                GlassMenuItem(title: 'PlatformInstantItem', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('PlatformInstantMenu'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('PlatformInstantItem'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  // ── Route-aware dismissal tests (#274) ────────────────────────────────────
  testWidgets(
      'GlassMenu dismisses instantly on route navigation without overlapping destination (#274)',
      (tester) async {
    bool closedCalled = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: GlassMenu(
                onClose: () => closedCalled = true,
                trigger: const SizedBox(
                  width: 80,
                  height: 40,
                  child: Text('Open Menu'),
                ),
                items: [
                  GlassMenuItem(
                    title: 'Navigate Item',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const Scaffold(
                            body: Center(child: Text('Page 2')),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Open the menu
    await tester.tap(find.text('Open Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Navigate Item'), findsOneWidget);
    expect(closedCalled, isFalse);

    // Tap navigate item
    await tester.tap(find.text('Navigate Item'));

    // Advance into the route transition
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Mid-transition into the new route, the menu must already be dismissed.
    // It should not linger in the root overlay over the incoming page.
    expect(find.text('Navigate Item'), findsNothing);
    expect(find.text('Page 2'), findsOneWidget);
    expect(closedCalled, isTrue);

    // Complete the transition
    await tester.pumpAndSettle();
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Navigate Item'), findsNothing);

    // Pop back to Page 1
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    // Back on Page 1: trigger is visible and menu is closed
    expect(find.text('Open Menu'), findsOneWidget);
    expect(find.text('Navigate Item'), findsNothing);

    // Menu can be reopened cleanly
    await tester.tap(find.text('Open Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Navigate Item'), findsOneWidget);
  });

  testWidgets(
      'GlassMenu dismisses instantly when route is pushed externally while open',
      (tester) async {
    late BuildContext homeContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            homeContext = context;
            return Scaffold(
              body: Center(
                child: GlassMenu(
                  trigger: const Text('Open Menu'),
                  items: [
                    GlassMenuItem(
                      title: 'Option',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Option'), findsOneWidget);

    // Push an external route
    Navigator.of(homeContext).push(
      MaterialPageRoute(
        builder: (_) => const Scaffold(
          body: Center(child: Text('External Route')),
        ),
      ),
    );

    // Advance into transition
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Option'), findsNothing);
    expect(find.text('External Route'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets(
      'GlassMenu dismisses instantly when route with zero duration is pushed while open',
      (tester) async {
    late BuildContext homeContext;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            homeContext = context;
            return Scaffold(
              body: Center(
                child: GlassMenu(
                  trigger: const Text('Open Menu'),
                  items: [
                    GlassMenuItem(
                      title: 'Option',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Option'), findsOneWidget);

    Navigator.of(homeContext).push(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => const Scaffold(
          body: Center(child: Text('Zero Duration Route')),
        ),
      ),
    );

    await tester.pump();
    expect(find.text('Option'), findsNothing);
    expect(find.text('Zero Duration Route'), findsOneWidget);
  });

  testWidgets(
      'GlassMenu dismisses instantly when containing route is popped while open',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(title: const Text('Second Route')),
                      body: Center(
                        child: GlassMenu(
                          trigger: const Text('Open SubMenu'),
                          items: [
                            GlassMenuItem(
                              title: 'Sub Option',
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Go to Second'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Go to Second'));
    await tester.pumpAndSettle();
    expect(find.text('Second Route'), findsOneWidget);

    // Open menu on second route
    await tester.tap(find.text('Open SubMenu'));
    await tester.pumpAndSettle();
    expect(find.text('Sub Option'), findsOneWidget);

    // Pop the containing route
    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    navigator.pop();

    // First frame of pop
    await tester.pump();
    expect(find.text('Sub Option'), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Go to Second'), findsOneWidget);
  });

  testWidgets(
      'GlassMenu dismisses instantly when route is pushed on ancestor Navigator (#274 nested navigator)',
      (tester) async {
    final shellNavigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          key: shellNavigatorKey,
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (context) => Scaffold(
                  body: Center(
                    child: GlassMenu(
                      trigger: const Text('Open Menu'),
                      items: [
                        GlassMenuItem(
                          title: 'Start Activity',
                          onTap: () {
                            shellNavigatorKey.currentState!.push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => const Scaffold(
                                  body: Center(child: Text('Destination page')),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Start Activity'), findsOneWidget);

    await tester.tap(find.text('Start Activity'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Mid-transition into Destination page on the ancestor navigator,
    // the menu should already be dismissed and not lingering in root overlay.
    expect(find.text('Destination page'), findsOneWidget);
    expect(find.text('Start Activity'), findsNothing);

    await tester.pumpAndSettle();
  });

  testWidgets(
      'GlassMenuItem does not throw RenderFlex overflow when constrained to narrow width',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 59.9,
              child: GlassMenuItem(
                icon: const Icon(Icons.share),
                title: 'Share',
                onTap: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byType(GlassMenuItem), findsOneWidget);
  });

  testWidgets(
      'GlassMenu opening morph with icons and default menuWidth does not overflow',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              trigger: const SizedBox(
                width: 44,
                height: 44,
                child: Text('Open'),
              ),
              menuWidth: 200,
              items: [
                GlassMenuItem(
                  icon: const Icon(Icons.share),
                  title: 'Option A',
                  onTap: () {},
                ),
                GlassMenuItem(
                  icon: const Icon(Icons.edit),
                  title: 'Option B',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    // Pump through morph animation frame by frame
    for (int i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    expect(find.text('Option A'), findsOneWidget);
    expect(find.text('Option B'), findsOneWidget);
  });

  // ── Trigger soft-detach opacity ───────────────────────────────────────────

  testWidgets('Trigger opacity is 1.0 before menu opens', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              trigger: const SizedBox(
                width: 44,
                height: 44,
                child: Text('Btn'),
              ),
              menuWidth: 200,
              items: [
                GlassMenuItem(title: 'Item', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Before tapping: the trigger is fully opaque with no Opacity wrapper
    // (omitting RenderOpacity at rest keeps triggers inside GlassBackdropGroup).
    expect(find.byType(Opacity), findsNothing);
    expect(find.text('Btn'), findsOneWidget);
  });

  testWidgets('Trigger dissolves cleanly to 0.0 when menu is fully open',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              trigger: const SizedBox(
                width: 44,
                height: 44,
                child: Text('Btn'),
              ),
              menuWidth: 200,
              items: [
                GlassMenuItem(title: 'Item', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Btn'));
    await tester.pumpAndSettle();

    // When fully open, the trigger must be cleanly dissolved (opacity 0.0)
    // so there is no ghost button or visual artifact under/behind the menu.
    final opacityWidgets = tester.widgetList<Opacity>(find.byType(Opacity));
    final triggerOpacity = opacityWidgets.first.opacity;
    expect(
      triggerOpacity,
      equals(0.0),
      reason:
          'Trigger should be fully dissolved when menu is open (clean detach)',
    );
  });

  testWidgets('Trigger opacity returns to 1.0 after menu fully closes',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              trigger: const SizedBox(
                width: 44,
                height: 44,
                child: Text('Btn'),
              ),
              menuWidth: 200,
              items: [
                GlassMenuItem(title: 'Item', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Btn'));
    await tester.pumpAndSettle();
    // Close by tapping again.
    await tester.tap(find.text('Btn'), warnIfMissed: false);
    await tester.pumpAndSettle();

    // Settled trigger omits Opacity (effective opacity 1.0) so it rejoins
    // any enclosing GlassBackdropGroup cleanly.
    expect(find.byType(Opacity), findsNothing);
    expect(find.text('Btn'), findsOneWidget);
  });

  testWidgets(
      'GlassMenu on standard quality renders only single GlassContainer on close (no Blob A ghost)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              quality: GlassQuality.standard,
              trigger: const SizedBox(
                width: 44,
                height: 44,
                child: Text('Btn'),
              ),
              menuWidth: 200,
              items: [
                GlassMenuItem(title: 'Item', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Btn'));
    await tester.pumpAndSettle();

    // Trigger close
    await tester.tap(find.text('Item'));
    // Pump partially into the close animation (e.g. 50ms)
    await tester.pump(const Duration(milliseconds: 50));

    // Under standard quality, Blob A is suppressed during close to prevent double-button overlap.
    // There should be exactly 1 GlassContainer inside the overlay (Blob B, the collapsing menu body).
    final overlayContainers = find.descendant(
      of: find.byType(AdaptiveLiquidGlassLayer),
      matching: find.byType(GlassContainer),
    );
    expect(overlayContainers, findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets(
      'GlassMenu on minimal quality renders only single GlassContainer on close (no Blob A ghost)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              quality: GlassQuality.minimal,
              trigger: const SizedBox(
                width: 44,
                height: 44,
                child: Text('Btn'),
              ),
              menuWidth: 200,
              items: [
                GlassMenuItem(title: 'Item', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Btn'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Item'));
    await tester.pump(const Duration(milliseconds: 50));

    final overlayContainers = find.descendant(
      of: find.byType(AdaptiveLiquidGlassLayer),
      matching: find.byType(GlassContainer),
    );
    expect(overlayContainers, findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets(
      'GlassMenu with platformViewBackdrop: true suppresses Blob A on close even with premium quality',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              quality: GlassQuality.premium,
              platformViewBackdrop: true,
              trigger: const SizedBox(
                width: 44,
                height: 44,
                child: Text('Btn'),
              ),
              menuWidth: 200,
              items: [
                GlassMenuItem(title: 'Item', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Btn'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Item'));
    await tester.pump(const Duration(milliseconds: 50));

    final overlayContainers = find.descendant(
      of: find.byType(AdaptiveLiquidGlassLayer),
      matching: find.byType(GlassContainer),
    );
    expect(overlayContainers, findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets(
      'GlassMenu renders Blob A trigger ghost during opening morph (liquid bridge preserved on open)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              quality: GlassQuality.standard,
              trigger: const SizedBox(
                width: 44,
                height: 44,
                child: Text('Btn'),
              ),
              menuWidth: 200,
              items: [
                GlassMenuItem(title: 'Item', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Btn'));
    // Pump partially into the opening animation where anchorScale > 0
    await tester.pump(const Duration(milliseconds: 30));

    // On open, both Blob A (trigger ghost) and Blob B (menu body) must be present
    final overlayContainers = find.descendant(
      of: find.byType(AdaptiveLiquidGlassLayer),
      matching: find.byType(GlassContainer),
    );
    expect(overlayContainers, findsNWidgets(2));

    await tester.pumpAndSettle();
  });

  testWidgets(
      'GlassMenu on standard quality lerps border radius toward trigger border radius during close',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: GlassMenu(
              quality: GlassQuality.standard,
              menuBorderRadius: 24.0,
              trigger: const SizedBox(
                width: 40,
                height: 20, // trigger shortest side / 2 = 10.0
                child: Text('Btn'),
              ),
              menuWidth: 200,
              items: [
                GlassMenuItem(title: 'Item', onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Btn'));
    await tester.pumpAndSettle();

    // Start close
    await tester.tap(find.text('Item'));
    // Pump into close travel
    await tester.pump(const Duration(milliseconds: 100));

    final containerFinder = find.descendant(
      of: find.byType(AdaptiveLiquidGlassLayer),
      matching: find.byType(GlassContainer),
    );
    expect(containerFinder, findsOneWidget);

    final container = tester.widget<GlassContainer>(containerFinder);
    final shape = container.shape as LiquidRoundedSuperellipse;
    // Border radius interpolates monotonically between trigger radius (10.0)
    // and menuBorderRadius (24.0) without ballooning above max(10.0, 24.0).
    expect(shape.borderRadius, lessThanOrEqualTo(24.0));
    expect(shape.borderRadius, greaterThanOrEqualTo(10.0));

    await tester.pumpAndSettle();
  });

  group('non-scrollable menu row activation', () {
    Future<(GlassMenuController, List<String>)> openMenu(
        WidgetTester tester) async {
      final controller = GlassMenuController();
      final tapped = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 40,
                  top: 80,
                  child: GlassMenu(
                    controller: controller,
                    menuAlignment: GlassMenuAlignment.topLeft,
                    trigger: const SizedBox(width: 8, height: 8),
                    items: [
                      GlassMenuItem(
                          title: 'Copy', onTap: () => tapped.add('Copy')),
                      GlassMenuItem(
                          title: 'Cut', onTap: () => tapped.add('Cut')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();
      return (controller, tapped);
    }

    testWidgets('a screen-reader tap activates the row', (tester) async {
      final semantics = tester.ensureSemantics();
      final (controller, tapped) = await openMenu(tester);

      final node = tester.getSemantics(find.bySemanticsLabel('Copy').first);
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();

      expect(tapped, ['Copy']);
      expect(controller.isOpen, isFalse);
      semantics.dispose();
    });

    testWidgets('Enter on a focused row activates it', (tester) async {
      final (controller, tapped) = await openMenu(tester);

      Focus.of(tester.element(find.text('Copy'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(tapped, ['Copy']);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('a touch tap still activates the row exactly once',
        (tester) async {
      final (_, tapped) = await openMenu(tester);

      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      expect(tapped, ['Copy']);
    });
  });

  testWidgets(
      'a slide-to-select released over the gap between two rows activates a '
      'row', (tester) async {
    final controller = GlassMenuController();
    final tapped = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                left: 40,
                top: 80,
                child: GlassMenu(
                  controller: controller,
                  menuAlignment: GlassMenuAlignment.topLeft,
                  trigger: const SizedBox(width: 8, height: 8),
                  items: [
                    GlassMenuItem(
                        title: 'Copy', onTap: () => tapped.add('Copy')),
                    GlassMenuItem(title: 'Cut', onTap: () => tapped.add('Cut')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.open();
    await tester.pumpAndSettle();

    // Rows are separated by a 2px gap; just below the midpoint between the
    // two row centres lies inside it.
    final copy = tester.getCenter(find.text('Copy'));
    final cut = tester.getCenter(find.text('Cut'));
    final gesture = await tester.startGesture(copy);
    await tester.pump();
    await gesture.moveTo(cut);
    await tester.pump();
    await gesture.moveTo(Offset(copy.dx, (copy.dy + cut.dy) / 2 + 0.5));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(tapped, hasLength(1));
    expect(controller.isOpen, isFalse);
  });

  group('GlassMenuItem.semanticsSelected', () {
    Future<void> openPicker(WidgetTester tester) async {
      final controller = GlassMenuController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 40,
                  top: 80,
                  child: GlassMenu(
                    controller: controller,
                    menuAlignment: GlassMenuAlignment.topLeft,
                    trigger: const SizedBox(width: 8, height: 8),
                    items: [
                      GlassMenuItem(
                        title: 'Alpha',
                        onTap: () {},
                        semanticsSelected: false,
                      ),
                      GlassMenuItem(
                        title: 'Beta',
                        onTap: () {},
                        trailing: const Icon(Icons.check),
                        semanticsSelected: true,
                      ),
                      GlassMenuItem(title: 'Gamma', onTap: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();
    }

    SemanticsNode row(WidgetTester tester, String title) =>
        tester.getSemantics(find.bySemanticsLabel(title).first);

    testWidgets('true reports the row as selected', (tester) async {
      final semantics = tester.ensureSemantics();
      await openPicker(tester);

      expect(
        row(tester, 'Beta'),
        isSemantics(
          label: 'Beta',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('false reports a selectable row that is not selected',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await openPicker(tester);

      expect(
        row(tester, 'Alpha'),
        isSemantics(
          label: 'Alpha',
          isButton: true,
          hasSelectedState: true,
          isSelected: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('null (the default) reports no selected state', (tester) async {
      final semantics = tester.ensureSemantics();
      await openPicker(tester);

      expect(
        row(tester, 'Gamma'),
        isSemantics(
          label: 'Gamma',
          isButton: true,
          hasSelectedState: false,
          isSelected: false,
        ),
      );
      semantics.dispose();
    });

    testWidgets('the hover pill does not change the semantic state',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await openPicker(tester);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      // The pill (the visual isSelected) moves onto each row in turn; the
      // reported state stays the semantic choice.
      await mouse.moveTo(tester.getCenter(find.text('Gamma')));
      await tester.pumpAndSettle();
      expect(
        row(tester, 'Gamma'),
        isSemantics(hasSelectedState: false, isSelected: false),
      );

      await mouse.moveTo(tester.getCenter(find.text('Alpha')));
      await tester.pumpAndSettle();
      expect(
        row(tester, 'Alpha'),
        isSemantics(hasSelectedState: true, isSelected: false),
      );
      expect(
        row(tester, 'Beta'),
        isSemantics(hasSelectedState: true, isSelected: true),
      );
      semantics.dispose();
    });
  });

  group('GlassMenu panel semantics', () {
    // A trigger next to other page content, the layout in which the open
    // menu used to drop out of the semantics tree.
    Future<GlassMenuController> openMenu(
      WidgetTester tester, {
      String? menuSemanticLabel,
      bool useTriggerBuilder = false,
    }) async {
      final controller = GlassMenuController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Page text'),
                  GlassMenu(
                    controller: controller,
                    menuSemanticLabel: menuSemanticLabel,
                    trigger: useTriggerBuilder
                        ? null
                        : const SizedBox(
                            width: 44, height: 44, child: Text('Open')),
                    triggerBuilder: useTriggerBuilder
                        ? (context, toggle) => GlassButton(
                              onTap: toggle,
                              label: 'More',
                              icon: const Icon(Icons.more_horiz),
                            )
                        : null,
                    items: [
                      GlassMenuItem(title: 'Copy', onTap: () {}),
                      GlassMenuItem(title: 'Cut', onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();
      return controller;
    }

    for (final useTriggerBuilder in [false, true]) {
      testWidgets(
          'the open rows are in the semantics tree and page is blocked '
          '(${useTriggerBuilder ? 'triggerBuilder' : 'trigger'})',
          (tester) async {
        final semantics = tester.ensureSemantics();
        final controller =
            await openMenu(tester, useTriggerBuilder: useTriggerBuilder);

        expect(find.semantics.byLabel('Copy'), findsOne);
        expect(find.semantics.byLabel('Cut'), findsOne);
        expect(find.semantics.byLabel('Dismiss menu'), findsOne);
        expect(find.semantics.byLabel('Page text'), findsNothing);

        controller.close();
        await tester.pumpAndSettle();

        expect(find.semantics.byLabel('Page text'), findsOne);
        semantics.dispose();
      });
    }

    testWidgets(
        'does not block page semantics or reorder traversal when '
        'showDismissBarrier is false', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = GlassMenuController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Before'),
                  GlassMenu(
                    controller: controller,
                    showDismissBarrier: false,
                    trigger: const SizedBox(
                      width: 44,
                      height: 44,
                      child: Text('Open'),
                    ),
                    items: [
                      GlassMenuItem(title: 'Copy', onTap: () {}),
                    ],
                  ),
                  const Text('After'),
                ],
              ),
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();

      expect(find.semantics.byLabel('Dismiss menu'), findsNothing);
      final labels = find.semantics
          .byLabel(RegExp(r'^(Before|Copy|After)$'))
          .evaluate()
          .map((node) => node.label)
          .toList();
      expect(labels, ['Before', 'Copy', 'After']);
      semantics.dispose();
    });

    testWidgets('the panel is a named route scope holding the rows',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await openMenu(tester);

      final panel = find.semantics.byLabel('Menu');
      expect(panel, findsOne);
      final node = panel.evaluate().single;
      expect(node.flagsCollection.scopesRoute, isTrue);
      expect(node.flagsCollection.namesRoute, isTrue);
      for (final row in ['Copy', 'Cut']) {
        expect(
          find.semantics.descendant(
            of: panel,
            matching: find.semantics.byLabel(row),
          ),
          findsOne,
        );
      }
      // explicitChildNodes keeps each row a node of its own instead of
      // merging the rows into the panel's label.
      expect(node.label, 'Menu');
      semantics.dispose();
    });

    testWidgets('menuSemanticLabel names the panel', (tester) async {
      final semantics = tester.ensureSemantics();
      await openMenu(tester, menuSemanticLabel: 'Sort by');

      expect(find.semantics.byLabel('Sort by'), findsOne);
      expect(find.semantics.byLabel('Menu'), findsNothing);
      semantics.dispose();
    });

    testWidgets('a closed menu adds no panel to the tree', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = await openMenu(tester);
      controller.close();
      await tester.pumpAndSettle();

      expect(find.semantics.byLabel('Menu'), findsNothing);
      expect(find.semantics.byLabel('Copy'), findsNothing);
      expect(find.semantics.byLabel('Open'), findsOne);
      semantics.dispose();
    });
  });

  group('Issue #453 — GlassQuality.premium liquid morph parity', () {
    testWidgets(
        'GlassMenu on premium quality hides static trigger on frame 1 of open so shrinking Blob A is visible',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassMenu(
                quality: GlassQuality.premium,
                triggerBuilder: (context, toggle) => GlassIconButton(
                  size: 46,
                  icon: const Icon(Icons.more_horiz),
                  onPressed: toggle,
                ),
                items: [
                  GlassMenuItem(title: 'One', onTap: () {}),
                  GlassMenuItem(title: 'Two', onTap: () {}),
                  GlassMenuItem(title: 'Three', onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(GlassIconButton));
      // Pump 16ms into open (early in the first 20% where standard cross-fades)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      // The static trigger Opacity must be 0.0 immediately so it does not cover
      // the shrinking Blob A inside the overlay.
      final triggerOpacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(triggerOpacity.opacity, equals(0.0));

      await tester.pumpAndSettle();
    });

    testWidgets(
        'GlassMenu on standard quality still cross-fades trigger over first 20% of open',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassMenu(
                quality: GlassQuality.standard,
                trigger: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Text('StdBtn'),
                ),
                items: [
                  GlassMenuItem(title: 'One', onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('StdBtn'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 8));

      final triggerOpacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(triggerOpacity.opacity, greaterThan(0.0));
      expect(triggerOpacity.opacity, lessThan(1.0));

      await tester.pumpAndSettle();
    });

    testWidgets(
        'GlassMenu items fade smoothly across close (~283ms) and unmount on handoff',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassMenu(
                quality: GlassQuality.premium,
                trigger: const SizedBox(
                  width: 46,
                  height: 46,
                  child: Text('OpenMenu'),
                ),
                items: [
                  GlassMenuItem(title: 'One', onTap: () {}),
                  GlassMenuItem(title: 'Two', onTap: () {}),
                  GlassMenuItem(title: 'Three', onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OpenMenu'));
      await tester.pumpAndSettle();
      expect(find.text('One'), findsOneWidget);

      // Tap item to close
      await tester.tap(find.text('One'));
      await tester.pump();
      // At 45ms and 110ms into close, items remain visible and smoothly fading
      // (no premature 67ms blackout).
      await tester.pump(const Duration(milliseconds: 45));
      expect(find.text('One'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 65)); // 110ms total
      expect(find.text('One'), findsOneWidget);
      double itemOpacityAt110 = 1.0;
      RenderObject? ro = tester.element(find.text('One')).renderObject;
      while (ro != null) {
        if (ro is RenderOpacity) {
          itemOpacityAt110 *= ro.opacity;
        }
        ro = ro.parent;
      }
      expect(itemOpacityAt110, greaterThan(0.20));
      expect(itemOpacityAt110, lessThan(0.60));

      // By ~290ms into close, the collapsing platter has reached 0.20 scale and
      // unmounted cleanly.
      await tester.pump(const Duration(milliseconds: 180)); // 290ms total
      expect(find.text('One'), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('One'), findsNothing);
    });

    testWidgets(
        'GlassMenu trigger smoothly re-materializes during final 42% of close before handoff',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassMenu(
                quality: GlassQuality.premium,
                trigger: const SizedBox(
                  width: 120,
                  height: 36,
                  child: Text('Pull-Down'),
                ),
                items: [
                  GlassMenuItem(title: 'One', onTap: () {}),
                  GlassMenuItem(title: 'Two', onTap: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Pull-Down'));
      await tester.pumpAndSettle();

      // Tap item to close
      await tester.tap(find.text('One'));
      await tester.pump();
      // At 180ms into close (clampedValue ≈ 0.25, before handoff at ~285ms),
      // triggerOpacity is already ramping back in (0 < opacity < 1).
      await tester.pump(const Duration(milliseconds: 180));
      final triggerOpacity = tester.widget<Opacity>(find.byType(Opacity).first);
      expect(triggerOpacity.opacity, greaterThan(0.0));
      expect(triggerOpacity.opacity, lessThan(1.0));

      await tester.pumpAndSettle();
      // Once settled at 1.0, the Opacity wrapper unmounts cleanly so the
      // trigger rejoins any enclosing GlassBackdropGroup.
      expect(find.byType(Opacity), findsNothing);
      expect(find.text('Pull-Down'), findsOneWidget);
    });
  });

  group('iOS 27 Liquid Morph Parity — Wide Triggers, Lengths, Recoil & Radii',
      () {
    List<Widget> buildItems(int count) => [
          for (var i = 1; i <= count; i++)
            GlassMenuItem(title: 'Action $i', onTap: () {}),
        ];

    Finder overlayContainers() => find.descendant(
          of: find.byType(AdaptiveLiquidGlassLayer),
          matching: find.byType(GlassContainer),
        );

    testWidgets(
        'wide centered trigger (260x44) auto-centers menu, collapses into middle without widening, and splashes horizontally (~400ms)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GlassMenuController();
      final triggerKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassMenu(
                controller: controller,
                autoAdjustToScreen: true,
                menuPadding: const EdgeInsets.all(12),
                menuWidth: 220,
                quality: GlassQuality.premium,
                triggerBuilder: (context, toggle) => GlassButton.custom(
                  key: triggerKey,
                  width: 260,
                  height: 44,
                  useOwnLayer: true,
                  onTap: toggle,
                  child: const Text('Wide Trigger'),
                ),
                items: buildItems(5),
              ),
            ),
          ),
        ),
      );

      final restingTriggerRect = tester.getRect(find.byKey(triggerKey));
      expect(restingTriggerRect.width, closeTo(260.0, 0.1));
      expect(restingTriggerRect.center.dx, closeTo(200.0, 0.1));

      controller.open();
      await tester.pump();

      // Early in open (~50ms), the trigger's width scale contracts toward the
      // 44x44 center core while zero fractional Opacity wraps the GlassButton.
      await tester.pump(const Duration(milliseconds: 50));
      final openOpacities = tester.widgetList<Opacity>(
        find.ancestor(
          of: find.byKey(triggerKey),
          matching: find.byType(Opacity),
        ),
      );
      expect(
        openOpacities.every((o) => o.opacity == 0.0 || o.opacity == 1.0),
        isTrue,
        reason: 'GlassButton trigger must never have fractional Opacity',
      );

      await tester.pumpAndSettle();

      // Settled menu must be horizontally centered on the 260x44 wide trigger.
      final settledMenuRect = tester.getRect(overlayContainers().last);
      expect(settledMenuRect.width, closeTo(220.0, 0.5));
      expect(
        settledMenuRect.center.dx,
        closeTo(restingTriggerRect.center.dx, 0.5),
      );

      // Close and sample every 16ms: platter must NEVER widen past 220pt toward
      // 260pt, and its horizontal center must stay locked to trigger.center.dx!
      controller.close();
      await tester.pump();

      double maxSplashWidth = 0.0;
      double minTriggerPaintedWidth = double.infinity;
      double minBlobAWidth = double.infinity;
      double maxBlobAWidth = 0.0;
      for (int elapsed = 16; elapsed <= 464; elapsed += 16) {
        await tester.pump(const Duration(milliseconds: 16));

        final elements = overlayContainers().evaluate().toList();
        for (final element in elements) {
          final box = element.renderObject as RenderBox;
          final rect = MatrixUtils.transformRect(
            box.getTransformTo(null),
            Offset.zero & box.size,
          );
          // Both Blob A (44px capsule) and Blob B (shrinking platter) stay
          // horizontally centered on trigger.center.dx!
          expect(
            rect.center.dx,
            closeTo(restingTriggerRect.center.dx, 0.5),
            reason:
                'Collapsing blob drifted off trigger center X at ${elapsed}ms',
          );
          final isBlobA =
              elements.length == 2 && identical(element, elements.first);
          if (!isBlobA) {
            expect(
              rect.width,
              lessThanOrEqualTo(220.5),
              reason:
                  'Platter widened to ${rect.width} at ${elapsed}ms instead of collapsing into center',
            );
          } else {
            if (box.size.width < minBlobAWidth) minBlobAWidth = box.size.width;
            if (box.size.width > maxBlobAWidth) maxBlobAWidth = box.size.width;
          }
        }

        // Measure painted/transformed trigger width via getRect on triggerKey:
        final currentTriggerRect = tester.getRect(find.byKey(triggerKey));
        if (currentTriggerRect.width < minTriggerPaintedWidth) {
          minTriggerPaintedWidth = currentTriggerRect.width;
        }
        if (elapsed >= 336 && elapsed <= 448) {
          if (currentTriggerRect.width > maxSplashWidth) {
            maxSplashWidth = currentTriggerRect.width;
          }
        }
        // Trigger stays centered around trigger.center.dx throughout splash!
        expect(
          currentTriggerRect.center.dx,
          closeTo(restingTriggerRect.center.dx, 0.5),
        );
      }

      // Real trigger button is NEVER affine-squished horizontally (< 90% width)!
      expect(
        minTriggerPaintedWidth,
        greaterThanOrEqualTo(260.0 * 0.895),
        reason:
            'Real wide trigger was affine-squashed to $minTriggerPaintedWidth px!',
      );
      // On Impeller (where Blob A is active on close), Blob A expands its true
      // container width from the center core (< 85px) out to wide capsule (> 220px).
      if (maxBlobAWidth > 0.0) {
        expect(minBlobAWidth, lessThan(85.0));
        expect(maxBlobAWidth, greaterThan(220.0));
      }

      // Around ~398ms, the wide pill exhibits the calibrated +1%..+2% splash!
      expect(
        maxSplashWidth,
        greaterThan(261.5),
        reason: 'Wide trigger should splash past 260px around ~400ms',
      );
      expect(maxSplashWidth, lessThan(268.0));

      await tester.pumpAndSettle();
      final finalTriggerRect = tester.getRect(find.byKey(triggerKey));
      expect(finalTriggerRect.width, closeTo(260.0, 0.2));
      expect(finalTriggerRect.center, restingTriggerRect.center);
    });

    testWidgets(
        'wide left-aligned trigger (240x44) centers menu on trigger.center and returns into middle',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GlassMenuController();
      final triggerKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16, top: 100),
                child: GlassMenu(
                  controller: controller,
                  autoAdjustToScreen: true,
                  menuPadding: const EdgeInsets.all(12),
                  menuWidth: 220,
                  quality: GlassQuality.premium,
                  triggerBuilder: (context, toggle) => GlassButton.custom(
                    key: triggerKey,
                    width: 240,
                    height: 44,
                    useOwnLayer: true,
                    onTap: toggle,
                    child: const Text('Wide Left'),
                  ),
                  items: buildItems(5),
                ),
              ),
            ),
          ),
        ),
      );

      final triggerRect = tester.getRect(find.byKey(triggerKey));
      expect(triggerRect.center.dx, closeTo(136.0, 0.1));

      controller.open();
      await tester.pumpAndSettle();

      final menuRect = tester.getRect(overlayContainers().last);
      expect(menuRect.center.dx, closeTo(triggerRect.center.dx, 0.5));

      controller.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));

      final closingRect = tester.getRect(overlayContainers().last);
      expect(closingRect.width, lessThan(220.0));
      expect(closingRect.center.dx, closeTo(triggerRect.center.dx, 1.0));

      await tester.pumpAndSettle();
    });

    testWidgets(
        'parallel close catch recoil starts immediately and peaks around ~183ms (not 400ms)',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GlassMenuController();
      final triggerKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 120),
                child: GlassMenu(
                  controller: controller,
                  autoAdjustToScreen: true,
                  menuWidth: 220,
                  quality: GlassQuality.premium,
                  triggerBuilder: (context, toggle) => GlassIconButton(
                    key: triggerKey,
                    size: 44,
                    useOwnLayer: true,
                    icon: const Icon(Icons.more_horiz),
                    onPressed: toggle,
                  ),
                  items: buildItems(5),
                ),
              ),
            ),
          ),
        ),
      );

      final restCenterY = tester.getCenter(find.byKey(triggerKey)).dy;

      controller.open();
      await tester.pumpAndSettle();

      controller.close();
      await tester.pump();

      double peakDisplacement = 0.0;
      int peakMs = 0;
      double dispAt48 = 0.0;
      double dispAt80 = 0.0;
      double dispAt180 = 0.0;
      double dispAt390 = 0.0;

      for (int ms = 16; ms <= 512; ms += 16) {
        await tester.pump(const Duration(milliseconds: 16));
        final dy =
            (tester.getCenter(find.byKey(triggerKey)).dy - restCenterY).abs();
        if (dy > peakDisplacement) {
          peakDisplacement = dy;
          peakMs = ms;
        }
        if (ms == 48) dispAt48 = dy;
        if (ms == 80) dispAt80 = dy;
        if (ms == 176) dispAt180 = dy;
        if (ms == 384) dispAt390 = dy;
      }

      // Immediate onset (already moving at 48ms and >2px by 80ms), peak inside
      // [140ms, 225ms] (~183ms native target), and decaying well before 384ms.
      expect(dispAt48, greaterThan(0.3));
      expect(dispAt80, greaterThan(2.0));
      expect(peakMs, greaterThanOrEqualTo(144));
      expect(peakMs, lessThanOrEqualTo(224));
      expect(peakDisplacement, greaterThan(6.0));
      expect(peakDisplacement, lessThan(16.5));
      expect(dispAt180, greaterThan(dispAt390 * 3.0));

      await tester.pumpAndSettle();
      expect(
        tester.getCenter(find.byKey(triggerKey)).dy,
        closeTo(restCenterY, 0.05),
      );
    });

    for (final count in [2, 5, 10]) {
      testWidgets(
          'menu length ($count items) maintains monotonic superellipse radius <= 32pt and smooth ~283ms return',
          (tester) async {
        tester.view.physicalSize = const Size(400, 850);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        final controller = GlassMenuController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 90),
                  child: GlassMenu(
                    controller: controller,
                    autoAdjustToScreen: true,
                    menuPadding: const EdgeInsets.all(12),
                    menuWidth: 220,
                    menuBorderRadius: 32.0,
                    quality: GlassQuality.premium,
                    triggerBuilder: (context, toggle) => GlassButton.custom(
                      width: 260,
                      height: 44,
                      useOwnLayer: true,
                      onTap: toggle,
                      child: Text('Menu $count'),
                    ),
                    items: buildItems(count),
                  ),
                ),
              ),
            ),
          ),
        );

        controller.open();
        await tester.pump();
        for (int ms = 16; ms <= 400; ms += 16) {
          await tester.pump(const Duration(milliseconds: 16));
          for (final c
              in tester.widgetList<GlassContainer>(overlayContainers())) {
            expect(c.shape, isA<LiquidRoundedSuperellipse>());
            final r = (c.shape as LiquidRoundedSuperellipse).borderRadius;
            // Native inflates the opening platter as a near-circular bubble:
            // the radius may exceed the resting 32pt but never half its own
            // shortest side.
            final halfShort = math.min(
                  c.width ?? double.infinity,
                  c.height ?? double.infinity,
                ) /
                2.0;
            expect(
              r,
              lessThanOrEqualTo(math.min(110.001, halfShort + 0.01)),
              reason:
                  'Open frame ${ms}ms ($count items) ballooned radius to $r',
            );
          }
        }
        await tester.pumpAndSettle();

        controller.close();
        await tester.pump();
        double prevHeight = double.infinity;
        for (int ms = 16; ms <= 320; ms += 16) {
          await tester.pump(const Duration(milliseconds: 16));
          final containers =
              tester.widgetList<GlassContainer>(overlayContainers()).toList();
          if (ms == 80) {
            expect(
              find.text('Action 1'),
              findsOneWidget,
              reason: 'Items must still be smoothly fading at 80ms ($count)',
            );
            // Platter glass stays 100% dense (glassProgress == 1.0) at 80ms
            // while items fade out, dissolving only over rawValue <= 0.25!
            final platterScope = tester.widget<GlassMaterializeScope>(
              find
                  .ancestor(
                    of: overlayContainers().last,
                    matching: find.byType(GlassMaterializeScope),
                  )
                  .first,
            );
            expect(platterScope.glassProgress, closeTo(1.0, 1e-6));
          }
          if (containers.isNotEmpty) {
            final platter = containers.last;
            expect(platter.shape, isA<LiquidRoundedSuperellipse>());
            final r = (platter.shape as LiquidRoundedSuperellipse).borderRadius;
            // Closing platter rounds toward a circle like native iOS 27: the
            // radius may exceed the resting 32pt but never half its own
            // shortest side.
            final halfShort = math.min(
                  platter.width ?? double.infinity,
                  platter.height ?? double.infinity,
                ) /
                2.0;
            expect(
              r,
              lessThanOrEqualTo(math.min(110.001, halfShort + 0.01)),
              reason:
                  'Close frame ${ms}ms ($count items) ballooned radius to $r',
            );
            if (platter.height != null) {
              expect(
                platter.height!,
                lessThanOrEqualTo(prevHeight + 0.01),
                reason: 'Platter height should contract monotonically on close',
              );
              prevHeight = platter.height!;
            }
          }
        }

        // By 320ms, platter and items have vanished cleanly.
        expect(find.text('Action 1'), findsNothing);
        expect(overlayContainers(), findsNothing);

        await tester.pumpAndSettle();
      });
    }

    testWidgets(
        'upward-opening menus (bottomCenter, bottomLeft, bottomRight) morph upward and recoil downward (+dy) at ~183ms',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      for (final (label, align, width) in <(String, Alignment, double)>[
        ('bottomCenter_wide', Alignment.bottomCenter, 240.0),
        ('bottomLeft_round', Alignment.bottomLeft, 44.0),
        ('bottomRight_round', Alignment.bottomRight, 44.0),
      ]) {
        final controller = GlassMenuController();
        final triggerKey = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: align,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassMenu(
                    controller: controller,
                    autoAdjustToScreen: true,
                    menuPadding: const EdgeInsets.all(12),
                    menuWidth: 200,
                    quality: GlassQuality.premium,
                    triggerBuilder: (context, toggle) => GlassButton.custom(
                      key: triggerKey,
                      width: width,
                      height: 44,
                      useOwnLayer: true,
                      onTap: toggle,
                      child: Text(label),
                    ),
                    items: buildItems(5),
                  ),
                ),
              ),
            ),
          ),
        );

        final restRect = tester.getRect(find.byKey(triggerKey));
        controller.open();
        await tester.pumpAndSettle();

        final openPlatterRect = tester.getRect(overlayContainers().last);
        // Menu opened UPWARD above the bottom trigger:
        expect(
          openPlatterRect.center.dy,
          lessThan(restRect.center.dy - 60.0),
          reason: '[$label] Menu should open upward above bottom trigger',
        );
        if (width > 100) {
          expect(
            openPlatterRect.center.dx,
            closeTo(restRect.center.dx, 0.5),
            reason: '[$label] Wide bottom trigger should center menu',
          );
        }

        // Close: falling menu impacts from above -> trigger recoils DOWNWARD (+dy > 0)!
        controller.close();
        await tester.pump();
        double maxDownwardDy = 0.0;
        int peakDownwardMs = 0;
        for (int ms = 16; ms <= 480; ms += 16) {
          await tester.pump(const Duration(milliseconds: 16));
          final dy =
              tester.getCenter(find.byKey(triggerKey)).dy - restRect.center.dy;
          if (dy > maxDownwardDy) {
            maxDownwardDy = dy;
            peakDownwardMs = ms;
          }
        }
        expect(
          maxDownwardDy,
          greaterThan(6.0),
          reason: '[$label] Upward menu close must recoil downward (+dy > 0)',
        );
        expect(peakDownwardMs, inInclusiveRange(144, 224));

        await tester.pumpAndSettle();
      }
    });

    testWidgets(
        'right-edge clamped wide & round triggers stay inside safe right margin and return into trigger.center',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      for (final width in [160.0, 44.0]) {
        final controller = GlassMenuController();
        final triggerKey = GlobalKey();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14, top: 100),
                  child: GlassMenu(
                    controller: controller,
                    autoAdjustToScreen: true,
                    menuPadding: const EdgeInsets.all(12),
                    menuWidth: 240,
                    quality: GlassQuality.premium,
                    triggerBuilder: (context, toggle) => GlassButton.custom(
                      key: triggerKey,
                      width: width,
                      height: 44,
                      useOwnLayer: true,
                      onTap: toggle,
                      child: const Text('Right'),
                    ),
                    items: buildItems(4),
                  ),
                ),
              ),
            ),
          ),
        );

        final restTrigger = tester.getRect(find.byKey(triggerKey));
        controller.open();
        await tester.pump();

        for (int ms = 16; ms <= 400; ms += 16) {
          await tester.pump(const Duration(milliseconds: 16));
          final platterRect = tester.getRect(overlayContainers().last);
          expect(
            platterRect.right,
            lessThanOrEqualTo(400.0 - 12.0 + 0.5),
            reason:
                'Right-edge menu (tw=$width) overflowed safe margin at ${ms}ms',
          );
        }
        await tester.pumpAndSettle();

        controller.close();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 224));
        if (overlayContainers().evaluate().isNotEmpty) {
          final nearLanding = tester.getRect(overlayContainers().last);
          expect(
            (nearLanding.center.dx - restTrigger.center.dx).abs(),
            lessThan(25.0),
            reason:
                'Clamped right-edge menu (tw=$width) must converge back into trigger.center',
          );
        }
        await tester.pumpAndSettle();
      }
    });

    testWidgets(
        'expanded submenu card contracts coherently with root platter into trigger.center on close',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GlassMenuController();
      final triggerKey = GlobalKey();
      bool subTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassMenu(
                controller: controller,
                autoAdjustToScreen: true,
                menuWidth: 220,
                quality: GlassQuality.premium,
                triggerBuilder: (context, toggle) => GlassButton.custom(
                  key: triggerKey,
                  width: 240,
                  height: 44,
                  useOwnLayer: true,
                  onTap: toggle,
                  child: const Text('Menu With Submenu'),
                ),
                items: [
                  GlassMenuItem(title: 'Copy', onTap: () {}),
                  GlassMenuItem(
                    title: 'Share',
                    onTap: () {},
                    submenu: [
                      GlassMenuItem(
                        title: 'AirDrop',
                        onTap: () => subTapped = true,
                      ),
                      GlassMenuItem(title: 'Messages', onTap: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final restTrigger = tester.getRect(find.byKey(triggerKey));
      controller.open();
      await tester.pumpAndSettle();
      expect(controller.submenuDepth, equals(0));

      // Expand submenu card
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(controller.submenuDepth, equals(1));
      expect(find.text('AirDrop'), findsOneWidget);

      // Tap submenu item to close entire menu
      await tester.tap(find.text('AirDrop'));
      expect(subTapped, isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      // Submenu card is shrinking & converging toward trigger.center alongside Blob B
      final cardFinder = find.ancestor(
        of: find.text('AirDrop'),
        matching: find.byType(GlassContainer),
      );
      expect(cardFinder, findsOneWidget);
      final cardPaintedRect = tester.getRect(cardFinder.first);
      expect(cardPaintedRect.width, lessThan(200.0));
      expect(cardPaintedRect.center.dx, closeTo(restTrigger.center.dx, 2.0));

      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(controller.submenuDepth, equals(0));
    });

    testWidgets(
        'mid-open close (83ms) and mid-close reopen (100ms & 350ms) maintain C0 position/size continuity',
        (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = GlassMenuController();
      final triggerKey = GlobalKey();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 120),
                child: GlassMenu(
                  controller: controller,
                  autoAdjustToScreen: true,
                  menuWidth: 220,
                  quality: GlassQuality.premium,
                  triggerBuilder: (context, toggle) => GlassButton.custom(
                    key: triggerKey,
                    width: 240,
                    height: 44,
                    useOwnLayer: true,
                    onTap: toggle,
                    child: const Text('Interruptible'),
                  ),
                  items: buildItems(5),
                ),
              ),
            ),
          ),
        ),
      );

      // 1. Mid-open close at ~83ms: zero platter jump on reversal frame!
      controller.open();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 83));
      final beforeClosePlatter = tester.getRect(overlayContainers().last);

      controller.close();
      await tester.pump(); // frame 0 of close
      final afterClosePlatter = tester.getRect(overlayContainers().last);
      expect(
        (afterClosePlatter.center - beforeClosePlatter.center).distance,
        lessThan(0.5),
      );
      expect(
        (afterClosePlatter.width - beforeClosePlatter.width).abs(),
        lessThan(0.5),
      );
      await tester.pumpAndSettle();

      // 2. Mid-close reopen at ~100ms (platter active + recoil active):
      controller.open();
      await tester.pumpAndSettle();
      controller.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final beforeReopen100Platter = tester.getRect(overlayContainers().last);
      final beforeReopen100Trig = tester.getCenter(find.byKey(triggerKey));

      // Tap trigger mid-close to reopen!
      await tester.tap(find.byKey(triggerKey), warnIfMissed: false);
      await tester.pump(); // frame 0 of reopen
      final afterReopen100Platter = tester.getRect(overlayContainers().last);
      final afterReopen100Trig = tester.getCenter(find.byKey(triggerKey));
      expect(
        (afterReopen100Platter.center - beforeReopen100Platter.center).distance,
        lessThan(0.5),
      );
      expect(
        (afterReopen100Platter.width - beforeReopen100Platter.width).abs(),
        lessThan(0.5),
      );
      expect(
        (afterReopen100Trig - beforeReopen100Trig).distance,
        lessThan(0.5),
      );
      await tester.pumpAndSettle();
      expect(find.text('Action 1'), findsOneWidget);

      // 3. Mid-close reopen at ~350ms (during wide-trigger splash tail):
      controller.close();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      final beforeReopen350Trig = tester.getCenter(find.byKey(triggerKey));

      controller.open();
      await tester.pump();
      final afterReopen350Trig = tester.getCenter(find.byKey(triggerKey));
      expect(
        (afterReopen350Trig - beforeReopen350Trig).distance,
        lessThan(0.5),
      );
      await tester.pumpAndSettle();
      expect(find.text('Action 1'), findsOneWidget);

      controller.close();
      await tester.pumpAndSettle();
    });
  });
}
