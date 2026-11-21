import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  group('Wave 1.4 — GlassMenu morph rebuilds and per-row Opacity elimination',
      () {
    testWidgets(
      'GlassMenu triggerBuilder does not double-rebuild per morph tick and '
      'menu rows do not allocate N individual Opacity saveLayers',
      (tester) async {
        var triggerBuilds = 0;
        final controller = GlassMenuController();
        final items = List<GlassMenuItem>.generate(
          8,
          (i) => GlassMenuItem(
            title: 'Action $i',
            icon: const Icon(CupertinoIcons.star),
            onTap: () {},
          ),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassMenu(
                    controller: controller,
                    triggerBuilder: (context, toggle) {
                      triggerBuilds++;
                      return GlassButton(
                        icon: const Icon(CupertinoIcons.ellipsis),
                        onTap: toggle,
                      );
                    },
                    items: items,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final initialBuilds = triggerBuilds;

        // Open menu and pump 20 animation ticks.
        controller.open();
        var maxMenuBodyOpacities = 0;
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          final scrollFinder = find.byType(SingleChildScrollView);
          if (scrollFinder.evaluate().isNotEmpty) {
            final opacityCount = find
                .descendant(
                  of: scrollFinder,
                  matching: find.byType(Opacity),
                )
                .evaluate()
                .length;
            if (opacityCount > maxMenuBodyOpacities) {
              maxMenuBodyOpacities = opacityCount;
            }
          }
        }
        await tester.pumpAndSettle();

        // Previously: _morphController.addListener called setState() every tick
        // AND AnimatedBuilder rebuilt triggerBuilder every tick (>20 rebuilds).
        // With W1.4: triggerBuilder is passed as AnimatedBuilder.child and
        // setState() is not called on every animation tick.
        expect(
          triggerBuilds - initialBuilds,
          lessThanOrEqualTo(2),
          reason:
              'GlassMenu must not rebuild triggerBuilder on every morph tick.',
        );

        // Previously: 8 items produced 8 nested Opacity widgets inside the
        // menu Column. With W1.4: at most 1 Opacity wraps the Column while
        // fading, and 0 when fully opaque at rest.
        expect(
          maxMenuBodyOpacities,
          lessThanOrEqualTo(1),
          reason:
              'Menu list must collapse N per-row Opacity widgets into <= 1.',
        );

        final settledOpacities = find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(Opacity),
            )
            .evaluate()
            .length;
        expect(
          settledOpacities,
          0,
          reason: 'Fully opaque settled GlassMenu should mount 0 Opacity '
              'wrappers inside its item list.',
        );

        // Verify RenderOpacity count inside SingleChildScrollView is also 0.
        final scrollRo =
            tester.renderObject(find.byType(SingleChildScrollView));
        var renderOpacities = 0;
        void walk(RenderObject node) {
          if (node is RenderOpacity) renderOpacities++;
          node.visitChildren(walk);
        }

        walk(scrollRo);
        expect(renderOpacities, 0);
      },
    );
  });

  group('Wave 1.7 — GlassContextMenu Offstage measurement unmounting', () {
    testWidgets(
      'GlassContextMenu unmounts its Offstage measurement pass after frame 1',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: GlassContextMenu(
                  actions: [
                    GlassContextMenuAction(
                      icon: const Icon(CupertinoIcons.doc_on_doc),
                      onPressed: () {},
                      child: const Text('Copy'),
                    ),
                    GlassContextMenuAction(
                      icon: const Icon(CupertinoIcons.share),
                      onPressed: () {},
                      child: const Text('Share'),
                    ),
                  ],
                  child: const SizedBox(
                    width: 180,
                    height: 60,
                    child: Center(child: Text('Hold me')),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Long-press to open context menu.
        final gesture =
            await tester.startGesture(tester.getCenter(find.text('Hold me')));
        await tester.pump(const Duration(milliseconds: 600));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(find.text('Copy'), findsOneWidget);
        // Once measured after frame 1, the Offstage measurement pass (which
        // held a duplicate GlassContainer.card) must be unmounted.
        final offstages = tester
            .widgetList<Offstage>(find.byType(Offstage))
            .where((o) => o.offstage)
            .toList();
        expect(
          offstages,
          isEmpty,
          reason: 'GlassContextMenu must unmount its Offstage measurement tree '
              'once preview and platter sizes are captured.',
        );
      },
    );
  });
}
