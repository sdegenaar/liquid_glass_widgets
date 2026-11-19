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
}
