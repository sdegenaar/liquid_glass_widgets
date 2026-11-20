// `GlassPopoverController` opens and closes a popover from outside, the seam
// `GlassMenuController` gives a menu.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets('open and close from the controller, with the callbacks', (
    tester,
  ) async {
    final controller = GlassPopoverController();
    var opened = 0;
    var closed = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: GlassPopover(
            controller: controller,
            popoverWidth: 200,
            popoverHeight: 100,
            onOpen: () => opened++,
            onClose: () => closed++,
            trigger: const SizedBox(width: 40, height: 40),
            contentBuilder: (_, __) => const Text('Content'),
          ),
        ),
      ),
    );
    expect(controller.isOpen, isFalse);

    controller.open();
    await tester.pumpAndSettle();
    expect(controller.isOpen, isTrue);
    expect(find.text('Content'), findsOneWidget);
    expect(opened, 1);

    controller.close();
    expect(closed, 1, reason: 'onClose fires as the close begins');
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(find.text('Content'), findsNothing);
  });

  testWidgets('a controller handed to a new popover drives the new one', (
    tester,
  ) async {
    final controller = GlassPopoverController();
    Widget host(String label) => CupertinoApp(
          home: Center(
            child: GlassPopover(
              key: ValueKey(label),
              controller: controller,
              popoverWidth: 200,
              popoverHeight: 100,
              trigger: const SizedBox(width: 40, height: 40),
              contentBuilder: (_, __) => Text(label),
            ),
          ),
        );
    await tester.pumpWidget(host('A'));
    await tester.pumpWidget(host('B'));
    controller.open();
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);
    controller.close();
    await tester.pumpAndSettle();
  });
  testWidgets('a controller swapped on a mounted popover moves over to it', (
    tester,
  ) async {
    final first = GlassPopoverController();
    final second = GlassPopoverController();
    Widget host(GlassPopoverController controller) => CupertinoApp(
          home: Center(
            child: GlassPopover(
              controller: controller,
              popoverWidth: 200,
              popoverHeight: 100,
              trigger: const SizedBox(width: 40, height: 40),
              contentBuilder: (_, __) => const Text('Content'),
            ),
          ),
        );
    await tester.pumpWidget(host(first));
    await tester.pumpWidget(host(second));

    // The old controller is detached: it no longer opens the popover.
    first.open();
    await tester.pumpAndSettle();
    expect(find.text('Content'), findsNothing);

    second.open();
    await tester.pumpAndSettle();
    expect(second.isOpen, isTrue);
    expect(find.text('Content'), findsOneWidget);
    second.close();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'intrinsic-height popover cancels cleanly on immediate open() + close()',
      (tester) async {
    final controller = GlassPopoverController();
    var opened = 0;
    var closed = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: GlassPopover(
            controller: controller,
            popoverWidth: 200,
            // Intentionally omit popoverHeight to exercise Offstage measurement.
            onOpen: () => opened++,
            onClose: () => closed++,
            trigger: const SizedBox(width: 40, height: 40),
            contentBuilder: (_, __) => const SizedBox(
              height: 80,
              child: Text('Intrinsic Content'),
            ),
          ),
        ),
      ),
    );

    // Same-frame open then close before the Offstage measurement callback runs.
    controller.open();
    controller.close();
    expect(controller.isOpen, isFalse);
    expect(opened, 1);
    expect(closed, 1);

    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(find.text('Intrinsic Content'), findsNothing);

    // Subsequent normal open still measures and opens properly.
    controller.open();
    await tester.pumpAndSettle();
    expect(controller.isOpen, isTrue);
    expect(find.text('Intrinsic Content'), findsOneWidget);
    controller.close();
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
  });

  testWidgets('open() and close() are idempotent', (tester) async {
    final controller = GlassPopoverController();
    var opened = 0;
    var closed = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: GlassPopover(
            controller: controller,
            popoverWidth: 200,
            popoverHeight: 100,
            onOpen: () => opened++,
            onClose: () => closed++,
            trigger: const SizedBox(width: 40, height: 40),
            contentBuilder: (_, __) => const Text('Idempotent'),
          ),
        ),
      ),
    );

    controller.open();
    controller.open();
    await tester.pumpAndSettle();
    controller.open();
    await tester.pump();
    expect(opened, 1);
    expect(controller.isOpen, isTrue);

    controller.close();
    controller.close();
    expect(closed, 1);
    await tester.pumpAndSettle();
    controller.close();
    expect(closed, 1);
    expect(controller.isOpen, isFalse);
  });

  testWidgets('toggle() opens, closes, and reverses mid-close', (tester) async {
    final controller = GlassPopoverController();
    var opened = 0;
    var closed = 0;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: GlassPopover(
            controller: controller,
            popoverWidth: 200,
            popoverHeight: 100,
            onOpen: () => opened++,
            onClose: () => closed++,
            trigger: const SizedBox(width: 40, height: 40),
            contentBuilder: (_, close) => GestureDetector(
              onTap: close,
              child: const Text('Toggle Content'),
            ),
          ),
        ),
      ),
    );

    controller.toggle();
    await tester.pumpAndSettle();
    expect(controller.isOpen, isTrue);
    expect(opened, 1);

    // Begin closing, then toggle mid-close while isOpen is still true.
    controller.toggle();
    await tester.pump(const Duration(milliseconds: 60));
    expect(closed, 1);
    expect(controller.isOpen, isTrue);

    controller.toggle();
    await tester.pumpAndSettle();
    expect(opened, 2);
    expect(controller.isOpen, isTrue);
    expect(find.text('Toggle Content'), findsOneWidget);

    // Closing from contentBuilder callback updates controller.isOpen.
    await tester.tap(find.text('Toggle Content'));
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
  });

  testWidgets('detached controller calls are safe no-ops', (tester) async {
    final controller = GlassPopoverController();
    expect(controller.isOpen, isFalse);
    controller.open();
    controller.close();
    controller.toggle();
    expect(controller.isOpen, isFalse);

    Widget buildHost(GlassPopoverController? ctrl) => CupertinoApp(
          home: Center(
            child: GlassPopover(
              controller: ctrl,
              popoverWidth: 200,
              popoverHeight: 100,
              trigger: const SizedBox(width: 40, height: 40),
              contentBuilder: (_, __) => const Text('Detached'),
            ),
          ),
        );

    await tester.pumpWidget(buildHost(controller));
    await tester.pumpWidget(buildHost(null));

    controller.open();
    await tester.pumpAndSettle();
    expect(controller.isOpen, isFalse);
    expect(find.text('Detached'), findsNothing);
  });
}
