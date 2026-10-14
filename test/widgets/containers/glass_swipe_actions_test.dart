import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassSwipeActions', () {
    testWidgets('renders primary child initially without showing actions',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassSwipeActions(
            trailingActions: [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
            ],
            child: SizedBox(
              height: 50,
              width: 300,
              child: Text('Primary Row Content'),
            ),
          ),
        ),
      );

      expect(find.text('Primary Row Content'), findsOneWidget);
      // In the Stack, the platter is not built when directionalOffset == 0
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('drag left reveals trailing actions and settles open',
        (tester) async {
      var state = GlassSwipeState.idle;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            onSwipeStateChanged: (s) => state = s,
            trailingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              height: 50,
              width: 400,
              child: Text('Row Item'),
            ),
          ),
        ),
      );

      // Drag left to reveal trailing action
      await tester.drag(find.text('Row Item'), const Offset(-100, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      expect(state, GlassSwipeState.openTrailing);
    });

    testWidgets('tapping revealed action executes onTap and closes by default',
        (tester) async {
      var actionTapped = false;
      var state = GlassSwipeState.idle;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            onSwipeStateChanged: (s) => state = s,
            trailingActions: [
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.trash),
                label: const Text('Delete'),
                onTap: () => actionTapped = true,
              ),
            ],
            child: const SizedBox(
              height: 50,
              width: 400,
              child: Text('Row Item'),
            ),
          ),
        ),
      );

      // Open trailing action
      await tester.drag(find.text('Row Item'), const Offset(-100, 0));
      await tester.pumpAndSettle();
      expect(state, GlassSwipeState.openTrailing);

      // Tap action
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(actionTapped, isTrue);
      expect(state, GlassSwipeState.idle);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('closeOnTap: false keeps row open after action tap',
        (tester) async {
      var actionTapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            trailingActions: [
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.flag),
                label: const Text('Flag'),
                closeOnTap: false,
                onTap: () => actionTapped = true,
              ),
            ],
            child: const SizedBox(
              height: 50,
              width: 400,
              child: Text('Row Item'),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Row Item'), const Offset(-100, 0));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flag'));
      await tester.pumpAndSettle();

      expect(actionTapped, isTrue);
      // Row stays open
      expect(find.text('Flag'), findsOneWidget);
    });

    testWidgets('drag right reveals leading actions', (tester) async {
      var state = GlassSwipeState.idle;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            onSwipeStateChanged: (s) => state = s,
            leadingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.mail),
                label: Text('Read'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              height: 50,
              width: 400,
              child: Text('Row Item'),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Row Item'), const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(find.text('Read'), findsOneWidget);
      expect(state, GlassSwipeState.openLeading);
    });

    testWidgets('full swipe triggers outermost action automatically',
        (tester) async {
      var deleteTriggered = false;

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassSwipeActions(
              fullSwipeThreshold: 0.5,
              trailingActions: [
                GlassSwipeAction(
                  icon: const Icon(CupertinoIcons.trash),
                  label: const Text('Delete'),
                  onTap: () => deleteTriggered = true,
                ),
              ],
              child: const SizedBox(
                height: 50,
                width: 300,
                child: Text('Row Item'),
              ),
            ),
          ),
        ),
      );

      // Drag beyond 50% of 300 (e.g. -220px)
      await tester.drag(find.text('Row Item'), const Offset(-220, 0));
      await tester.pumpAndSettle();

      expect(deleteTriggered, isTrue);
      expect(find.text('Delete'), findsNothing); // returns closed
    });

    testWidgets('allowsFullSwipe: false disables auto-execution',
        (tester) async {
      var deleteTriggered = false;

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassSwipeActions(
              allowsFullSwipe: false,
              trailingActions: [
                GlassSwipeAction(
                  icon: const Icon(CupertinoIcons.trash),
                  label: const Text('Delete'),
                  onTap: () => deleteTriggered = true,
                ),
              ],
              child: const SizedBox(
                height: 50,
                width: 300,
                child: Text('Row Item'),
              ),
            ),
          ),
        ),
      );

      // Drag past threshold
      await tester.drag(find.text('Row Item'), const Offset(-250, 0));
      await tester.pumpAndSettle();

      // Action was NOT triggered automatically
      expect(deleteTriggered, isFalse);
      // Row is open at standard width
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('tapping shifted child closes row without triggering child tap',
        (tester) async {
      var childTapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            trailingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
            ],
            child: GestureDetector(
              onTap: () => childTapped = true,
              child: const SizedBox(
                height: 50,
                width: 400,
                child: Text('Clickable Child'),
              ),
            ),
          ),
        ),
      );

      // Open row
      await tester.drag(find.text('Clickable Child'), const Offset(-100, 0));
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget);

      // Tap on the shifted child (obscured by tap barrier, hence warnIfMissed: false)
      await tester.tap(find.text('Clickable Child'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Child was NOT tapped; row was closed instead
      expect(childTapped, isFalse);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('programmatic control via GlassSwipeController',
        (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            controller: controller,
            trailingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
            ],
            leadingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.mail),
                label: Text('Read'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              height: 50,
              width: 400,
              child: Text('Row Item'),
            ),
          ),
        ),
      );

      expect(controller.isOpen, isFalse);

      controller.openTrailing();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(controller.swipeState, GlassSwipeState.openTrailing);
      expect(find.text('Delete'), findsOneWidget);

      controller.close();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(find.text('Delete'), findsNothing);

      controller.openLeading();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(controller.swipeState, GlassSwipeState.openLeading);
      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets('RTL layout mirrors swipe directions', (tester) async {
      var state = GlassSwipeState.idle;

      await tester.pumpWidget(
        createTestApp(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: GlassSwipeActions(
              onSwipeStateChanged: (s) => state = s,
              trailingActions: const [
                GlassSwipeAction(
                  icon: Icon(CupertinoIcons.trash),
                  label: Text('Delete'),
                  onTap: _noop,
                ),
              ],
              child: const SizedBox(
                height: 50,
                width: 400,
                child: Text('RTL Row Item'),
              ),
            ),
          ),
        ),
      );

      // In RTL, trailing is on the left, so dragging right (+dx) reveals trailing actions!
      await tester.drag(find.text('RTL Row Item'), const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      expect(state, GlassSwipeState.openTrailing);
    });
  });

  group('GlassSwipeActionScope', () {
    testWidgets('enforces mutual exclusivity between rows', (tester) async {
      final controller1 = GlassSwipeController();
      final controller2 = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActionScope(
            child: Column(
              children: [
                GlassSwipeActions(
                  controller: controller1,
                  trailingActions: const [
                    GlassSwipeAction(
                      icon: Icon(CupertinoIcons.trash),
                      label: Text('Delete 1'),
                      onTap: _noop,
                    ),
                  ],
                  child: const SizedBox(
                    height: 50,
                    width: 400,
                    child: Text('Row 1'),
                  ),
                ),
                GlassSwipeActions(
                  controller: controller2,
                  trailingActions: const [
                    GlassSwipeAction(
                      icon: Icon(CupertinoIcons.trash),
                      label: Text('Delete 2'),
                      onTap: _noop,
                    ),
                  ],
                  child: const SizedBox(
                    height: 50,
                    width: 400,
                    child: Text('Row 2'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Open Row 1
      controller1.openTrailing();
      await tester.pumpAndSettle();
      expect(controller1.isOpen, isTrue);
      expect(controller2.isOpen, isFalse);

      // Open Row 2 -> Row 1 should automatically close
      controller2.openTrailing();
      await tester.pumpAndSettle();
      expect(controller1.isOpen, isFalse);
      expect(controller2.isOpen, isTrue);
    });

    testWidgets('scrolling closes open swipe row', (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActionScope(
            child: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return GlassSwipeActions(
                    controller: controller,
                    trailingActions: const [
                      GlassSwipeAction(
                        icon: Icon(CupertinoIcons.trash),
                        label: Text('Delete'),
                        onTap: _noop,
                      ),
                    ],
                    child: const SizedBox(
                      height: 50,
                      child: Text('Item 0'),
                    ),
                  );
                }
                return SizedBox(
                  height: 50,
                  child: Text('Item $index'),
                );
              },
            ),
          ),
        ),
      );

      controller.openTrailing();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);

      // Scroll the list
      await tester.drag(find.byType(ListView), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
    });

    testWidgets(
        'trailing actions place actions[0] at outer screen edge matching Swift/UIKit',
        (tester) async {
      var primaryActionTapped = false;
      var secondaryActionTapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            trailingActions: [
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.trash),
                label: const Text('Delete'),
                onTap: () => primaryActionTapped = true,
              ),
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.flag),
                label: const Text('Flag'),
                onTap: () => secondaryActionTapped = true,
              ),
            ],
            child: const SizedBox(
              height: 50,
              width: 400,
              child: Text('Swift Order Row'),
            ),
          ),
        ),
      );

      // Drag left to reveal both actions
      await tester.drag(find.text('Swift Order Row'), const Offset(-160, 0));
      await tester.pumpAndSettle();

      final deletePos = tester.getTopLeft(find.text('Delete'));
      final flagPos = tester.getTopLeft(find.text('Flag'));

      // In Swift/UIKit, actions[0] ('Delete') is outermost (farthest right in LTR)
      // and actions[1] ('Flag') is inward (to the left of Delete).
      expect(deletePos.dx, greaterThan(flagPos.dx));

      // Tap Flag (inward action)
      await tester.tap(find.text('Flag'));
      await tester.pumpAndSettle();
      expect(secondaryActionTapped, isTrue);
      expect(primaryActionTapped, isFalse);
    });

    testWidgets(
        'full swipe with onDismissed animates row height to 0 and invokes callback',
        (tester) async {
      var dismissed = false;
      var deleteTapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassSwipeActions(
              onDismissed: () => dismissed = true,
              trailingActions: [
                GlassSwipeAction(
                  icon: const Icon(CupertinoIcons.trash),
                  label: const Text('Delete'),
                  onTap: () => deleteTapped = true,
                ),
              ],
              child: const SizedBox(
                height: 60,
                child: Text('Dismissable Row'),
              ),
            ),
          ),
        ),
      );

      // Perform a drag exceeding the 65% threshold of 300 (e.g. -220px)
      await tester.drag(find.text('Dismissable Row'), const Offset(-220, 0));
      expect(deleteTapped, isTrue);

      // During dismiss animation, SizeTransition shrinks height
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(dismissed, isFalse);

      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
      final size = tester.getSize(find.byType(GlassSwipeActions));
      expect(size.height, 0.0);
    });

    testWidgets(
        'renders tintedGlass and solidVibrancy styles properly and handles press',
        (tester) async {
      final ctrl1 = GlassSwipeController();
      final ctrl2 = GlassSwipeController();
      final rtlCtrl = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: Column(
            children: [
              GlassSwipeActions(
                controller: ctrl1,
                style: GlassSwipeActionStyle.tintedGlass,
                trailingActions: const [
                  GlassSwipeAction(
                    icon: Icon(CupertinoIcons.gear),
                    label: Text('Tinted'),
                    onTap: _noop,
                  ),
                ],
                child: const SizedBox(
                    height: 50, width: 300, child: Text('Row 1')),
              ),
              GlassSwipeActions(
                controller: ctrl2,
                style: GlassSwipeActionStyle.solidVibrancy,
                trailingActions: const [
                  GlassSwipeAction(
                    icon: Icon(CupertinoIcons.gear),
                    label: Text('Solid'),
                    onTap: _noop,
                  ),
                ],
                child: const SizedBox(
                    height: 50, width: 300, child: Text('Row 2')),
              ),
              Directionality(
                textDirection: TextDirection.rtl,
                child: GlassSwipeActions(
                  controller: rtlCtrl,
                  leadingActions: const [
                    GlassSwipeAction(
                      icon: Icon(CupertinoIcons.gear),
                      label: Text('RtlLeading'),
                      onTap: _noop,
                    ),
                  ],
                  child: const SizedBox(
                      height: 50, width: 300, child: Text('Row 3')),
                ),
              ),
            ],
          ),
        ),
      );

      ctrl1.openTrailing(animated: false);
      ctrl2.openTrailing(animated: false);
      rtlCtrl.openLeading(animated: false);
      await tester.pumpAndSettle();

      expect(find.text('Tinted'), findsOneWidget);
      expect(find.text('Solid'), findsOneWidget);
      expect(find.text('RtlLeading'), findsOneWidget);

      // Press and cancel on Tinted (covers tintedGlass pressed + onTapCancel)
      final gesture1 =
          await tester.startGesture(tester.getCenter(find.text('Tinted')));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture1.cancel();
      await tester.pumpAndSettle();

      // Press and cancel on Solid (covers solidVibrancy pressed)
      final gesture2 =
          await tester.startGesture(tester.getCenter(find.text('Solid')));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture2.cancel();
      await tester.pumpAndSettle();
    });
  });

  group('GlassListTile swipe actions integration', () {
    testWidgets('renders GlassListTile with trailing and leading swipe actions',
        (tester) async {
      var deleteTapped = false;
      var readTapped = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            leading: const Icon(CupertinoIcons.mail),
            title: const Text('Inbox message'),
            leadingSwipeActions: [
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.mail),
                label: const Text('Mark Read'),
                backgroundColor: CupertinoColors.systemBlue,
                onTap: () => readTapped = true,
              ),
            ],
            trailingSwipeActions: [
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.trash),
                label: const Text('Delete'),
                isDestructive: true,
                onTap: () => deleteTapped = true,
              ),
            ],
          ),
        ),
      );

      expect(find.text('Inbox message'), findsOneWidget);

      // Swipe to reveal trailing action
      await tester.drag(find.text('Inbox message'), const Offset(-120, 0));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(deleteTapped, isTrue);

      // Swipe to reveal leading action
      await tester.drag(find.text('Inbox message'), const Offset(120, 0));
      await tester.pumpAndSettle();

      expect(find.text('Mark Read'), findsOneWidget);
      await tester.tap(find.text('Mark Read'));
      await tester.pumpAndSettle();
      expect(readTapped, isTrue);
    });

    testWidgets('GlassListTile forwards swipeActionStyle and onDismissed',
        (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassListTile(
              title: const Text('Dismissable Tile'),
              swipeActionStyle: GlassSwipeActionStyle.solidVibrancy,
              onDismissed: () => dismissed = true,
              trailingSwipeActions: const [
                GlassSwipeAction(
                  icon: Icon(CupertinoIcons.trash),
                  label: Text('Delete'),
                  onTap: _noop,
                ),
              ],
            ),
          ),
        ),
      );

      // Drag left past full swipe threshold of 300 (e.g. -220px)
      await tester.drag(find.text('Dismissable Tile'), const Offset(-220, 0));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets(
        'unmounting an open row does not throw when another row is swiped',
        (tester) async {
      var showFirst = true;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActionScope(
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    if (showFirst)
                      const SizedBox(
                        width: 300,
                        height: 60,
                        child: GlassSwipeActions(
                          key: ValueKey('first'),
                          trailingActions: [
                            GlassSwipeAction(
                              icon: Icon(CupertinoIcons.trash),
                              label: Text('Delete 1'),
                              onTap: _noop,
                            ),
                          ],
                          child: Text('First Row'),
                        ),
                      ),
                    const SizedBox(
                      width: 300,
                      height: 60,
                      child: GlassSwipeActions(
                        key: ValueKey('second'),
                        trailingActions: [
                          GlassSwipeAction(
                            icon: Icon(CupertinoIcons.trash),
                            label: Text('Delete 2'),
                            onTap: _noop,
                          ),
                        ],
                        child: Text('Second Row'),
                      ),
                    ),
                    CupertinoButton(
                      child: const Text('Toggle'),
                      onPressed: () => setState(() => showFirst = false),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Drag first row to open
      await tester.drag(find.text('First Row'), const Offset(-100, 0));
      await tester.pumpAndSettle();

      // Now unmount first row
      await tester.tap(find.text('Toggle'));
      await tester.pumpAndSettle();

      // Now drag second row — must not throw "widget has been unmounted"
      await tester.drag(find.text('Second Row'), const Offset(-100, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('GlassSwipeController programmatic open, close, and offset',
        (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            controller: controller,
            trailingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
            ],
            leadingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.flag),
                label: Text('Flag'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              width: 300,
              height: 50,
              child: Text('Controller Item'),
            ),
          ),
        ),
      );

      expect(controller.isOpen, isFalse);
      expect(controller.offset, 0.0);

      // Open trailing programmatically
      controller.openTrailing(animated: false);
      await tester.pumpAndSettle();

      expect(controller.isOpen, isTrue);
      expect(controller.offset, lessThan(0.0));

      // Close programmatically
      controller.close(animated: false);
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
      expect(controller.offset, 0.0);

      // Open leading programmatically
      controller.openLeading(animated: false);
      await tester.pumpAndSettle();

      expect(controller.isOpen, isTrue);
      expect(controller.offset, greaterThan(0.0));

      controller.close(animated: false);
      await tester.pumpAndSettle();
    });

    testWidgets('GlassSwipeActions didUpdateWidget swaps controller',
        (tester) async {
      final ctrl1 = GlassSwipeController();
      final ctrl2 = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            controller: ctrl1,
            trailingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              width: 300,
              height: 60,
              child: Text('Swapping Item'),
            ),
          ),
        ),
      );

      expect(ctrl1.isOpen, isFalse);

      // Swap controller
      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            controller: ctrl2,
            trailingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              width: 300,
              height: 60,
              child: Text('Swapping Item'),
            ),
          ),
        ),
      );

      ctrl2.openTrailing(animated: false);
      await tester.pumpAndSettle();

      expect(ctrl2.isOpen, isTrue);
    });

    testWidgets('GlassSwipeActionScope.closeAll closes currently open row',
        (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActionScope(
            child: Builder(
              builder: (context) {
                return Column(
                  children: [
                    GlassSwipeActions(
                      controller: controller,
                      trailingActions: const [
                        GlassSwipeAction(
                          icon: Icon(CupertinoIcons.trash),
                          label: Text('Delete'),
                          onTap: _noop,
                        ),
                      ],
                      child: const SizedBox(
                        width: 300,
                        height: 60,
                        child: Text('Row In Scope'),
                      ),
                    ),
                    CupertinoButton(
                      child: const Text('Close All Button'),
                      onPressed: () => GlassSwipeActionScope.closeAll(context),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      controller.openTrailing(animated: false);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);

      await tester.tap(find.text('Close All Button'));
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
    });

    testWidgets('GlassSwipeActions clips with borderRadius', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const GlassSwipeActions(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            trailingActions: [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
            ],
            child: SizedBox(
              width: 300,
              height: 60,
              child: Text('Rounded Row'),
            ),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsWidgets);
    });

    testWidgets('GlassSwipeActions leading overdrag and full swipe execution',
        (tester) async {
      bool flagged = false;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            allowsFullSwipe: true,
            fullSwipeThreshold: 0.3,
            leadingActions: [
              GlassSwipeAction(
                icon: const Icon(CupertinoIcons.flag),
                label: const Text('Flag'),
                onTap: () => flagged = true,
              ),
            ],
            child: const SizedBox(
              width: 300,
              height: 60,
              child: Text('Leading Swipe Item'),
            ),
          ),
        ),
      );

      // Drag right with large offset to trigger rubber-banding and full swipe
      await tester.drag(find.text('Leading Swipe Item'), const Offset(250, 0));
      await tester.pumpAndSettle();

      expect(flagged, isTrue);
    });

    testWidgets('GlassSwipeActionScope closes on ScrollUpdateNotification',
        (tester) async {
      final controller = GlassSwipeController();
      late BuildContext buildContext;

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActionScope(
            child: Builder(
              builder: (context) {
                buildContext = context;
                return GlassSwipeActions(
                  controller: controller,
                  trailingActions: const [
                    GlassSwipeAction(
                      icon: Icon(CupertinoIcons.trash),
                      label: Text('Delete'),
                      onTap: _noop,
                    ),
                  ],
                  child: const SizedBox(
                    width: 300,
                    height: 60,
                    child: Text('Scroll Close Item'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      controller.openTrailing(animated: false);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);

      // Dispatch ScrollUpdateNotification with scrollDelta > 1.0
      ScrollUpdateNotification(
        metrics: FixedScrollMetrics(
          minScrollExtent: 0,
          maxScrollExtent: 100,
          pixels: 10,
          viewportDimension: 50,
          axisDirection: AxisDirection.down,
          devicePixelRatio: 1.0,
        ),
        context: buildContext,
        scrollDelta: 5.0,
      ).dispatch(buildContext);

      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
    });
  });
}

void _noop() {}
