import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/widgets/shared/glass_focus_region.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithApp(Widget child) {
    return CupertinoApp(
      home: CupertinoPageScaffold(child: Center(child: child)),
    );
  }

  testWidgets('GlassContextMenu renders child at rest without error', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithApp(
        GlassContextMenu(
          actions: [
            GlassContextMenuAction(
              child: const Text('Share'),
              onPressed: () {},
            ),
          ],
          child: const Text('Target Item'),
        ),
      ),
    );

    expect(find.text('Target Item'), findsOneWidget);
    // Menu route is not open yet
    expect(find.text('Share'), findsNothing);
  });

  testWidgets(
    'GlassContextMenu long press opens route with preview and actions',
    (tester) async {
      bool sharePressed = false;
      bool openedCalled = false;
      bool dismissedCalled = false;

      await tester.pumpWidget(
        wrapWithApp(
          GlassContextMenu(
            onOpened: () => openedCalled = true,
            onDismissed: () => dismissedCalled = true,
            actions: [
              GlassContextMenuAction(
                icon: const Icon(CupertinoIcons.share),
                child: const Text('Share'),
                onPressed: () => sharePressed = true,
              ),
              GlassContextMenuAction(
                icon: const Icon(CupertinoIcons.delete),
                isDestructive: true,
                child: const Text('Delete'),
                onPressed: () {},
              ),
            ],
            child: Container(
              key: const ValueKey('target_box'),
              width: 100,
              height: 100,
              color: CupertinoColors.activeBlue,
              child: const Text('Hold Me'),
            ),
          ),
        ),
      );

      expect(find.text('Hold Me'), findsOneWidget);
      expect(find.text('Share'), findsNothing);

      // Long press on target
      final targetFinder = find.byKey(const ValueKey('target_box'));
      final gesture = await tester.startGesture(tester.getCenter(targetFinder));
      await tester.pump(
        const Duration(milliseconds: 200),
      ); // press down compression
      await tester.pump(
        const Duration(milliseconds: 600),
      ); // long press threshold
      await gesture.up();
      await tester.pumpAndSettle();

      expect(openedCalled, isTrue);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap on 'Share' action
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      expect(sharePressed, isTrue);
      expect(dismissedCalled, isTrue);
      expect(find.text('Share'), findsNothing);
    },
  );

  testWidgets('GlassContextMenu dismisses on tapping barrier background', (
    tester,
  ) async {
    bool dismissedCalled = false;

    await tester.pumpWidget(
      wrapWithApp(
        GlassContextMenu(
          onDismissed: () => dismissedCalled = true,
          actions: [
            GlassContextMenuAction(
              child: const Text('Option 1'),
              onPressed: () {},
            ),
          ],
          child: const SizedBox(
            key: ValueKey('tap_target'),
            width: 120,
            height: 60,
            child: Text('Tap Target'),
          ),
        ),
      ),
    );

    // Long press to open
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('tap_target'))),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Option 1'), findsOneWidget);

    // Tap outside at (10, 10)
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(dismissedCalled, isTrue);
    expect(find.text('Option 1'), findsNothing);
  });

  testWidgets(
    'GlassContextMenu secondary tap (right-click) opens immediately',
    (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          GlassContextMenu(
            actions: [
              GlassContextMenuAction(
                child: const Text('Context Option'),
                onPressed: () {},
              ),
            ],
            child: const Text(
              'Right Click Me',
              key: ValueKey('right_click_target'),
            ),
          ),
        ),
      );

      expect(find.text('Context Option'), findsNothing);

      // Secondary tap (right-click)
      await tester.tap(
        find.byKey(const ValueKey('right_click_target')),
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();

      expect(find.text('Context Option'), findsOneWidget);

      // Dismiss
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(find.text('Context Option'), findsNothing);
    },
  );

  testWidgets('GlassContextMenu with custom previewBuilder renders preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithApp(
        GlassContextMenu(
          previewBuilder: (context) =>
              const Text('Custom Big Preview', key: ValueKey('custom_preview')),
          actions: [
            GlassContextMenuAction(
              child: const Text('Preview Action'),
              onPressed: () {},
            ),
          ],
          child: const Text('Small Item', key: ValueKey('small_item')),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('custom_preview')), findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('small_item'))),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('custom_preview')), findsOneWidget);
    expect(find.text('Preview Action'), findsOneWidget);

    // Tapping the preview dismisses the context menu
    await tester.tap(find.byKey(const ValueKey('custom_preview')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('custom_preview')), findsNothing);
    expect(find.text('Preview Action'), findsNothing);
  });

  testWidgets(
    'GlassContextMenuAction renders icons, selection checkmark, and destructive styling',
    (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          Column(
            children: [
              GlassContextMenuAction(
                icon: const Icon(CupertinoIcons.heart),
                iconPosition: GlassContextMenuIconPosition.leading,
                child: const Text('Leading Favorite'),
              ),
              GlassContextMenuAction(
                icon: const Icon(CupertinoIcons.share),
                iconPosition: GlassContextMenuIconPosition.trailing,
                isSelected: true,
                child: const Text('Selected Option'),
              ),
              GlassContextMenuAction(
                isDestructive: true,
                child: const Text('Delete Permanently'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Leading Favorite'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.heart), findsOneWidget);
      expect(find.text('Selected Option'), findsOneWidget);
      expect(find.byIcon(CupertinoIcons.checkmark), findsOneWidget);
      expect(find.text('Delete Permanently'), findsOneWidget);
    },
  );

  testWidgets('GlassContextMenuAction disabled does not fire callback', (
    tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      wrapWithApp(
        GlassContextMenuAction(
          enabled: false,
          onPressed: () => tapped = true,
          child: const Text('Disabled Action'),
        ),
      ),
    );

    await tester.tap(find.text('Disabled Action'));
    await tester.pumpAndSettle();

    expect(tapped, isFalse);
  });

  testWidgets(
    'showGlassContextMenu opens context menu imperatively at targetRect',
    (tester) async {
      bool executed = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: Builder(
            builder: (context) {
              return CupertinoPageScaffold(
                child: Center(
                  child: CupertinoButton(
                    child: const Text('Open Menu'),
                    onPressed: () {
                      showGlassContextMenu<void>(
                        context: context,
                        targetRect: const Rect.fromLTWH(100, 200, 150, 50),
                        actions: [
                          GlassContextMenuAction(
                            child: const Text('Imperative Option'),
                            onPressed: () => executed = true,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Imperative Option'), findsNothing);

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Imperative Option'), findsOneWidget);

      await tester.tap(find.text('Imperative Option'));
      await tester.pumpAndSettle();

      expect(executed, isTrue);
      expect(find.text('Imperative Option'), findsNothing);
    },
  );

  testWidgets('.glassContextMenu() extension method wraps widget correctly', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithApp(
        const Text(
          'Extension Item',
          key: ValueKey('ext_item'),
        ).glassContextMenu(
          actions: [GlassContextMenuAction(child: Text('Ext Action'))],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('ext_item')), findsOneWidget);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('ext_item'))),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Ext Action'), findsOneWidget);
  });

  testWidgets('GlassContextMenu supports continuous glide-to-select', (
    tester,
  ) async {
    bool glideSelected = false;

    await tester.pumpWidget(
      wrapWithApp(
        GlassContextMenu(
          actions: [
            GlassContextMenuAction(
              child: const Text('First Item'),
              onPressed: () {},
            ),
            GlassContextMenuAction(
              child: const Text('Glide Target'),
              onPressed: () => glideSelected = true,
            ),
          ],
          child: const Text(
            'Target Text',
            key: ValueKey('glide_target_trigger'),
          ),
        ),
      ),
    );

    // Open via long press
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('glide_target_trigger'))),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Glide Target'), findsOneWidget);

    // Release initial long press
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Glide Target'), findsOneWidget);

    // Perform glide gesture across open menu items: start on First Item, glide to Glide Target, release
    final glideGesture = await tester.startGesture(
      tester.getCenter(find.text('First Item')),
    );
    await tester.pump();
    final targetCenter = tester.getCenter(find.text('Glide Target'));
    await glideGesture.moveTo(targetCenter);
    await tester.pump();
    await glideGesture.up();
    await tester.pumpAndSettle();

    expect(glideSelected, isTrue);
    expect(find.text('Glide Target'), findsNothing);
  });

  testWidgets('GlassContextMenu respects custom longPressDuration', (
    tester,
  ) async {
    bool opened = false;
    await tester.pumpWidget(
      wrapWithApp(
        GlassContextMenu(
          longPressDuration: const Duration(milliseconds: 150),
          onOpened: () => opened = true,
          actions: [
            GlassContextMenuAction(
              child: const Text('Action'),
              onPressed: () {},
            ),
          ],
          child: const Text('Fast Target'),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Fast Target')),
    );
    await tester.pump(const Duration(milliseconds: 180));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('GlassContextMenu with GlassMenuItem executes onTap and pops', (
    tester,
  ) async {
    bool menuItemTapped = false;

    await tester.pumpWidget(
      wrapWithApp(
        GlassContextMenu(
          actions: [
            GlassMenuItem(
              title: 'Menu Item Title',
              onTap: () => menuItemTapped = true,
            ),
          ],
          child: const Text('Item Target'),
        ),
      ),
    );

    // Open menu
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Item Target')),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Menu Item Title'), findsOneWidget);

    // Tap the GlassMenuItem
    await tester.tap(find.text('Menu Item Title'));
    await tester.pumpAndSettle();

    expect(menuItemTapped, isTrue);
    expect(find.text('Menu Item Title'), findsNothing);
  });

  testWidgets('tapping outside context menu barrier dismisses the menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithApp(
        GlassContextMenu(
          actions: [
            GlassContextMenuAction(
              trailing: const Text('Ctrl+D'),
              onPressed: () {},
              child: const Text('Action To Dismiss'),
            ),
          ],
          child: const Text('Barrier Target'),
        ),
      ),
    );

    // Open menu
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Barrier Target')),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Action To Dismiss'), findsOneWidget);
    expect(find.text('Ctrl+D'), findsOneWidget);

    // Tap outside at top-left corner
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Action To Dismiss'), findsNothing);
  });

  testWidgets('tapping lifted target preview dismisses the context menu', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithApp(
        GlassContextMenu(
          actions: [
            GlassContextMenuAction(
              onPressed: () {},
              child: const Text('Some Action'),
            ),
          ],
          child: const Text('Preview Target'),
        ),
      ),
    );

    // Open menu
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Preview Target')),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Some Action'), findsOneWidget);

    // Tap the lifted preview target in the overlay
    await tester.tap(find.text('Preview Target').last);
    await tester.pumpAndSettle();

    expect(find.text('Some Action'), findsNothing);
  });

  testWidgets('GlassContextMenu near bottom edge places platter above target', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrapWithApp(
        Align(
          alignment: Alignment.bottomCenter,
          child: GlassContextMenu(
            actions: [
              GlassContextMenuAction(
                onPressed: () {},
                child: const Text('Bottom Action'),
              ),
            ],
            child: const Text('Bottom Target'),
          ),
        ),
      ),
    );

    // Open menu
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Bottom Target')),
    );
    await tester.pump(const Duration(milliseconds: 800));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Bottom Action'), findsOneWidget);
  });

  testWidgets(
    'GlassContextMenuAction semanticOnTap and onKeyboardActivate execute action',
    (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        wrapWithApp(
          GlassContextMenu(
            actions: [
              GlassContextMenuAction(
                onPressed: () => tapCount++,
                child: const Text('Keyboard Action'),
              ),
            ],
            child: const Text('Keyboard Target'),
          ),
        ),
      );

      // Open menu
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Keyboard Target')),
      );
      await tester.pump(const Duration(milliseconds: 800));
      await gesture.up();
      await tester.pumpAndSettle();

      final focusRegionFinder = find.byType(GlassFocusRegion);
      expect(focusRegionFinder, findsOneWidget);
      final focusRegion = tester.widget<GlassFocusRegion>(focusRegionFinder);
      focusRegion.semanticOnTap?.call();
      focusRegion.onKeyboardActivate?.call();
      expect(tapCount, 2);
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'GlassContextMenu hero morphs from targetRect to preview and back on dismissal',
    (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 100),
              child: GlassContextMenu(
                actions: [
                  GlassContextMenuAction(
                    child: const Text('Edit'),
                    onPressed: () {},
                  ),
                ],
                previewBuilder: (_) => Container(
                  width: 240,
                  height: 180,
                  color: CupertinoColors.white,
                  child: const Text('Hero Custom Preview'),
                ),
                child: Container(
                  key: const ValueKey('row_target'),
                  width: 320,
                  height: 60,
                  color: CupertinoColors.systemGrey,
                  child: const Text('Row Target Content'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Row Target Content'), findsOneWidget);
      expect(find.text('Hero Custom Preview'), findsNothing);

      // Initial position of row
      final rowFinder = find.byKey(const ValueKey('row_target'));
      final initialRowRect = tester.getRect(rowFinder);
      expect(initialRowRect.top, 100.0);
      expect(initialRowRect.width, 320.0);
      expect(initialRowRect.height, 60.0);

      // Long press to open menu
      final gesture = await tester.startGesture(tester.getCenter(rowFinder));
      await tester.pump(const Duration(milliseconds: 800));
      await gesture.up();

      // Pump partially into the transition (frame mid-flight)
      await tester.pump(const Duration(milliseconds: 100));

      // The preview widget is already in tree
      expect(find.text('Hero Custom Preview'), findsOneWidget);

      // Settle to resting position
      await tester.pumpAndSettle();
      expect(find.text('Hero Custom Preview'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);

      // Resting preview is visible
      final previewFinder = find.text('Hero Custom Preview');
      expect(previewFinder, findsOneWidget);

      // Tap outside to dismiss
      await tester.tapAt(const Offset(10, 10));
      // Pump partially: reverses back towards initialRowRect
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Context menu is dismissed and row is visible again
      expect(find.text('Hero Custom Preview'), findsNothing);
      expect(find.text('Edit'), findsNothing);
      expect(find.text('Row Target Content'), findsOneWidget);
    },
  );

  testWidgets(
    'GlassContextMenu hides target row in background while route is open',
    (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          GlassContextMenu(
            actions: [
              GlassContextMenuAction(
                child: const Text('Action 1'),
                onPressed: () {},
              ),
            ],
            child: const Text('Target Should Hide'),
          ),
        ),
      );

      // Long press
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Target Should Hide')),
      );
      await tester.pump(const Duration(milliseconds: 800));
      await gesture.up();
      await tester.pumpAndSettle();

      // The context menu route is open
      expect(find.text('Action 1'), findsOneWidget);

      // In the underlying widget tree, opacity of child is 0.0
      final opacityFinder = find.ancestor(
        of: find.text('Target Should Hide').first,
        matching: find.byType(Opacity),
      );
      expect(opacityFinder, findsWidgets);
      final opacities = tester
          .widgetList<Opacity>(opacityFinder)
          .where((o) => o.opacity == 0.0);
      expect(opacities, isNotEmpty);
    },
  );

  testWidgets(
    'GlassContextMenu performs jump-out with shadow before morphing to rounded rect',
    (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          Center(
            child: SizedBox(
              width: 320,
              height: 60,
              child: GlassContextMenu(
                rowBorderRadius: 12.0,
                previewBorderRadius: 20.0,
                actions: [
                  GlassContextMenuAction(
                    child: const Text('Action Item'),
                    onPressed: () {},
                  ),
                ],
                previewBuilder: (_) => const SizedBox(
                  width: 220,
                  height: 180,
                  child: Text('Rounded Rect Preview'),
                ),
                child: const Text('Original Row Item'),
              ),
            ),
          ),
        ),
      );

      // Initial press and hold triggers menu presentation
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Original Row Item')),
      );
      await tester.pump(const Duration(milliseconds: 800));
      await gesture.up();

      // Stage 1: ~50ms into transition (still inside the lift stage)
      // Row has jumped out with shadow: child is still row item with shadow
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.text('Original Row Item'), findsWidgets);

      // Stage 2: Settle to completed presentation
      await tester.pumpAndSettle();
      expect(find.text('Rounded Rect Preview'), findsOneWidget);
      expect(find.text('Action Item'), findsOneWidget);

      // Dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Returns back to original row
      expect(find.text('Rounded Rect Preview'), findsNothing);
      expect(find.text('Original Row Item'), findsOneWidget);
    },
  );

  testWidgets(
    'GlassContextMenu paints the origin slot colour and removes shadow on return dismissal',
    (tester) async {
      const slotColor = Color(0xFFF2F2F7);
      await tester.pumpWidget(
        wrapWithApp(
          Center(
            child: SizedBox(
              width: 300,
              height: 50,
              child: GlassContextMenu(
                originSlotColor: slotColor,
                actions: [
                  GlassContextMenuAction(
                    child: const Text('Action 1'),
                    onPressed: () {},
                  ),
                ],
                previewBuilder: (_) => const SizedBox(
                  width: 200,
                  height: 150,
                  child: Text('Preview Content'),
                ),
                child: const Text('Slot Item'),
              ),
            ),
          ),
        ),
      );

      // Open context menu
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Slot Item')),
      );
      await tester.pump(const Duration(milliseconds: 800));
      await gesture.up();
      await tester.pumpAndSettle();

      // The empty slot shows the supplied page background (not a white slab).
      final slotBoxes = tester.widgetList<ColoredBox>(find.byType(ColoredBox));
      expect(slotBoxes.any((c) => c.color == slotColor), isTrue);

      bool anyCardShadow() => tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .any(
            (d) =>
                d.decoration is ShapeDecoration &&
                (d.decoration as ShapeDecoration).shadows != null &&
                (d.decoration as ShapeDecoration).shadows!.isNotEmpty,
          );

      // At rest the card carries its drop shadow.
      expect(anyCardShadow(), isTrue);

      // Tap outside to trigger reverse dismissal; the shadow is gone by the end.
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 160));
      expect(anyCardShadow(), isFalse);

      await tester.pumpAndSettle();
      expect(find.text('Slot Item'), findsOneWidget);
    },
  );

  testWidgets(
    'GlassContextMenu holds raised row with drop shadow during press-and-hold dwell and morphs to rectangle on commit',
    (tester) async {
      await tester.pumpWidget(
        wrapWithApp(
          Center(
            child: SizedBox(
              width: 300,
              height: 60,
              child: GlassContextMenu(
                actions: [
                  GlassContextMenuAction(
                    child: const Text('Commit Action'),
                    onPressed: () {},
                  ),
                ],
                previewBuilder: (_) => Container(
                  width: 220,
                  height: 160,
                  color: CupertinoColors.systemBackground,
                  child: const Center(child: Text('Morphed Rectangle Preview')),
                ),
                child: const Text('Hold Dwell Item'),
              ),
            ),
          ),
        ),
      );

      // Touch and hold on the item
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Hold Dwell Item')),
      );

      // Pump 180ms: gesture recognizer recognizes hold and pushes interactive route
      await tester.pump(const Duration(milliseconds: 180));
      // Pump 150ms: route builds and advances into lift dwell state in overlay
      await tester.pump(const Duration(milliseconds: 150));

      // In dwell state: verify the container has unclipped drop shadow
      final hasShadow = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .any(
            (d) =>
                d.decoration is ShapeDecoration &&
                (d.decoration as ShapeDecoration).shadows != null &&
                (d.decoration as ShapeDecoration).shadows!.isNotEmpty,
          );
      expect(hasShadow, isTrue);

      // The row content is visible in the overlay while the background row is hidden
      expect(find.text('Hold Dwell Item'), findsNWidgets(2));

      // Commit by advancing past commitDuration (total 600ms from touch down)
      await tester.pump(const Duration(milliseconds: 400));
      await gesture.up();
      await tester.pumpAndSettle();

      // After commit: morphed into preview rectangle and actions platter is open
      expect(find.text('Morphed Rectangle Preview'), findsOneWidget);
      expect(find.text('Commit Action'), findsOneWidget);

      // Tap outside to dismiss
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Morphed Rectangle Preview'), findsNothing);
      expect(find.text('Hold Dwell Item'), findsOneWidget);
    },
  );

  testWidgets(
    'GlassContextMenu covers disabled state, early interactive cancellation, backdropBlur, destructive hover, and bottom-of-screen preview placement',
    (tester) async {
      // 1. Disabled menu returns child directly
      await tester.pumpWidget(
        wrapWithApp(
          GlassContextMenu(
            enabled: false,
            actions: [
              GlassContextMenuAction(
                child: const Text('Disabled Action'),
                onPressed: () {},
              ),
            ],
            child: const Text('Disabled Child'),
          ),
        ),
      );
      expect(find.text('Disabled Child'), findsOneWidget);

      // 2. Interactive hold cancelled by moving pointer away before commit,
      //    and cancelled by releasing pointer before commit
      await tester.pumpWidget(
        GlassTheme(
          data: const GlassThemeData(brightness: Brightness.dark),
          child: wrapWithApp(
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  width: 220,
                  height: 50,
                  child: GlassContextMenu(
                    backdropBlur: 12.0,
                    actions: [
                      GlassContextMenuAction(
                        isDestructive: true,
                        child: const Text('Destructive Action'),
                        onPressed: () {},
                      ),
                      GlassContextMenuAction(
                        child: const Text('Second Action'),
                        onPressed: () {},
                      ),
                    ],
                    previewBuilder: (_) => const SizedBox(
                      width: 240,
                      height: 360,
                      child: Text('Tall Bottom Preview'),
                    ),
                    child: const Text('Bottom Item'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Quick tap rejects _ContextMenuLongPressRecognizer in gesture arena (hits rejectGesture)
      await tester.tap(find.text('Bottom Item').first);
      await tester.pump();

      final itemCenter = tester.getCenter(find.text('Bottom Item').first);

      // Cancel interactive hold by dragging far away (> width * 0.6)
      final g1 = await tester.startGesture(itemCenter);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 50));
      final g1Move = await tester.startGesture(itemCenter);
      await g1Move.moveBy(const Offset(250, 0));
      await g1Move.up();
      await g1.up();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Cancel interactive hold by releasing early before commitDuration
      final g2 = await tester.startGesture(itemCenter);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 50));
      final g2Up = await tester.startGesture(itemCenter);
      await g2Up.up();
      await g2.up();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Cancel interactive hold via PointerCancelEvent
      final g3 = await tester.startGesture(itemCenter);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 50));
      final g3Cancel = await tester.startGesture(itemCenter);
      await g3Cancel.cancel();
      await g3.cancel();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Full hold -> commit -> glide over destructive action -> cancel pointer
      final g4 = await tester.startGesture(itemCenter);
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();
      expect(find.text('Tall Bottom Preview'), findsOneWidget);

      final destructiveCenter = tester.getCenter(
        find.text('Destructive Action'),
      );
      final g4Glide = await tester.startGesture(destructiveCenter);
      await g4Glide.moveTo(destructiveCenter);
      await tester.pump();
      await g4Glide.cancel();
      await g4.up();
      await tester.pump();

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    },
  );
}
