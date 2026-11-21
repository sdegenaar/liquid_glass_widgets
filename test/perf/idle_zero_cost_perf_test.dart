import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
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
        // active interaction should restore Clip.antiAliasWithSaveLayer so
        // the moving pill clips cleanly across icons.
        final barCenter = tester.getCenter(find.byType(GlassTabBar));
        final gesture = await tester.startGesture(barCenter);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));
        expect(
          _countSaveLayerClipPaths(tester),
          greaterThanOrEqualTo(2),
          reason: 'Active GlassTabBar.bottom press/drag should keep saveLayer '
              'masking while the pill moves across icons.',
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
  });
}
