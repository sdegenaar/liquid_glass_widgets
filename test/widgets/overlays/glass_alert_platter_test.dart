// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show ColorScheme, MaterialApp, ThemeData;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
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
      Color capsuleColor(Finder region) {
        final container = tester.widget<Container>(
          find.descendant(
            of: region,
            matching: find.byWidgetPredicate(
              (w) => w is Container && w.decoration is ShapeDecoration,
            ),
          ),
        );
        return (container.decoration! as ShapeDecoration).color!;
      }

      // 1. Plain action disabled mid-press returns to its neutral rest wash.
      final applyRegion = find.ancestor(
        of: find.text('Apply'),
        matching: find.byType(GlassFocusRegion),
      );
      await tester.pumpWidget(app(
        GlassStyle.ios27,
        GlassDialog(
          title: 'Tea name',
          actions: [
            GlassDialogAction(label: 'Cancel', onPressed: () {}),
            GlassDialogAction(label: 'Apply', onPressed: () {}),
          ],
        ),
      ));

      final plainRestColor = capsuleColor(applyRegion);
      final plainGesture =
          await tester.startGesture(tester.getCenter(applyRegion));
      await tester.pump();
      expect(capsuleColor(applyRegion), isNot(equals(plainRestColor)));

      await tester.pumpWidget(app(
        GlassStyle.ios27,
        GlassDialog(
          title: 'Tea name',
          actions: [
            GlassDialogAction(label: 'Cancel', onPressed: () {}),
            const GlassDialogAction(label: 'Apply', onPressed: null),
          ],
        ),
      ));
      expect(capsuleColor(applyRegion), equals(plainRestColor));

      await plainGesture.up();
      await tester.pump();
      expect(capsuleColor(applyRegion), equals(plainRestColor));

      // 2. Primary action disabled mid-press reverts from pressed accent fill
      //    to the neutral capsule wash and stays neutral on release.
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

      final primaryRestColor = capsuleColor(saveRegion);
      expect(primaryRestColor, isNot(equals(plainRestColor)));

      final primaryGesture =
          await tester.startGesture(tester.getCenter(saveRegion));
      await tester.pump();
      expect(capsuleColor(saveRegion), isNot(equals(primaryRestColor)));

      await tester.pumpWidget(app(
        GlassStyle.ios27,
        GlassDialog(
          title: 'Tea name',
          actions: cancelAndDisabledSave(() {}),
        ),
      ));
      expect(capsuleColor(saveRegion), equals(plainRestColor));

      await primaryGesture.up();
      await tester.pump();
      expect(capsuleColor(saveRegion), equals(plainRestColor));
    });
  });

  group('prominent primary & custom tinted actions', () {
    Color capsuleColorOf(WidgetTester tester, String label) {
      final region = find.ancestor(
        of: find.text(label),
        matching: find.byType(GlassFocusRegion),
      );
      final container = tester.widget<Container>(
        find.descendant(
          of: region,
          matching: find.byWidgetPredicate(
            (w) => w is Container && w.decoration is ShapeDecoration,
          ),
        ),
      );
      return (container.decoration! as ShapeDecoration).color!;
    }

    TextStyle labelStyleOf(WidgetTester tester, String label) =>
        tester.widget<Text>(find.text(label)).style!;

    for (final style in [GlassStyle.ios26, GlassStyle.ios27]) {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        testWidgets(
            'isPrimary fills with CupertinoTheme.primaryColor + white w600 ($style, $brightness)',
            (tester) async {
          await tester.pumpWidget(
            CupertinoApp(
              theme: CupertinoThemeData(
                brightness: brightness,
                primaryColor: CupertinoColors.systemBlue,
              ),
              home: GlassTheme(
                data: GlassThemeData(style: style, brightness: brightness),
                child: CupertinoPageScaffold(
                  child: GlassDialog(
                    title: 'Save Changes?',
                    actions: [
                      GlassDialogAction(label: 'Cancel', onPressed: () {}),
                      GlassDialogAction(
                        label: 'Continue',
                        isPrimary: true,
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );

          final ctx = tester.element(find.text('Continue'));
          final expectedPrimary = CupertinoDynamicColor.resolve(
            CupertinoColors.systemBlue,
            ctx,
          );
          final expectedNeutral = brightness == Brightness.dark
              ? CupertinoColors.white
                  .withValues(alpha: style == GlassStyle.ios26 ? 0.13 : 0.115)
              : CupertinoColors.black
                  .withValues(alpha: style == GlassStyle.ios26 ? 0.10 : 0.15);

          expect(capsuleColorOf(tester, 'Continue'), expectedPrimary);
          expect(labelStyleOf(tester, 'Continue').color, CupertinoColors.white);
          expect(labelStyleOf(tester, 'Continue').fontWeight, FontWeight.w600);

          expect(capsuleColorOf(tester, 'Cancel'), expectedNeutral);
          expect(
            labelStyleOf(tester, 'Cancel').color,
            CupertinoColors.label.resolveFrom(ctx),
          );
          expect(labelStyleOf(tester, 'Cancel').fontWeight, FontWeight.w500);
        });
      }

      testWidgets(
          'disabled primary / tinted action reverts to neutral wash + tertiaryLabel ($style)',
          (tester) async {
        await tester.pumpWidget(app(
          style,
          GlassDialog(
            title: 'Subscribe?',
            actions: [
              GlassDialogAction(label: 'Cancel', onPressed: () {}),
              const GlassDialogAction(
                label: 'Continue',
                isPrimary: true,
                tintColor: CupertinoColors.systemPurple,
                foregroundColor: CupertinoColors.white,
                onPressed: null,
              ),
            ],
          ),
        ));

        final ctx = tester.element(find.text('Continue'));
        expect(
          capsuleColorOf(tester, 'Continue'),
          capsuleColorOf(tester, 'Cancel'),
        );
        expect(
          labelStyleOf(tester, 'Continue').color,
          CupertinoColors.tertiaryLabel.resolveFrom(ctx),
        );
        expect(labelStyleOf(tester, 'Continue').fontWeight, FontWeight.w600);
      });

      testWidgets(
          'destructive + isPrimary stays neutral capsule with Semibold red text ($style)',
          (tester) async {
        await tester.pumpWidget(app(
          style,
          GlassDialog(
            title: 'Delete Item?',
            actions: [
              GlassDialogAction(label: 'Cancel', onPressed: () {}),
              GlassDialogAction(
                label: 'Delete',
                isPrimary: true,
                isDestructive: true,
                onPressed: () {},
              ),
            ],
          ),
        ));

        final ctx = tester.element(find.text('Delete'));
        expect(
          capsuleColorOf(tester, 'Delete'),
          capsuleColorOf(tester, 'Cancel'),
        );
        expect(
          labelStyleOf(tester, 'Delete').color,
          CupertinoColors.systemRed.resolveFrom(ctx),
        );
        expect(labelStyleOf(tester, 'Delete').fontWeight, FontWeight.w600);
      });
    }

    testWidgets(
        'custom tintColor resolves CupertinoDynamicColor and flips contrast foreground',
        (tester) async {
      // Bright yellow tint → flips foreground to black.
      await tester.pumpWidget(app(
        GlassStyle.ios27,
        GlassDialog(
          title: 'Notice',
          actions: [
            GlassDialogAction(label: 'Cancel', onPressed: () {}),
            GlassDialogAction(
              label: 'Highlight',
              isPrimary: true,
              tintColor: CupertinoColors.systemYellow,
              onPressed: () {},
            ),
          ],
        ),
      ));

      var ctx = tester.element(find.text('Highlight'));
      expect(
        capsuleColorOf(tester, 'Highlight'),
        CupertinoColors.systemYellow.resolveFrom(ctx),
      );
      expect(labelStyleOf(tester, 'Highlight').color, CupertinoColors.black);

      // Dark-mode dynamic purple tint → resolves dark variant + white text.
      await tester.pumpWidget(app(
        GlassStyle.ios27,
        GlassDialog(
          title: 'Upgrade Plan',
          actions: [
            GlassDialogAction(label: 'Cancel', onPressed: () {}),
            GlassDialogAction(
              label: 'Upgrade',
              tintColor: CupertinoColors.systemPurple,
              onPressed: () {},
            ),
          ],
        ),
        brightness: Brightness.dark,
      ));

      ctx = tester.element(find.text('Upgrade'));
      expect(
        capsuleColorOf(tester, 'Upgrade'),
        CupertinoColors.systemPurple.resolveFrom(ctx),
      );
      expect(labelStyleOf(tester, 'Upgrade').color, CupertinoColors.white);
      expect(labelStyleOf(tester, 'Upgrade').fontWeight, FontWeight.w600);

      // Translucent tint (alpha <= 0.5) keeps ambient label contrast.
      final softWash = CupertinoColors.systemBlue.withValues(alpha: 0.2);
      await tester.pumpWidget(app(
        GlassStyle.ios27,
        GlassDialog(
          title: 'Soft Tint',
          actions: [
            GlassDialogAction(
              label: 'Soft',
              tintColor: softWash,
              onPressed: () {},
            ),
          ],
        ),
      ));
      ctx = tester.element(find.text('Soft'));
      expect(capsuleColorOf(tester, 'Soft'), softWash);
      expect(
        labelStyleOf(tester, 'Soft').color,
        CupertinoColors.label.resolveFrom(ctx),
      );
    });

    testWidgets(
        'explicit foregroundColor overrides auto-contrast and destructive tint fills explicitly',
        (tester) async {
      const customFg = CupertinoDynamicColor.withBrightness(
        color: Color(0xFFFFF8E1),
        darkColor: Color(0xFF1A1A1A),
      );

      await tester.pumpWidget(app(
        GlassStyle.ios27,
        GlassDialog(
          title: 'Confirm',
          actions: [
            GlassDialogAction(
              label: 'Brand',
              isPrimary: true,
              tintColor: const Color(0xFF00A896),
              foregroundColor: customFg,
              onPressed: () {},
            ),
            GlassDialogAction(
              label: 'Delete',
              isDestructive: true,
              tintColor: CupertinoColors.systemRed,
              onPressed: () {},
            ),
          ],
        ),
      ));

      final ctx = tester.element(find.text('Delete'));
      expect(capsuleColorOf(tester, 'Brand'), const Color(0xFF00A896));
      expect(
        labelStyleOf(tester, 'Brand').color?.toARGB32(),
        const Color(0xFFFFF8E1).toARGB32(),
      );
      expect(
        capsuleColorOf(tester, 'Delete'),
        CupertinoColors.systemRed.resolveFrom(ctx),
      );
      expect(labelStyleOf(tester, 'Delete').color, CupertinoColors.white);
    });

    testWidgets(
        'pressed prominent capsule drops to 0.40 alpha and hover applies subtle feedback',
        (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );

      const brand = Color(0xFF0088FF);
      await tester.pumpWidget(app(
        GlassStyle.ios27,
        GlassDialog(
          title: 'Confirm',
          actions: [
            GlassDialogAction(label: 'Cancel', onPressed: () {}),
            GlassDialogAction(
              label: 'Continue',
              isPrimary: true,
              tintColor: brand,
              onPressed: () {},
            ),
          ],
        ),
      ));

      expect(capsuleColorOf(tester, 'Continue'), brand);
      final neutralRest = capsuleColorOf(tester, 'Cancel');

      // Hover prominent capsule → 0.85 alpha.
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.text('Continue')));
      await tester.pump();
      expect(
        capsuleColorOf(tester, 'Continue').a,
        closeTo(0.85, 0.01),
      );

      // Hover plain capsule → restAlpha + 0.04.
      await mouse.moveTo(tester.getCenter(find.text('Cancel')));
      await tester.pump();
      expect(
        capsuleColorOf(tester, 'Cancel').a,
        closeTo(neutralRest.a + 0.04, 0.01),
      );
      await mouse.removePointer();
      await tester.pump();

      // Press prominent capsule → 0.40 alpha (measured on iOS 27.0).
      final press =
          await tester.startGesture(tester.getCenter(find.text('Continue')));
      await tester.pump();
      expect(
        capsuleColorOf(tester, 'Continue').a,
        closeTo(0.40, 0.01),
      );
      await press.up();
      await tester.pump();
      expect(capsuleColorOf(tester, 'Continue'), brand);
    });

    testWidgets(
        'GlassStyle.classic forwards prominent style, tintColor, and foregroundColor to GlassButton',
        (tester) async {
      await tester.pumpWidget(app(
        GlassStyle.classic,
        GlassDialog(
          title: 'Confirm',
          actions: [
            GlassDialogAction(label: 'Cancel', onPressed: () {}),
            GlassDialogAction(
              label: 'Continue',
              isPrimary: true,
              tintColor: CupertinoColors.systemYellow,
              onPressed: () {},
            ),
            GlassDialogAction(
              label: 'Delete',
              isPrimary: true,
              isDestructive: true,
              onPressed: () {},
            ),
          ],
        ),
      ));

      GlassButton buttonOf(String label) => tester.widget<GlassButton>(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(GlassButton),
            ),
          );

      final ctx = tester.element(find.text('Continue'));
      expect(buttonOf('Cancel').style, GlassButtonStyle.filled);
      expect(buttonOf('Cancel').tintColor, isNull);

      expect(buttonOf('Continue').style, GlassButtonStyle.prominent);
      expect(
        buttonOf('Continue').tintColor,
        CupertinoColors.systemYellow.resolveFrom(ctx),
      );
      expect(labelStyleOf(tester, 'Continue').color, CupertinoColors.black);

      // Destructive + isPrimary without explicit tint stays filled + resolved red.
      expect(buttonOf('Delete').style, GlassButtonStyle.filled);
      expect(buttonOf('Delete').tintColor, isNull);
      expect(
        labelStyleOf(tester, 'Delete').color,
        CupertinoColors.destructiveRed.resolveFrom(ctx),
      );
    });

    testWidgets(
        'open GlassDialog.show updates prominent capsule color live on brightness switch',
        (tester) async {
      final brightness = ValueNotifier<Brightness>(Brightness.light);
      addTearDown(brightness.dispose);

      await tester.pumpWidget(
        ValueListenableBuilder<Brightness>(
          valueListenable: brightness,
          builder: (context, currentBrightness, _) => GlassTheme(
            data: GlassThemeData.ios27(brightness: currentBrightness),
            child: CupertinoApp(
              theme: CupertinoThemeData(
                brightness: currentBrightness,
                primaryColor: CupertinoColors.systemBlue,
              ),
              home: CupertinoPageScaffold(
                child: Builder(
                  builder: (ctx) => CupertinoButton(
                    onPressed: () => GlassDialog.show<void>(
                      context: ctx,
                      title: 'Sync',
                      actions: [
                        GlassDialogAction(
                          label: 'Cancel',
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                        GlassDialogAction(
                          label: 'Continue',
                          isPrimary: true,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        capsuleColorOf(tester, 'Continue').toARGB32(),
        CupertinoColors.systemBlue.color.toARGB32(),
      );

      brightness.value = Brightness.dark;
      await tester.pumpAndSettle();
      expect(
        capsuleColorOf(tester, 'Continue').toARGB32(),
        CupertinoColors.systemBlue.darkColor.toARGB32(),
      );
    });

    testWidgets(
        'MaterialApp colorScheme.primary automatically drives isPrimary capsule fill',
        (tester) async {
      const customPrimary = Color(0xFF006A6A);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: const ColorScheme.light(primary: customPrimary),
          ),
          home: GlassDialog(
            title: 'Subscribe?',
            actions: [
              GlassDialogAction(label: 'Cancel', onPressed: () {}),
              GlassDialogAction(
                label: 'Continue',
                isPrimary: true,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      expect(
        capsuleColorOf(tester, 'Continue').toARGB32(),
        customPrimary.toARGB32(),
      );
      expect(labelStyleOf(tester, 'Continue').color, CupertinoColors.white);
      expect(labelStyleOf(tester, 'Continue').fontWeight, FontWeight.w600);
    });

    testWidgets(
        'MaterialApp dark mode pastel colorScheme.primary auto-flips label to black',
        (tester) async {
      final darkScheme = ColorScheme.fromSeed(
        seedColor: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      );
      expect(darkScheme.primary.computeLuminance(), greaterThan(0.55));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: darkScheme),
          home: GlassTheme(
            data: const GlassThemeData.ios27(brightness: Brightness.dark),
            child: GlassDialog(
              title: 'Continue?',
              actions: [
                GlassDialogAction(label: 'Cancel', onPressed: () {}),
                GlassDialogAction(
                  label: 'Continue',
                  isPrimary: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        capsuleColorOf(tester, 'Continue').toARGB32(),
        darkScheme.primary.toARGB32(),
      );
      expect(labelStyleOf(tester, 'Continue').color, CupertinoColors.black);
    });

    testWidgets(
        'direct GlassDialog syncs CupertinoTheme brightness with GlassTheme.brightnessOf',
        (tester) async {
      // Light CupertinoApp host with an explicit dark GlassTheme override.
      await tester.pumpWidget(
        CupertinoApp(
          theme: const CupertinoThemeData(
            brightness: Brightness.light,
            primaryColor: CupertinoColors.systemBlue,
          ),
          home: GlassTheme(
            data: const GlassThemeData.ios27(brightness: Brightness.dark),
            child: GlassDialog(
              title: 'Dark Override',
              actions: [
                GlassDialogAction(label: 'Cancel', onPressed: () {}),
                GlassDialogAction(
                  label: 'Continue',
                  isPrimary: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(
        capsuleColorOf(tester, 'Continue').toARGB32(),
        CupertinoColors.systemBlue.darkColor.toARGB32(),
      );
      expect(
        labelStyleOf(tester, 'Cancel').color?.toARGB32(),
        CupertinoColors.label.darkColor.toARGB32(),
      );
    });

    testWidgets(
        'Increase Contrast (highContrast: true) resolves high-contrast accent variants',
        (tester) async {
      for (final brightness in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(highContrast: true),
            child: CupertinoApp(
              theme: CupertinoThemeData(
                brightness: brightness,
                primaryColor: CupertinoColors.systemBlue,
              ),
              home: GlassTheme(
                data: GlassThemeData.ios27(brightness: brightness),
                child: GlassDialog(
                  title: 'High Contrast',
                  actions: [
                    GlassDialogAction(
                      label: 'Continue',
                      isPrimary: true,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final expected = brightness == Brightness.dark
            ? CupertinoColors.systemBlue.darkHighContrastColor
            : CupertinoColors.systemBlue.highContrastColor;
        expect(
          capsuleColorOf(tester, 'Continue').toARGB32(),
          expected.toARGB32(),
        );
      }
    });

    group('hardware keyboard Return / Enter primary activation', () {
      for (final style in GlassStyle.values) {
        testWidgets('Enter activates single enabled isPrimary action ($style)',
            (tester) async {
          var cancels = 0;
          var confirms = 0;
          await tester.pumpWidget(app(
            style,
            GlassDialog(
              title: 'Confirm',
              actions: [
                GlassDialogAction(
                  label: 'Cancel',
                  onPressed: () => cancels++,
                ),
                GlassDialogAction(
                  label: 'Continue',
                  isPrimary: true,
                  onPressed: () => confirms++,
                ),
              ],
            ),
          ));
          await tester.pump();

          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(confirms, 1);
          expect(cancels, 0);

          await tester.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
          await tester.pump();
          expect(confirms, 2);
          expect(cancels, 0);
        });
      }

      testWidgets(
          'Tab to Cancel + Enter activates Cancel instead of primary action',
          (tester) async {
        var cancels = 0;
        var confirms = 0;
        await tester.pumpWidget(app(
          GlassStyle.ios27,
          GlassDialog(
            title: 'Confirm',
            actions: [
              GlassDialogAction(label: 'Cancel', onPressed: () => cancels++),
              GlassDialogAction(
                label: 'Continue',
                isPrimary: true,
                onPressed: () => confirms++,
              ),
            ],
          ),
        ));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(cancels, 1);
        expect(confirms, 0);
      });

      testWidgets(
          'disabled primary action and Shift+Enter do not trigger primary callback',
          (tester) async {
        var confirms = 0;
        await tester.pumpWidget(app(
          GlassStyle.ios27,
          GlassDialog(
            title: 'Confirm',
            actions: [
              GlassDialogAction(label: 'Cancel', onPressed: () {}),
              const GlassDialogAction(
                label: 'Continue',
                isPrimary: true,
                onPressed: null,
              ),
            ],
          ),
        ));
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(confirms, 0);

        // Enable primary action and test Shift+Enter is ignored.
        await tester.pumpWidget(app(
          GlassStyle.ios27,
          GlassDialog(
            title: 'Confirm',
            actions: [
              GlassDialogAction(label: 'Cancel', onPressed: () {}),
              GlassDialogAction(
                label: 'Continue',
                isPrimary: true,
                onPressed: () => confirms++,
              ),
            ],
          ),
        ));
        await tester.pump();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.pump();
        expect(confirms, 0);
      });

      testWidgets(
          'autofocused CupertinoTextField in content keeps focus and owns Enter',
          (tester) async {
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        var confirms = 0;

        await tester.pumpWidget(app(
          GlassStyle.ios27,
          GlassDialog(
            title: 'Rename',
            content: CupertinoTextField(
              focusNode: focusNode,
              autofocus: true,
            ),
            actions: [
              GlassDialogAction(label: 'Cancel', onPressed: () {}),
              GlassDialogAction(
                label: 'Save',
                isPrimary: true,
                onPressed: () => confirms++,
              ),
            ],
          ),
        ));
        await tester.pump();
        await tester.pump();

        expect(focusNode.hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(confirms, 0);
      });
    });
  });
}
