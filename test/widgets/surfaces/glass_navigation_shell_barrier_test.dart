import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/widgets/surfaces/shell_chrome_barrier.dart';
import 'package:liquid_glass_widgets/widgets/surfaces/shared/glass_nav_pinned_host.dart';

// The shell paints its pinned chrome in an Overlay of its own, after the app's
// Navigator, so a page-level menu's dismiss barrier neither covers it for
// pointers nor blocks it for screen readers on its own (#472).
void main() {
  setUp(() {
    // Headless test runs report no shader support; force the gate open so the
    // pinned path is exercised.
    GlassNavigationShellState.debugPinningSupported = true;
  });

  tearDown(() {
    GlassNavigationShellState.debugPinningSupported = null;
  });

  /// Settles the route transition and the post-frame registration handover.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump();
  }

  List<String> traversal(WidgetTester tester) => tester.semantics
      .simulatedAccessibilityTraversal()
      .map((node) => node.label)
      .where((label) => label.isNotEmpty)
      .toList();

  GlassBarItem addItem({VoidCallback? onTap}) => GlassBarItem.icon(
    id: 'add',
    icon: const Icon(CupertinoIcons.add),
    label: 'Add',
    onTap: onTap ?? () {},
  );

  /// The pinned `Add` icon, as a pointer user hits it.
  Finder pinnedAdd() => find.descendant(
    of: find.byType(GlassNavPinnedHost),
    matching: find.byIcon(CupertinoIcons.add),
  );

  Widget pageMenu(
    GlassMenuController controller, {
    bool showDismissBarrier = true,
    VoidCallback? onCopy,
  }) => GlassMenu(
    controller: controller,
    showDismissBarrier: showDismissBarrier,
    trigger: const SizedBox(width: 44, height: 44, child: Text('Open')),
    items: [GlassMenuItem(title: 'Copy', onTap: onCopy ?? () {})],
  );

  /// The #472 repro: a pinned `Add` action and a menu in the page body.
  Widget page(Widget body, {List<GlassBarItem>? actions}) => GlassScaffold(
    appBar: GlassAppBar.pinned(
      title: const Text('Title'),
      actions: actions ?? [addItem()],
    ),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [const Text('Page text'), body],
      ),
    ),
  );

  Widget shellApp(Widget home) => CupertinoApp(
    builder: (context, child) => GlassNavigationShell(child: child!),
    home: home,
  );

  group('a page GlassMenu inside GlassNavigationShell', () {
    testWidgets(
      'hides the pinned actions while open and restores them on close '
      '(#472)',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final controller = GlassMenuController();
        await tester.pumpWidget(shellApp(page(pageMenu(controller))));
        await settle(tester);
        expect(find.semantics.byLabel('Add'), findsOne);

        controller.open();
        await settle(tester);

        expect(find.semantics.byLabel('Add'), findsNothing);
        expect(find.semantics.byLabel('Page text'), findsNothing);
        expect(find.semantics.byLabel('Copy'), findsOne);
        expect(traversal(tester), ['Dismiss menu', 'Copy']);

        controller.close();
        await settle(tester);

        expect(find.semantics.byLabel('Add'), findsOne);
        expect(find.semantics.byLabel('Page text'), findsOne);
        semantics.dispose();
      },
    );

    testWidgets(
      'a tap on the pinned actions closes the menu instead of reaching them',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final controller = GlassMenuController();
        var added = 0;
        await tester.pumpWidget(
          shellApp(
            page(
              pageMenu(controller),
              actions: [addItem(onTap: () => added++)],
            ),
          ),
        );
        await settle(tester);
        controller.open();
        await settle(tester);

        await tester.tap(pinnedAdd(), warnIfMissed: false);
        await settle(tester);

        expect(added, 0);
        expect(controller.isOpen, isFalse);
        // Back for pointers in the same frame as for screen readers.
        expect(find.semantics.byLabel('Add'), findsOne);

        await tester.tap(pinnedAdd());
        await settle(tester);
        expect(added, 1);
        semantics.dispose();
      },
    );

    testWidgets('a long press or drag on the chrome activates nothing', (
      tester,
    ) async {
      final controller = GlassMenuController();
      var added = 0;
      await tester.pumpWidget(
        shellApp(
          page(
            pageMenu(controller),
            actions: [
              addItem(onTap: () => added++),
              GlassBarItem.icon(
                id: 'share',
                icon: const Icon(CupertinoIcons.share),
                label: 'Share',
                onTap: () {},
              ),
            ],
          ),
        ),
      );
      await settle(tester);

      // Past the touch slop and back, ending where it started.
      Future<void> dragOnAdd() async {
        final center = tester.getCenter(pinnedAdd());
        final gesture = await tester.startGesture(center);
        for (final dy in [10.0, 20.0, 30.0, 20.0, 10.0, 0.0]) {
          await gesture.moveTo(center + Offset(0, dy));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await settle(tester);
      }

      /// The render objects a pointer on `Add` reaches.
      List<Object> hitsOnAdd() {
        final result = HitTestResult();
        tester.binding.hitTestInView(
          result,
          tester.getCenter(pinnedAdd()),
          tester.view.viewId,
        );
        return [for (final entry in result.path) entry.target];
      }

      bool underGate(Object target) {
        if (target is! RenderObject) return false;
        for (var node = target.parent; node != null; node = node.parent) {
          if (node is RenderShellChromeBarrierGate) return true;
        }
        return false;
      }

      // Not held, the capsule activates an item on a long press.
      expect(hitsOnAdd().where(underGate), isNotEmpty);
      await tester.longPress(pinnedAdd());
      await settle(tester);
      expect(added, 1);
      added = 0;

      controller.open();
      await settle(tester);

      // Held, nothing in the chrome (a tap, long press or drag recognizer)
      // is in the pointer's path.
      expect(hitsOnAdd().where(underGate), isEmpty);

      await dragOnAdd();
      expect(added, 0);
      // A drag is not a tap, so the menu stays open.
      expect(controller.isOpen, isTrue);

      await tester.longPress(pinnedAdd(), warnIfMissed: false);
      await settle(tester);
      expect(added, 0);
      // Released in place, a long press is a tap on the barrier, as it is
      // anywhere else on the page.
      expect(controller.isOpen, isFalse);
    });

    testWidgets('pointers that miss the chrome reach the menu and barrier', (
      tester,
    ) async {
      final controller = GlassMenuController();
      var copied = 0;
      await tester.pumpWidget(
        shellApp(page(pageMenu(controller, onCopy: () => copied++))),
      );
      await settle(tester);
      controller.open();
      await settle(tester);

      await tester.tap(find.text('Copy'));
      await settle(tester);
      expect(copied, 1);

      controller.open();
      await settle(tester);
      await tester.tapAt(const Offset(400, 560));
      await settle(tester);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('restores the pinned actions when closed from the barrier', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = GlassMenuController();
      await tester.pumpWidget(shellApp(page(pageMenu(controller))));
      await settle(tester);

      controller.open();
      await settle(tester);
      expect(find.semantics.byLabel('Add'), findsNothing);

      tester.semantics.tap(find.semantics.byLabel('Dismiss menu'));
      await settle(tester);

      expect(controller.isOpen, isFalse);
      expect(find.semantics.byLabel('Add'), findsOne);
      semantics.dispose();
    });

    testWidgets(
      'leaves the pinned actions alone with showDismissBarrier: false',
      (tester) async {
        final semantics = tester.ensureSemantics();
        final controller = GlassMenuController();
        var added = 0;
        await tester.pumpWidget(
          shellApp(
            page(
              pageMenu(controller, showDismissBarrier: false),
              actions: [addItem(onTap: () => added++)],
            ),
          ),
        );
        await settle(tester);

        controller.open();
        await settle(tester);

        expect(find.byType(ShellChromeBarrier), findsNothing);
        expect(find.semantics.byLabel('Dismiss menu'), findsNothing);
        expect(find.semantics.byLabel('Page text'), findsOne);
        expect(find.semantics.byLabel('Add'), findsOne);
        expect(traversal(tester), containsAllInOrder(['Add', 'Copy']));

        await tester.tap(pinnedAdd());
        await tester.pump();
        expect(added, 1);
        semantics.dispose();
      },
    );

    testWidgets('restores the pinned actions when removed while open', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = GlassMenuController();
      final showMenu = ValueNotifier<bool>(true);
      addTearDown(showMenu.dispose);
      var added = 0;
      await tester.pumpWidget(
        shellApp(
          page(
            ValueListenableBuilder<bool>(
              valueListenable: showMenu,
              builder: (context, show, _) =>
                  show ? pageMenu(controller) : const SizedBox.shrink(),
            ),
            actions: [addItem(onTap: () => added++)],
          ),
        ),
      );
      await settle(tester);

      controller.open();
      await settle(tester);
      expect(find.semantics.byLabel('Add'), findsNothing);

      showMenu.value = false;
      await settle(tester);

      expect(find.semantics.byLabel('Copy'), findsNothing);
      expect(find.semantics.byLabel('Add'), findsOne);
      await tester.tap(pinnedAdd());
      await tester.pump();
      expect(added, 1);
      semantics.dispose();
    });

    testWidgets('restores the chrome when its route is popped while open', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final controller = GlassMenuController();
      var edited = 0;
      await tester.pumpWidget(
        shellApp(
          page(
            const SizedBox.shrink(),
            actions: [
              GlassBarItem.icon(
                id: 'edit',
                icon: const Icon(CupertinoIcons.pencil),
                label: 'Edit',
                onTap: () => edited++,
              ),
            ],
          ),
        ),
      );
      await settle(tester);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.push(
        CupertinoPageRoute<void>(builder: (_) => page(pageMenu(controller))),
      );
      await settle(tester);

      controller.open();
      await settle(tester);
      expect(find.semantics.byLabel('Add'), findsNothing);

      navigator.pop();
      await settle(tester);

      expect(find.semantics.byLabel('Copy'), findsNothing);
      expect(find.semantics.byLabel('Edit'), findsOne);
      await tester.tap(
        find.descendant(
          of: find.byType(GlassNavPinnedHost),
          matching: find.byIcon(CupertinoIcons.pencil),
        ),
      );
      await tester.pump();
      expect(edited, 1);
      semantics.dispose();
    });
  });

  group('a GlassBarItem.menu in the pinned capsule', () {
    Widget capsuleMenuPage({
      Widget body = const SizedBox.shrink(),
      VoidCallback? onCut,
    }) => page(
      body,
      actions: [
        GlassBarItem.menu(
          icon: const Icon(CupertinoIcons.ellipsis),
          id: 'more',
          label: 'More',
          menuItems: [GlassMenuItem(title: 'Cut', onTap: onCut ?? () {})],
        ),
      ],
    );

    Future<void> openCapsuleMenu(WidgetTester tester) async {
      await tester.tap(
        find.descendant(
          of: find.byType(GlassNavPinnedHost),
          matching: find.byIcon(CupertinoIcons.ellipsis),
        ),
      );
      await settle(tester);
    }

    testWidgets('exposes its rows and blocks the capsule and the page', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(shellApp(capsuleMenuPage()));
      await settle(tester);
      expect(find.semantics.byLabel('More'), findsOne);

      await openCapsuleMenu(tester);

      expect(find.byType(ShellChromeBarrier), findsOne);
      expect(
        tester
            .renderObject<RenderShellChromeBarrierGate>(
              find.byType(ShellChromeBarrierGate),
            )
            .excluding,
        isFalse,
      );
      expect(find.semantics.byLabel('Cut'), findsOne);
      expect(find.semantics.byLabel('Dismiss menu'), findsOne);
      expect(find.semantics.byLabel('More'), findsNothing);
      expect(find.semantics.byLabel('Page text'), findsNothing);
      semantics.dispose();
    });

    testWidgets('keeps working while a page-level barrier holds the chrome', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final held = ValueNotifier<bool>(false);
      addTearDown(held.dispose);
      var cut = 0;
      await tester.pumpWidget(
        shellApp(
          capsuleMenuPage(
            onCut: () => cut++,
            body: ValueListenableBuilder<bool>(
              valueListenable: held,
              builder: (context, value, _) => value
                  ? const ShellChromeBarrier(child: SizedBox.shrink())
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await settle(tester);

      await openCapsuleMenu(tester);
      held.value = true;
      await tester.pump();

      final gate = tester.renderObject<RenderShellChromeBarrierGate>(
        find.byType(ShellChromeBarrierGate),
      );
      expect(gate.excluding, isTrue);
      expect(find.semantics.byLabel('Cut'), findsOne);
      expect(find.semantics.byLabel('Dismiss menu'), findsOne);

      await tester.tap(find.text('Cut'));
      await settle(tester);
      expect(cut, 1);

      held.value = false;
      await tester.pump();
      expect(gate.excluding, isFalse);
      semantics.dispose();
    });
  });

  testWidgets('without a shell, a page menu behaves as before', (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = GlassMenuController();
    var added = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: page(
          pageMenu(controller),
          actions: [addItem(onTap: () => added++)],
        ),
      ),
    );
    await settle(tester);
    expect(find.byType(ShellChromeBarrierGate), findsNothing);
    expect(find.byType(ShellChromeBarrierScope), findsNothing);
    expect(find.semantics.byLabel('Add'), findsOne);

    controller.open();
    await settle(tester);

    expect(find.byType(ShellChromeBarrier), findsOne);
    expect(find.semantics.byLabel('Add'), findsNothing);
    expect(find.semantics.byLabel('Copy'), findsOne);

    // The in-route bar is under the barrier, which takes the tap.
    await tester.tap(find.byIcon(CupertinoIcons.add), warnIfMissed: false);
    await settle(tester);
    expect(added, 0);
    expect(controller.isOpen, isFalse);
    expect(find.semantics.byLabel('Add'), findsOne);
    semantics.dispose();
  });

  group('ShellChromeBarriers', () {
    test('notifies only when the first hold is taken or the last released', () {
      final barriers = ShellChromeBarriers();
      addTearDown(barriers.dispose);
      var notified = 0;
      barriers.addListener(() => notified++);
      final a = Object();
      final b = Object();

      barriers.hold(a);
      barriers.hold(a);
      barriers.hold(b);
      expect(barriers.active, isTrue);
      expect(notified, 1);

      barriers.release(a);
      expect(barriers.active, isTrue);
      barriers.release(b);
      barriers.release(b);
      expect(barriers.active, isFalse);
      expect(notified, 2);
    });

    testWidgets('a barrier moves its hold when its scope changes', (
      tester,
    ) async {
      final first = ShellChromeBarriers();
      final second = ShellChromeBarriers();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      const barrier = ShellChromeBarrier(child: SizedBox.shrink());

      await tester.pumpWidget(
        ShellChromeBarrierScope(barriers: first, child: barrier),
      );
      expect(first.active, isTrue);

      await tester.pumpWidget(
        ShellChromeBarrierScope(barriers: second, child: barrier),
      );
      expect(first.active, isFalse);
      expect(second.active, isTrue);

      await tester.pumpWidget(const SizedBox.shrink());
      expect(second.active, isFalse);
    });

    testWidgets('a barrier moved with a GlobalKey keeps its hold', (
      tester,
    ) async {
      final barriers = ShellChromeBarriers();
      addTearDown(barriers.dispose);
      final key = GlobalKey();
      Widget tree({required bool left}) => ShellChromeBarrierScope(
        barriers: barriers,
        child: Row(
          textDirection: TextDirection.ltr,
          children: [
            for (final side in [true, false])
              SizedBox(
                width: 10,
                child: side == left
                    ? ShellChromeBarrier(
                        key: key,
                        child: const SizedBox.shrink(),
                      )
                    : null,
              ),
          ],
        ),
      );

      await tester.pumpWidget(tree(left: true));
      expect(barriers.active, isTrue);

      await tester.pumpWidget(tree(left: false));
      expect(find.byKey(key), findsOne);
      expect(barriers.active, isTrue);

      await tester.pumpWidget(
        ShellChromeBarrierScope(
          barriers: barriers,
          child: const SizedBox.shrink(),
        ),
      );
      expect(barriers.active, isFalse);
    });

    testWidgets('a gate follows a swapped registry', (tester) async {
      final first = ShellChromeBarriers();
      final second = ShellChromeBarriers()..hold(1);
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      await tester.pumpWidget(ShellChromeBarrierGate(barriers: first));
      final gate = tester.renderObject<RenderShellChromeBarrierGate>(
        find.byType(ShellChromeBarrierGate),
      );
      expect(gate.excluding, isFalse);

      await tester.pumpWidget(ShellChromeBarrierGate(barriers: second));
      expect(gate.barriers, same(second));
      expect(gate.excluding, isTrue);

      first.hold(1);
      second.release(1);
      expect(gate.excluding, isFalse);

      // Detached, it no longer follows either registry.
      await tester.pumpWidget(const SizedBox.shrink());
      first.release(1);
      second.hold(1);
      expect(gate.excluding, isFalse);
    });
  });
}
