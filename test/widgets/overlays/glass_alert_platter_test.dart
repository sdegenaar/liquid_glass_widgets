import 'package:flutter/cupertino.dart';
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
  });
}
