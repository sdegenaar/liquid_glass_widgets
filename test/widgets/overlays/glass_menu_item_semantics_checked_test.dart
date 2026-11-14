import 'dart:ui' show CheckedState;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsAction, SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void _noop() {}

void main() {
  group('GlassMenuItem.semanticsChecked', () {
    Future<void> openPicker(WidgetTester tester) async {
      final controller = GlassMenuController();
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
                        title: 'Alpha',
                        onTap: () {},
                        semanticsChecked: false,
                      ),
                      GlassMenuItem(
                        title: 'Beta',
                        onTap: () {},
                        semanticsChecked: true,
                      ),
                      GlassMenuItem(title: 'Gamma', onTap: () {}),
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
    }

    SemanticsNode row(WidgetTester tester, String title) =>
        tester.getSemantics(find.bySemanticsLabel(title).first);

    testWidgets('a checked row is a checked radio button, not a button', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await openPicker(tester);

      final beta = row(tester, 'Beta').getSemanticsData();
      expect(beta.flagsCollection.isButton, isFalse);
      expect(beta.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(beta.flagsCollection.isChecked, CheckedState.isTrue);
      expect(beta.hasAction(SemanticsAction.tap), isTrue);

      final alpha = row(tester, 'Alpha').getSemanticsData();
      expect(alpha.flagsCollection.isButton, isFalse);
      expect(alpha.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(alpha.flagsCollection.isChecked, CheckedState.isFalse);
      expect(alpha.hasAction(SemanticsAction.tap), isTrue);
      semantics.dispose();
    });

    testWidgets('null (the default) keeps the button', (tester) async {
      final semantics = tester.ensureSemantics();
      await openPicker(tester);

      final gamma = row(tester, 'Gamma').getSemanticsData().flagsCollection;
      expect(gamma.isButton, isTrue);
      expect(gamma.isInMutuallyExclusiveGroup, isFalse);
      expect(gamma.isChecked, CheckedState.none);
      semantics.dispose();
    });
  });

  testWidgets('GlassPullDownButton preserves semanticsChecked when onSelected '
      'is set', (tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: AdaptiveLiquidGlassLayer(
            child: Center(
              child: GlassPullDownButton(
                icon: const Icon(CupertinoIcons.ellipsis_circle),
                onSelected: (title) {},
                items: const [
                  GlassMenuItem(
                    title: 'Name',
                    onTap: _noop,
                    semanticsChecked: true,
                  ),
                  GlassMenuItem(
                    title: 'Date',
                    onTap: _noop,
                    semanticsChecked: false,
                  ),
                  GlassMenuItem(title: 'Size', onTap: _noop),
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
    expect(items.map((item) => item.semanticsChecked), [true, false, null]);
  });
}
