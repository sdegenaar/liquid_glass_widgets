import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/widgets/surfaces/dynamic_preferred_size.dart';
import 'package:liquid_glass_widgets/widgets/shared/glass_effect.dart';

import '../../shared/test_helpers.dart';

void main() {
  group('GlassScaffold', () {
    testWidgets('renders with body and bottom bar', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              body: const Text('Body'),
              bottomBar: GlassTabBar.bottom(
                selectedIndex: 0,
                onTabSelected: (_) {},
                tabs: const [
                  GlassTab(
                    label: 'Tab 1',
                    icon: Icon(Icons.home),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Body'), findsOneWidget);
      expect(find.byType(GlassTabBar), findsOneWidget);
    });

    testWidgets('renders with app bar', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassScaffold(
              appBar: GlassAppBar(title: Text('Title')),
              body: Text('Body'),
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    // ── Edge fade: top fade height calculation ──────────────────────────────

    testWidgets('forwards edgeFadeAbsorbsPointers to GlassScrollEdgeEffect',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassScaffold(
              bottomEdgeFade: true,
              edgeFadeAbsorbsPointers: true,
              body: SizedBox.expand(),
            ),
          ),
        ),
      );

      final scrollEdge = tester.widget<GlassScrollEdgeEffect>(
        find.byType(GlassScrollEdgeEffect),
      );
      expect(scrollEdge.absorbPointer, isTrue);
    });

    testWidgets('top fade excludes appBarHeight when no appBar is provided',
        (tester) async {
      // When topEdgeFade is true but no appBar is set, the fade should
      // only cover the status bar area + extent — NOT include the default
      // 44px appBarHeight. Regression test for the fix that checks
      // `appBar != null` before adding effectiveAppBarHeight.
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassScaffold(
              topEdgeFade: true,
              body: SizedBox.expand(),
            ),
          ),
        ),
      );

      // The GlassScrollEdgeEffect should be present (fade is enabled).
      expect(find.byType(GlassScrollEdgeEffect), findsOneWidget);

      // Verify the fade widget exists and the scaffold rendered without error.
      final scrollEdge = tester.widget<GlassScrollEdgeEffect>(
        find.byType(GlassScrollEdgeEffect),
      );
      // Without appBar, topFadeHeight = topPad + 20 (default extent).
      // The key assertion: it should NOT be topPad + 44 + 20.
      // In test environment, topPad is zero.
      expect(scrollEdge.topFadeHeight, 20.0);
    });

    testWidgets('top fade includes appBarHeight when appBar is provided',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassScaffold(
              appBar: GlassAppBar(title: Text('Title')),
              body: SizedBox.expand(),
            ),
          ),
        ),
      );

      expect(find.byType(GlassScrollEdgeEffect), findsOneWidget);

      final scrollEdge = tester.widget<GlassScrollEdgeEffect>(
        find.byType(GlassScrollEdgeEffect),
      );
      // GlassAppBar default vertical padding adds 20pt to the 44pt toolbar,
      // then the 20pt fade extent.
      expect(scrollEdge.topFadeHeight, 84.0);
    });

    testWidgets(
        'defaults to GlassScrollEdgeStyle.soft and does not render ProgressiveBlur',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassScaffold(
              topEdgeFade: true,
              body: SizedBox.expand(),
            ),
          ),
        ),
      );

      final scrollEdge = tester.widget<GlassScrollEdgeEffect>(
        find.byType(GlassScrollEdgeEffect),
      );
      expect(scrollEdge.style, GlassScrollEdgeStyle.soft);
      expect(scrollEdge.absorbPointer, isFalse);
      expect(find.byType(ProgressiveBlur), findsNothing);
    });

    testWidgets(
        'forwards explicit blur edgeStyle to GlassScrollEdgeEffect and renders ProgressiveBlur',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassScaffold(
              topEdgeFade: true,
              edgeStyle: GlassScrollEdgeStyle.blur,
              maxSigma: 22,
              body: SizedBox.expand(),
            ),
          ),
        ),
      );

      final scrollEdge = tester.widget<GlassScrollEdgeEffect>(
        find.byType(GlassScrollEdgeEffect),
      );
      expect(scrollEdge.style, GlassScrollEdgeStyle.blur);
      expect(scrollEdge.maxSigma, 22);

      final blur = tester.widget<ProgressiveBlur>(find.byType(ProgressiveBlur));
      expect(blur.maxSigma, 22);
    });

    // ── Isolation scope: bars get premium quality hint ───────────────────────

    testWidgets('wraps bars in GlassIsolationScope with defaultQuality premium',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              appBar: const GlassAppBar(title: Text('Title')),
              body: const Text('Body'),
              bottomBar: GlassTabBar.bottom(
                selectedIndex: 0,
                onTabSelected: (_) {},
                tabs: const [
                  GlassTab(
                    label: 'Tab 1',
                    icon: Icon(Icons.home),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // GlassIsolationScope should be present (wrapping bars).
      expect(find.byType(GlassIsolationScope), findsWidgets);
    });

    testWidgets('bars use isolated: true for correct Z-order', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              appBar: const GlassAppBar(title: Text('Title')),
              body: const Text('Body'),
              bottomBar: GlassTabBar.bottom(
                selectedIndex: 0,
                onTabSelected: (_) {},
                tabs: const [
                  GlassTab(
                    label: 'Tab 1',
                    icon: Icon(Icons.home),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify GlassIsolationScope widgets have isolated: true.
      final scopes = tester.widgetList<GlassIsolationScope>(
        find.byType(GlassIsolationScope),
      );
      for (final scope in scopes) {
        if (scope.defaultQuality == GlassQuality.premium) {
          // Bar scopes from GlassScaffold should be isolated.
          expect(scope.isolated, isTrue,
              reason: 'Bar isolation scope should use isolated: true '
                  'for correct Z-order of glass components');
        }
      }
    });
  });

  // ── Header + headerScrollController + headerFadeDistance ────────────────

  group('GlassScaffold.header', () {
    testWidgets('renders header widget when provided', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              header: const Text('Listen Now'),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );

      expect(find.text('Listen Now'), findsOneWidget);
    });

    testWidgets('header has ValueKey for stable identity', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              header: const Text('Header'),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('glass_scaffold_header')),
        findsOneWidget,
      );
    });

    testWidgets('header fades on scroll via headerScrollController',
        (tester) async {
      final controller = ScrollController();

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              header: const Text('Fading Header'),
              headerScrollController: controller,
              headerFadeDistance: 100.0,
              body: ListView.builder(
                controller: controller,
                itemCount: 50,
                itemBuilder: (_, i) => SizedBox(height: 80, child: Text('$i')),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Fading Header'), findsOneWidget);

      controller.jumpTo(150.0);
      await tester.pumpAndSettle();

      expect(find.text('Fading Header'), findsOneWidget);

      final igp = tester.widgetList<IgnorePointer>(
        find.ancestor(
          of: find.text('Fading Header'),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(igp.any((w) => w.ignoring), isTrue,
          reason: 'Fully faded header should be non-interactive');

      controller.dispose();
    });

    testWidgets('header without scroll controller renders directly',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              header: const Text('Static Header'),
              body: const SizedBox.expand(),
            ),
          ),
        ),
      );

      expect(find.text('Static Header'), findsOneWidget);
    });
  });

  // ── bodyOverlays ────────────────────────────────────────────────────────

  group('GlassScaffold.bodyOverlays', () {
    testWidgets('renders overlay widgets between body and bars',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              body: const Text('Body Content'),
              bodyOverlays: [
                const Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Text('Play Bar Pill'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Body Content'), findsOneWidget);
      expect(find.text('Play Bar Pill'), findsOneWidget);
    });

    testWidgets('multiple overlays all render', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              body: const SizedBox.expand(),
              bodyOverlays: const [
                Positioned(bottom: 10, child: Text('Overlay 1')),
                Positioned(bottom: 50, child: Text('Overlay 2')),
                Positioned(bottom: 90, child: Text('Overlay 3')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Overlay 1'), findsOneWidget);
      expect(find.text('Overlay 2'), findsOneWidget);
      expect(find.text('Overlay 3'), findsOneWidget);
    });

    testWidgets(
        'promotes GlassButton in bodyOverlays to premium while body GlassButton stays standard and hero controls default to premium',
        (tester) async {
      final bodyButtonKey = UniqueKey();
      final overlayButtonKey = UniqueKey();

      await tester.pumpWidget(
        createTestApp(
          child: GlassScaffold(
            body: Column(
              children: [
                GlassButton(
                  key: bodyButtonKey,
                  icon: const Icon(CupertinoIcons.add),
                  onTap: () {},
                ),
                GlassSwitch(value: true, onChanged: (_) {}),
                GlassSlider(value: 0.5, onChanged: (_) {}),
                GlassSegmentedControl(
                  segments: const [
                    GlassSegment(label: 'A'),
                    GlassSegment(label: 'B'),
                  ],
                  selectedIndex: 0,
                  onSegmentSelected: (_) {},
                ),
              ],
            ),
            bodyOverlays: [
              Positioned(
                bottom: 24,
                right: 24,
                child: GlassButton(
                  key: overlayButtonKey,
                  icon: const Icon(CupertinoIcons.play_fill),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      );

      final bodyButtonGlass = tester.widget<AdaptiveGlass>(
        find.descendant(
          of: find.byKey(bodyButtonKey),
          matching: find.byType(AdaptiveGlass),
        ),
      );
      final overlayButtonGlass = tester.widget<AdaptiveGlass>(
        find.descendant(
          of: find.byKey(overlayButtonKey),
          matching: find.byType(AdaptiveGlass),
        ),
      );
      expect(bodyButtonGlass.quality, GlassQuality.standard);
      expect(overlayButtonGlass.quality, GlassQuality.premium);

      final switchEffect = tester.widget<GlassEffect>(
        find.descendant(
          of: find.byType(GlassSwitch),
          matching: find.byType(GlassEffect),
        ),
      );
      final sliderEffect = tester.widget<GlassEffect>(
        find.descendant(
          of: find.byType(GlassSlider),
          matching: find.byType(GlassEffect),
        ),
      );
      final segIndicator = tester.widget<AnimatedGlassIndicator>(
        find
            .descendant(
              of: find.byType(GlassSegmentedControl),
              matching: find.byType(AnimatedGlassIndicator),
            )
            .first,
      );
      expect(switchEffect.quality, GlassQuality.premium);
      expect(sliderEffect.quality, GlassQuality.premium);
      expect(segIndicator.quality, GlassQuality.premium);
    });

    testWidgets('GlassStyle.classic keeps hero controls on standard quality',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: GlassTheme(
            data: const GlassThemeData.classic(),
            child: GlassScaffold(
              body: Column(
                children: [
                  GlassSwitch(value: true, onChanged: (_) {}),
                  GlassSlider(value: 0.5, onChanged: (_) {}),
                ],
              ),
            ),
          ),
        ),
      );

      for (final type in [GlassSwitch, GlassSlider]) {
        final effect = tester.widget<GlassEffect>(
          find.descendant(
            of: find.byType(type),
            matching: find.byType(GlassEffect),
          ),
        );
        expect(effect.quality, GlassQuality.standard, reason: '$type');
      }
    });

    testWidgets('keyed bodyOverlays keep their state when the list reorders',
        (tester) async {
      const a = ValueKey<String>('overlay-a');
      const b = ValueKey<String>('overlay-b');

      Widget scaffold(List<Key> order) => createTestApp(
            child: GlassScaffold(
              body: const SizedBox.expand(),
              bodyOverlays: [
                for (final key in order)
                  Positioned(
                    key: key,
                    top: key == a ? 0 : 100,
                    left: 0,
                    child:
                        _OverlayCounter(label: (key as ValueKey<String>).value),
                  ),
              ],
            ),
          );

      await tester.pumpWidget(scaffold(const [a, b]));
      // Bump only overlay A's state.
      await tester.tap(find.byKey(const ValueKey('counter-overlay-a')));
      await tester.pump();
      expect(find.text('overlay-a:1'), findsOneWidget);
      expect(find.text('overlay-b:0'), findsOneWidget);

      await tester.pumpWidget(scaffold(const [b, a]));
      // State follows the key, not the position.
      expect(find.text('overlay-a:1'), findsOneWidget);
      expect(find.text('overlay-b:0'), findsOneWidget);
    });
  });

  // ── ValueKey stability ──────────────────────────────────────────────────

  group('GlassScaffold ValueKeys', () {
    testWidgets('app bar has stable ValueKey', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassScaffold(
              appBar: GlassAppBar(title: Text('Title')),
              body: SizedBox.expand(),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('glass_scaffold_app_bar')),
        findsOneWidget,
      );
    });

    testWidgets('bottom bar has stable ValueKey', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              body: const SizedBox.expand(),
              bottomBar: GlassTabBar.bottom(
                selectedIndex: 0,
                onTabSelected: (_) {},
                tabs: const [
                  GlassTab(label: 'Home', icon: Icon(Icons.home)),
                ],
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('glass_scaffold_bottom_bar')),
        findsOneWidget,
      );
    });

    testWidgets('toggling header preserves bar state', (tester) async {
      late StateSetter rebuildFn;
      bool showHeader = true;

      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuildFn = setState;
                return GlassScaffold(
                  header: showHeader ? const Text('Header') : null,
                  appBar: const GlassAppBar(title: Text('Title')),
                  body: const SizedBox.expand(),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);

      rebuildFn(() => showHeader = false);
      await tester.pumpAndSettle();

      expect(find.text('Header'), findsNothing);
      expect(find.text('Title'), findsOneWidget);
    });
  });

  // ── contentAwareBrightness ────────────────────────────────────────────────

  group('GlassScaffold.contentAwareBrightness', () {
    testWidgets('installs scope and content wrapper when true', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              contentAwareBrightness: true,
              body: const Text('Body'),
              bottomBar: GlassTabBar.bottom(
                selectedIndex: 0,
                onTabSelected: (_) {},
                tabs: const [
                  GlassTab(label: 'Home', icon: Icon(Icons.home)),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassContentAwareScope), findsOneWidget);
      expect(find.byType(GlassContentAwareContent), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });

    testWidgets('does not install scope when false (default)', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              body: const Text('Body'),
              bottomBar: GlassTabBar.bottom(
                selectedIndex: 0,
                onTabSelected: (_) {},
                tabs: const [
                  GlassTab(label: 'Home', icon: Icon(Icons.home)),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassContentAwareScope), findsNothing);
      expect(find.byType(GlassContentAwareContent), findsNothing);
      expect(find.text('Body'), findsOneWidget);
    });

    // ── Dark-mode gradient flash regression (fix: fadeColor + transparent scaffold) ──

    testWidgets(
        'passes backgroundColor to GlassScrollEdgeEffect.fadeColor '
        'so fallback gradient uses correct colour in dark mode',
        (tester) async {
      // Regression test for: GlassTabBar gradient flickering dark when
      // GlassScaffold(backgroundColor: Colors.white) is used in dark mode.
      // GlassScrollEdgeEffect's async-capture fallback previously defaulted
      // to CupertinoTheme.scaffoldBackgroundColor (near-black in dark mode).
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassScaffold(
              backgroundColor: Colors.white,
              topEdgeFade: true,
              bottomEdgeFade: true,
              body: SizedBox.expand(),
            ),
          ),
        ),
      );

      final scrollEdge = tester.widget<GlassScrollEdgeEffect>(
        find.byType(GlassScrollEdgeEffect),
      );
      // fadeColor must be the explicit white, not null/dark theme default.
      expect(scrollEdge.fadeColor, Colors.white);
    });

    testWidgets(
        'GlassScrollEdgeEffect.fadeColor is null when no backgroundColor set',
        (tester) async {
      // When no backgroundColor is provided, fadeColor should be null so
      // GlassScrollEdgeEffect falls back to the theme default (existing behaviour).
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassScaffold(
              topEdgeFade: true,
              body: SizedBox.expand(),
            ),
          ),
        ),
      );

      final scrollEdge = tester.widget<GlassScrollEdgeEffect>(
        find.byType(GlassScrollEdgeEffect),
      );
      expect(scrollEdge.fadeColor, isNull);
    });

    testWidgets(
        'inner CupertinoPageScaffold is always transparent '
        'regardless of background or backgroundColor', (tester) async {
      // Regression test: Scaffold.backgroundColor was conditionally null when
      // only backgroundColor (not background widget) was provided, causing the
      // Material dark-mode theme colour to bleed through and corrupt glass
      // bar backdrop captures. Now uses CupertinoPageScaffold.
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassScaffold(
              backgroundColor: Colors.white,
              body: Text('Body'),
            ),
          ),
        ),
      );

      // Find the inner CupertinoPageScaffold inside GlassScaffold.
      final scaffold = tester.widget<CupertinoPageScaffold>(
        find.descendant(
          of: find.byType(GlassScaffold),
          matching: find.byType(CupertinoPageScaffold),
        ),
      );
      expect(scaffold.backgroundColor, const Color(0x00000000));
    });

    testWidgets(
        'inner CupertinoPageScaffold uses CupertinoTheme background with no background set',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: const GlassScaffold(
              body: Text('Body'),
            ),
          ),
        ),
      );

      final scaffold = tester.widget<CupertinoPageScaffold>(
        find.descendant(
          of: find.byType(GlassScaffold),
          matching: find.byType(CupertinoPageScaffold),
        ),
      );
      // Without a background widget the CupertinoPageScaffold must NOT be
      // forced transparent — null lets it use the CupertinoTheme default (opaque)
      // to prevent the underlying route bleeding through during route transitions
      // (issue #177). Mirrors prior Scaffold(backgroundColor: null) behaviour.
      expect(scaffold.backgroundColor, isNull);
    });
  });

  group('GlassScaffold safe area', () {
    testWidgets('does not impose a minimum without GlassAppBar',
        (tester) async {
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.only(top: 8, bottom: 12),
          GlassScaffold(
            body: Builder(
              builder: (context) {
                bodyPadding = MediaQuery.paddingOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(bodyPadding.top, 8);
      expect(bodyPadding.bottom, 12);
    });

    testWidgets('preserves a top inset greater than 20', (tester) async {
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.only(top: 32, bottom: 12),
          GlassScaffold(
            body: Builder(
              builder: (context) {
                bodyPadding = MediaQuery.paddingOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(bodyPadding.top, 32);
    });

    testWidgets('GlassAppBar keeps the platform top inset', (tester) async {
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.only(top: 8, bottom: 12),
          GlassScaffold(
            appBar: const GlassAppBar(title: Text('Title')),
            body: Builder(
              builder: (context) {
                bodyPadding = MediaQuery.paddingOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(bodyPadding.top, 8 + 64);
    });

    testWidgets('GlassAppBar preserves a top inset greater than 20',
        (tester) async {
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.only(top: 32, bottom: 12),
          GlassScaffold(
            appBar: const GlassAppBar(title: Text('Title')),
            body: Builder(
              builder: (context) {
                bodyPadding = MediaQuery.paddingOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(bodyPadding.top, 32 + 64);
    });

    testWidgets('publishes the complete GlassAppBar safe area to ListView',
        (tester) async {
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.fromLTRB(10, 24, 12, 20),
          AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              appBar: const GlassAppBar(
                title: Text('Title'),
                padding: EdgeInsets.fromLTRB(8, 10, 8, 14),
              ),
              body: Builder(
                builder: (context) {
                  bodyPadding = MediaQuery.paddingOf(context);
                  return ListView(
                    children: const [
                      SizedBox(key: ValueKey('first-item'), height: 20),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final appBarBottom = tester.getBottomLeft(find.byType(GlassAppBar)).dy;
      expect(bodyPadding.top, closeTo(appBarBottom, 0.5));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('first-item'))).dy,
        closeTo(appBarBottom, 0.5),
        reason: 'ListView must consume the complete GlassAppBar safe area',
      );
    });

    testWidgets('publishes a wrapped GlassAppBar rendered height to ListView',
        (tester) async {
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.fromLTRB(10, 24, 12, 20),
          AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              appBarHeight: 52,
              appBar: Builder(
                builder: (context) => const GlassAppBar(
                  title: Text('Title'),
                  toolbarHeight: 52,
                  padding: EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
              body: Builder(
                builder: (context) {
                  bodyPadding = MediaQuery.paddingOf(context);
                  return ListView(
                    children: const [
                      SizedBox(key: ValueKey('wrapped-first-item'), height: 20),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final appBarBottom = tester.getBottomLeft(find.byType(GlassAppBar)).dy;
      expect(bodyPadding.top, closeTo(appBarBottom, 0.5));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('wrapped-first-item'))).dy,
        closeTo(appBarBottom, 0.5),
      );
    });

    testWidgets('GlassLargeTitle clears the complete GlassAppBar safe area',
        (tester) async {
      final titleController = GlassLargeTitleController();
      addTearDown(titleController.dispose);
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.fromLTRB(10, 24, 12, 20),
          AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              appBar: GlassAppBar(
                title: const Text('Inline Title'),
                largeTitleController: titleController,
                padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
              ),
              body: Builder(
                builder: (context) {
                  bodyPadding = MediaQuery.paddingOf(context);
                  return CustomScrollView(
                    controller: titleController.scrollController,
                    slivers: [
                      GlassLargeTitle(
                        text: 'Large Title',
                        controller: titleController,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final appBarBottom = tester.getBottomLeft(find.byType(GlassAppBar)).dy;
      expect(bodyPadding.top, closeTo(appBarBottom, 0.5));
      expect(
        tester.getTopLeft(find.text('Large Title')).dy,
        closeTo(appBarBottom, 0.5),
        reason: 'GlassLargeTitle must reserve the complete app-bar safe area',
      );
    });

    testWidgets(
        'GlassLargeTitle clears a wrapped GlassAppBar rendered safe area',
        (tester) async {
      final titleController = GlassLargeTitleController();
      addTearDown(titleController.dispose);
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.fromLTRB(10, 24, 12, 20),
          AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              appBarHeight: 52,
              appBar: Builder(
                builder: (context) => GlassAppBar(
                  title: const Text('Inline Title'),
                  toolbarHeight: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  largeTitleController: titleController,
                ),
              ),
              body: Builder(
                builder: (context) {
                  bodyPadding = MediaQuery.paddingOf(context);
                  return CustomScrollView(
                    controller: titleController.scrollController,
                    slivers: [
                      GlassLargeTitle(
                        text: 'Wrapped Large Title',
                        controller: titleController,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final appBarBottom = tester.getBottomLeft(find.byType(GlassAppBar)).dy;
      expect(bodyPadding.top, closeTo(appBarBottom, 0.5));
      expect(
        tester.getTopLeft(find.text('Wrapped Large Title')).dy,
        closeTo(appBarBottom, 0.5),
      );
    });

    testWidgets('publishes system and bar insets through the body MediaQuery',
        (tester) async {
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.fromLTRB(10, 24, 12, 20),
          AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              appBar: const PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: SizedBox(height: 60),
              ),
              bottomBar: const PreferredSize(
                preferredSize: Size.fromHeight(80),
                child: SizedBox(height: 80),
              ),
              body: Builder(
                builder: (context) {
                  bodyPadding = MediaQuery.paddingOf(context);
                  return ListView(
                    children: const [
                      SizedBox(key: ValueKey('first-item'), height: 20),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(bodyPadding, const EdgeInsets.fromLTRB(10, 84, 12, 100));
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('first-item'))).dy,
        84,
        reason: 'ListView default padding must consume the scaffold inset',
      );
    });

    testWidgets(
        'reserves only the rendered bar on iOS, without a second home inset',
        (tester) async {
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.only(top: 24, bottom: 34),
          GlassScaffold(
            bottomBar: const PreferredSize(
              preferredSize: Size.fromHeight(80),
              child: SizedBox(height: 80),
            ),
            body: Builder(
              builder: (context) {
                bodyPadding = MediaQuery.paddingOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(
        bodyPadding.bottom,
        80,
        reason: 'the floating bar is already at the screen edge; the body '
            'only needs to clear the bar rectangle',
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('includes the Android navigation inset once', (tester) async {
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.only(top: 24, bottom: 34),
          GlassScaffold(
            bottomBar: const PreferredSize(
              preferredSize: Size.fromHeight(80),
              child: SizedBox(height: 80),
            ),
            body: Builder(
              builder: (context) {
                bodyPadding = MediaQuery.paddingOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );

      expect(
        bodyPadding.bottom,
        114,
        reason: 'the scaffold lifts the bar above Android navigation and the '
            'body must clear the complete rendered chrome',
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('removes bar insets when the body is already positioned',
        (tester) async {
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.fromLTRB(10, 24, 12, 20),
          AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              extendBody: false,
              appBar: const PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: SizedBox(height: 60),
              ),
              bottomBar: const PreferredSize(
                preferredSize: Size.fromHeight(80),
                child: SizedBox(height: 80),
              ),
              body: Builder(
                builder: (context) {
                  bodyPadding = MediaQuery.paddingOf(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );

      expect(bodyPadding, const EdgeInsets.fromLTRB(10, 0, 12, 0));
    });

    testWidgets('tracks a bottom bar whose preferred size changes in place',
        (tester) async {
      final barSize = ValueNotifier<double>(60);
      addTearDown(barSize.dispose);
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.only(top: 20, bottom: 16),
          AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: GlassScaffold(
              bottomBar: _DynamicPreferredSizeBar(size: barSize),
              body: Builder(
                builder: (context) {
                  bodyPadding = MediaQuery.paddingOf(context);
                  return const SizedBox.expand();
                },
              ),
            ),
          ),
        ),
      );

      expect(bodyPadding.bottom, 76);

      barSize.value = 104;
      await tester.pump();
      await tester.pump();

      expect(bodyPadding.bottom, 120,
          reason: 'the scaffold must re-read a dynamic bar preferred size');
    });

    testWidgets('measures a custom bottom bar without a preferred size',
        (tester) async {
      final barSize = ValueNotifier<double>(72);
      addTearDown(barSize.dispose);
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.only(top: 20, bottom: 16),
          GlassScaffold(
            bottomBar: ValueListenableBuilder<double>(
              valueListenable: barSize,
              builder: (context, height, _) => SizedBox(height: height),
            ),
            body: Builder(
              builder: (context) {
                bodyPadding = MediaQuery.paddingOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(bodyPadding.bottom, 88,
          reason: 'actual layout must replace the 60px fallback');

      barSize.value = 96;
      await tester.pump();
      await tester.pump();

      expect(bodyPadding.bottom, 112,
          reason: 'a non-PreferredSizeWidget can still resize at runtime');
    });

    testWidgets('measures a custom app bar without a preferred size',
        (tester) async {
      final barSize = ValueNotifier<double>(70);
      addTearDown(barSize.dispose);
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.only(top: 20, bottom: 16),
          GlassScaffold(
            appBar: ValueListenableBuilder<double>(
              valueListenable: barSize,
              builder: (context, height, _) => SizedBox(height: height),
            ),
            body: Builder(
              builder: (context) {
                bodyPadding = MediaQuery.paddingOf(context);
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(bodyPadding.top, 70);

      barSize.value = 100;
      await tester.pump();
      await tester.pump();

      expect(bodyPadding.top, 100);
    });

    testWidgets('tracks GlassAppBar vertical padding changes', (tester) async {
      late StateSetter rebuild;
      var verticalPadding = 10.0;
      late EdgeInsets bodyPadding;

      await tester.pumpWidget(
        _testAppWithPadding(
          const EdgeInsets.only(top: 20, bottom: 16),
          AdaptiveLiquidGlassLayer(
            settings: defaultTestGlassSettings,
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return GlassScaffold(
                  appBar: GlassAppBar(
                    title: const Text('Title'),
                    padding: EdgeInsets.fromLTRB(
                      8,
                      verticalPadding,
                      8,
                      verticalPadding,
                    ),
                  ),
                  body: Builder(
                    builder: (context) {
                      bodyPadding = MediaQuery.paddingOf(context);
                      return const SizedBox.expand();
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(bodyPadding.top, 84,
          reason: '20 status + 44 toolbar + 20 vertical padding');

      rebuild(() => verticalPadding = 20);
      await tester.pump();

      expect(bodyPadding.top, 104,
          reason: 'the updated app-bar preferred height must update the body '
              'safe area in the same rebuild');
    });
  });
}

Widget _testAppWithPadding(EdgeInsets padding, Widget child) {
  return MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(padding: padding),
        child: Scaffold(body: child),
      ),
    ),
  );
}

class _DynamicPreferredSizeBar extends StatelessWidget
    with GlassDynamicPreferredSize {
  const _DynamicPreferredSizeBar({required this.size});

  final ValueNotifier<double> size;

  @override
  Size get preferredSize => Size.fromHeight(size.value);

  @override
  Listenable get preferredSizeListenable => size;

  @override
  Widget build(BuildContext context) => SizedBox(height: size.value);
}

/// A tappable counter used to prove overlay state follows the overlay's key.
class _OverlayCounter extends StatefulWidget {
  const _OverlayCounter({required this.label});

  final String label;

  @override
  State<_OverlayCounter> createState() => _OverlayCounterState();
}

class _OverlayCounterState extends State<_OverlayCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('counter-${widget.label}'),
      onTap: () => setState(() => _count++),
      child: Text('${widget.label}:$_count'),
    );
  }
}
