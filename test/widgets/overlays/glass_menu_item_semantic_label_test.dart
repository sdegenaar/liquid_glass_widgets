import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SemanticsAction, SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void _noop() {}

void main() {
  group('GlassMenuItem.semanticLabel', () {
    Future<List<String>> openMenu(WidgetTester tester) async {
      final controller = GlassMenuController();
      final tapped = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  left: 40,
                  top: 80,
                  child: GlassMenu(
                    controller: controller,
                    menuAlignment: GlassMenuAlignment.topLeft,
                    trigger: const SizedBox(width: 8, height: 8),
                    items: [
                      GlassMenuItem(
                        title: 'Save',
                        semanticLabel: 'Save, Command S',
                        trailing: const Text('⌘S'),
                        onTap: () => tapped.add('Save'),
                      ),
                      GlassMenuItem(
                        title: 'Export',
                        subtitle: 'PDF',
                        semanticLabel: 'Export, Shift Command E',
                        trailing: const Text('⇧⌘E'),
                        onTap: () {},
                      ),
                      GlassMenuItem(title: 'Close', onTap: () {}),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      controller.open();
      await tester.pumpAndSettle();
      return tapped;
    }

    SemanticsNode row(WidgetTester tester, String label) =>
        tester.getSemantics(find.bySemanticsLabel(label).first);

    testWidgets('names the row instead of the title', (tester) async {
      final semantics = tester.ensureSemantics();
      await openMenu(tester);

      expect(
        row(tester, 'Save, Command S'),
        isSemantics(label: 'Save, Command S', isButton: true),
      );
      expect(find.semantics.byLabel('Save'), findsNothing);
      // The trailing shortcut stays out of the tree; the label carries it.
      expect(find.semantics.byLabel('⌘S'), findsNothing);
      semantics.dispose();
    });

    testWidgets('keeps the subtitle as the value', (tester) async {
      final semantics = tester.ensureSemantics();
      await openMenu(tester);

      expect(
        row(tester, 'Export, Shift Command E'),
        isSemantics(
          label: 'Export, Shift Command E',
          value: 'PDF',
          isButton: true,
        ),
      );
      semantics.dispose();
    });

    testWidgets('null (the default) names the row by its title',
        (tester) async {
      final semantics = tester.ensureSemantics();
      await openMenu(tester);

      expect(
        row(tester, 'Close'),
        isSemantics(label: 'Close', isButton: true),
      );
      semantics.dispose();
    });

    testWidgets('a screen-reader tap on the renamed row activates it',
        (tester) async {
      final semantics = tester.ensureSemantics();
      final tapped = await openMenu(tester);

      final node = row(tester, 'Save, Command S');
      node.owner!.performAction(node.id, SemanticsAction.tap);
      await tester.pumpAndSettle();

      expect(tapped, ['Save']);
      semantics.dispose();
    });
  });

  testWidgets(
      'GlassPullDownButton preserves semanticLabel when onSelected is set',
      (tester) async {
    String? selected;
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: AdaptiveLiquidGlassLayer(
            child: Center(
              child: GlassPullDownButton(
                icon: const Icon(CupertinoIcons.ellipsis_circle),
                onSelected: (title) => selected = title,
                items: const [
                  GlassMenuItem(
                    title: 'Save',
                    semanticLabel: 'Save, Command S',
                    onTap: _noop,
                  ),
                  GlassMenuItem(title: 'Close', onTap: _noop),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final menu = tester.widget<GlassMenu>(find.byType(GlassMenu));
    final items = menu.items.cast<GlassMenuItem>();
    expect(items.map((item) => item.semanticLabel), ['Save, Command S', null]);
    // onSelected still reports the title, not the spoken label.
    items.first.onTap();
    expect(selected, 'Save');
  });
}
