import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  // Labels of the semantics traversal, empty labels dropped.
  List<String> traversal(WidgetTester tester) => tester.semantics
      .simulatedAccessibilityTraversal()
      .map((node) => node.label)
      .where((label) => label.isNotEmpty)
      .toList();

  Widget popover({
    bool useTriggerBuilder = false,
    bool barrierDismissible = true,
    void Function(VoidCallback close)? onBuildContent,
  }) {
    return GlassPopover(
      barrierDismissible: barrierDismissible,
      trigger: useTriggerBuilder
          ? null
          : const SizedBox(width: 80, height: 44, child: Text('Open')),
      triggerBuilder: useTriggerBuilder
          ? (context, toggle) => GestureDetector(
                onTap: toggle,
                child: const SizedBox(
                  width: 80,
                  height: 44,
                  child: Text('Open'),
                ),
              )
          : null,
      contentBuilder: (context, close) {
        onBuildContent?.call(close);
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Popover content'),
        );
      },
    );
  }

  // The layouts the open popover used to drop out of the semantics tree in.
  final layouts = <String, Widget Function(Widget popover)>{
    'alone': (popover) => Center(child: popover),
    'Column siblings': (popover) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [const Text('Before'), popover, const Text('After')],
          ),
        ),
    'Row siblings': (popover) => Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [const Text('Before'), popover],
          ),
        ),
  };

  Future<void> pumpPage(WidgetTester tester, Widget body) {
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: body)));
  }

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('GlassPopover semantics', () {
    for (final layout in layouts.entries) {
      for (final useTriggerBuilder in [false, true]) {
        final trigger = useTriggerBuilder ? 'triggerBuilder' : 'trigger';
        testWidgets(
            'the open popover is in the semantics tree and blocks the page '
            '(${layout.key}, $trigger)', (tester) async {
          final semantics = tester.ensureSemantics();
          await pumpPage(
            tester,
            layout.value(popover(useTriggerBuilder: useTriggerBuilder)),
          );
          final pageTexts =
              ['Before', 'After'].where((t) => find.text(t).hasFound).toList();
          for (final text in pageTexts) {
            expect(find.semantics.byLabel(text), findsOne);
          }

          await open(tester);

          expect(find.semantics.byLabel('Popover content'), findsOne);
          expect(find.semantics.byLabel('Dismiss'), findsOne);
          for (final text in pageTexts) {
            expect(find.semantics.byLabel(text), findsNothing);
          }
          // Siblings are traversed in geometric order, which depends on where
          // the popover opens.
          expect(
            traversal(tester),
            unorderedEquals(['Dismiss', 'Popover content']),
          );

          // A screen reader closes it through the barrier.
          tester.semantics.dismiss(find.semantics.byLabel('Dismiss'));
          await tester.pumpAndSettle();

          expect(find.text('Popover content'), findsNothing);
          expect(find.semantics.byLabel('Dismiss'), findsNothing);
          for (final text in pageTexts) {
            expect(find.semantics.byLabel(text), findsOne);
          }
          semantics.dispose();
        });
      }
    }

    testWidgets(
        'a non-dismissible popover is in the semantics tree and blocks the '
        'page', (tester) async {
      final semantics = tester.ensureSemantics();
      late VoidCallback close;
      await pumpPage(
        tester,
        layouts['Column siblings']!(
          popover(
            barrierDismissible: false,
            onBuildContent: (callback) => close = callback,
          ),
        ),
      );

      await open(tester);

      expect(find.semantics.byLabel('Popover content'), findsOne);
      expect(find.semantics.byLabel('Dismiss'), findsNothing);
      expect(find.semantics.byLabel('Before'), findsNothing);
      expect(find.semantics.byLabel('After'), findsNothing);
      expect(traversal(tester), ['Popover content']);

      close();
      await tester.pumpAndSettle();

      expect(find.text('Popover content'), findsNothing);
      expect(traversal(tester), ['Before', 'Open', 'After']);
      semantics.dispose();
    });

    testWidgets('closing by tapping the barrier brings the page back',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPage(tester, layouts['Column siblings']!(popover()));
      await open(tester);
      expect(find.semantics.byLabel('Before'), findsNothing);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Popover content'), findsNothing);
      expect(traversal(tester), ['Before', 'Open', 'After']);
      semantics.dispose();
    });

    testWidgets(
        'the content keeps its own nodes, inside the popover body, as on a '
        'page', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPage(
        tester,
        Center(
          child: GlassPopover(
            trigger: const SizedBox(width: 80, height: 44, child: Text('Open')),
            contentBuilder: (context, close) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Line A'),
                const Text('Line B'),
                TextButton(onPressed: close, child: const Text('Done')),
              ],
            ),
          ),
        ),
      );
      await open(tester);

      expect(find.semantics.byLabel('Line A'), findsOne);
      expect(find.semantics.byLabel('Line B'), findsOne);
      expect(find.semantics.byLabel('Done'), findsOne);
      expect(traversal(tester), ['Dismiss', 'Line A', 'Line B', 'Done']);

      // The content's parent node is the popover body, not the full-screen
      // overlay.
      final body = find.semantics.byLabel('Line A').evaluate().single.parent!;
      final screen = tester.getSize(find.byType(Scaffold));
      expect(body.rect.width, lessThan(screen.width));
      expect(body.rect.height, lessThan(screen.height));

      tester.semantics.tap(find.semantics.byLabel('Done'));
      await tester.pumpAndSettle();
      expect(find.text('Line A'), findsNothing);
      semantics.dispose();
    });

    testWidgets('the open popover blocks a GlassNavigationShell page',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => GlassNavigationShell(child: child!),
          home: Scaffold(body: layouts['Column siblings']!(popover())),
        ),
      );
      await tester.pumpAndSettle();
      await open(tester);

      expect(find.semantics.byLabel('Popover content'), findsOne);
      expect(find.semantics.byLabel('Dismiss'), findsOne);
      expect(find.semantics.byLabel('Before'), findsNothing);
      expect(find.semantics.byLabel('After'), findsNothing);

      tester.semantics.dismiss(find.semantics.byLabel('Dismiss'));
      await tester.pumpAndSettle();

      expect(find.semantics.byLabel('Before'), findsOne);
      expect(find.semantics.byLabel('After'), findsOne);
      semantics.dispose();
    });
  });
}
