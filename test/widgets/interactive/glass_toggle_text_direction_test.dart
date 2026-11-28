import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

/// A name the user typed in another script, such as an Arabic folder name in
/// an English app, keeps its own direction on screen and for screen readers,
/// while the toggle's layout follows the app.
void main() {
  Widget host(Widget child) => CupertinoApp(
        home: CupertinoPageScaffold(child: Center(child: child)),
      );

  group('GlassToggle.button textDirection', () {
    testWidgets(
        'gives the label its direction, on screen and to screen '
        'readers', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(host(GlassToggle.button(
        value: true,
        onChanged: (_) {},
        icon: const Icon(CupertinoIcons.folder),
        label: 'مشاريع',
        textDirection: TextDirection.rtl,
      )));

      expect(
        tester.renderObject<RenderParagraph>(find.text('مشاريع')).textDirection,
        TextDirection.rtl,
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('مشاريع'))
            .getSemanticsData()
            .textDirection,
        TextDirection.rtl,
      );
      // The icon still leads on the app's (left-to-right) side.
      expect(
        tester.getCenter(find.byIcon(CupertinoIcons.folder)).dx,
        lessThan(tester.getCenter(find.text('مشاريع')).dx),
      );
      handle.dispose();
    });

    testWidgets('null keeps the ambient direction', (tester) async {
      await tester.pumpWidget(host(
        GlassToggle.button(value: true, onChanged: (_) {}, label: 'Projects'),
      ));

      expect(
        tester
            .renderObject<RenderParagraph>(find.text('Projects'))
            .textDirection,
        TextDirection.ltr,
      );
    });
  });
}
