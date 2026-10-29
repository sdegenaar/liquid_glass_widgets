import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
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

    testWidgets('full swipe stays past the open width of long labels',
        (tester) async {
      final controller = GlassSwipeController();
      var removeTriggered = false;

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassSwipeActions(
              controller: controller,
              trailingActions: [
                GlassSwipeAction(
                  icon: const Icon(CupertinoIcons.trash),
                  label: const Text('Remove this download'),
                  onTap: () => removeTriggered = true,
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

      controller.openTrailing(animated: false);
      await tester.pumpAndSettle();
      final openWidth = -controller.offset;
      // The long label opens the actions past the 65% full swipe threshold.
      expect(openWidth, greaterThan(0.65 * 300));

      controller.close();
      await tester.pumpAndSettle();

      await tester.drag(find.text('Row Item'), Offset(-openWidth, 0));
      await tester.pumpAndSettle();

      expect(removeTriggered, isFalse);
      expect(controller.swipeState, GlassSwipeState.openTrailing);

      controller.close();
      await tester.pumpAndSettle();

      await tester.drag(find.text('Row Item'), const Offset(-300, 0));
      await tester.pumpAndSettle();

      expect(removeTriggered, isTrue);
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

    testWidgets('a button with a long label is not shrunk', (tester) async {
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
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.flag),
                label: Text('Flag'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(height: 80, child: Text('Capsule Row')),
          ),
        ),
      );

      controller.openTrailing(animated: false);
      await tester.pumpAndSettle();

      _expectButtonsNotShrunk(tester);
      expect(_isTruncated(tester, 'Delete'), isFalse);
      expect(_isTruncated(tester, 'Flag'), isFalse);
    });

    testWidgets(
        'labels too long for the row are truncated to the same width, without shrinking their buttons',
        (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: GlassSwipeActions(
              controller: controller,
              trailingActions: const [
                GlassSwipeAction(
                  icon: Icon(CupertinoIcons.flag),
                  label: Text('Flag'),
                  onTap: _noop,
                ),
                GlassSwipeAction(
                  icon: Icon(CupertinoIcons.bookmark),
                  label: Text('Add this game to bookmarks'),
                  onTap: _noop,
                ),
                GlassSwipeAction(
                  icon: Icon(CupertinoIcons.trash),
                  label: Text('Remove this download'),
                  onTap: _noop,
                ),
              ],
              child: const SizedBox(height: 80, child: Text('Long Label Row')),
            ),
          ),
        ),
      );

      controller.openTrailing(animated: false);
      await tester.pumpAndSettle();

      _expectButtonsNotShrunk(tester);
      expect(-controller.offset, lessThan(300));
      expect(_isTruncated(tester, 'Flag'), isFalse);
      expect(_isTruncated(tester, 'Add this game to bookmarks'), isTrue);
      expect(_isTruncated(tester, 'Remove this download'), isTrue);
      expect(tester.getSize(find.text('Add this game to bookmarks')).width,
          tester.getSize(find.text('Remove this download')).width);
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
                closeOnTapOutside: false,
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

    testWidgets(
        'buttonDiameter, buttonSpacing, and horizontalPadding configure button geometry',
        (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            controller: controller,
            buttonDiameter: 44.0,
            buttonSpacing: 10.0,
            horizontalPadding: 16.0,
            trailingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                // Fits the circle.
                label: Text('Bin'),
                onTap: _noop,
              ),
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.flag),
                label: Text('Flag'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              width: 300,
              height: 70,
              child: Text('Configurable Tile'),
            ),
          ),
        ),
      );

      // Open trailing actions without animation
      controller.openTrailing(animated: false);
      await tester.pumpAndSettle();

      // Total width: 2 * 16 + 2 * 44 + 10 = 32 + 88 + 10 = 130
      expect(controller.offset, -130.0);

      // Delete should be at end: 16, Flag should be at end: 16 + 44 + 10 = 70
      final deleteCenter = tester.getCenter(find.byIcon(CupertinoIcons.trash));
      final flagCenter = tester.getCenter(find.byIcon(CupertinoIcons.flag));
      expect(deleteCenter.dx, greaterThan(flagCenter.dx));
      expect(deleteCenter.dx - flagCenter.dx, closeTo(54.0, 0.1));
    });

    testWidgets(
        'buttons remain stationary horizontally during reveal drag and do not move sideways',
        (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            controller: controller,
            buttonDiameter: 50.0,
            buttonSpacing: 12.0,
            horizontalPadding: 12.0,
            trailingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                // Fits the circle.
                label: Text('Bin'),
                onTap: _noop,
              ),
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.flag),
                label: Text('Flag'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              width: 400,
              height: 80,
              child: Text('Drag Static Row'),
            ),
          ),
        ),
      );

      // Partial drag to reveal Delete (offset -80)
      controller.animateToOffset(-80.0, animated: false);
      await tester.pump();
      expect(find.text('Bin'), findsOneWidget);
      final deletePosAt80 = tester.getTopLeft(find.text('Bin')).dx;

      // Drag further open to resting width (offset -136)
      controller.animateToOffset(-136.0, animated: false);
      await tester.pump();
      expect(find.text('Bin'), findsOneWidget);
      expect(find.text('Flag'), findsOneWidget);
      final deletePosAt136 = tester.getTopLeft(find.text('Bin')).dx;
      final flagPosAt136 = tester.getTopLeft(find.text('Flag')).dx;

      // Delete position must NOT move sideways during reveal (from 80 to 136)!
      expect(deletePosAt136, equals(deletePosAt80));

      // Overdrag past resting width to -180: excess = 180 - 136 = 44
      controller.animateToOffset(-180.0, animated: false);
      await tester.pump();
      final flagPosAt180 = tester.getTopLeft(find.text('Flag')).dx;

      // Flag shifts left by excess (44) to maintain the constant 12pt spacing
      expect(flagPosAt136 - flagPosAt180, closeTo(44.0, 1.0));
    });

    testWidgets(
        'buttons remain stationary horizontally during close/hide animation',
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
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.flag),
                label: Text('Flag'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              width: 400,
              height: 80,
              child: Text('Closing Row'),
            ),
          ),
        ),
      );

      // Fully open row
      controller.openTrailing(animated: false);
      await tester.pumpAndSettle();
      final deleteInitialX = tester.getTopLeft(find.text('Delete')).dx;

      // Trigger closing animation
      controller.close(animated: true);
      // Pump halfway through the close animation
      await tester.pump(const Duration(milliseconds: 60));

      if (find.text('Delete').evaluate().isNotEmpty) {
        final deleteClosingX = tester.getTopLeft(find.text('Delete')).dx;
        // Delete must remain at its exact X coordinate while scaling down/fading out
        expect(deleteClosingX, equals(deleteInitialX));
      }

      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
    });

    testWidgets(
        'GlassListTile forwards swipeActionButtonDiameter, spacing, and padding',
        (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassListTile(
            swipeController: controller,
            swipeActionButtonDiameter: 40.0,
            swipeActionButtonSpacing: 8.0,
            swipeActionHorizontalPadding: 10.0,
            title: const Text('Forwarding Tile'),
            trailingSwipeActions: const [
              // No label: a label wider than the circle stretches the button.
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                onTap: _noop,
              ),
            ],
          ),
        ),
      );

      controller.openTrailing(animated: false);
      await tester.pumpAndSettle();

      // Total width: 2 * 10 + 40 = 60
      expect(controller.offset, -60.0);
    });

    testWidgets(
        'full swipe primes icon alignment flick to inner edge and fades label',
        (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 400,
            child: GlassSwipeActions(
              controller: controller,
              fullSwipeThreshold: 0.65,
              trailingActions: const [
                GlassSwipeAction(
                  icon: Icon(CupertinoIcons.trash),
                  label: Text('Delete'),
                  onTap: _noop,
                ),
                GlassSwipeAction(
                  icon: Icon(CupertinoIcons.flag),
                  label: Text('Flag'),
                  onTap: _noop,
                ),
              ],
              child: const SizedBox(
                height: 60,
                child: Text('Flick Test Row'),
              ),
            ),
          ),
        ),
      );

      // Open resting
      controller.openTrailing(animated: false);
      await tester.pumpAndSettle();

      // In resting open, both labels are present and visible
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Flag'), findsOneWidget);

      // Now animate to offset past 65% of 400 = 260px (e.g. -280px)
      controller.animateToOffset(-280.0, animated: false);
      await tester.pump();

      // Check AnimatedAlign for the icon: targetAlignment is centerStart
      final animatedAligns =
          tester.widgetList<AnimatedAlign>(find.byType(AnimatedAlign));
      expect(animatedAligns, isNotEmpty);
      expect(animatedAligns.first.alignment, AlignmentDirectional.centerStart);

      // And the label for Delete is faded out (opacity 0)
      final animatedOpacities =
          tester.widgetList<AnimatedOpacity>(find.byType(AnimatedOpacity));
      expect(animatedOpacities.any((o) => o.opacity == 0.0), isTrue);
    });

    testWidgets(
        'GlassSwipeController.dismiss programmatically executes full-swipe dismissal',
        (tester) async {
      final controller = GlassSwipeController();
      var dismissed = false;

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 400,
            child: GlassSwipeActions(
              controller: controller,
              onDismissed: () => dismissed = true,
              trailingActions: const [
                GlassSwipeAction(
                  icon: Icon(CupertinoIcons.trash),
                  label: Text('Delete'),
                  onTap: _noop,
                ),
              ],
              child: const SizedBox(
                height: 60,
                child: Text('Dismiss Controller Row'),
              ),
            ),
          ),
        ),
      );

      controller.dismiss(animated: false);
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets(
        'tapping outside an open swipe row automatically closes it without blocking action taps',
        (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActionScope(
            child: Column(
              children: [
                const SizedBox(
                  width: 400,
                  height: 60,
                  child: Text('Header Outside Area'),
                ),
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
                    width: 400,
                    height: 60,
                    child: Text('Swipeable Row'),
                  ),
                ),
                const SizedBox(
                  width: 400,
                  height: 60,
                  child: Text('Another Row Below'),
                ),
              ],
            ),
          ),
        ),
      );

      // Open the swipe row
      await tester.drag(find.text('Swipeable Row'), const Offset(-100, 0));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(find.text('Delete'), findsOneWidget);

      // Tap outside on another row
      await tester.tap(find.text('Another Row Below'));
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
      expect(controller.offset, 0.0);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets(
        'swiping to close an open row with both leading and trailing actions docks at 0 without opening opposite side',
        (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        createTestApp(
          child: GlassSwipeActions(
            controller: controller,
            leadingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.pin),
                label: Text('Pin'),
                onTap: _noop,
              ),
            ],
            trailingActions: const [
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.trash),
                label: Text('Delete'),
                onTap: _noop,
              ),
              GlassSwipeAction(
                icon: Icon(CupertinoIcons.flag),
                label: Text('Flag'),
                onTap: _noop,
              ),
            ],
            child: const SizedBox(
              width: 400,
              height: 60,
              child: Text('Bidirectional Row'),
            ),
          ),
        ),
      );

      // Swipe left to open trailing actions
      await tester.drag(find.text('Bidirectional Row'), const Offset(-140, 0));
      await tester.pumpAndSettle();
      expect(controller.swipeState, GlassSwipeState.openTrailing);
      expect(controller.offset, lessThan(0.0));

      // Swipe right generously (200px) to close trailing actions: must dock at 0.0
      // and NEVER cross over into opening leading actions ('Pin').
      await tester.drag(find.byType(GlassSwipeActions), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
      expect(controller.swipeState, GlassSwipeState.idle);
      expect(controller.offset, 0.0);
      expect(find.text('Pin'), findsNothing);
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets(
        'solid dark section swipe row maintains opaque card-to-grey surface while closing without black transparency',
        (tester) async {
      final controller = GlassSwipeController();

      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(brightness: Brightness.dark),
          home: GlassTheme(
            data: const GlassThemeData(brightness: Brightness.dark),
            child: GlassGroupedSection(
              surfaceStyle: GlassSurfaceStyle.solid,
              children: [
                GlassListTile(
                  swipeController: controller,
                  title: const Text('Dark Solid Row'),
                  trailingSwipeActions: const [
                    GlassSwipeAction(
                      icon: Icon(CupertinoIcons.trash),
                      label: Text('Delete'),
                      onTap: _noop,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      // Open trailing actions
      controller.openTrailing(animated: false);
      await tester.pump();
      expect(controller.isOpen, isTrue);

      // Animate to a near-closed offset (-8.0px, within the 24px fade zone)
      controller.animateToOffset(-8.0, animated: false);
      await tester.pump();

      // Find the sliding child's DecoratedBox inside ClipRRect
      final clipRRect = find.descendant(
        of: find.byType(GlassSwipeActions),
        matching: find.byType(ClipRRect),
      );
      expect(clipRRect, findsWidgets);
      final decoratedBoxes = tester.widgetList<DecoratedBox>(
        find.descendant(
          of: clipRRect.first,
          matching: find.byType(DecoratedBox),
        ),
      );
      expect(decoratedBoxes, isNotEmpty);
      final boxDecoration = decoratedBoxes.first.decoration as BoxDecoration;
      // Must be 100% opaque (alpha == 1.0) and never pure black (#000000)
      expect(boxDecoration.color!.a, closeTo(1.0, 0.001));
      expect(boxDecoration.color, isNot(equals(const Color(0xFF000000))));
    });

    testWidgets(
        'covers explicit actionWidth, rubber-band damping without fullSwipe, RTL dismiss, platter tap-to-close, and button press states',
        (tester) async {
      final controller = GlassSwipeController();
      var dismissedCount = 0;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: Center(
                child: SizedBox(
                  width: 320,
                  height: 64,
                  child: GlassSwipeActions(
                    controller: controller,
                    actionWidth: 72.0,
                    allowsFullSwipe: false,
                    leadingActions: [
                      GlassSwipeAction(
                        icon: const Icon(CupertinoIcons.pin),
                        label: const Text('Pin'),
                        onTap: _noop,
                      ),
                      GlassSwipeAction(
                        icon: const Icon(CupertinoIcons.star),
                        label: const Text('Star'),
                        onTap: _noop,
                      ),
                    ],
                    trailingActions: [
                      GlassSwipeAction(
                        icon: const Icon(CupertinoIcons.trash),
                        label: const Text('Delete'),
                        isDestructive: true,
                        onTap: _noop,
                      ),
                    ],
                    onDismissed: () => dismissedCount++,
                    child: const ColoredBox(
                      color: CupertinoColors.systemGrey,
                      child: Center(child: Text('RTL Damped Row')),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Drag leading (in RTL, dragging left reveals leading) past 2 * 72 = 144 to exercise rubber-band damping
      await tester.drag(find.byType(GlassSwipeActions), const Offset(-220, 0));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);

      // Drag while already openLeading (in RTL, _dragStartSide == 1) and release to settle
      await tester.drag(find.byType(GlassSwipeActions), const Offset(-20, 0));
      await tester.pumpAndSettle();

      // Ensure leading is open and press down + cancel on tintedGlass action button
      controller.openLeading(animated: false);
      await tester.pump();
      final pinFinder = find.text('Pin');
      final gPress = await tester.startGesture(tester.getCenter(pinFinder));
      await tester.pump();
      await gPress.cancel();
      await tester.pump();

      // Animate to 0 via animateToOffset(0.0)
      controller.animateToOffset(0.0, animated: false);
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);

      // Drag trailing (in RTL, dragging right reveals trailing) past 72 to exercise trailing rubber-band damping
      await tester.drag(find.byType(GlassSwipeActions), const Offset(180, 0));
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);

      // Programmatic animated dismiss fromLeading in RTL
      controller.dismiss(animated: true, fromLeading: true);
      await tester.pumpAndSettle();
      expect(dismissedCount, 1);
    });

    testWidgets(
        'full-swipe delete in a list removes only one row even without row keys',
        (tester) async {
      final items = ['Alex Rivera', 'Jordan Lee', 'Taylor Brooks'];
      final controllers =
          List.generate(items.length, (_) => GlassSwipeController());
      var pinCount = 0;

      await tester.pumpWidget(
        createTestApp(
          child: SizedBox(
            width: 300,
            child: StatefulBuilder(
              builder: (context, setState) {
                return GlassGroupedSection(
                  surfaceStyle: GlassSurfaceStyle.solid,
                  children: [
                    for (var i = 0; i < items.length; i++)
                      GlassListTile(
                        swipeController: controllers[i],
                        allowsFullSwipe: true,
                        onDismissed: () => setState(() {
                          items.removeAt(i);
                          controllers.removeAt(i);
                        }),
                        leadingSwipeActions: [
                          GlassSwipeAction(
                            icon: const Icon(CupertinoIcons.pin_fill),
                            label: const Text('Pin'),
                            onTap: () => pinCount++,
                          ),
                        ],
                        trailingSwipeActions: [
                          GlassSwipeAction(
                            icon: const Icon(CupertinoIcons.trash),
                            label: const Text('Delete'),
                            isDestructive: true,
                            onTap: () => controllers[i].dismiss(),
                          ),
                        ],
                        title: Text(items[i]),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Full-swiping right on non-destructive Pin should trigger Pin and close, NOT dismiss
      await tester.drag(find.text('Alex Rivera'), const Offset(240, 0));
      await tester.pumpAndSettle();
      expect(pinCount, 1);
      expect(items.length, 3);
      expect(tester.getSize(find.text('Alex Rivera')).height, greaterThan(0));

      // Full-swiping left on destructive Delete should remove ONLY 'Alex Rivera'
      // and leave 'Jordan Lee' and 'Taylor Brooks' visible with non-zero height.
      await tester.drag(find.text('Alex Rivera'), const Offset(-240, 0));
      await tester.pumpAndSettle();

      expect(items, ['Jordan Lee', 'Taylor Brooks']);
      expect(find.text('Alex Rivera'), findsNothing);
      expect(find.text('Jordan Lee'), findsOneWidget);
      expect(find.text('Taylor Brooks'), findsOneWidget);

      final jordanTile = find.ancestor(
        of: find.text('Jordan Lee'),
        matching: find.byType(GlassSwipeActions),
      );
      expect(tester.getSize(jordanTile).height, greaterThan(20));
    });
  });
}

void _noop() {}

/// Expects that no swipe action button is scaled down to fit its slot.
void _expectButtonsNotShrunk(WidgetTester tester) {
  final fittedBoxes = tester.renderObjectList<RenderProxyBox>(find.descendant(
      of: find.byType(GlassSwipeActions), matching: find.byType(FittedBox)));
  expect(fittedBoxes, isNotEmpty);
  for (final fitted in fittedBoxes) {
    expect(fitted.child!.size, fitted.size);
  }
}

/// Whether the swipe action label [text] is truncated with an ellipsis.
bool _isTruncated(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text)).didExceedMaxLines;
