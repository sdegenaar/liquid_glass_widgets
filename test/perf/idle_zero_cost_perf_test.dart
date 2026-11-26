import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/src/renderer/glass_backdrop_group_boundary.dart';
import 'package:liquid_glass_widgets/src/widgets/surfaces/lens_content_warp.dart';
import 'package:liquid_glass_widgets/src/widgets/surfaces/tab_bar_bottom_internal.dart';
import 'package:liquid_glass_widgets/theme/glass_theme_helpers.dart';

class _PaintCounterBox extends SingleChildRenderObjectWidget {
  const _PaintCounterBox({required this.onPaint, super.child});

  final VoidCallback onPaint;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPaintCounter(onPaint);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPaintCounter renderObject,
  ) {
    renderObject.onPaint = onPaint;
  }
}

class _RenderPaintCounter extends RenderProxyBox {
  _RenderPaintCounter(this.onPaint);

  VoidCallback onPaint;

  @override
  void paint(PaintingContext context, Offset offset) {
    onPaint();
    super.paint(context, offset);
  }
}

int _countSaveLayerClipPaths(WidgetTester tester) {
  var count = 0;
  for (final ro in tester.allRenderObjects) {
    if (ro is RenderClipPath &&
        ro.clipBehavior == Clip.antiAliasWithSaveLayer) {
      count++;
    }
  }
  return count;
}

