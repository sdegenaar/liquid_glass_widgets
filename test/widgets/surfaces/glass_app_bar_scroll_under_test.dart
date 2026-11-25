import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/widgets/surfaces/app_bar_scroll_under_surface.dart';
import 'package:liquid_glass_widgets/src/widgets/surfaces/vertical_bar_regions.dart';

import '../../shared/test_helpers.dart';

void main() {
  /// Finds the scroll-under surface's [BackdropFilter], if currently mounted.
  Finder findScrollUnderBackdropFilter() => find.descendant(
        of: find.byType(GlassAppBarScrollUnderSurface),
        matching: find.byType(BackdropFilter),
      );

  /// Finds the scroll-under surface's [DecoratedBox], if currently mounted.
  Finder findScrollUnderDecoratedBox() => find.descendant(
        of: find.byType(GlassAppBarScrollUnderSurface),
        matching: find.byType(DecoratedBox),
      );

  Widget buildScrollableScaffold({
    GlassAppBar appBar = const GlassAppBar(title: Text('Messages')),
    GlassThemeData theme = const GlassThemeData(),
    GlassThemeData? themeOverride,
    GlassScrollEdgeStyle edgeStyle = GlassScrollEdgeStyle.soft,
    bool? topEdgeFade,
    double topEdgeFadeExtent = 20.0,
    bool edgeFade = true,
    Widget? bottomBar,
    ScrollController? controller,
    bool reverse = false,
    Axis scrollDirection = Axis.vertical,
    int itemCount = 40,
    bool reduceTransparency = false,
    double devicePixelRatio = 3.0,
    bool useCupertinoApp = true,
    Brightness platformBrightness = Brightness.light,
  }) {
    final Widget scaffold = GlassScaffold(
      appBar: appBar,
      bottomBar: bottomBar,
      themeOverride: themeOverride,
      edgeStyle: edgeStyle,
      topEdgeFade: topEdgeFade,
      topEdgeFadeExtent: topEdgeFadeExtent,
      edgeFade: edgeFade,
      body: ListView.builder(
        controller: controller,
        reverse: reverse,
        scrollDirection: scrollDirection,
        itemCount: itemCount,
        itemExtent: 60,
        itemBuilder: (_, i) => Text('Item $i'),
      ),
    );

    final Widget themed = GlassAccessibilityScope(
      reduceTransparency: reduceTransparency,
      child: GlassTheme(
        data: theme,
        child: AdaptiveLiquidGlassLayer(
          settings: defaultTestGlassSettings,
          child: scaffold,
        ),
      ),
    );

    final Widget app = useCupertinoApp
        ? CupertinoApp(
            theme: CupertinoThemeData(brightness: platformBrightness),
            home: themed,
          )
        : MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: platformBrightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            home: themed,
          );

    return MediaQuery(
      data: MediaQueryData(
        size: const Size(402, 874),
        devicePixelRatio: devicePixelRatio,
        padding: const EdgeInsets.only(top: 62, bottom: 34),
        platformBrightness: platformBrightness,
      ),
      child: app,
    );
  }

  group('GlassAppBar scroll-under surface (#534)', () {
    testWidgets(
      'ios27 automatic default: transparent at offset 0, interpolates over '
      '10pt, reaches full blur + 1px hairline, and hides again at top',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildScrollableScaffold(
              controller: controller, devicePixelRatio: 3.0),
        );
        await tester.pump();

        // At scroll offset 0: no BackdropFilter and no DecoratedBox painted.
        expect(find.byType(GlassAppBarScrollUnderSurface), findsOneWidget);
        expect(findScrollUnderBackdropFilter(), findsNothing);
        expect(findScrollUnderDecoratedBox(), findsNothing);

        // Mid-transition (5 logical px / 10 extent => visibility = 0.5).
        controller.jumpTo(5.0);
        await tester.pump();

        expect(findScrollUnderBackdropFilter(), findsOneWidget);
        final midFilter =
            tester.widget<BackdropFilter>(findScrollUnderBackdropFilter());
        expect(
          midFilter.filter,
          equals(
            ui.ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
              tileMode: ui.TileMode.clamp,
            ),
          ),
        );
        final midDec = tester
            .widget<DecoratedBox>(findScrollUnderDecoratedBox())
            .decoration as BoxDecoration;
        expect(
          midDec.color!.a,
          closeTo(kGlassAppBarBlurTintLight.a * 0.5, 1e-2),
        );
        final midBorder = (midDec.border! as Border).bottom;
        expect(midBorder.width, closeTo(1.0 / 3.0, 1e-6));
        expect(
          midBorder.color.a,
          closeTo(kGlassAppBarHairlineLight.a * 0.5, 1e-2),
        );

        // Fully scrolled under (50 logical px >= 10 => visibility = 1.0).
        controller.jumpTo(50.0);
        await tester.pump();

        final fullFilter =
            tester.widget<BackdropFilter>(findScrollUnderBackdropFilter());
        expect(
          fullFilter.filter,
          equals(
            ui.ImageFilter.blur(
              sigmaX: 20.0,
              sigmaY: 20.0,
              tileMode: ui.TileMode.clamp,
            ),
          ),
        );
        final fullDec = tester
            .widget<DecoratedBox>(findScrollUnderDecoratedBox())
            .decoration as BoxDecoration;
        expect(fullDec.color!.toARGB32(), kGlassAppBarBlurTintLight.toARGB32());
        final fullBorder = (fullDec.border! as Border).bottom;
        expect(
            fullBorder.color.toARGB32(), kGlassAppBarHairlineLight.toARGB32());
        expect(fullBorder.width, closeTo(1.0 / 3.0, 1e-6));

        // Scroll back to 0 => surface disappears completely (zero BackdropFilter).
        controller.jumpTo(0.0);
        await tester.pump();

        expect(findScrollUnderBackdropFilter(), findsNothing);
        expect(findScrollUnderDecoratedBox(), findsNothing);
      },
    );

    testWidgets(
        'dark mode uses calibrated dark frost tint and white 0.10 hairline',
        (tester) async {
      final controller = ScrollController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        buildScrollableScaffold(
          controller: controller,
          theme: const GlassThemeData(brightness: Brightness.dark),
          platformBrightness: Brightness.dark,
        ),
      );
      controller.jumpTo(40.0);
      await tester.pump();

      final dec = tester
          .widget<DecoratedBox>(findScrollUnderDecoratedBox())
          .decoration as BoxDecoration;
      expect(dec.color!.toARGB32(), kGlassAppBarBlurTintDark.toARGB32());
      final border = (dec.border! as Border).bottom;
      expect(border.color.toARGB32(), kGlassAppBarHairlineDark.toARGB32());
    });

    testWidgets(
      'GlassStyle.ios26 and GlassStyle.classic keep automatic transparent and '
      'preserve GlassScaffold top edge fade',
      (tester) async {
        for (final theme in [
          const GlassThemeData.ios26(),
          const GlassThemeData.classic(),
        ]) {
          final controller = ScrollController();
          await tester.pumpWidget(
            buildScrollableScaffold(controller: controller, theme: theme),
          );
          controller.jumpTo(80.0);
          await tester.pump();

          expect(find.byType(GlassAppBarScrollUnderSurface), findsNothing);
          final edge = tester.widget<GlassScrollEdgeEffect>(
            find.byType(GlassScrollEdgeEffect),
          );
          expect(edge.fadeTop, isTrue);
          controller.dispose();
        }
      },
    );

    testWidgets(
      'explicit surfaceStyle overrides GlassStyle in both directions',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        // Explicit fullBlur on ios26 enables scroll-under blur.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            theme: const GlassThemeData.ios26(),
            appBar: const GlassAppBar(
              title: Text('iOS 26 Full Blur'),
              surfaceStyle: GlassAppBarSurfaceStyle.fullBlur,
            ),
          ),
        );
        controller.jumpTo(40.0);
        await tester.pump();

        expect(findScrollUnderBackdropFilter(), findsOneWidget);
        expect(
          tester
              .widget<GlassScrollEdgeEffect>(find.byType(GlassScrollEdgeEffect))
              .fadeTop,
          isFalse,
        );

        // Explicit transparent on ios27 restores GlassScaffold top edge fade.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            theme: const GlassThemeData.ios27(),
            appBar: const GlassAppBar(
              title: Text('iOS 27 Transparent'),
              surfaceStyle: GlassAppBarSurfaceStyle.transparent,
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(GlassAppBarScrollUnderSurface), findsNothing);
        expect(
          tester
              .widget<GlassScrollEdgeEffect>(find.byType(GlassScrollEdgeEffect))
              .fadeTop,
          isTrue,
        );
      },
    );

    testWidgets(
      'GlassScaffold coordination suppresses default soft top fade without '
      'affecting bottom fade, and yields automatic to explicit scaffold edge',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        // 1. Default ios27 scaffold + appBar + bottomBar: top suppressed, bottom kept.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            bottomBar: GlassTabBar.bottom(
              selectedIndex: 0,
              onTabSelected: (_) {},
              tabs: const [
                GlassTab(icon: Icon(CupertinoIcons.house), label: 'Home'),
              ],
            ),
          ),
        );
        await tester.pump();

        var edge = tester.widget<GlassScrollEdgeEffect>(
          find.byType(GlassScrollEdgeEffect),
        );
        expect(edge.fadeTop, isFalse);
        expect(edge.fadeBottom, isTrue);
        expect(find.byType(GlassAppBarScrollUnderSurface), findsOneWidget);

        // 2. Explicit edgeStyle: blur on GlassScaffold => automatic yields to scaffold.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            edgeStyle: GlassScrollEdgeStyle.blur,
          ),
        );
        controller.jumpTo(50.0);
        await tester.pump();

        edge = tester.widget<GlassScrollEdgeEffect>(
          find.byType(GlassScrollEdgeEffect),
        );
        expect(edge.fadeTop, isTrue);
        expect(find.byType(GlassAppBarScrollUnderSurface), findsNothing);

        // 3. Explicit topEdgeFade: true => automatic yields to scaffold.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            topEdgeFade: true,
          ),
        );
        await tester.pump();

        edge = tester.widget<GlassScrollEdgeEffect>(
          find.byType(GlassScrollEdgeEffect),
        );
        expect(edge.fadeTop, isTrue);
        expect(find.byType(GlassAppBarScrollUnderSurface), findsNothing);

        // 4. Explicit custom topEdgeFadeExtent => automatic yields to scaffold.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            topEdgeFadeExtent: 40.0,
          ),
        );
        await tester.pump();

        edge = tester.widget<GlassScrollEdgeEffect>(
          find.byType(GlassScrollEdgeEffect),
        );
        expect(edge.fadeTop, isTrue);
        expect(find.byType(GlassAppBarScrollUnderSurface), findsNothing);

        // 5. Explicit GlassAppBar(surfaceStyle: fullBlur) wins over scaffold edgeStyle: blur.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            edgeStyle: GlassScrollEdgeStyle.blur,
            appBar: const GlassAppBar(
              title: Text('Explicit Blur'),
              surfaceStyle: GlassAppBarSurfaceStyle.fullBlur,
            ),
          ),
        );
        controller.jumpTo(60.0);
        await tester.pump();

        edge = tester.widget<GlassScrollEdgeEffect>(
          find.byType(GlassScrollEdgeEffect),
        );
        expect(edge.fadeTop, isFalse);
        expect(findScrollUnderBackdropFilter(), findsOneWidget);

        // 6. GlassScaffold themeOverride: ios26 keeps top fade and suppresses fullBlur.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            themeOverride: const GlassThemeData.ios26(),
          ),
        );
        await tester.pump();

        edge = tester.widget<GlassScrollEdgeEffect>(
          find.byType(GlassScrollEdgeEffect),
        );
        expect(edge.fadeTop, isTrue);
        expect(find.byType(GlassAppBarScrollUnderSurface), findsNothing);
      },
    );

    testWidgets(
      'non-transparent backgroundColor disables automatic fullBlur',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            appBar: const GlassAppBar(
              title: Text('Solid'),
              backgroundColor: Color(0xFF2C2C2E),
            ),
          ),
        );
        controller.jumpTo(80.0);
        await tester.pump();

        expect(find.byType(GlassAppBarScrollUnderSurface), findsNothing);
      },
    );

    testWidgets(
      'works with GlassAppBar.pinned and GlassNavigationShell without wrapping '
      'buttons in BackdropFilter',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(402, 874),
              devicePixelRatio: 3.0,
              padding: EdgeInsets.only(top: 62, bottom: 34),
            ),
            child: GlassTheme(
              data: const GlassThemeData.ios27(),
              child: CupertinoApp(
                builder: (context, child) =>
                    GlassNavigationShell(child: child!),
                home: GlassScaffold(
                  appBar: GlassAppBar.pinned(
                    title: const Text('Pinned'),
                    actions: [
                      GlassBarItem.icon(
                        icon: const Icon(CupertinoIcons.add),
                        onTap: () {},
                      ),
                    ],
                  ),
                  body: ListView.builder(
                    controller: controller,
                    itemCount: 30,
                    itemExtent: 60,
                    itemBuilder: (_, i) => Text('Row $i'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(findScrollUnderBackdropFilter(), findsNothing);

        controller.jumpTo(30.0);
        await tester.pump();

        expect(findScrollUnderBackdropFilter(), findsOneWidget);
        // The scroll-under BackdropFilter must be a sibling behind bar chrome,
        // never an ancestor of the title or action buttons.
        expect(
          find.ancestor(
            of: find.text('Pinned'),
            matching: find.byType(GlassAppBarScrollUnderSurface),
          ),
          findsNothing,
        );
        expect(
          find.ancestor(
            of: find.byIcon(CupertinoIcons.add),
            matching: find.byType(GlassAppBarScrollUnderSurface),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'works inside CupertinoPageScaffold and Material Scaffold',
      (tester) async {
        final cupertinoCtrl = ScrollController();
        addTearDown(cupertinoCtrl.dispose);

        await tester.pumpWidget(
          GlassTheme(
            data: const GlassThemeData.ios27(),
            child: CupertinoApp(
              home: CupertinoPageScaffold(
                navigationBar: const GlassAppBar(title: Text('Cupertino')),
                child: ListView.builder(
                  controller: cupertinoCtrl,
                  itemCount: 30,
                  itemExtent: 60,
                  itemBuilder: (_, i) => Text('C $i'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsNothing);
        cupertinoCtrl.jumpTo(25.0);
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsOneWidget);

        final materialCtrl = ScrollController();
        addTearDown(materialCtrl.dispose);

        await tester.pumpWidget(
          GlassTheme(
            data: const GlassThemeData.ios27(),
            child: MaterialApp(
              home: Scaffold(
                extendBodyBehindAppBar: true,
                appBar: const GlassAppBar(title: Text('Material')),
                body: ListView.builder(
                  controller: materialCtrl,
                  itemCount: 30,
                  itemExtent: 60,
                  itemBuilder: (_, i) => Text('M $i'),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsNothing);
        materialCtrl.jumpTo(25.0);
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsOneWidget);
      },
    );

    testWidgets(
      'automaticSurfaceVisibility: false stays visible without any scroll '
      'observer, and live toggles update visibility immediately',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        // Standalone without ScrollNotificationObserver.
        await tester.pumpWidget(
          GlassTheme(
            data: const GlassThemeData.ios27(),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: MediaQuery(
                data: const MediaQueryData(size: Size(402, 874)),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: const GlassAppBar(
                    title: Text('Always Blurred'),
                    automaticSurfaceVisibility: false,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(findScrollUnderBackdropFilter(), findsOneWidget);

        // Live toggle automaticSurfaceVisibility & surfaceAppearanceExtent.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            appBar: const GlassAppBar(
              title: Text('Dynamic'),
              surfaceAppearanceExtent: 10.0,
            ),
          ),
        );
        controller.jumpTo(10.0);
        await tester.pump();
        var dec = tester
            .widget<DecoratedBox>(findScrollUnderDecoratedBox())
            .decoration as BoxDecoration;
        expect(dec.color!.a, closeTo(kGlassAppBarBlurTintLight.a, 1e-2));

        // Expand appearanceExtent to 40 -> at offset 10 visibility drops to 0.25.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            appBar: const GlassAppBar(
              title: Text('Dynamic'),
              surfaceAppearanceExtent: 40.0,
            ),
          ),
        );
        await tester.pump();
        dec = tester
            .widget<DecoratedBox>(findScrollUnderDecoratedBox())
            .decoration as BoxDecoration;
        expect(dec.color!.a, closeTo(kGlassAppBarBlurTintLight.a * 0.25, 1e-2));

        // Flip automaticSurfaceVisibility to false -> immediately snaps to 1.0.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            appBar: const GlassAppBar(
              title: Text('Dynamic'),
              automaticSurfaceVisibility: false,
              surfaceAppearanceExtent: 40.0,
            ),
          ),
        );
        await tester.pump();
        dec = tester
            .widget<DecoratedBox>(findScrollUnderDecoratedBox())
            .decoration as BoxDecoration;
        expect(dec.color!.a, closeTo(kGlassAppBarBlurTintLight.a, 1e-2));
      },
    );

    testWidgets(
      'surfaceAppearanceExtent: 0 snaps immediately once offset > 0',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            appBar: const GlassAppBar(
              title: Text('Snap'),
              surfaceAppearanceExtent: 0.0,
            ),
          ),
        );
        expect(findScrollUnderBackdropFilter(), findsNothing);

        controller.jumpTo(0.5);
        await tester.pump();

        final dec = tester
            .widget<DecoratedBox>(findScrollUnderDecoratedBox())
            .decoration as BoxDecoration;
        expect(dec.color!.toARGB32(), kGlassAppBarBlurTintLight.toARGB32());

        controller.jumpTo(0.0);
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsNothing);
      },
    );

    testWidgets(
      'ignores horizontal scroll notifications and respects notificationPredicate '
      'for nested vertical scroll views',
      (tester) async {
        final hController = ScrollController();
        addTearDown(hController.dispose);

        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: hController,
            scrollDirection: Axis.horizontal,
          ),
        );
        hController.jumpTo(120.0);
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsNothing);

        // Nested vertical ListView (depth 1 inside PageView depth 0).
        final nestedCtrl = ScrollController();
        addTearDown(nestedCtrl.dispose);

        Widget buildNested(ScrollNotificationPredicate predicate) => MediaQuery(
              data: const MediaQueryData(size: Size(402, 874)),
              child: CupertinoApp(
                home: GlassTheme(
                  data: const GlassThemeData.ios27(),
                  child: GlassScaffold(
                    appBar: GlassAppBar(
                      title: const Text('Nested'),
                      notificationPredicate: predicate,
                    ),
                    body: PageView(
                      children: [
                        ListView.builder(
                          controller: nestedCtrl,
                          itemCount: 30,
                          itemExtent: 60,
                          itemBuilder: (_, i) => Text('Nested $i'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );

        // Default predicate (depth == 0) ignores depth-1 inner vertical list.
        await tester
            .pumpWidget(buildNested(defaultScrollNotificationPredicate));
        nestedCtrl.jumpTo(40.0);
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsNothing);

        // Custom predicate accepting depth == 1 activates on the inner list.
        await tester.pumpWidget(buildNested((n) => n.depth == 1));
        nestedCtrl.jumpTo(50.0);
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsOneWidget);
      },
    );

    testWidgets(
      'handles reversed vertical scroll views (AxisDirection.up) and '
      'ScrollMetricsNotification when content shrinks',
      (tester) async {
        final revCtrl = ScrollController();
        addTearDown(revCtrl.dispose);

        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: revCtrl,
            reverse: true,
            itemCount: 40,
          ),
        );
        await tester.pump();

        // At bottom of a long reversed list, content extends above viewport
        // (behind the top bar), so ScrollMetricsNotification activates blur.
        expect(findScrollUnderBackdropFilter(), findsOneWidget);

        // Scroll to the very top of the reversed list (extentAfter == 0).
        revCtrl.jumpTo(revCtrl.position.maxScrollExtent);
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsNothing);

        // Normal list: scroll down, then shrink itemCount so list resets via
        // ScrollMetricsNotification without a drag event.
        final shrinkCtrl = ScrollController();
        addTearDown(shrinkCtrl.dispose);

        await tester.pumpWidget(
          buildScrollableScaffold(controller: shrinkCtrl, itemCount: 40),
        );
        shrinkCtrl.jumpTo(120.0);
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsOneWidget);

        await tester.pumpWidget(
          buildScrollableScaffold(controller: shrinkCtrl, itemCount: 1),
        );
        await tester.pumpAndSettle();
        expect(findScrollUnderBackdropFilter(), findsNothing);
      },
    );

    testWidgets(
      'custom backdropTint, backdropBlurSigma, bottomBorder, and '
      'CupertinoDynamicColor in dark MaterialApp',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        const dynamicTint = CupertinoDynamicColor.withBrightness(
          color: Color(0x66FF0000),
          darkColor: Color(0x8800FF00),
        );
        const dynamicBorderColor = CupertinoDynamicColor.withBrightness(
          color: Color(0x440000FF),
          darkColor: Color(0x66FFFF00),
        );

        // MaterialApp in dark mode with GlassTheme dark brightness + dynamic colours.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            useCupertinoApp: false,
            theme: const GlassThemeData(brightness: Brightness.dark),
            platformBrightness: Brightness.dark,
            devicePixelRatio: 2.0,
            appBar: const GlassAppBar(
              title: Text('Custom'),
              backdropBlurSigma: 12.0,
              backdropTint: dynamicTint,
              bottomBorder: BorderSide(color: dynamicBorderColor, width: 0.0),
            ),
          ),
        );
        controller.jumpTo(30.0);
        await tester.pump();

        final filter =
            tester.widget<BackdropFilter>(findScrollUnderBackdropFilter());
        expect(
          filter.filter,
          equals(
            ui.ImageFilter.blur(
              sigmaX: 12.0,
              sigmaY: 12.0,
              tileMode: ui.TileMode.clamp,
            ),
          ),
        );
        final dec = tester
            .widget<DecoratedBox>(findScrollUnderDecoratedBox())
            .decoration as BoxDecoration;
        expect(dec.color!.toARGB32(), const Color(0x8800FF00).toARGB32());
        final border = (dec.border! as Border).bottom;
        expect(border.color.toARGB32(), const Color(0x66FFFF00).toARGB32());
        expect(border.width, closeTo(0.5, 1e-6)); // 0.0 width -> 1 / dpr

        // BorderSide.none hides border; backdropBlurSigma: 0 skips BackdropFilter.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            useCupertinoApp: false,
            appBar: const GlassAppBar(
              title: Text('No Blur No Border'),
              backdropBlurSigma: 0.0,
              bottomBorder: BorderSide.none,
            ),
          ),
        );
        await tester.pump();

        expect(findScrollUnderBackdropFilter(), findsNothing);
        expect(findScrollUnderDecoratedBox(), findsOneWidget);
        final noBorderDec = tester
            .widget<DecoratedBox>(findScrollUnderDecoratedBox())
            .decoration as BoxDecoration;
        expect(noBorderDec.border, isNull);

        // BorderSide(style: BorderStyle.none) with non-default color also hides border.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            useCupertinoApp: false,
            appBar: const GlassAppBar(
              title: Text('Custom Style None'),
              backdropBlurSigma: 0.0,
              bottomBorder: BorderSide(
                color: Color(0xFFFF0000),
                style: BorderStyle.none,
              ),
            ),
          ),
        );
        await tester.pump();
        final styleNoneDec = tester
            .widget<DecoratedBox>(findScrollUnderDecoratedBox())
            .decoration as BoxDecoration;
        expect(styleNoneDec.border, isNull);
      },
    );

    testWidgets(
      'reduceTransparency skips BackdropFilter and renders high-opacity fill '
      'and higher-contrast hairline',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            reduceTransparency: true,
          ),
        );
        controller.jumpTo(40.0);
        await tester.pump();

        expect(findScrollUnderBackdropFilter(), findsNothing);
        expect(findScrollUnderDecoratedBox(), findsOneWidget);
        final dec = tester
            .widget<DecoratedBox>(findScrollUnderDecoratedBox())
            .decoration as BoxDecoration;
        expect(
          dec.color!.toARGB32(),
          kGlassAppBarReduceTransparencyTintLight.toARGB32(),
        );
        expect(
          (dec.border! as Border).bottom.color.toARGB32(),
          kGlassAppBarHairlineHighContrastLight.toARGB32(),
        );

        // Custom translucent tint is boosted to >= 0.96 under reduceTransparency.
        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            reduceTransparency: true,
            appBar: const GlassAppBar(
              title: Text('Custom RT'),
              backdropTint: Color(0x40336699),
            ),
          ),
        );
        await tester.pump();

        expect(findScrollUnderBackdropFilter(), findsNothing);
        final customDec = tester
            .widget<DecoratedBox>(findScrollUnderDecoratedBox())
            .decoration as BoxDecoration;
        expect(customDec.color!.a, greaterThanOrEqualTo(0.96));
      },
    );

    testWidgets(
      'scrolling does not rebuild GlassAppBar title/chrome and preserves '
      'shouldFullyObstruct == false for translucent fullBlur',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);
        int titleBuilds = 0;

        const bar = GlassAppBar(
          surfaceStyle: GlassAppBarSurfaceStyle.fullBlur,
          automaticSurfaceVisibility: false,
        );

        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            appBar: GlassAppBar(
              title: Builder(
                builder: (_) {
                  titleBuilds++;
                  return const Text('Counting');
                },
              ),
            ),
          ),
        );
        await tester.pump();

        final ctx = tester.element(find.byType(GlassAppBar));
        expect(bar.shouldFullyObstruct(ctx), isFalse);

        final buildsBeforeScroll = titleBuilds;
        for (double offset = 2; offset <= 100; offset += 4) {
          controller.jumpTo(offset);
          await tester.pump();
        }
        expect(titleBuilds, equals(buildsBeforeScroll));
      },
    );

    testWidgets(
      'live GlassStyle ios27 <-> ios26 toggle preserves GlassAppBar child state',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            theme: const GlassThemeData.ios27(),
            appBar: const GlassAppBar(title: _StatefulTitle()),
          ),
        );
        final stateBefore = tester.state<_StatefulTitleState>(
          find.byType(_StatefulTitle),
        );

        await tester.pumpWidget(
          buildScrollableScaffold(
            controller: controller,
            theme: const GlassThemeData.ios26(),
            appBar: const GlassAppBar(title: _StatefulTitle()),
          ),
        );
        final stateAfter = tester.state<_StatefulTitleState>(
          find.byType(_StatefulTitle),
        );
        expect(identical(stateBefore, stateAfter), isTrue);
      },
    );

    testWidgets(
      'resolves all CupertinoDynamicColor variants when GlassTheme brightness '
      'diverges from CupertinoTheme brightness',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        const fullDynamic = CupertinoDynamicColor(
          color: Color(0xFF111111),
          darkColor: Color(0xFF222222),
          highContrastColor: Color(0xFF333333),
          darkHighContrastColor: Color(0xFF444444),
          elevatedColor: Color(0xFF555555),
          darkElevatedColor: Color(0xFF666666),
          highContrastElevatedColor: Color(0xFF777777),
          darkHighContrastElevatedColor: Color(0xFF888888),
        );

        Future<int> probeVariant({
          required Brightness glassBrightness,
          required bool highContrast,
          required bool elevated,
        }) async {
          await tester.pumpWidget(
            MediaQuery(
              data: MediaQueryData(
                size: const Size(402, 874),
                highContrast: highContrast,
              ),
              child: CupertinoApp(
                // Force opposite CupertinoTheme brightness so the manual
                // GlassTheme-synced resolver branch executes for every variant.
                theme: CupertinoThemeData(
                  brightness: glassBrightness == Brightness.dark
                      ? Brightness.light
                      : Brightness.dark,
                ),
                home: GlassAccessibilityScope(
                  reduceTransparency: false,
                  child: GlassTheme(
                    data: GlassThemeData(brightness: glassBrightness),
                    child: CupertinoUserInterfaceLevel(
                      data: elevated
                          ? CupertinoUserInterfaceLevelData.elevated
                          : CupertinoUserInterfaceLevelData.base,
                      child: const Scaffold(
                        extendBodyBehindAppBar: true,
                        appBar: GlassAppBar(
                          title: Text('Variant'),
                          automaticSurfaceVisibility: false,
                          backdropTint: fullDynamic,
                        ),
                        body: SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          final dec = tester
              .widget<DecoratedBox>(findScrollUnderDecoratedBox())
              .decoration as BoxDecoration;
          return dec.color!.toARGB32();
        }

        expect(
          await probeVariant(
            glassBrightness: Brightness.light,
            highContrast: false,
            elevated: false,
          ),
          0xFF111111,
        );
        expect(
          await probeVariant(
            glassBrightness: Brightness.dark,
            highContrast: false,
            elevated: false,
          ),
          0xFF222222,
        );
        expect(
          await probeVariant(
            glassBrightness: Brightness.light,
            highContrast: true,
            elevated: false,
          ),
          0xFF333333,
        );
        expect(
          await probeVariant(
            glassBrightness: Brightness.dark,
            highContrast: true,
            elevated: false,
          ),
          0xFF444444,
        );
        expect(
          await probeVariant(
            glassBrightness: Brightness.light,
            highContrast: false,
            elevated: true,
          ),
          0xFF555555,
        );
        expect(
          await probeVariant(
            glassBrightness: Brightness.dark,
            highContrast: false,
            elevated: true,
          ),
          0xFF666666,
        );
        expect(
          await probeVariant(
            glassBrightness: Brightness.light,
            highContrast: true,
            elevated: true,
          ),
          0xFF777777,
        );
        expect(
          await probeVariant(
            glassBrightness: Brightness.dark,
            highContrast: true,
            elevated: true,
          ),
          0xFF888888,
        );
      },
    );

    testWidgets(
      'stays transparent on top rubber-band overscroll and spans optional '
      'bottom widget height when scrolled under',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(
              size: Size(402, 874),
              devicePixelRatio: 3.0,
              padding: EdgeInsets.only(top: 62, bottom: 34),
            ),
            child: CupertinoApp(
              home: GlassTheme(
                data: const GlassThemeData.ios27(),
                child: GlassScaffold(
                  appBar: const GlassAppBar(
                    title: Text('With Bottom'),
                    bottom: PreferredSize(
                      preferredSize: Size.fromHeight(36),
                      child: SizedBox(height: 36),
                    ),
                  ),
                  body: ListView.builder(
                    controller: controller,
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    itemCount: 30,
                    itemExtent: 60,
                    itemBuilder: (_, i) => Text('Item $i'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Rubber-band pull down past offset 0 stays transparent.
        controller.jumpTo(-40.0);
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsNothing);

        // Scroll under: surface spans status bar (62) + toolbar (44) + bottom (36) = 142.
        controller.jumpTo(40.0);
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsOneWidget);
        final surfaceSize =
            tester.getSize(find.byType(GlassAppBarScrollUnderSurface));
        expect(surfaceSize.height, closeTo(62.0 + 44.0 + 36.0, 1e-3));
      },
    );

    testWidgets(
      'GlassScaffold(extendBody: false) suppresses automatic fullBlur while '
      'still honoring explicit surfaceStyle: fullBlur',
      (tester) async {
        final controller = ScrollController();
        addTearDown(controller.dispose);

        Widget buildNoExtend(GlassAppBar appBar) => MediaQuery(
              data: const MediaQueryData(
                size: Size(402, 874),
                devicePixelRatio: 3.0,
                padding: EdgeInsets.only(top: 62, bottom: 34),
              ),
              child: CupertinoApp(
                home: GlassTheme(
                  data: const GlassThemeData.ios27(),
                  child: GlassScaffold(
                    extendBody: false,
                    appBar: appBar,
                    body: ListView.builder(
                      controller: controller,
                      itemCount: 30,
                      itemExtent: 60,
                      itemBuilder: (_, i) => Text('Item $i'),
                    ),
                  ),
                ),
              ),
            );

        // Automatic backs off because body does not extend behind the bar.
        await tester.pumpWidget(
          buildNoExtend(const GlassAppBar(title: Text('No Extend'))),
        );
        controller.jumpTo(80.0);
        await tester.pump();
        expect(find.byType(GlassAppBarScrollUnderSurface), findsNothing);

        // Explicit fullBlur is still respected if explicitly requested.
        await tester.pumpWidget(
          buildNoExtend(
            const GlassAppBar(
              title: Text('Explicit Full Blur'),
              surfaceStyle: GlassAppBarSurfaceStyle.fullBlur,
            ),
          ),
        );
        controller.jumpTo(90.0);
        await tester.pump();
        expect(findScrollUnderBackdropFilter(), findsOneWidget);
      },
    );

    testWidgets(
      'ScrollController(initialScrollOffset: 200) activates surface on mount '
      'via ScrollMetricsNotification',
      (tester) async {
        final controller = ScrollController(initialScrollOffset: 200.0);
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          buildScrollableScaffold(controller: controller),
        );
        await tester.pump();

        expect(findScrollUnderBackdropFilter(), findsOneWidget);
        final dec = tester
            .widget<DecoratedBox>(findScrollUnderDecoratedBox())
            .decoration as BoxDecoration;
        expect(dec.color!.toARGB32(), kGlassAppBarBlurTintLight.toARGB32());
      },
    );

    testWidgets(
      'iPhone Duo vertical bar strip suppresses even explicit fullBlur on '
      'GlassAppBar.pinned',
      (tester) async {
        GlassNavigationShellState.debugPinningSupported = true;
        addTearDown(() {
          GlassNavigationShellState.debugPinningSupported = null;
          VerticalBarRegions.instance.debugReset();
        });

        const dpr = 3.0;
        const size = Size(466, 678);
        const viewPad = FakeViewPadding(right: 84 * dpr, bottom: 34 * dpr);
        tester.view
          ..devicePixelRatio = dpr
          ..physicalSize = size * dpr
          ..viewPadding = viewPad
          ..padding = viewPad;
        addTearDown(tester.view.reset);

        final controller = ScrollController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          GlassTheme(
            data: const GlassThemeData.ios27(),
            child: CupertinoApp(
              builder: (context, child) => GlassNavigationShell(child: child!),
              home: GlassScaffold(
                appBar: const GlassAppBar.pinned(
                  title: Text('Duo'),
                  surfaceStyle: GlassAppBarSurfaceStyle.fullBlur,
                  automaticSurfaceVisibility: false,
                ),
                body: ListView.builder(
                  controller: controller,
                  itemCount: 30,
                  itemExtent: 60,
                  itemBuilder: (_, i) => Text('Row $i'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final ctx = tester.element(find.byType(GlassAppBar));
        expect(GlassVerticalBar.maybeOf(ctx), isNotNull);
        expect(find.byType(GlassAppBarScrollUnderSurface), findsNothing);
      },
      variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    );

    test('rejects infinite surfaceAppearanceExtent and backdropBlurSigma', () {
      expect(
        () => GlassAppBar(surfaceAppearanceExtent: double.infinity),
        throwsAssertionError,
      );
      expect(
        () => GlassAppBar(backdropBlurSigma: double.infinity),
        throwsAssertionError,
      );
      expect(
        () => GlassAppBar.pinned(surfaceAppearanceExtent: double.infinity),
        throwsAssertionError,
      );
      expect(
        () => GlassAppBar.pinned(backdropBlurSigma: double.infinity),
        throwsAssertionError,
      );
    });
  });
}

class _StatefulTitle extends StatefulWidget {
  const _StatefulTitle();

  @override
  State<_StatefulTitle> createState() => _StatefulTitleState();
}

class _StatefulTitleState extends State<_StatefulTitle> {
  @override
  Widget build(BuildContext context) => const Text('Stateful');
}
