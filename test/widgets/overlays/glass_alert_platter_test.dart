import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/widgets/overlays/glass_alert_platter.dart';
import 'package:liquid_glass_widgets/widgets/shared/glass_focus_region.dart';

/// Geometry measured from the native `UIAlertController` on the iOS 26.0 and
/// iOS 27.0 simulators (identical on both): a 320 pt platter with a 34 pt
/// continuous radius, a leading-aligned header at x = 30 / y = 22, and 48 pt
/// filled capsule actions inset 16 pt, 8 pt apart.
void main() {
  Widget app(GlassStyle style, Widget child,
      {Brightness brightness = Brightness.light}) {
    return CupertinoApp(
      theme: CupertinoThemeData(brightness: brightness),
      home: GlassTheme(
        data: GlassThemeData(style: style, brightness: brightness),
        child: CupertinoPageScaffold(child: child),
      ),
    );
  }

  List<GlassDialogAction> actions(int n) => [
        for (var i = 0; i < n; i++)
          GlassDialogAction(label: 'Act$i', onPressed: () {}),
      ];

  for (final style in [GlassStyle.ios26, GlassStyle.ios27]) {
    group('GlassDialog native platter ($style)', () {
      testWidgets('is 320pt wide with a 34pt continuous radius',
          (tester) async {
        await tester.pumpWidget(app(
          style,
          GlassDialog(title: 'Title', message: 'Message', actions: actions(2)),
        ));

        final container =
            tester.widget<GlassContainer>(find.byType(GlassContainer));
        expect(
          container.shape,
          const LiquidRoundedSuperellipse(borderRadius: 34),
        );
        expect(tester.getSize(find.byType(GlassContainer)).width, 320);
      });

      testWidgets('header is leading-aligned at x=30 with 17/15pt type',
          (tester) async {
        await tester.pumpWidget(app(
          style,
          GlassDialog(title: 'Title', message: 'Message', actions: actions(2)),
        ));

        final platter = tester.getTopLeft(find.byType(GlassContainer));
        final title = tester.widget<Text>(find.text('Title'));
        final message = tester.widget<Text>(find.text('Message'));
        expect(title.style!.fontSize, 17);
        expect(title.style!.fontWeight, FontWeight.w600);
        expect(message.style!.fontSize, 15);

        expect(tester.getTopLeft(find.text('Title')).dx - platter.dx, 30);
        expect(tester.getTopLeft(find.text('Title')).dy - platter.dy, 22);
        // 7.33pt between the title and message boxes.
        final titleBottom = tester.getBottomLeft(find.text('Title')).dy;
        final messageTop = tester.getTopLeft(find.text('Message')).dy;
        expect(messageTop - titleBottom, closeTo(7.33, 0.01));
      });

      testWidgets('two actions share a row as 140x48 capsules', (tester) async {
        await tester.pumpWidget(app(
          style,
          GlassDialog(title: 'Title', message: 'Message', actions: actions(2)),
        ));

        final regions = find.byType(GlassFocusRegion);
        expect(regions, findsNWidgets(2));
        final a = tester.getRect(regions.at(0));
        final b = tester.getRect(regions.at(1));
        expect(a.size, const Size(140, 48));
        expect(b.size, const Size(140, 48));
        expect(a.top, b.top);
        expect(b.left - a.right, 8);
        final platter = tester.getRect(find.byType(GlassContainer));
        expect(a.left - platter.left, 16);
        expect(platter.right - b.right, 16);
        expect(platter.bottom - a.bottom, 16);
      });

      testWidgets('three actions stack as 288x48 capsules 8pt apart',
          (tester) async {
        await tester.pumpWidget(app(
          style,
          GlassDialog(title: 'Title', message: 'Message', actions: actions(3)),
        ));

        final regions = find.byType(GlassFocusRegion);
        expect(regions, findsNWidgets(3));
        for (var i = 0; i < 3; i++) {
          expect(tester.getSize(regions.at(i)), const Size(288, 48));
        }
        expect(
          tester.getTopLeft(regions.at(1)).dy -
              tester.getBottomLeft(regions.at(0)).dy,
          8,
        );
      });

      testWidgets('destructive action is red, others use the label color',
          (tester) async {
        await tester.pumpWidget(app(
          style,
          GlassDialog(
            title: 'Title',
            actions: [
              GlassDialogAction(label: 'Keep', onPressed: () {}),
              GlassDialogAction(
                label: 'Delete',
                isDestructive: true,
                onPressed: () {},
              ),
            ],
          ),
        ));

        final context = tester.element(find.byType(GlassDialog));
        expect(
          tester.widget<Text>(find.text('Delete')).style!.color,
          CupertinoColors.systemRed.resolveFrom(context),
        );
        expect(
          tester.widget<Text>(find.text('Keep')).style!.color,
          CupertinoColors.label.resolveFrom(context),
        );
      });

      testWidgets('actions are tappable', (tester) async {
        var taps = 0;
        await tester.pumpWidget(app(
          style,
          GlassDialog(
            title: 'Title',
            actions: [GlassDialogAction(label: 'Go', onPressed: () => taps++)],
          ),
        ));

        await tester.tap(find.text('Go'));
        expect(taps, 1);
      });
    });

    group('showGlassActionSheet native platter ($style)', () {
      testWidgets('is the centred alert platter with Cancel inside',
          (tester) async {
        await tester.pumpWidget(app(
          style,
          Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => showGlassActionSheet<void>(
                context: context,
                title: 'Choose Action',
                message: 'Pick one',
                actions: [
                  GlassActionSheetAction(label: 'Share', onPressed: () {}),
                  GlassActionSheetAction(
                    label: 'Delete',
                    style: GlassActionSheetStyle.destructive,
                    onPressed: () {},
                  ),
                ],
              ),
              child: const Text('Open'),
            ),
          ),
        ));

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();

        expect(find.byType(GlassAlertPlatter), findsOneWidget);
        final platter = tester.getRect(find.byType(GlassContainer));
        expect(platter.width, 320);
        // Centred, not bottom-anchored.
        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        expect(platter.center.dy, closeTo(screen.height / 2, 1));

        // Share, Delete and Cancel are stacked 288x48 capsules in the platter.
        final regions = find.descendant(
          of: find.byType(GlassAlertPlatter),
          matching: find.byType(GlassFocusRegion),
        );
        expect(regions, findsNWidgets(3));
        for (var i = 0; i < 3; i++) {
          expect(tester.getSize(regions.at(i)), const Size(288, 48));
        }
        expect(
          tester.getTopLeft(find.text('Cancel')).dy,
          greaterThan(tester.getTopLeft(find.text('Delete')).dy),
        );
      });

      testWidgets('actions run their callback and dismiss; Cancel dismisses',
          (tester) async {
        var shared = 0;
        await tester.pumpWidget(app(
          style,
          Builder(
            builder: (context) => CupertinoButton(
              onPressed: () => showGlassActionSheet<void>(
                context: context,
                actions: [
                  GlassActionSheetAction(
                    label: 'Share',
                    onPressed: () => shared++,
                  ),
                ],
              ),
              child: const Text('Open'),
            ),
          ),
        ));

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Share'));
        await tester.pumpAndSettle();
        expect(shared, 1);
        expect(find.byType(GlassAlertPlatter), findsNothing);

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(GlassAlertPlatter), findsNothing);
      });
    });
  }

  testWidgets('classic keeps the 280pt dialog and the bottom action sheet',
      (tester) async {
    await tester.pumpWidget(app(
      GlassStyle.classic,
      Builder(
        builder: (context) => Column(
          children: [
            CupertinoButton(
              onPressed: () => showGlassActionSheet<void>(
                context: context,
                actions: [
                  GlassActionSheetAction(label: 'Share', onPressed: () {}),
                ],
              ),
              child: const Text('Open'),
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.byType(GlassAlertPlatter), findsNothing);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    expect(
      tester.getCenter(find.text('Cancel')).dy,
      greaterThan(screen.height * 0.6),
      reason: 'classic action sheet is bottom-anchored',
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(app(
      GlassStyle.classic,
      GlassDialog(title: 'Title', actions: actions(2)),
    ));
    expect(tester.getSize(find.byType(GlassContainer)).width, 280);
  });

  group('measured native material', () {
    Color? capsuleFill(WidgetTester tester) {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(GlassFocusRegion).first,
              matching: find.byType(Container),
            )
            .first,
      );
      return (container.decoration as ShapeDecoration).color;
    }

    LiquidGlassSettings platterSettings(WidgetTester tester) => tester
        .widget<AdaptiveGlass>(
          find
              .descendant(
                of: find.byType(GlassAlertPlatter),
                matching: find.byType(AdaptiveGlass),
              )
              .first,
        )
        .settings;

    Future<void> pumpDialog(
      WidgetTester tester,
      GlassStyle style,
      Brightness brightness, {
      LiquidGlassSettings? settings,
    }) {
      return tester.pumpWidget(app(
        style,
        GlassDialog(title: 'T', settings: settings, actions: actions(2)),
        brightness: brightness,
      ));
    }

    test('barrier dims 0.21 (light) / 0.47 (dark), as measured natively', () {
      expect(glassAlertBarrierColor(isDark: false), const Color(0x35000000));
      expect(glassAlertBarrierColor(isDark: true), const Color(0x77000000));
    });

    testWidgets('capsule wash: iOS 27 0.15 light / 0.115 dark', (tester) async {
      await pumpDialog(tester, GlassStyle.ios27, Brightness.light);
      expect(
          capsuleFill(tester), CupertinoColors.black.withValues(alpha: 0.15));
      await pumpDialog(tester, GlassStyle.ios27, Brightness.dark);
      expect(
        capsuleFill(tester),
        CupertinoColors.white.withValues(alpha: 0.115),
      );
    });

    testWidgets('capsule wash: iOS 26 0.10 light / 0.13 dark', (tester) async {
      await pumpDialog(tester, GlassStyle.ios26, Brightness.light);
      expect(
          capsuleFill(tester), CupertinoColors.black.withValues(alpha: 0.10));
      await pumpDialog(tester, GlassStyle.ios26, Brightness.dark);
      expect(
          capsuleFill(tester), CupertinoColors.white.withValues(alpha: 0.13));
    });

    testWidgets('defaults to GlassQuality.premium on the native styles',
        (tester) async {
      await pumpDialog(tester, GlassStyle.ios26, Brightness.dark);
      final adaptive = tester.widget<AdaptiveGlass>(
        find
            .descendant(
              of: find.byType(GlassAlertPlatter),
              matching: find.byType(AdaptiveGlass),
            )
            .first,
      );
      expect(adaptive.quality, GlassQuality.premium);
      expect(platterSettings(tester).frostOpacity, 1.0);
    });

    testWidgets('iOS 26 dark alert uses the thin measured tint',
        (tester) async {
      await pumpDialog(tester, GlassStyle.ios26, Brightness.dark);
      expect(platterSettings(tester).glassColor, const Color(0x05FFFFFF));
    });

    testWidgets('other style/brightness keep the shared platter preset',
        (tester) async {
      await pumpDialog(tester, GlassStyle.ios26, Brightness.light);
      expect(
        platterSettings(tester).glassColor,
        LiquidGlassSettings.ios26Light.glassColor,
      );
      await pumpDialog(tester, GlassStyle.ios27, Brightness.dark);
      expect(
        platterSettings(tester).glassColor,
        LiquidGlassSettings.ios27Dark.glassColor,
      );
    });

    testWidgets('explicit settings are never overridden', (tester) async {
      const custom = LiquidGlassSettings(
        glassColor: Color(0x80FF0000),
        frost: 3,
        blur: 2,
      );
      await pumpDialog(
        tester,
        GlassStyle.ios26,
        Brightness.dark,
        settings: custom,
      );
      expect(platterSettings(tester).glassColor, custom.glassColor);
    });

    testWidgets(
        'renders title alongside custom content and resets press highlight on tap cancel',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: GlassTheme(
            data: const GlassThemeData.ios27(brightness: Brightness.light),
            child: GlassDialog(
              title: 'Header Title',
              content: const Text('Custom body content'),
              actions: [
                GlassDialogAction(label: 'OK', onPressed: () {}),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Header Title'), findsOneWidget);
      expect(find.text('Custom body content'), findsOneWidget);

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('OK')),
      );
      await tester.pump();
      await gesture.cancel();
      await tester.pump();
    });
  });

  // Behaviour measured from UIAlertController on the iOS 26.5 and iOS 27.0
  // simulators: the header scrolls, the platter re-centres above the keyboard,
  // and action titles wrap only at accessibility text sizes.
  group('native platter with real content', () {
    final longMessage =
        List.filled(60, 'This is a long line of message text.').join(' ');

    void setScreen(WidgetTester tester, Size size, {double keyboard = 0}) {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = size;
      tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.reset);
    }

    Widget dialog({
      String? title = 'Title',
      String? message,
      Widget? content,
      List<GlassDialogAction>? actions,
      double textScale = 1,
    }) {
      return Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: GlassDialog(
            title: title,
            message: message,
            content: content,
            actions: actions ??
                [
                  GlassDialogAction(label: 'No', onPressed: () {}),
                  GlassDialogAction(label: 'OK', onPressed: () {}),
                ],
          ),
        ),
      );
    }

    // Opens [show] from a button, so the platter is a route above the page.
    Widget opener(void Function(BuildContext) show) => Builder(
          builder: (context) => CupertinoButton(
            onPressed: () => show(context),
            child: const Text('Open'),
          ),
        );

    testWidgets('a header taller than the screen scrolls; actions stay visible',
        (tester) async {
      setScreen(tester, const Size(390, 400));
      await tester
          .pumpWidget(app(GlassStyle.ios27, dialog(message: longMessage)));

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(
          of: find.byType(GlassAlertPlatter),
          matching: find.byType(Scrollable),
        ),
        findsOneWidget,
      );
      expect(tester.getRect(find.text('OK')).bottom, lessThanOrEqualTo(400));
    });

    testWidgets('re-centres in the space above the keyboard', (tester) async {
      // Shown as a route, so no page scaffold has already inset it.
      setScreen(tester, const Size(402, 874), keyboard: 336);
      await tester.pumpWidget(app(
        GlassStyle.ios27,
        opener((context) => GlassDialog.show<void>(
              context: context,
              title: 'Tea name',
              content: const CupertinoTextField(),
              actions: [GlassDialogAction(label: 'OK', onPressed: () {})],
            )),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final platter = tester.getRect(find.byType(GlassContainer));
      expect(platter.center.dy, closeTo((874 - 336) / 2, 1));
      expect(platter.bottom, lessThanOrEqualTo(874 - 336));
    });

    testWidgets('reports an alert dialog route to assistive technology',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(GlassStyle.ios27, dialog(message: 'Body')));

      final node = tester.getSemantics(find.bySemanticsLabel('Alert'));
      expect(node.getSemanticsData().role, SemanticsRole.alertDialog);
      expect(node, isSemantics(scopesRoute: true, namesRoute: true));
      handle.dispose();
    });

    testWidgets('an action sheet reports a dialog route', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(
        GlassStyle.ios27,
        opener((context) => showGlassActionSheet<void>(
              context: context,
              title: 'Choose',
              actions: [
                GlassActionSheetAction(label: 'Share', onPressed: () {}),
              ],
            )),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final node = tester.getSemantics(find.bySemanticsLabel('Alert'));
      expect(node.getSemanticsData().role, SemanticsRole.dialog);
      expect(node, isSemantics(scopesRoute: true, namesRoute: true));
      handle.dispose();
    });

    testWidgets(
        'shown from a MaterialApp, text does not inherit the error style',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: opener((context) => GlassDialog.show<void>(
              context: context,
              title: 'Title',
              message: 'Message',
              content: const Text('Content'),
              actions: [GlassDialogAction(label: 'OK', onPressed: () {})],
            )),
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      for (final text in ['Title', 'Message', 'Content', 'OK']) {
        final style =
            tester.renderObject<RenderParagraph>(find.text(text)).text.style!;
        expect(style.decoration, isNot(TextDecoration.underline), reason: text);
        expect(style.fontFamily, isNot('monospace'), reason: text);
      }
      // Plain text in custom content takes the message style.
      final content = tester
          .renderObject<RenderParagraph>(find.text('Content'))
          .text
          .style!;
      expect(content.fontSize, 15);
    });

    const longLabel = 'Discard all unsaved changes';
    List<GlassDialogAction> longActions() => [
          GlassDialogAction(
              label: longLabel, isDestructive: true, onPressed: () {}),
          GlassDialogAction(label: 'Keep', onPressed: () {}),
        ];
    final longButton = find.ancestor(
      of: find.text(longLabel),
      matching: find.byType(GlassFocusRegion),
    );
    ShapeBorder buttonShape(WidgetTester tester) {
      final fill = tester.widget<Container>(find
          .ancestor(of: find.text(longLabel), matching: find.byType(Container))
          .first);
      return (fill.decoration! as ShapeDecoration).shape;
    }

    testWidgets('action titles stay on one line at regular text sizes',
        (tester) async {
      await tester
          .pumpWidget(app(GlassStyle.ios27, dialog(actions: longActions())));
      expect(tester.widget<Text>(find.text(longLabel)).maxLines, 1);
      expect(tester.getSize(longButton).height, 48);
      expect(buttonShape(tester), const StadiumBorder());

      // The largest scale below the accessibility sizes: still one line.
      await tester.pumpWidget(app(
        GlassStyle.ios27,
        dialog(actions: longActions(), textScale: 1.3),
      ));
      expect(tester.widget<Text>(find.text(longLabel)).maxLines, 1);
    });

    testWidgets('action titles wrap and grow the button at accessibility sizes',
        (tester) async {
      await tester.pumpWidget(app(
        GlassStyle.ios27,
        dialog(actions: longActions(), textScale: 2),
      ));

      expect(tester.takeException(), isNull);
      final text = tester.widget<Text>(find.text(longLabel));
      expect(text.maxLines, isNull);
      expect(text.overflow, isNull);
      expect(tester.getSize(longButton).height, greaterThan(48));
      // A tall button takes rounded corners rather than becoming an oval.
      expect(
        buttonShape(tester),
        const RoundedSuperellipseBorder(
          borderRadius: BorderRadius.all(Radius.circular(32)),
        ),
      );
    });
  });

  // A disabled UIAlertAction (isEnabled = false) on the iOS 27.0 simulator
  // keeps its capsule and weight and reports its title in tertiaryLabel.
  group('disabled actions', () {
    List<GlassDialogAction> cancelAndDisabledSave(void Function() onCancel) => [
          GlassDialogAction(label: 'Cancel', onPressed: onCancel),
          const GlassDialogAction(
            label: 'Save',
            onPressed: null,
            isPrimary: true,
          ),
        ];
    final saveRegion = find.ancestor(
      of: find.text('Save'),
      matching: find.byType(GlassFocusRegion),
    );

    for (final style in [GlassStyle.ios26, GlassStyle.ios27]) {
      testWidgets('a null onPressed disables the action ($style)',
          (tester) async {
        var cancels = 0;
        await tester.pumpWidget(app(
          style,
          GlassDialog(
            title: 'Tea name',
            actions: cancelAndDisabledSave(() => cancels++),
          ),
        ));

        await tester.tap(find.text('Save'));
        await tester.pump();
        expect(tester.takeException(), isNull);

        final save = tester.widget<Text>(find.text('Save'));
        final context = tester.element(find.text('Save'));
        expect(
          save.style!.color,
          CupertinoColors.tertiaryLabel.resolveFrom(context),
        );
        // The preferred action stays semibold while disabled.
        expect(save.style!.fontWeight, FontWeight.w600);
        // Still a full 48pt capsule in its place in the row.
        expect(tester.getSize(saveRegion), const Size(140, 48));

        // Its enabled neighbour is unaffected.
        await tester.tap(find.text('Cancel'));
        expect(cancels, 1);
      });
    }

    testWidgets('a disabled action is reported as disabled with no tap action',
        (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(app(
        GlassStyle.ios27,
        GlassDialog(title: 'Tea name', actions: cancelAndDisabledSave(() {})),
      ));

      expect(
        tester.getSemantics(saveRegion),
        isSemantics(
          label: 'Save',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          hasTapAction: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('classic disables the GlassButton', (tester) async {
      await tester.pumpWidget(app(
        GlassStyle.classic,
        GlassDialog(title: 'Tea name', actions: cancelAndDisabledSave(() {})),
      ));

      final save = tester.widget<GlassButton>(find.ancestor(
        of: find.text('Save'),
        matching: find.byType(GlassButton),
      ));
      expect(save.enabled, isFalse);
    });

    testWidgets(
        'disabling an action while pressed clears the pressed capsule wash',
        (tester) async {
      Color capsuleColor() {
        final container = tester.widget<Container>(
          find.descendant(
            of: saveRegion,
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is ShapeDecoration,
            ),
          ),
        );
        return (container.decoration! as ShapeDecoration).color!;
      }

      await tester.pumpWidget(app(
        GlassStyle.ios27,
        GlassDialog(
          title: 'Tea name',
          actions: [
            GlassDialogAction(label: 'Cancel', onPressed: () {}),
            GlassDialogAction(
              label: 'Save',
              onPressed: () {},
              isPrimary: true,
            ),
          ],
        ),
      ));

      final restColor = capsuleColor();

      // Press down on the enabled Save action and hold.
      final gesture = await tester.startGesture(tester.getCenter(saveRegion));
      await tester.pump();
      expect(capsuleColor(), isNot(equals(restColor)));

      // Rebuild with Save disabled while the pointer is still down.
      await tester.pumpWidget(app(
        GlassStyle.ios27,
        GlassDialog(
          title: 'Tea name',
          actions: cancelAndDisabledSave(() {}),
        ),
      ));
      expect(capsuleColor(), equals(restColor));

      await gesture.up();
      await tester.pump();
      expect(capsuleColor(), equals(restColor));
    });
  });
}