void main() {
  const tabs = <GlassTab>[
    GlassTab(icon: Icon(CupertinoIcons.home), label: 'Home'),
    GlassTab(icon: Icon(CupertinoIcons.search), label: 'Search'),
    GlassTab(icon: Icon(CupertinoIcons.person), label: 'Profile'),
  ];

  group('Wave 1.1 — Resting GlassTabBar saveLayer elimination', () {
    testWidgets(
      'GlassTabBar.bottom uses 0 Clip.antiAliasWithSaveLayer passes at rest '
      'and promotes to saveLayer during active drag',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: GlassTabBar.bottom(
                  tabs: tabs,
                  selectedIndex: 0,
                  onTabSelected: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _countSaveLayerClipPaths(tester),
          0,
          reason:
              'Resting GlassTabBar.bottom must use Clip.antiAlias instead of '
              'Clip.antiAliasWithSaveLayer.',
        );
        expect(tester.binding.hasScheduledFrame, isFalse);

        // Press and hold on the bar to activate the lifted glass pill:
        // active interaction should restore Clip.antiAliasWithSaveLayer on the
        // selected-lens mask so the moving pill clips cleanly across icons
        // (the unselected inverse mask stays Clip.antiAlias so its track-bound
        // saveLayer does not crop tab badges / halos painted past the track).
        final barCenter = tester.getCenter(find.byType(GlassTabBar));
        final gesture = await tester.startGesture(barCenter);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          _countSaveLayerClipPaths(tester),
          greaterThanOrEqualTo(1),
          reason: 'Active GlassTabBar.bottom press/drag should keep saveLayer '
              'masking on the lens side while the pill moves across icons.',
        );

        await gesture.up();
        await tester.pumpAndSettle();
        expect(
          _countSaveLayerClipPaths(tester),
          0,
          reason: 'Returning to rest must release Clip.antiAliasWithSaveLayer.',
        );
      },
    );

    testWidgets(
      'GlassTabBar.searchable uses 0 Clip.antiAliasWithSaveLayer passes at rest',
      (tester) async {
        final searchController = TextEditingController();
        addTearDown(searchController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: GlassTabBar.searchable(
                  tabs: tabs,
                  selectedIndex: 0,
                  onTabSelected: (_) {},
                  searchConfig: GlassSearchBarConfig(
                    onSearchToggle: (_) {},
                    controller: searchController,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          _countSaveLayerClipPaths(tester),
          0,
          reason:
              'Resting GlassTabBar.searchable must use Clip.antiAlias instead '
              'of Clip.antiAliasWithSaveLayer.',
        );
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );

    testWidgets(
      'GlassTabBar.bottom with native lens enabled avoids resting saveLayers, '
      'resting 1/255 ColoredBox overdraw, and idle inner-shadow indicator',
      (tester) async {
        final prev = TabIndicator.debugNativeLensSupported;
        TabIndicator.debugNativeLensSupported = true;
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: GlassTabBar.bottom(
                    tabs: tabs,
                    selectedIndex: 0,
                    onTabSelected: (_) {},
                    quality: GlassQuality.premium,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(LensContentWarp), findsOneWidget);
          expect(
            _countSaveLayerClipPaths(tester),
            0,
            reason:
                'Resting native-lens GlassTabBar.bottom must use 0 saveLayers.',
          );
          expect(
            find.descendant(
              of: find.byType(LensContentWarp),
              matching: find.byWidgetPredicate(
                (w) => w is ColoredBox && w.color == const Color(0x01000000),
              ),
            ),
            findsNothing,
            reason:
                'LensContentWarp must not paint 1/255 alpha ColoredBox at rest.',
          );
          expect(
            find.byType(AnimatedGlassIndicator),
            findsNWidgets(2),
            reason: 'The 3rd inner-shadow AnimatedGlassIndicator must stay '
                'unmounted while thickness <= 0.05.',
          );
          expect(tester.binding.hasScheduledFrame, isFalse);

          // Lifting the lens mounts the 3rd inner-shadow indicator; settling
          // releases it cleanly back to 2.
          final barCenter = tester.getCenter(find.byType(GlassTabBar));
          final gesture = await tester.startGesture(barCenter);
          await tester.pump(const Duration(milliseconds: 50));
          await tester.pump(const Duration(milliseconds: 50));
          expect(find.byType(AnimatedGlassIndicator), findsNWidgets(3));

          await gesture.up();
          await tester.pumpAndSettle();
          expect(find.byType(AnimatedGlassIndicator), findsNWidgets(2));
          expect(_countSaveLayerClipPaths(tester), 0);
        } finally {
          TabIndicator.debugNativeLensSupported = prev;
        }
      },
    );

    testWidgets(
      'GlassTabBar.searchable with native lens enabled avoids resting '
      'saveLayers, resting 1/255 ColoredBox overdraw, and idle inner-shadow',
      (tester) async {
        final prev = TabIndicator.debugNativeLensSupported;
        final searchController = TextEditingController();
        addTearDown(searchController.dispose);
        TabIndicator.debugNativeLensSupported = true;
        try {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Align(
                  alignment: Alignment.bottomCenter,
                  child: GlassTabBar.searchable(
                    tabs: tabs,
                    selectedIndex: 0,
                    onTabSelected: (_) {},
                    quality: GlassQuality.premium,
                    searchConfig: GlassSearchBarConfig(
                      onSearchToggle: (_) {},
                      controller: searchController,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(LensContentWarp), findsOneWidget);
          expect(_countSaveLayerClipPaths(tester), 0);
          expect(
            find.descendant(
              of: find.byType(LensContentWarp),
              matching: find.byWidgetPredicate(
                (w) => w is ColoredBox && w.color == const Color(0x01000000),
              ),
            ),
            findsNothing,
          );
          expect(find.byType(AnimatedGlassIndicator), findsNWidgets(2));
          expect(tester.binding.hasScheduledFrame, isFalse);
        } finally {
          TabIndicator.debugNativeLensSupported = prev;
        }
      },
    );
  });

  group('Idle zero-cost gate', () {
    testWidgets(
      'representative GlassScaffold screen triggers 0 builds and 0 paints '
      'across 10 idle frames once settled',
      (tester) async {
        var builds = 0;
        var paints = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: _PaintCounterBox(
              onPaint: () => paints++,
              child: Builder(
                builder: (context) {
                  builds++;
                  return GlassScaffold(
                    appBar: GlassAppBar(
                      title: const Text('Audit'),
                      actions: [
                        GlassButton(
                          icon: const Icon(CupertinoIcons.add),
                          onTap: () {},
                        ),
                      ],
                    ),
                    bottomBar: GlassTabBar.bottom(
                      tabs: tabs,
                      selectedIndex: 0,
                      onTabSelected: (_) {},
                    ),
                    body: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              GlassSwitch(value: true, onChanged: (_) {}),
                              const SizedBox(width: 16),
                              Expanded(
                                child: GlassSlider(
                                  value: 0.5,
                                  onChanged: (_) {},
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final settledBuilds = builds;
        final settledPaints = paints;

        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        expect(builds, settledBuilds, reason: 'No idle rebuilds expected.');
        expect(paints, settledPaints, reason: 'No idle repaints expected.');
        expect(tester.binding.hasScheduledFrame, isFalse);
        expect(_countSaveLayerClipPaths(tester), 0);
      },
    );

    testWidgets(
      'Wave 1.6 — keyboard viewInsets changes do not rebuild GlassScaffold, '
      'GlassSwitch, GlassSlider, GlassMenu trigger, or resolveAdaptiveRadius',
      (tester) async {
        final insets = ValueNotifier<EdgeInsets>(EdgeInsets.zero);
        addTearDown(insets.dispose);

        var radiusBuilds = 0;
        var menuTriggerBuilds = 0;
        var scaffoldBodyBuilds = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: ValueListenableBuilder<EdgeInsets>(
              valueListenable: insets,
              builder: (context, viewInsets, child) {
                final base = MediaQuery.of(context);
                return MediaQuery(
                  data: base.copyWith(viewInsets: viewInsets),
                  child: child!,
                );
              },
              child: GlassScaffold(
                appBar: GlassAppBar(
                  title: const Text('Keyboard Test'),
                  actions: [
                    GlassMenu(
                      triggerBuilder: (context, toggle) {
                        menuTriggerBuilds++;
                        return GlassButton(
                          icon: const Icon(CupertinoIcons.ellipsis),
                          onTap: toggle,
                        );
                      },
                      items: [
                        GlassMenuItem(title: 'One', onTap: () {}),
                      ],
                    ),
                  ],
                ),
                body: Builder(
                  builder: (context) {
                    scaffoldBodyBuilds++;
                    return Column(
                      children: [
                        Builder(
                          builder: (ctx) {
                            radiusBuilds++;
                            GlassThemeHelpers.resolveAdaptiveRadius(ctx);
                            return const SizedBox.shrink();
                          },
                        ),
                        GlassSwitch(value: true, onChanged: (_) {}),
                        GlassSlider(value: 0.5, onChanged: (_) {}),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final r0 = radiusBuilds;
        final m0 = menuTriggerBuilds;
        final sb0 = scaffoldBodyBuilds;
        final rebuiltGlassWidgets = <Type>[];
        final prevHook = debugOnRebuildDirtyWidget;
        debugOnRebuildDirtyWidget = (Element e, bool builtOnce) {
          final w = e.widget;
          if (w is GlassScaffold ||
              w is GlassSwitch ||
              w is GlassSlider ||
              w is GlassMenu) {
            rebuiltGlassWidgets.add(w.runtimeType);
          }
          prevHook?.call(e, builtOnce);
        };
        addTearDown(() => debugOnRebuildDirtyWidget = prevHook);

        // Simulate keyboard animating up across 5 frames.
        for (final h in [60.0, 120.0, 180.0, 240.0, 300.0]) {
          insets.value = EdgeInsets.only(bottom: h);
          await tester.pump(const Duration(milliseconds: 16));
        }

        expect(radiusBuilds, r0,
            reason: 'resolveAdaptiveRadius must not rebuild on viewInsets.');
        expect(menuTriggerBuilds, m0,
            reason: 'GlassMenu trigger must not rebuild on viewInsets.');
        expect(scaffoldBodyBuilds, sb0,
            reason: 'GlassScaffold body must not rebuild on viewInsets.');
        expect(
          rebuiltGlassWidgets,
          isEmpty,
          reason: 'GlassScaffold, GlassSwitch, GlassSlider, and GlassMenu must '
              'not rebuild when MediaQuery.viewInsets changes.',
        );
      },
    );

    testWidgets(
      'Wave 2.1 — idle GlassMenu trigger inside GlassAppBar stays inside '
      'GlassBackdropGroup (opensRenderPassBelow == false)',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: GlassScaffold(
              appBar: GlassAppBar(
                title: const Text('Menu Group'),
                actions: [
                  GlassMenu(
                    triggerBuilder: (context, toggle) => GlassButton(
                      icon: const Icon(CupertinoIcons.ellipsis),
                      onTap: toggle,
                    ),
                    items: [
                      GlassMenuItem(title: 'Edit', onTap: () {}),
                    ],
                  ),
                ],
              ),
              body: const SizedBox.expand(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final buttonRo = tester.renderObject(find.byType(GlassButton));
        final boundaryRo = tester
            .renderObjectList<RenderGlassBackdropGroupBoundary>(
              find.byType(GlassBackdropGroupBoundary, skipOffstage: false),
            )
            .last;
        var blockedByRenderPass = false;
        RenderObject? cursor = buttonRo.parent;
        while (cursor != null && cursor != boundaryRo) {
          if (opensRenderPassBelow(cursor)) {
            blockedByRenderPass = true;
            break;
          }
          cursor = cursor.parent;
        }
        expect(
          blockedByRenderPass,
          isFalse,
          reason:
              'Idle GlassMenu trigger must not mount RenderOpacity barriers '
              'that eject it from GlassBackdropGroup.',
        );
      },
    );

    testWidgets(
      'Wave 2.1 — minimal _FrostedFallback uses at most 1 BackdropFilter '
      'even when saturation != 1.0',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 160,
                  height: 60,
                  child: AdaptiveGlass(
                    quality: GlassQuality.minimal,
                    settings: LiquidGlassSettings(blur: 10, saturation: 2.0),
                    shape: LiquidRoundedSuperellipse(borderRadius: 16),
                    child: SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byType(BackdropFilter),
          findsOneWidget,
          reason: '_FrostedFallback must compose blur + saturation into 1 '
              'BackdropFilter instead of nesting 2.',
        );
      },
    );

    test(
      'Wave 2.6 — SingleSpringController & OffsetSpringController allocate '
      '0 Tickers at rest and unify OffsetSpringController onto 1 Ticker',
      () {
        final countingVsync = _CountingTickerProvider();
        final single = SingleSpringController(
          vsync: countingVsync,
          spring: GlassSpring.snappy(),
        );
        final offset = OffsetSpringController(
          vsync: countingVsync,
          spring: GlassSpring.snappy(),
        );

        // Resting controllers must allocate 0 Tickers.
        expect(countingVsync.createdCount, 0);

        // First animateTo allocates exactly 1 Ticker each (not 2 for Offset).
        single.animateTo(1.0);
        expect(countingVsync.createdCount, 1);

        var offsetNotifies = 0;
        offset.addListener(() => offsetNotifies++);
        offset.animateTo(const Offset(10.0, 20.0));
        expect(
          countingVsync.createdCount,
          2,
          reason:
              'OffsetSpringController must share 1 Ticker across both axes.',
        );

        // Driving a single vsync on OffsetSpringController fires listeners once.
        countingVsync.lastCallback!(const Duration(milliseconds: 16));
        expect(offsetNotifies, 1);

        single.dispose();
        offset.dispose();
      },
    );

    testWidgets(
      'Wave 2.6 — GlassButtonGroup omits IntrinsicHeight when showDividers is false',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: GlassButtonGroup(
                  showDividers: false,
                  children: [
                    GlassButton(
                      icon: const Icon(CupertinoIcons.add),
                      onTap: () {},
                    ),
                    GlassButton(
                      icon: const Icon(CupertinoIcons.minus),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(IntrinsicHeight), findsNothing);
      },
    );
  });
}

class _CountingTickerProvider implements TickerProvider {
  int createdCount = 0;
  TickerCallback? lastCallback;

  @override
  Ticker createTicker(TickerCallback onTick) {
    createdCount++;
    lastCallback = onTick;
    return Ticker(onTick);
  }
}
