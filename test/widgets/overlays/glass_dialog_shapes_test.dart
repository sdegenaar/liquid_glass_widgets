// `GlassDialog.shape` / `actionShape` / `actionTextStyle` on the ios27 alert
// platter.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  Future<void> pump(WidgetTester t, GlassDialog dialog) => t.pumpWidget(
        CupertinoApp(
          home: GlassTheme(data: const GlassThemeData.ios27(), child: dialog),
        ),
      );

  ShapeDecoration capsuleOf(WidgetTester t, String label) => t
      .widget<Container>(
        find
            .ancestor(of: find.text(label), matching: find.byType(Container))
            .first,
      )
      .decoration! as ShapeDecoration;

  testWidgets('the platter takes the dialog\'s action shape and type', (
    t,
  ) async {
    await pump(
      t,
      GlassDialog(
        actionShape: const LiquidRoundedRectangle(borderRadius: 9),
        actionTextStyle: const TextStyle(fontSize: 13),
        actions: [GlassDialogAction(label: 'OK', onPressed: () {})],
      ),
    );
    expect(capsuleOf(t, 'OK').shape, isA<LiquidRoundedRectangle>());
    expect(t.widget<Text>(find.text('OK')).style?.fontSize, 13);

    await pump(
      t,
      GlassDialog(actions: [GlassDialogAction(label: 'OK', onPressed: () {})]),
    );
    expect(capsuleOf(t, 'OK').shape, const StadiumBorder());
  });

  testWidgets('a wrapped label keeps the caller\'s shape, else 32 pt corners', (
    t,
  ) async {
    Future<void> big(GlassDialog d) => t.pumpWidget(
          CupertinoApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: GlassTheme(data: const GlassThemeData.ios27(), child: d),
            ),
          ),
        );
    await big(
      GlassDialog(
        actionShape: const LiquidRoundedRectangle(borderRadius: 9),
        actions: [GlassDialogAction(label: 'OK', onPressed: () {})],
      ),
    );
    expect(capsuleOf(t, 'OK').shape, isA<LiquidRoundedRectangle>());
    await big(
      GlassDialog(actions: [GlassDialogAction(label: 'OK', onPressed: () {})]),
    );
    expect(capsuleOf(t, 'OK').shape, isA<RoundedSuperellipseBorder>());
  });
}
