import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/widgets/shared/glass_focus_region.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapWithApp(Widget child) {
    return CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(
          child: child,
        ),
      ),
    );
  }

  testWidgets('GlassContextMenu renders child at rest without error',
      (tester) async {
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
    await tester
        .pump(const Duration(milliseconds: 200)); // press down compression
    await tester
        .pump(const Duration(milliseconds: 400)); // long press threshold
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
  });

  testWidgets('GlassContextMenu dismisses on tapping barrier background',
      (tester) async {
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
        tester.getCenter(find.byKey(const ValueKey('tap_target'))));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Option 1'), findsOneWidget);

    // Tap outside at (10, 10)
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(dismissedCalled, isTrue);
    expect(find.text('Option 1'), findsNothing);
  });

  testWidgets('GlassContextMenu secondary tap (right-click) opens immediately',
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
          child:
              const Text('Right Click Me', key: ValueKey('right_click_target')),
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
  });

  testWidgets('GlassContextMenu with custom previewBuilder renders preview',
      (tester) async {
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
        tester.getCenter(find.byKey(const ValueKey('small_item'))));
    await tester.pump(const Duration(milliseconds: 600));
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
  });

  testWidgets('GlassContextMenuAction disabled does not fire callback',
      (tester) async {
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
  });

  testWidgets('.glassContextMenu() extension method wraps widget correctly',
      (tester) async {
    await tester.pumpWidget(
      wrapWithApp(
        const Text('Extension Item', key: ValueKey('ext_item'))
            .glassContextMenu(
          actions: [
            GlassContextMenuAction(
              child: Text('Ext Action'),
            ),
          ],
        ),
      ),
    );

    expect(find.byKey(const ValueKey('ext_item')), findsOneWidget);

    final gesture = await tester
        .startGesture(tester.getCenter(find.byKey(const ValueKey('ext_item'))));
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Ext Action'), findsOneWidget);
  });

  testWidgets('GlassContextMenu supports continuous glide-to-select',
      (tester) async {
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
          child:
              const Text('Target Text', key: ValueKey('glide_target_trigger')),
        ),
      ),
    );

    // Open via long press
    final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('glide_target_trigger'))));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Glide Target'), findsOneWidget);

    // Release initial long press
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Glide Target'), findsOneWidget);

    // Perform glide gesture across open menu items: start on First Item, glide to Glide Target, release
    final glideGesture =
        await tester.startGesture(tester.getCenter(find.text('First Item')));
    await tester.pump();
    final targetCenter = tester.getCenter(find.text('Glide Target'));
    await glideGesture.moveTo(targetCenter);
    await tester.pump();
    await glideGesture.up();
    await tester.pumpAndSettle();

    expect(glideSelected, isTrue);
    expect(find.text('Glide Target'), findsNothing);
  });

  testWidgets('GlassContextMenu respects custom longPressDuration',
      (tester) async {
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

    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Fast Target')));
    await tester.pump(const Duration(milliseconds: 180));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(opened, isTrue);
  });

  testWidgets('GlassContextMenu with GlassMenuItem executes onTap and pops',
      (tester) async {
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
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Item Target')));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Menu Item Title'), findsOneWidget);

    // Tap the GlassMenuItem
    await tester.tap(find.text('Menu Item Title'));
    await tester.pumpAndSettle();

    expect(menuItemTapped, isTrue);
    expect(find.text('Menu Item Title'), findsNothing);
  });

  testWidgets('tapping outside context menu barrier dismisses the menu',
      (tester) async {
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
    final gesture = await tester
        .startGesture(tester.getCenter(find.text('Barrier Target')));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Action To Dismiss'), findsOneWidget);
    expect(find.text('Ctrl+D'), findsOneWidget);

    // Tap outside at top-left corner
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Action To Dismiss'), findsNothing);
  });

  testWidgets('tapping lifted target preview dismisses the context menu',
      (tester) async {
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
    final gesture = await tester
        .startGesture(tester.getCenter(find.text('Preview Target')));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Some Action'), findsOneWidget);

    // Tap the lifted preview target in the overlay
    await tester.tap(find.text('Preview Target').last);
    await tester.pumpAndSettle();

    expect(find.text('Some Action'), findsNothing);
  });

  testWidgets('GlassContextMenu near bottom edge places platter above target',
      (tester) async {
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
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('Bottom Target')));
    await tester.pump(const Duration(milliseconds: 500));
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
    final gesture = await tester
        .startGesture(tester.getCenter(find.text('Keyboard Target')));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    final focusRegionFinder = find.byType(GlassFocusRegion);
    expect(focusRegionFinder, findsOneWidget);
    final focusRegion = tester.widget<GlassFocusRegion>(focusRegionFinder);
    focusRegion.semanticOnTap?.call();
    focusRegion.onKeyboardActivate?.call();
    expect(tapCount, 2);
  });
}
