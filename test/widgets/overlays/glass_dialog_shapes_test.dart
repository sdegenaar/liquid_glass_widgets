// `GlassDialog.shape` / `actionShape` / `actionTextStyle` on both the ios27
// alert platter and the classic style, including `GlassDialog.show`.
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  Future<void> pump(
    WidgetTester t,
    GlassDialog dialog, {
    GlassThemeData theme = const GlassThemeData.ios27(),
  }) =>
      t.pumpWidget(
        CupertinoApp(
          home: GlassTheme(data: theme, child: dialog),
        ),
      );

  ShapeDecoration capsuleOf(WidgetTester t, String label) => t
      .widget<Container>(
        find
            .ancestor(of: find.text(label), matching: find.byType(Container))
            .first,
      )
      .decoration! as ShapeDecoration;

  testWidgets('the platter takes the dialog\'s shape, action shape and type', (
    t,
  ) async {
    const customPlatter = LiquidRoundedRectangle(borderRadius: 20);
    await pump(
      t,
      GlassDialog(
        shape: customPlatter,
        actionShape: const LiquidRoundedRectangle(borderRadius: 9),
        actionTextStyle: const TextStyle(fontSize: 13),
        actions: [GlassDialogAction(label: 'OK', onPressed: () {})],
      ),
    );
    expect(
      t.widget<GlassContainer>(find.byType(GlassContainer)).shape,
      customPlatter,
    );
    expect(capsuleOf(t, 'OK').shape, isA<LiquidRoundedRectangle>());
    expect(t.widget<Text>(find.text('OK')).style?.fontSize, 13);

    await pump(
      t,
      GlassDialog(actions: [GlassDialogAction(label: 'OK', onPressed: () {})]),
    );
    expect(
      t.widget<GlassContainer>(find.byType(GlassContainer)).shape,
      const LiquidRoundedSuperellipse(borderRadius: 34),
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

  testWidgets('GlassDialog.show forwards shape, actionShape, actionTextStyle', (
    t,
  ) async {
    const customPlatter = LiquidRoundedRectangle(borderRadius: 18);
    const customAction = LiquidRoundedRectangle(borderRadius: 8);
    late BuildContext hostContext;

    await t.pumpWidget(
      CupertinoApp(
        home: GlassTheme(
          data: const GlassThemeData.ios27(),
          child: Builder(
            builder: (ctx) {
              hostContext = ctx;
              return const SizedBox();
            },
          ),
        ),
      ),
    );

    GlassDialog.show<void>(
      context: hostContext,
      title: 'Custom',
      shape: customPlatter,
      actionShape: customAction,
      actionTextStyle: const TextStyle(fontSize: 14, letterSpacing: 0.5),
      actions: [
        GlassDialogAction(
          label: 'Done',
          onPressed: () => Navigator.of(hostContext).pop(),
        ),
      ],
    );
    await t.pumpAndSettle();

    expect(
      t.widget<GlassContainer>(find.byType(GlassContainer)).shape,
      customPlatter,
    );
    expect(capsuleOf(t, 'Done').shape, customAction);
    final labelStyle = t.widget<Text>(find.text('Done')).style;
    expect(labelStyle?.fontSize, 14);
    expect(labelStyle?.letterSpacing, 0.5);
  });

  testWidgets('GlassStyle.classic honors shape, actionShape, actionTextStyle', (
    t,
  ) async {
    const customCard = LiquidRoundedRectangle(borderRadius: 16);
    const customAction = LiquidRoundedRectangle(borderRadius: 6);

    await pump(
      t,
      GlassDialog(
        shape: customCard,
        actionShape: customAction,
        actionTextStyle: const TextStyle(fontSize: 14),
        actions: [
          GlassDialogAction(
            label: 'Confirm',
            isPrimary: true,
            onPressed: () {},
          ),
        ],
      ),
      theme: const GlassThemeData.classic(),
    );

    expect(
      t.widget<GlassContainer>(find.byType(GlassContainer)).shape,
      customCard,
    );
    expect(
      t.widget<GlassButton>(find.byType(GlassButton)).shape,
      customAction,
    );
    final style = t.widget<Text>(find.text('Confirm')).style;
    expect(style?.fontSize, 14);
    expect(style?.fontWeight, FontWeight.bold);

    // Defaults remain 12 pt superellipse for both card and action button.
    await pump(
      t,
      GlassDialog(
        actions: [GlassDialogAction(label: 'OK', onPressed: () {})],
      ),
      theme: const GlassThemeData.classic(),
    );
    expect(
      t.widget<GlassContainer>(find.byType(GlassContainer)).shape,
      const LiquidRoundedSuperellipse(borderRadius: 12),
    );
    expect(
      t.widget<GlassButton>(find.byType(GlassButton)).shape,
      const LiquidRoundedSuperellipse(borderRadius: 12),
    );
  });

  testWidgets(
      'actionTextStyle preserves role colors, primary weight, and stacks when large',
      (t) async {
    const ignoredColor = Color(0xFF12AB34);

    await pump(
      t,
      GlassDialog(
        actionTextStyle: const TextStyle(color: ignoredColor, fontSize: 15),
        actions: [
          GlassDialogAction(
            label: 'Primary',
            isPrimary: true,
            onPressed: () {},
          ),
          GlassDialogAction(
            label: 'Delete',
            isDestructive: true,
            onPressed: () {},
          ),
          const GlassDialogAction(label: 'Disabled', onPressed: null),
        ],
      ),
    );

    final primaryStyle = t.widget<Text>(find.text('Primary')).style;
    final deleteStyle = t.widget<Text>(find.text('Delete')).style;
    final disabledStyle = t.widget<Text>(find.text('Disabled')).style;

    expect(primaryStyle?.fontWeight, FontWeight.w600);
    expect(primaryStyle?.color, isNot(ignoredColor));
    expect(deleteStyle?.color, isNot(ignoredColor));
    expect(disabledStyle?.color, isNot(ignoredColor));
    expect(deleteStyle?.color, isNot(primaryStyle?.color));
    expect(disabledStyle?.color, isNot(primaryStyle?.color));

    // Enlarging actionTextStyle causes two short labels to stack vertically.
    await pump(
      t,
      GlassDialog(
        actionTextStyle: const TextStyle(fontSize: 40),
        actions: [
          GlassDialogAction(label: 'Cancel', onPressed: () {}),
          GlassDialogAction(label: 'Confirm', onPressed: () {}),
        ],
      ),
    );
    final cancelRect = t.getRect(find.text('Cancel'));
    final confirmRect = t.getRect(find.text('Confirm'));
    expect(confirmRect.top, greaterThan(cancelRect.bottom));
  });
}
