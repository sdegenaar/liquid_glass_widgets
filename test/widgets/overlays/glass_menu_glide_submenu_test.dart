import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// Hosts a controller-driven menu whose trigger sits near the top-left, so the
/// menu (anchored top-left) opens down and to the right, fully on screen.
Widget _host(GlassMenuController controller, List<Widget> items) {
  return MaterialApp(
    home: Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: 40,
            top: 80,
            child: GlassMenu(
              controller: controller,
              showDismissBarrier: false,
              menuAlignment: GlassMenuAlignment.topLeft,
              trigger: const SizedBox(width: 8, height: 8),
              items: items,
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _open(WidgetTester tester, GlassMenuController controller) async {
  controller.open();
  await tester.pumpAndSettle();
}

void main() {
  group('GlassMenuController glide', () {
    testWidgets('glideTo + endGlide activates exactly the item under the '
        'external pointer and closes the menu', (tester) async {
      final controller = GlassMenuController();
      final tapped = <String>[];
      await tester.pumpWidget(_host(controller, [
        GlassMenuItem(title: 'Copy', onTap: () => tapped.add('Copy')),
        GlassMenuItem(title: 'Cut', onTap: () => tapped.add('Cut')),
      ]));
      await _open(tester, controller);

      expect(controller.glideTo(tester.getCenter(find.text('Copy'))), isTrue);
      expect(controller.glideTo(tester.getCenter(find.text('Cut'))), isTrue);
      await tester.pump();
      expect(controller.endGlide(), isTrue);
      await tester.pumpAndSettle();

      expect(tapped, ['Cut']);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('endGlide with nothing highlighted keeps the menu open',
        (tester) async {
      final controller = GlassMenuController();
      var tapped = false;
      await tester.pumpWidget(_host(controller, [
        GlassMenuItem(title: 'Copy', onTap: () => tapped = true),
      ]));
      await _open(tester, controller);

      expect(controller.glideTo(const Offset(700, 560)), isFalse);
      expect(controller.endGlide(), isFalse);
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
      expect(controller.isOpen, isTrue);
      expect(find.text('Copy'), findsOneWidget);
    });

    testWidgets('cancelGlide clears the highlight so endGlide does nothing',
        (tester) async {
      final controller = GlassMenuController();
      var tapped = false;
      await tester.pumpWidget(_host(controller, [
        GlassMenuItem(title: 'Copy', onTap: () => tapped = true),
      ]));
      await _open(tester, controller);

      controller.glideTo(tester.getCenter(find.text('Copy')));
      controller.cancelGlide();
      expect(controller.endGlide(), isFalse);
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
      expect(controller.isOpen, isTrue);
    });

    testWidgets('glide calls are no-ops while the menu is closed',
        (tester) async {
      final controller = GlassMenuController();
      var tapped = false;
      await tester.pumpWidget(_host(controller, [
        GlassMenuItem(title: 'Copy', onTap: () => tapped = true),
      ]));

      expect(controller.glideTo(const Offset(60, 100)), isFalse);
      expect(controller.endGlide(), isFalse);
      controller.cancelGlide();
      expect(tapped, isFalse);
    });

    testWidgets('the gap between two rows belongs to a row (contiguous hit '
        'zones), so a release there is never silently dropped', (tester) async {
      final controller = GlassMenuController();
      final tapped = <String>[];
      await tester.pumpWidget(_host(controller, [
        GlassMenuItem(title: 'Copy', onTap: () => tapped.add('Copy')),
        GlassMenuItem(title: 'Cut', onTap: () => tapped.add('Cut')),
      ]));
      await _open(tester, controller);

      // Rows are 44 px with a 2 px gap: the midpoint between the two row
      // centres is the middle of that gap.
      final a = tester.getCenter(find.text('Copy'));
      final b = tester.getCenter(find.text('Cut'));
      controller.glideTo(Offset(a.dx, (a.dy + b.dy) / 2));
      expect(controller.endGlide(), isTrue);
      await tester.pumpAndSettle();

      expect(tapped, hasLength(1));
    });

    testWidgets('a touch drag across the rows releases on the highlighted row',
        (tester) async {
      final controller = GlassMenuController();
      final tapped = <String>[];
      await tester.pumpWidget(_host(controller, [
        GlassMenuItem(title: 'Copy', onTap: () => tapped.add('Copy')),
        GlassMenuItem(title: 'Cut', onTap: () => tapped.add('Cut')),
      ]));
      await _open(tester, controller);

      final gesture =
          await tester.startGesture(tester.getCenter(find.text('Copy')));
      await tester.pump();
      final a = tester.getCenter(find.text('Copy'));
      final b = tester.getCenter(find.text('Cut'));
      // End in the gap just below Copy: the highlight stays on a row.
      await gesture.moveTo(Offset(b.dx, b.dy));
      await tester.pump();
      await gesture.moveTo(Offset(a.dx, (a.dy + b.dy) / 2 + 0.5));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tapped, hasLength(1));
    });
  });

  group('GlassMenuItem.submenu', () {
    List<Widget> items(List<String> tapped) => [
          GlassMenuItem(title: 'Copy', onTap: () => tapped.add('Copy')),
          GlassMenuItem(
            title: 'Resize',
            onTap: () => tapped.add('Resize'),
            submenu: [
              GlassMenuItem(title: 'Small', onTap: () => tapped.add('Small')),
              GlassMenuItem(title: 'Large', onTap: () => tapped.add('Large')),
            ],
          ),
        ];

    testWidgets('tapping a submenu item morphs the same menu into its list '
        'headed by Back, without running or closing', (tester) async {
      final controller = GlassMenuController();
      final tapped = <String>[];
      await tester.pumpWidget(_host(controller, items(tapped)));
      await _open(tester, controller);
      final firstRowTop = tester.getTopLeft(find.text('Copy'));

      await tester.tap(find.text('Resize'));
      await tester.pumpAndSettle();

      expect(tapped, isEmpty);
      expect(controller.isOpen, isTrue);
      expect(controller.submenuDepth, 1);
      expect(find.text('Back'), findsOneWidget);
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
      expect(find.text('Copy'), findsNothing);
      // Back is the first row, in the same spot the parent's first row had:
      // the anchored (top-left) corner did not move.
      expect(tester.getTopLeft(find.text('Back')).dy,
          moreOrLessEquals(firstRowTop.dy, epsilon: 0.5));
      // Back sits above every submenu item.
      expect(tester.getCenter(find.text('Back')).dy,
          lessThan(tester.getCenter(find.text('Small')).dy));
    });

    testWidgets('Back morphs back to the parent list', (tester) async {
      final controller = GlassMenuController();
      final tapped = <String>[];
      await tester.pumpWidget(_host(controller, items(tapped)));
      await _open(tester, controller);

      await tester.tap(find.text('Resize'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(controller.submenuDepth, 0);
      expect(controller.isOpen, isTrue);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Resize'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
      expect(tapped, isEmpty);
    });

    testWidgets('a submenu child runs and closes the whole menu',
        (tester) async {
      final controller = GlassMenuController();
      final tapped = <String>[];
      await tester.pumpWidget(_host(controller, items(tapped)));
      await _open(tester, controller);

      await tester.tap(find.text('Resize'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Large'));
      await tester.pumpAndSettle();

      expect(tapped, ['Large']);
      expect(controller.isOpen, isFalse);
    });

    testWidgets('glide release on a submenu item opens the submenu',
        (tester) async {
      final controller = GlassMenuController();
      final tapped = <String>[];
      await tester.pumpWidget(_host(controller, items(tapped)));
      await _open(tester, controller);

      controller.glideTo(tester.getCenter(find.text('Resize')));
      expect(controller.endGlide(), isTrue);
      await tester.pumpAndSettle();

      expect(controller.submenuDepth, 1);
      expect(controller.isOpen, isTrue);
      expect(tapped, isEmpty);
    });

    testWidgets('every open starts at the root list', (tester) async {
      final controller = GlassMenuController();
      final tapped = <String>[];
      await tester.pumpWidget(_host(controller, items(tapped)));
      await _open(tester, controller);
      await tester.tap(find.text('Resize'));
      await tester.pumpAndSettle();

      controller.close();
      await tester.pumpAndSettle();
      await _open(tester, controller);

      expect(controller.submenuDepth, 0);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('a submenu item shows a trailing chevron by default',
        (tester) async {
      final controller = GlassMenuController();
      await tester.pumpWidget(_host(controller, items(<String>[])));
      await _open(tester, controller);

      expect(find.byIcon(CupertinoIcons.chevron_right), findsOneWidget);
    });
  });

  group('assistive activation', () {
    /// Performs the accessibility tap action on the row labelled [label], as
    /// VoiceOver / TalkBack would (no pointer events).
    void semanticTap(WidgetTester tester, String label) {
      final node = tester.getSemantics(find.bySemanticsLabel(label).first);
      node.owner!.performAction(node.id, SemanticsAction.tap);
    }

    testWidgets('a semantics tap activates rows on a non-scrollable menu, '
        'including a submenu row and its Back row', (tester) async {
      final semantics = tester.ensureSemantics();
      final controller = GlassMenuController();
      final tapped = <String>[];
      await tester.pumpWidget(_host(controller, [
        GlassMenuItem(title: 'Copy', onTap: () => tapped.add('Copy')),
        GlassMenuItem(
          title: 'Resize',
          onTap: () => tapped.add('Resize'),
          submenu: [
            GlassMenuItem(title: 'Large', onTap: () => tapped.add('Large')),
          ],
        ),
      ]));
      await _open(tester, controller);

      semanticTap(tester, 'Resize');
      await tester.pumpAndSettle();
      expect(controller.submenuDepth, 1);

      semanticTap(tester, 'Back');
      await tester.pumpAndSettle();
      expect(controller.submenuDepth, 0);

      semanticTap(tester, 'Copy');
      await tester.pumpAndSettle();
      expect(tapped, ['Copy']);
      expect(controller.isOpen, isFalse);
      semantics.dispose();
    });

    testWidgets('a touch tap still activates a row exactly once',
        (tester) async {
      final controller = GlassMenuController();
      final tapped = <String>[];
      await tester.pumpWidget(_host(controller, [
        GlassMenuItem(title: 'Copy', onTap: () => tapped.add('Copy')),
      ]));
      await _open(tester, controller);

      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();
      expect(tapped, ['Copy']);
    });
  });

  group('submenu crossfade', () {
    double opacityOf(WidgetTester tester, String text) {
      final fades = tester
          .widgetList<FadeTransition>(find.ancestor(
            of: find.text(text),
            matching: find.byType(FadeTransition),
          ))
          .map((f) => f.opacity.value);
      return fades.fold(1.0, (a, b) => a * b);
    }

    testWidgets('the outgoing rows fade out before the incoming rows fade in '
        '(no overlapping text mid-morph)', (tester) async {
      final controller = GlassMenuController();
      await tester.pumpWidget(_host(controller, [
        GlassMenuItem(title: 'Copy', onTap: () {}),
        GlassMenuItem(
          title: 'Resize',
          onTap: () {},
          submenu: [GlassMenuItem(title: 'Large', onTap: () {})],
        ),
      ]));
      await _open(tester, controller);

      await tester.tap(find.text('Resize'));
      await tester.pump(); // morph starts
      await tester.pump(const Duration(milliseconds: 80)); // first quarter
      expect(opacityOf(tester, 'Copy'), greaterThan(0.0));
      expect(opacityOf(tester, 'Large'), 0.0,
          reason: 'incoming rows stay hidden while the old rows fade out');

      await tester.pump(const Duration(milliseconds: 160)); // third quarter
      expect(find.text('Copy'), findsOneWidget); // still mounted, outgoing
      expect(opacityOf(tester, 'Copy'), 0.0,
          reason: 'outgoing rows are gone before the new rows show');
      expect(opacityOf(tester, 'Large'), greaterThan(0.0));

      await tester.pumpAndSettle();
      expect(find.text('Copy'), findsNothing);
      expect(opacityOf(tester, 'Large'), 1.0);
    });
  });
}
