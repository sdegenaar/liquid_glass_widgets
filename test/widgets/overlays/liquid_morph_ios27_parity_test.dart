import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

const Duration _kFrame = Duration(microseconds: 16667); // 60fps (16.67ms)

double? _extractShapeRadius(LiquidShape shape) {
  if (shape is LiquidRoundedSuperellipse) return shape.borderRadius;
  if (shape is LiquidRoundedRectangle) return shape.borderRadius;
  return null;
}

double _effectiveRenderOpacity(Element leaf) {
  double opacity = 1.0;
  RenderObject? current = leaf.renderObject;
  while (current != null) {
    if (current is RenderOpacity) {
      opacity *= current.opacity;
    }
    current = current.parent;
  }
  return opacity;
}

Rect? _findOverlayPlatterRect(WidgetTester tester, {double minHeight = 46.0}) {
  Rect? best;
  for (final elem in find.byType(GlassContainer).evaluate()) {
    final gc = elem.widget as GlassContainer;
    if (gc.useOwnLayer) continue;
    final box = elem.renderObject as RenderBox?;
    if (box == null || !box.hasSize || box.size.height <= minHeight) continue;
    final rect = box.localToGlobal(Offset.zero) & box.size;
    if (best == null || rect.height > best.height) {
      best = rect;
    }
  }
  return best;
}

void _expectCompositingSafety(WidgetTester tester, String contextLabel) {
  for (final element in find.byType(AdaptiveLiquidGlassLayer).evaluate()) {
    RenderObject? current = element.renderObject?.parent;
    while (current != null) {
      if (current is RenderOpacity) {
        expect(
          current.opacity <= 0.001 || current.opacity >= 0.999,
          isTrue,
          reason:
              '[$contextLabel] Fractional RenderOpacity(${current.opacity}) '
              'found above AdaptiveLiquidGlassLayer!',
        );
      }
      current = current.parent;
    }
  }

  for (final element in find.byType(GlassContainer).evaluate()) {
    final gc = element.widget as GlassContainer;
    if (!gc.useOwnLayer) continue;
    RenderObject? current = element.renderObject?.parent;
    while (current != null) {
      if (current is RenderOpacity) {
        expect(
          current.opacity <= 0.001 || current.opacity >= 0.999,
          isTrue,
          reason:
              '[$contextLabel] Fractional RenderOpacity(${current.opacity}) '
              'found above GlassContainer(useOwnLayer: true)!',
        );
      }
      current = current.parent;
    }
  }

  for (final element in find.byType(LiquidGlassBlendGroup).evaluate()) {
    int ancestorBlendGroups = 0;
    element.visitAncestorElements((ancestor) {
      if (ancestor.widget is LiquidGlassBlendGroup) {
        ancestorBlendGroups++;
      }
      return true;
    });
    expect(
      ancestorBlendGroups,
      equals(0),
      reason:
          '[$contextLabel] Duplicate nested LiquidGlassBlendGroup detected!',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void configurePhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(393 * 3, 852 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Widget wrapStage(Widget child, {bool reduceMotion = false}) {
    return GlassTheme(
      data: const GlassThemeData.ios27(brightness: Brightness.dark),
      child: CupertinoApp(
        theme: const CupertinoThemeData(brightness: Brightness.dark),
        builder: (context, appChild) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(disableAnimations: reduceMotion),
            child: GlassAccessibilityScope(
              reduceMotion: reduceMotion,
              child: appChild!,
            ),
          );
        },
        home: CupertinoPageScaffold(
          backgroundColor: const Color(0xFF050814),
          child: Stack(
            fit: StackFit.expand,
            children: [child],
          ),
        ),
      ),
    );
  }

  List<Widget> buildItems(int count) {
    return [
      for (int i = 0; i < count; i++)
        GlassMenuItem(
          title: 'Menu Action ${i + 1}',
          icon: const Icon(CupertinoIcons.sparkles),
          isDestructive: i == count - 1 && count >= 2,
          onTap: () {},
        ),
    ];
  }

  group('1. GlassMenu 60fps iOS 27 Parity Matrix (4 Triggers x 3 Lengths)', () {
    for (final (triggerName, tw, leftX) in <(String, double, double?)>[
      ('round_44', 44.0, null),
      ('pill_120', 120.0, null),
      ('wide_center_260', 260.0, null),
      ('wide_left_240', 240.0, 16.0),
    ]) {
      for (final itemCount in <int>[2, 5, 10]) {
        testWidgets(
          'Trigger=$triggerName x Items=$itemCount: Open & Close 16.67ms invariants',
          (tester) async {
            configurePhoneViewport(tester);
            final ctrl = GlassMenuController();
            const triggerKey = ValueKey('menu_trigger_btn');

            await tester.pumpWidget(
              wrapStage(
                Positioned(
                  top: 160,
                  left: leftX ?? (393.0 - tw) / 2.0,
                  child: GlassMenu(
                    controller: ctrl,
                    menuWidth: 220,
                    menuBorderRadius: 32.0,
                    autoAdjustToScreen: true,
                    menuPadding: const EdgeInsets.symmetric(horizontal: 12),
                    quality: GlassQuality.premium,
                    items: buildItems(itemCount),
                    triggerBuilder: (ctx, toggle) => GlassButton.custom(
                      key: triggerKey,
                      width: tw,
                      height: 44,
                      shape: tw == 44
                          ? const LiquidOval()
                          : const LiquidRoundedSuperellipse(borderRadius: 22),
                      useOwnLayer: true,
                      quality: GlassQuality.premium,
                      onTap: toggle,
                      child: const Text('T', style: TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            final restTriggerRect = tester.getRect(find.byKey(triggerKey));
            expect(restTriggerRect.width, closeTo(tw, 0.5));
            expect(restTriggerRect.height, closeTo(44.0, 0.5));

            // --- OPEN PHASE (0..500ms at 16.67ms) ---
            ctrl.open();
            final openRadii = <double>[];
            double maxOpenCenterDriftX = 0.0;
            for (int f = 0; f <= 30; f++) {
              await tester.pump(f == 0 ? Duration.zero : _kFrame);
              _expectCompositingSafety(
                tester,
                '$triggerName/${itemCount}i OPEN f=$f',
              );

              final trigElems = find.byKey(triggerKey).evaluate();
              if (trigElems.isNotEmpty &&
                  _effectiveRenderOpacity(trigElems.first) > 0.001) {
                final curTrig = tester.getRect(find.byKey(triggerKey));
                expect(
                  curTrig.width / tw,
                  greaterThanOrEqualTo(0.895),
                  reason:
                      '[$triggerName/${itemCount}i OPEN f=$f] Real trigger scaleX squashed below 0.90!',
                );
              }

              for (final elem in find.byType(GlassContainer).evaluate()) {
                final gc = elem.widget as GlassContainer;
                final r = _extractShapeRadius(gc.shape);
                if (r != null) openRadii.add(r);
                final box = elem.renderObject as RenderBox?;
                if (triggerName == 'wide_center_260' &&
                    box != null &&
                    box.hasSize &&
                    box.size.height > 50.0) {
                  final globalTopLeft = box.localToGlobal(Offset.zero);
                  final cx = globalTopLeft.dx + box.size.width * 0.5;
                  final drift = (cx - restTriggerRect.center.dx).abs();
                  if (drift > maxOpenCenterDriftX) {
                    maxOpenCenterDriftX = drift;
                  }
                }
              }
            }
            await tester.pumpAndSettle();

            for (final r in openRadii) {
              expect(
                r,
                lessThanOrEqualTo(32.5),
                reason:
                    '[$triggerName/${itemCount}i OPEN] Corner radius ballooned to $r (> 32pt)!',
              );
            }

            if (triggerName == 'wide_center_260') {
              expect(
                maxOpenCenterDriftX,
                lessThan(2.5),
                reason:
                    '[wide_center_260/${itemCount}i OPEN] Platter drifted off center by $maxOpenCenterDriftX px!',
              );
            }

            // --- CLOSE PHASE (0..600ms at 16.67ms) ---
            ctrl.close();
            final closeRadii = <double>[];
            final platterCloseSamples = <(double, Rect)>[];
            double dyAt67ms = 0.0;
            double dyAt250ms = 0.0;
            double peakUpwardTriggerDy = 0.0;
            double peakUpwardTriggerMs = -1.0;
            double maxTriggerWidthOnClose = tw;
            double maxTriggerWidthMs = -1.0;
            double opacityAt83ms = 0.0;
            double opacityAt167ms = 0.0;
            double? blobAWidthAt50ms;
            double? blobAWidthAt200ms;

            for (int f = 0; f <= 36; f++) {
              await tester.pump(f == 0 ? Duration.zero : _kFrame);
              final ms = f * 16.667;

              _expectCompositingSafety(
                tester,
                '$triggerName/${itemCount}i CLOSE f=$f',
              );

              for (final elem in find.byType(GlassContainer).evaluate()) {
                final gc = elem.widget as GlassContainer;
                final r = _extractShapeRadius(gc.shape);
                if (r != null) closeRadii.add(r);
                final box = elem.renderObject as RenderBox?;
                if (box != null && box.hasSize && !gc.useOwnLayer) {
                  final topLeft = box.localToGlobal(Offset.zero);
                  final rect = topLeft & box.size;
                  if (box.size.height > 46.0) {
                    platterCloseSamples.add((ms, rect));
                  } else if (gc.height == 44.0 &&
                      ImageFilter.isShaderFilterSupported &&
                      tw > 44.0) {
                    final blobACenter =
                        box.localToGlobal(box.size.center(Offset.zero));
                    expect(
                      (blobACenter.dx - restTriggerRect.center.dx).abs(),
                      lessThan(1.5),
                      reason:
                          '[$triggerName/${itemCount}i CLOSE f=$f] Blob A capsule drifted off trigger.center.dx!',
                    );
                    if (f == 3) blobAWidthAt50ms = gc.width;
                    if (f == 12) blobAWidthAt200ms = gc.width;
                  }
                }
              }

              if (f == 5 || f == 10) {
                final itemElements = find.text('Menu Action 1').evaluate();
                if (itemElements.isNotEmpty) {
                  final effOp = _effectiveRenderOpacity(itemElements.first);
                  if (f == 5) opacityAt83ms = effOp;
                  if (f == 10) opacityAt167ms = effOp;
                }
              }

              final trigElems = find.byKey(triggerKey).evaluate();
              if (trigElems.isNotEmpty) {
                final curTrigRect = tester.getRect(find.byKey(triggerKey));
                if (_effectiveRenderOpacity(trigElems.first) > 0.001) {
                  expect(
                    curTrigRect.width / tw,
                    greaterThanOrEqualTo(0.895),
                    reason:
                        '[$triggerName/${itemCount}i CLOSE f=$f] Real trigger scaleX squashed below 0.90!',
                  );
                }
                final dy = curTrigRect.center.dy - restTriggerRect.center.dy;
                if (f == 4) dyAt67ms = dy;
                if (f == 15) dyAt250ms = dy;
                if (dy < peakUpwardTriggerDy) {
                  peakUpwardTriggerDy = dy;
                  peakUpwardTriggerMs = ms;
                }
                if (curTrigRect.width > maxTriggerWidthOnClose) {
                  maxTriggerWidthOnClose = curTrigRect.width;
                  maxTriggerWidthMs = ms;
                }
              }
            }

            await tester.pumpAndSettle();
            final settledTrigRect = tester.getRect(find.byKey(triggerKey));
            expect(settledTrigRect.width, closeTo(tw, 0.25));
            expect(
              settledTrigRect.center.dy,
              closeTo(restTriggerRect.center.dy, 0.25),
            );

            // Native iOS 27 deliberately rounds the collapsing platter toward
            // a circle (silhouette roundness 0.29 → ~0.9), so the radius may
            // exceed the resting 32pt but never the blob's own half-width
            // (menuWidth 220 / 2).
            for (final r in closeRadii) {
              expect(
                r,
                lessThanOrEqualTo(110.5),
                reason:
                    '[$triggerName/${itemCount}i CLOSE] Corner radius ballooned to $r (> half menu width)!',
              );
            }

            if (tw > 220.0) {
              for (final (ms, rect) in platterCloseSamples) {
                expect(
                  rect.width,
                  lessThanOrEqualTo(221.0),
                  reason:
                      '[$triggerName/${itemCount}i CLOSE @ ${ms.toStringAsFixed(1)}ms] '
                      'Platter widened to ${rect.width} instead of collapsing into trigger.center!',
                );
              }
            }
            if (tw >= 120.0) {
              if (ImageFilter.isShaderFilterSupported) {
                expect(blobAWidthAt50ms, isNotNull);
                expect(blobAWidthAt200ms, isNotNull);
                expect(blobAWidthAt200ms!, greaterThan(blobAWidthAt50ms!));
                expect(blobAWidthAt200ms, greaterThan(tw * 0.72));
              }
              expect(
                maxTriggerWidthOnClose,
                greaterThan(tw * 1.007),
                reason:
                    '[$triggerName/${itemCount}i CLOSE] Wide trigger missing horizontal splash!',
              );
              expect(
                maxTriggerWidthMs,
                inInclusiveRange(350.0, 450.0),
                reason:
                    '[$triggerName/${itemCount}i CLOSE] Wide splash peaked at ${maxTriggerWidthMs}ms (expected ~400ms)!',
              );
            }

            expect(
              opacityAt83ms,
              inInclusiveRange(0.35, 0.70),
              reason:
                  '[$triggerName/${itemCount}i CLOSE] Content opacity at 83.3ms was $opacityAt83ms (expected ~0.52)!',
            );
            expect(
              opacityAt167ms,
              inInclusiveRange(0.05, 0.25),
              reason:
                  '[$triggerName/${itemCount}i CLOSE] Content opacity at 166.7ms was $opacityAt167ms (expected ~0.13)!',
            );

            expect(
              dyAt67ms,
              lessThan(-0.8),
              reason:
                  '[$triggerName/${itemCount}i CLOSE] Trigger recoil must ramp immediately in parallel on close (t=67ms)!',
            );
            expect(
              peakUpwardTriggerDy,
              inInclusiveRange(-16.5, -4.0),
              reason:
                  '[$triggerName/${itemCount}i CLOSE] Peak recoil $peakUpwardTriggerDy out of calibrated bounds!',
            );
            expect(
              peakUpwardTriggerMs,
              inInclusiveRange(150.0, 220.0),
              reason:
                  '[$triggerName/${itemCount}i CLOSE] Peak recoil at ${peakUpwardTriggerMs}ms (expected ~183ms, NOT 400ms)!',
            );
            expect(
              dyAt250ms,
              lessThan(-1.5),
              reason:
                  '[$triggerName/${itemCount}i CLOSE] Trigger was frozen at 250ms (dy=$dyAt250ms)!',
            );
          },
        );
      }
    }
  });

  group(
      '2. Cross-Widget 60fps iOS 27 Parity (PullDown, Popover, Sheet, ContextMenu)',
      () {
    testWidgets(
      'GlassPullDownButton: icon-only 44x44 & intrinsic wide capsule + nested submenu onSelected + ~183ms recoil',
      (tester) async {
        configurePhoneViewport(tester);
        String? picked;
        final wideCtrl = GlassMenuController();
        const iconPdKey = ValueKey('icon_pd');
        const widePdKey = ValueKey('wide_pd');

        await tester.pumpWidget(
          wrapStage(
            Stack(
              children: [
                Positioned(
                  top: 80,
                  left: 24,
                  child: GlassPullDownButton(
                    key: iconPdKey,
                    items: buildItems(2),
                  ),
                ),
                Positioned(
                  top: 160,
                  left: 80,
                  child: GlassPullDownButton(
                    key: widePdKey,
                    label: 'Workspace Actions',
                    controller: wideCtrl,
                    onSelected: (v) => picked = v,
                    items: [
                      GlassMenuItem(
                        title: 'Duplicate',
                        onTap: () {},
                      ),
                      GlassMenuItem(
                        title: 'Export…',
                        onTap: () {},
                        submenu: [
                          GlassMenuItem(title: 'PDF Report', onTap: () {}),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final iconRect = tester.getRect(find.byKey(iconPdKey));
        expect(iconRect.width, closeTo(44.0, 0.5));
        expect(iconRect.height, closeTo(44.0, 0.5));

        final wideBtnFinder = find.descendant(
          of: find.byKey(widePdKey),
          matching: find.byType(GlassButton),
        );
        final restWideRect = tester.getRect(wideBtnFinder);
        expect(restWideRect.width, greaterThan(150.0));

        wideCtrl.open();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Export…'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('PDF Report'));
        await tester.pump();

        double minDy = 0.0;
        double minDyMs = -1.0;
        for (int f = 1; f <= 34; f++) {
          await tester.pump(_kFrame);
          _expectCompositingSafety(tester, 'PullDown CLOSE f=$f');
          final btnElems = wideBtnFinder.evaluate();
          final r = tester.getRect(wideBtnFinder);
          if (btnElems.isNotEmpty &&
              _effectiveRenderOpacity(btnElems.first) > 0.001) {
            expect(
              r.width / restWideRect.width,
              greaterThanOrEqualTo(0.895),
              reason: 'PullDown wide button scaleX squashed below 0.90!',
            );
          }
          final dy = r.center.dy - restWideRect.center.dy;
          if (dy < minDy) {
            minDy = dy;
            minDyMs = f * 16.667;
          }
        }
        await tester.pumpAndSettle();

        expect(picked, 'PDF Report');
        expect(minDy, lessThan(-3.5));
        expect(minDyMs, inInclusiveRange(150.0, 220.0));
      },
    );

    testWidgets(
      'GlassPopover: wide centered 240x44 auto-centers, avoids radius ballooning, splashes ~400ms & peaks recoil ~183ms',
      (tester) async {
        configurePhoneViewport(tester);
        VoidCallback? openPop;
        VoidCallback? closePop;
        const popTrigKey = ValueKey('pop_wide_trig');

        await tester.pumpWidget(
          wrapStage(
            Positioned(
              top: 160,
              left: (393.0 - 240.0) / 2.0,
              child: GlassPopover(
                popoverWidth: 260,
                popoverHeight: 160,
                popoverBorderRadius: 28.0,
                quality: GlassQuality.premium,
                triggerBuilder: (ctx, toggle) {
                  openPop = toggle;
                  return GlassButton.custom(
                    key: popTrigKey,
                    width: 240,
                    height: 44,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                    useOwnLayer: true,
                    quality: GlassQuality.premium,
                    onTap: toggle,
                    child: const Text('Wide Popover Trigger'),
                  );
                },
                contentBuilder: (ctx, close) {
                  closePop = close;
                  return const Center(child: Text('Popover Body'));
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final restTrig = tester.getRect(find.byKey(popTrigKey));
        openPop!();
        final openRadii = <double>[];
        for (int f = 0; f <= 30; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
          _expectCompositingSafety(tester, 'Popover OPEN f=$f');
          for (final gc in tester
              .widgetList<GlassContainer>(find.byType(GlassContainer))) {
            final r = _extractShapeRadius(gc.shape);
            if (r != null) openRadii.add(r);
          }
        }
        await tester.pumpAndSettle();

        for (final r in openRadii) {
          expect(r, lessThanOrEqualTo(28.5));
        }

        final bodyCenter = tester.getCenter(find.text('Popover Body'));
        expect((bodyCenter.dx - restTrig.center.dx).abs(), lessThan(2.5));

        closePop!();
        final closeRadii = <double>[];
        double peakDy = 0.0;
        double peakMs = -1.0;
        double maxSplashW = 240.0;
        double maxSplashMs = -1.0;
        double contentOpAt83ms = 0.0;
        double? blobAWidthAt50ms;
        double? blobAWidthAt200ms;

        for (int f = 0; f <= 36; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
          final ms = f * 16.667;
          _expectCompositingSafety(tester, 'Popover CLOSE f=$f');
          for (final gc in tester
              .widgetList<GlassContainer>(find.byType(GlassContainer))) {
            final r = _extractShapeRadius(gc.shape);
            if (r != null) closeRadii.add(r);
            if (!gc.useOwnLayer &&
                gc.height == 44.0 &&
                ImageFilter.isShaderFilterSupported) {
              if (f == 3) blobAWidthAt50ms = gc.width;
              if (f == 12) blobAWidthAt200ms = gc.width;
            }
          }
          if (f == 5) {
            final bodyElems = find.text('Popover Body').evaluate();
            if (bodyElems.isNotEmpty) {
              contentOpAt83ms = _effectiveRenderOpacity(bodyElems.first);
            }
          }
          final trigElems = find.byKey(popTrigKey).evaluate();
          final curTrig = tester.getRect(find.byKey(popTrigKey));
          if (trigElems.isNotEmpty &&
              _effectiveRenderOpacity(trigElems.first) > 0.001) {
            expect(
              curTrig.width / 240.0,
              greaterThanOrEqualTo(0.895),
              reason: 'Popover wide trigger scaleX squashed below 0.90!',
            );
          }
          final dy = curTrig.center.dy - restTrig.center.dy;
          if (dy < peakDy) {
            peakDy = dy;
            peakMs = ms;
          }
          if (curTrig.width > maxSplashW) {
            maxSplashW = curTrig.width;
            maxSplashMs = ms;
          }
        }
        await tester.pumpAndSettle();

        for (final r in closeRadii) {
          expect(r, lessThanOrEqualTo(28.5));
        }
        if (ImageFilter.isShaderFilterSupported) {
          expect(blobAWidthAt50ms, isNotNull);
          expect(blobAWidthAt200ms, isNotNull);
          expect(blobAWidthAt200ms!, greaterThan(blobAWidthAt50ms!));
          expect(blobAWidthAt200ms, greaterThan(240.0 * 0.72));
        }
        expect(contentOpAt83ms, inInclusiveRange(0.35, 0.70));
        expect(peakDy, inInclusiveRange(-16.5, -4.0));
        expect(peakMs, inInclusiveRange(150.0, 220.0));
        expect(maxSplashW, greaterThan(240.0 * 1.008));
        expect(maxSplashMs, inInclusiveRange(350.0, 450.0));
      },
    );

    for (final initialDetent in <GlassSheetState>[
      GlassSheetState.half,
      GlassSheetState.full,
    ]) {
      testWidgets(
        'GlassModalSheet (${initialDetent.name}): ~183ms parallel recoil, ~400ms wide splash & clean <=580ms settle',
        (tester) async {
          configurePhoneViewport(tester);
          GlassModalSheet.debugMorphSupportsBlending = true;
          addTearDown(() => GlassModalSheet.debugMorphSupportsBlending = null);
          GlassMorphAnchor? anchorRef;
          BuildContext? hostCtx;
          const sheetTrigKey = ValueKey('sheet_morph_trig');

          await tester.pumpWidget(
            wrapStage(
              Positioned(
                top: 150,
                left: (393.0 - 180.0) / 2.0,
                child: Builder(
                  builder: (ctx) {
                    hostCtx = ctx;
                    return GlassMorphTrigger(
                      builder: (tCtx, anchor) {
                        anchorRef = anchor;
                        return GlassButton.custom(
                          key: sheetTrigKey,
                          width: 180,
                          height: 44,
                          shape:
                              const LiquidRoundedSuperellipse(borderRadius: 22),
                          useOwnLayer: true,
                          quality: GlassQuality.premium,
                          onTap: () {},
                          child: const Text('Open Morph Sheet'),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final restTrig = tester.getRect(find.byKey(sheetTrigKey));

          GlassModalSheet.show<void>(
            context: hostCtx!,
            morphFrom: anchorRef,
            quality: GlassQuality.premium,
            initialState: initialDetent,
            detents: const {GlassSheetDetent.medium, GlassSheetDetent.large},
            builder: (sCtx) => Center(
              child: CupertinoButton(
                onPressed: () => Navigator.of(sCtx).pop(),
                child: const Text('Close Sheet'),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text('Close Sheet'), findsOneWidget);

          await tester.tap(find.text('Close Sheet'));
          double peakDy = 0.0;
          double peakDyMs = -1.0;
          double maxSplashW = 180.0;
          double maxSplashMs = -1.0;

          for (int f = 0; f <= 36; f++) {
            await tester.pump(f == 0 ? Duration.zero : _kFrame);
            final ms = f * 16.667;

            if (anchorRef!.isPresenting) {
              for (final elem in find.byType(AdaptiveGlass).evaluate()) {
                final ag = elem.widget as AdaptiveGlass;
                if (ag.useOwnLayer) continue;
                final box = elem.renderObject as RenderBox?;
                if (box == null || !box.hasSize) continue;
                final rect = box.localToGlobal(Offset.zero) & box.size;
                if ((rect.height - 44.0).abs() < 8.0 &&
                    (rect.center.dx - restTrig.center.dx).abs() < 12.0) {
                  final dy = rect.center.dy - restTrig.center.dy;
                  if (dy < peakDy) {
                    peakDy = dy;
                    peakDyMs = ms;
                  }
                  break;
                }
              }
            } else {
              final curTrig = tester.getRect(find.byKey(sheetTrigKey));
              expect(
                curTrig.width / 180.0,
                greaterThanOrEqualTo(0.895),
                reason: 'Sheet wide trigger scaleX squashed below 0.90!',
              );
              final dy = curTrig.center.dy - restTrig.center.dy;
              if (dy < peakDy) {
                peakDy = dy;
                peakDyMs = ms;
              }
              if (curTrig.width > maxSplashW) {
                maxSplashW = curTrig.width;
                maxSplashMs = ms;
              }
            }
          }

          final trigAt600ms = tester.getRect(find.byKey(sheetTrigKey));
          final dyAt600ms = (trigAt600ms.center.dy - restTrig.center.dy).abs();
          final widthDiffAt600ms = (trigAt600ms.width - 180.0).abs();

          await tester.pumpAndSettle();

          expect(peakDy, inInclusiveRange(-16.5, -5.0));
          expect(peakDyMs, inInclusiveRange(150.0, 220.0));
          expect(maxSplashW, greaterThan(180.0 * 1.008));
          expect(maxSplashMs, inInclusiveRange(350.0, 450.0));
          expect(dyAt600ms, lessThan(0.5));
          expect(widthDiffAt600ms, lessThan(0.5));
        },
      );
    }

    testWidgets(
      'GlassContextMenu: spring open overshoot, zero fractional glass Opacity, ~180ms close recoil & Reduce Motion',
      (tester) async {
        configurePhoneViewport(tester);
        const cmRowKey = ValueKey('cm_verify_row');

        await tester.pumpWidget(
          wrapStage(
            Positioned(
              top: 140,
              left: (393.0 - 220.0) / 2.0,
              child: GlassContextMenu(
                actions: [
                  GlassContextMenuAction(
                    child: const Text('Pin Item'),
                    onPressed: () {},
                  ),
                ],
                child: Container(
                  key: cmRowKey,
                  width: 220,
                  height: 52,
                  color: CupertinoColors.systemIndigo,
                  child: const Text('CM Row'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final restRow = tester.getRect(find.byKey(cmRowKey));

        await tester.tap(find.byKey(cmRowKey), buttons: kSecondaryMouseButton);
        double maxPlatterWidth = 0.0;
        for (int f = 0; f <= 30; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
          _expectCompositingSafety(tester, 'ContextMenu OPEN f=$f');
          for (final elem in find.byType(GlassContainer).evaluate()) {
            final gc = elem.widget as GlassContainer;
            if (!gc.useOwnLayer) continue;
            final r = tester.getRect(find.byWidget(gc));
            if (r.width > maxPlatterWidth) {
              maxPlatterWidth = r.width;
            }
          }
        }
        await tester.pumpAndSettle();
        expect(find.text('Pin Item'), findsOneWidget);
        expect(maxPlatterWidth, greaterThan(252.0));

        await tester.tapAt(const Offset(12, 12));
        double minDy = 0.0;
        double minDyMs = -1.0;
        double opAt83ms = 0.0;
        for (int f = 0; f <= 32; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
          final ms = f * 16.667;
          _expectCompositingSafety(tester, 'ContextMenu CLOSE f=$f');
          if (f == 5) {
            final pinElems = find.text('Pin Item').evaluate();
            if (pinElems.isNotEmpty) {
              opAt83ms = _effectiveRenderOpacity(pinElems.first);
            }
          }
          final overlayRows = find.text('CM Row');
          if (overlayRows.evaluate().isNotEmpty) {
            final cy = tester.getCenter(overlayRows.last).dy;
            final dy = cy - restRow.center.dy;
            if (dy < minDy) {
              minDy = dy;
              minDyMs = ms;
            }
          }
        }
        await tester.pumpAndSettle();

        expect(opAt83ms, inInclusiveRange(0.35, 0.70));
        expect(minDy, lessThan(-4.0));
        expect(minDyMs, inInclusiveRange(150.0, 215.0));

        await tester.pumpWidget(
          wrapStage(
            reduceMotion: true,
            Positioned(
              top: 140,
              left: (393.0 - 220.0) / 2.0,
              child: GlassContextMenu(
                actions: [
                  GlassContextMenuAction(
                    child: const Text('Pin Item'),
                    onPressed: () {},
                  ),
                ],
                child: Container(
                  key: cmRowKey,
                  width: 220,
                  height: 52,
                  color: CupertinoColors.systemIndigo,
                  child: const Text('CM Row'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(cmRowKey), buttons: kSecondaryMouseButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        expect(find.text('Pin Item'), findsOneWidget);

        await tester.tapAt(const Offset(12, 12));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1));
        expect(find.text('Pin Item'), findsNothing);
      },
    );
  });

  group('3. Hardened Visual & Edge-Scenario Parity Suite', () {
    testWidgets(
      'Dense glass droplet body on close: platterOpacity stays 1.0 at 83ms & 133ms while contentOpacity fades linearly',
      (tester) async {
        configurePhoneViewport(tester);

        // A. Direct GlassMorphController 60fps verification
        final morph = GlassMorphController(vsync: tester);
        addTearDown(morph.dispose);
        morph.open();
        await tester.pumpAndSettle();

        morph.close();
        double ctrlPlatterOp83 = 0.0;
        double ctrlPlatterOp117 = 0.0;
        double ctrlPlatterOp133 = 0.0;
        double ctrlPlatterOp217 = 0.0;
        double ctrlContentOp83 = 0.0;
        double ctrlContentOp167 = 0.0;

        for (int f = 0; f <= 20; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
          final s = morph.computeState(finalDx: 0, finalDy: 120);
          if (f == 5) {
            ctrlPlatterOp83 = s.platterOpacity;
            ctrlContentOp83 = s.contentOpacity;
          }
          if (f == 7) ctrlPlatterOp117 = s.platterOpacity;
          if (f == 8) ctrlPlatterOp133 = s.platterOpacity;
          if (f == 10) ctrlContentOp167 = s.contentOpacity;
          if (f == 13) ctrlPlatterOp217 = s.platterOpacity;
        }
        await tester.pumpAndSettle();

        expect(ctrlPlatterOp83, equals(1.0));
        expect(ctrlPlatterOp117, equals(1.0));
        expect(ctrlPlatterOp133, greaterThanOrEqualTo(0.97));
        expect(ctrlPlatterOp217, inExclusiveRange(0.01, 0.90));
        expect(ctrlContentOp83, inInclusiveRange(0.45, 0.60));
        expect(ctrlContentOp167, inInclusiveRange(0.08, 0.20));

        // B. Live GlassMenu & GlassPopover surface visibility verification
        final menuCtrl = GlassMenuController();
        VoidCallback? openPop;
        VoidCallback? closePop;

        await tester.pumpWidget(
          wrapStage(
            Stack(
              children: [
                Positioned(
                  top: 120,
                  left: 24,
                  child: GlassMenu(
                    controller: menuCtrl,
                    menuWidth: 220,
                    quality: GlassQuality.standard,
                    items: buildItems(4),
                    trigger: const Icon(CupertinoIcons.ellipsis_circle),
                  ),
                ),
                Positioned(
                  top: 260,
                  left: 24,
                  child: GlassPopover(
                    popoverWidth: 240,
                    popoverHeight: 140,
                    quality: GlassQuality.standard,
                    triggerBuilder: (ctx, toggle) {
                      openPop = toggle;
                      return GlassButton.custom(
                        width: 44,
                        height: 44,
                        onTap: toggle,
                        child: const Text('Pop'),
                      );
                    },
                    contentBuilder: (ctx, close) {
                      closePop = close;
                      return const Center(child: Text('Dense Popover Body'));
                    },
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check GlassMenu platter visibility vs row content opacity
        menuCtrl.open();
        await tester.pumpAndSettle();
        menuCtrl.close();

        double menuSurfaceVis83 = 0.0;
        double menuSurfaceVis133 = 0.0;
        double menuContentOp83 = 0.0;
        for (int f = 0; f <= 16; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
          if (f == 5 || f == 8) {
            for (final elem in find.byType(LightweightLiquidGlass).evaluate()) {
              final box = elem.renderObject as RenderBox?;
              if (box != null && box.hasSize && box.size.height > 46.0) {
                final lwg = elem.widget as LightweightLiquidGlass;
                final vis = lwg.settings?.visibility ?? 1.0;
                if (f == 5) menuSurfaceVis83 = vis;
                if (f == 8) menuSurfaceVis133 = vis;
              }
            }
            if (f == 5) {
              final itemElems = find.text('Menu Action 1').evaluate();
              if (itemElems.isNotEmpty) {
                menuContentOp83 = _effectiveRenderOpacity(itemElems.first);
              }
            }
          }
        }
        await tester.pumpAndSettle();

        expect(menuSurfaceVis83, equals(1.0));
        expect(menuSurfaceVis133, greaterThanOrEqualTo(0.97));
        expect(menuContentOp83, inInclusiveRange(0.45, 0.60));

        // Check GlassPopover platter visibility vs content opacity
        openPop!();
        await tester.pumpAndSettle();
        closePop!();

        double popSurfaceVis83 = 0.0;
        double popSurfaceVis133 = 0.0;
        double popContentOp83 = 0.0;
        for (int f = 0; f <= 16; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
          if (f == 5 || f == 8) {
            for (final elem in find
                .descendant(
                  of: find.byType(AdaptiveLiquidGlassLayer),
                  matching: find.byType(LightweightLiquidGlass),
                )
                .evaluate()) {
              final box = elem.renderObject as RenderBox?;
              if (box != null && box.hasSize && box.size.height > 46.0) {
                final lwg = elem.widget as LightweightLiquidGlass;
                final vis = lwg.settings?.visibility ?? 1.0;
                if (f == 5) popSurfaceVis83 = vis;
                if (f == 8) popSurfaceVis133 = vis;
              }
            }
            if (f == 5) {
              final bodyElems = find.text('Dense Popover Body').evaluate();
              if (bodyElems.isNotEmpty) {
                popContentOp83 = _effectiveRenderOpacity(bodyElems.first);
              }
            }
          }
        }
        await tester.pumpAndSettle();

        expect(popSurfaceVis83, equals(1.0));
        expect(popSurfaceVis133, greaterThanOrEqualTo(0.97));
        expect(popContentOp83, inInclusiveRange(0.45, 0.60));
      },
    );

    testWidgets(
      'Upward-opening bottom-bar menus & popovers (bottomCenter, bottomLeft, bottomRight, auto) + bottom sheet recoil downward ~183ms',
      (tester) async {
        configurePhoneViewport(tester);

        for (final (label, leftX, tw, alignment)
            in <(String, double, double, GlassMenuAlignment?)>[
          (
            'bottomCenter_wide',
            (393.0 - 200.0) / 2.0,
            200.0,
            GlassMenuAlignment.bottomCenter
          ),
          ('bottomLeft_pill', 16.0, 120.0, GlassMenuAlignment.bottomLeft),
          (
            'bottomRight_pill',
            393.0 - 16.0 - 120.0,
            120.0,
            GlassMenuAlignment.bottomRight
          ),
          ('auto_bottom_round', (393.0 - 44.0) / 2.0, 44.0, null),
        ]) {
          final ctrl = GlassMenuController();
          final trigKey = ValueKey('upward_menu_$label');

          await tester.pumpWidget(
            wrapStage(
              Positioned(
                top: 760,
                left: leftX,
                child: GlassMenu(
                  controller: ctrl,
                  menuWidth: 210,
                  menuAlignment: alignment,
                  autoAdjustToScreen: true,
                  menuPadding: const EdgeInsets.all(12),
                  quality: GlassQuality.premium,
                  items: buildItems(5),
                  triggerBuilder: (ctx, toggle) => GlassButton.custom(
                    key: trigKey,
                    width: tw,
                    height: 44,
                    shape: tw == 44
                        ? const LiquidOval()
                        : const LiquidRoundedSuperellipse(borderRadius: 22),
                    useOwnLayer: true,
                    quality: GlassQuality.premium,
                    onTap: toggle,
                    child: const Text('Up'),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final restTrig = tester.getRect(find.byKey(trigKey));
          ctrl.open();
          await tester.pumpAndSettle();

          final openPlatter = _findOverlayPlatterRect(tester);
          expect(openPlatter, isNotNull);
          expect(
            openPlatter!.center.dy,
            lessThan(restTrig.top),
            reason: '[$label] Bottom-bar menu must open upward above trigger!',
          );

          ctrl.close();
          double maxDownwardDy = 0.0;
          double maxDownwardMs = -1.0;
          for (int f = 0; f <= 34; f++) {
            await tester.pump(f == 0 ? Duration.zero : _kFrame);
            final curTrig = tester.getRect(find.byKey(trigKey));
            final dy = curTrig.center.dy - restTrig.center.dy;
            if (dy > maxDownwardDy) {
              maxDownwardDy = dy;
              maxDownwardMs = f * 16.667;
            }
          }
          await tester.pumpAndSettle();

          expect(
            maxDownwardDy,
            greaterThan(5.0),
            reason:
                '[$label] Upward menu must recoil downward (+dy > 5px) on close!',
          );
          expect(
            maxDownwardMs,
            inInclusiveRange(150.0, 220.0),
            reason:
                '[$label] Downward recoil peaked at ${maxDownwardMs}ms (expected ~183ms)!',
          );
        }

        // Upward-opening bottom-bar GlassPopover
        VoidCallback? openPop;
        VoidCallback? closePop;
        const botPopTrigKey = ValueKey('bottom_pop_trig');
        await tester.pumpWidget(
          wrapStage(
            Positioned(
              top: 760,
              left: (393.0 - 160.0) / 2.0,
              child: GlassPopover(
                popoverWidth: 240,
                popoverHeight: 160,
                quality: GlassQuality.premium,
                triggerBuilder: (ctx, toggle) {
                  openPop = toggle;
                  return GlassButton.custom(
                    key: botPopTrigKey,
                    width: 160,
                    height: 44,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                    useOwnLayer: true,
                    quality: GlassQuality.premium,
                    onTap: toggle,
                    child: const Text('Bottom Popover'),
                  );
                },
                contentBuilder: (ctx, close) {
                  closePop = close;
                  return const Center(child: Text('Upward Popover Body'));
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final restPopTrig = tester.getRect(find.byKey(botPopTrigKey));
        openPop!();
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(find.text('Upward Popover Body')).dy,
          lessThan(restPopTrig.top),
        );

        closePop!();
        double popDownDy = 0.0;
        double popDownMs = -1.0;
        for (int f = 0; f <= 34; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
          final curTrig = tester.getRect(find.byKey(botPopTrigKey));
          final dy = curTrig.center.dy - restPopTrig.center.dy;
          if (dy > popDownDy) {
            popDownDy = dy;
            popDownMs = f * 16.667;
          }
        }
        await tester.pumpAndSettle();

        expect(popDownDy, greaterThan(5.0));
        expect(popDownMs, inInclusiveRange(150.0, 220.0));
      },
    );

    testWidgets(
      'Right-edge clamped triggers (GlassMenu & GlassPopover): zero J-curve screen overflow & diagonal return into trigger.center',
      (tester) async {
        configurePhoneViewport(tester);

        for (final tw in <double>[44.0, 200.0]) {
          final ctrl = GlassMenuController();
          final trigKey = ValueKey('right_edge_menu_$tw');

          await tester.pumpWidget(
            wrapStage(
              Positioned(
                top: 160,
                left: 393.0 - 16.0 - tw,
                child: GlassMenu(
                  controller: ctrl,
                  menuWidth: 230,
                  autoAdjustToScreen: true,
                  menuPadding: const EdgeInsets.symmetric(horizontal: 12),
                  quality: GlassQuality.premium,
                  items: buildItems(5),
                  triggerBuilder: (ctx, toggle) => GlassButton.custom(
                    key: trigKey,
                    width: tw,
                    height: 44,
                    shape: tw == 44
                        ? const LiquidOval()
                        : const LiquidRoundedSuperellipse(borderRadius: 22),
                    useOwnLayer: true,
                    quality: GlassQuality.premium,
                    onTap: toggle,
                    child: const Text('R'),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          final restTrig = tester.getRect(find.byKey(trigKey));
          ctrl.open();
          for (int f = 0; f <= 30; f++) {
            await tester.pump(f == 0 ? Duration.zero : _kFrame);
            final platter = _findOverlayPlatterRect(tester);
            if (platter != null) {
              expect(
                platter.right,
                lessThanOrEqualTo(393.0 - 11.5),
                reason:
                    '[right_edge tw=$tw OPEN f=$f] Menu overflowed right safe margin (${platter.right} > 381.0)!',
              );
            }
          }
          await tester.pumpAndSettle();

          ctrl.close();
          Rect? lateClosePlatter;
          for (int f = 0; f <= 34; f++) {
            await tester.pump(f == 0 ? Duration.zero : _kFrame);
            final p = _findOverlayPlatterRect(tester, minHeight: 16.0);
            if (p != null) lateClosePlatter = p;
          }
          await tester.pumpAndSettle();

          expect(lateClosePlatter, isNotNull);
          expect(
            (lateClosePlatter!.center.dx - restTrig.center.dx).abs(),
            lessThan(24.0),
          );
        }

        // Right-edge GlassPopover
        VoidCallback? openPop;
        VoidCallback? closePop;
        await tester.pumpWidget(
          wrapStage(
            Positioned(
              top: 160,
              left: 393.0 - 16.0 - 140.0,
              child: GlassPopover(
                popoverWidth: 250,
                popoverHeight: 150,
                autoAdjustToScreen: true,
                screenPadding: const EdgeInsets.all(12),
                quality: GlassQuality.premium,
                triggerBuilder: (ctx, toggle) {
                  openPop = toggle;
                  return GlassButton.custom(
                    width: 140,
                    height: 44,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                    useOwnLayer: true,
                    quality: GlassQuality.premium,
                    onTap: toggle,
                    child: const Text('Right Pop'),
                  );
                },
                contentBuilder: (ctx, close) {
                  closePop = close;
                  return const Center(child: Text('Clamped Popover'));
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        openPop!();
        for (int f = 0; f <= 30; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
          final platter = _findOverlayPlatterRect(tester);
          if (platter != null) {
            expect(platter.right, lessThanOrEqualTo(393.0 - 11.5));
          }
        }
        await tester.pumpAndSettle();
        closePop!();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Expanded GlassMenuItem.submenu collapses coherently into trigger.center on close & resets depth on settle',
      (tester) async {
        configurePhoneViewport(tester);
        final ctrl = GlassMenuController();
        const subTrigKey = ValueKey('submenu_wide_trig');

        await tester.pumpWidget(
          wrapStage(
            Positioned(
              top: 150,
              left: (393.0 - 220.0) / 2.0,
              child: GlassMenu(
                controller: ctrl,
                menuWidth: 220,
                autoAdjustToScreen: true,
                menuPadding: const EdgeInsets.symmetric(horizontal: 12),
                quality: GlassQuality.premium,
                items: [
                  GlassMenuItem(title: 'Quick Look', onTap: () {}),
                  GlassMenuItem(
                    title: 'Move to Folder',
                    onTap: () {},
                    submenu: [
                      GlassMenuItem(title: '2026 Releases', onTap: () {}),
                      GlassMenuItem(title: 'Design Specs', onTap: () {}),
                    ],
                  ),
                ],
                triggerBuilder: (ctx, toggle) => GlassButton.custom(
                  key: subTrigKey,
                  width: 220,
                  height: 44,
                  shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                  useOwnLayer: true,
                  quality: GlassQuality.premium,
                  onTap: toggle,
                  child: const Text('Submenu Trigger'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final restTrig = tester.getRect(find.byKey(subTrigKey));
        ctrl.open();
        await tester.pumpAndSettle();

        await tester.tap(find.text('Move to Folder'));
        await tester.pumpAndSettle();
        expect(find.text('2026 Releases'), findsOneWidget);

        final initialSubCenter = tester.getCenter(find.text('2026 Releases'));
        final initialDist = (initialSubCenter - restTrig.center).distance;

        ctrl.close();
        double? distAt133ms;
        for (int f = 0; f <= 34; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
          if (f == 8 && find.text('2026 Releases').evaluate().isNotEmpty) {
            final curSubCenter = tester.getCenter(find.text('2026 Releases'));
            distAt133ms = (curSubCenter - restTrig.center).distance;
          }
        }
        await tester.pumpAndSettle();

        expect(distAt133ms, isNotNull);
        expect(
          distAt133ms!,
          lessThan(initialDist * 0.65),
          reason:
              'Expanded submenu card must collapse coherently toward trigger.center alongside Blob B!',
        );

        // Reopen and verify submenu stack was cleanly reset to root depth 0
        ctrl.open();
        await tester.pumpAndSettle();
        expect(find.text('Quick Look'), findsOneWidget);
        expect(find.text('2026 Releases'), findsNothing);
        ctrl.close();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'Mid-open close (83ms), mid-close reopen (100ms & 350ms) C0 continuity, and early ModalSheet dismiss non-squish',
      (tester) async {
        configurePhoneViewport(tester);

        // A. GlassMenu C0 reversals (83ms mid-open close, 100ms & 350ms mid-close reopen)
        final menuCtrl = GlassMenuController();
        const revMenuTrigKey = ValueKey('rev_menu_trig');

        await tester.pumpWidget(
          wrapStage(
            Positioned(
              top: 160,
              left: (393.0 - 240.0) / 2.0,
              child: GlassMenu(
                controller: menuCtrl,
                menuWidth: 220,
                quality: GlassQuality.premium,
                items: buildItems(5),
                triggerBuilder: (ctx, toggle) => GlassButton.custom(
                  key: revMenuTrigKey,
                  width: 240,
                  height: 44,
                  shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                  useOwnLayer: true,
                  quality: GlassQuality.premium,
                  onTap: toggle,
                  child: const Text('Reversal Menu'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1) Mid-open close at 83.3ms (f=5)
        menuCtrl.open();
        for (int f = 0; f <= 5; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
        }
        final beforeMidOpenClose = _findOverlayPlatterRect(tester)!;
        menuCtrl.close();
        await tester.pump(_kFrame);
        final afterMidOpenClose = _findOverlayPlatterRect(tester)!;
        expect(
          (afterMidOpenClose.center - beforeMidOpenClose.center).distance,
          lessThan(28.0),
          reason: 'GlassMenu mid-open close snapped position discontinuously!',
        );
        expect(
          (afterMidOpenClose.width - beforeMidOpenClose.width).abs(),
          lessThan(28.0),
          reason: 'GlassMenu mid-open close snapped width discontinuously!',
        );
        await tester.pumpAndSettle();

        // 2) Mid-close reopen at 100ms (f=6)
        menuCtrl.open();
        await tester.pumpAndSettle();
        menuCtrl.close();
        for (int f = 0; f <= 6; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
        }
        final beforeMidCloseReopen = _findOverlayPlatterRect(tester)!;
        await tester.tap(find.byKey(revMenuTrigKey));
        await tester.pump(_kFrame);
        final afterMidCloseReopen = _findOverlayPlatterRect(tester)!;
        expect(
          (afterMidCloseReopen.center - beforeMidCloseReopen.center).distance,
          lessThan(28.0),
          reason:
              'GlassMenu mid-close reopen snapped position discontinuously!',
        );
        expect(afterMidCloseReopen.width, greaterThan(80.0));
        await tester.pumpAndSettle();
        expect(find.text('Menu Action 1'), findsOneWidget);

        // 3) Mid-close tap reopen at 350ms (f=21, post-handoff splash tail)
        menuCtrl.close();
        for (int f = 0; f <= 21; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
        }
        await tester.tap(find.byKey(revMenuTrigKey));
        await tester.pumpAndSettle();
        expect(find.text('Menu Action 1'), findsOneWidget);
        menuCtrl.close();
        await tester.pumpAndSettle();

        // B. GlassPopover mid-close tap reopen at 100ms & 350ms
        VoidCallback? openPop;
        VoidCallback? closePop;
        const revPopTrigKey = ValueKey('rev_pop_trig');

        await tester.pumpWidget(
          wrapStage(
            Positioned(
              top: 160,
              left: (393.0 - 220.0) / 2.0,
              child: GlassPopover(
                popoverWidth: 250,
                popoverHeight: 150,
                quality: GlassQuality.premium,
                triggerBuilder: (ctx, toggle) {
                  openPop = toggle;
                  return GlassButton.custom(
                    key: revPopTrigKey,
                    width: 220,
                    height: 44,
                    shape: const LiquidRoundedSuperellipse(borderRadius: 22),
                    useOwnLayer: true,
                    quality: GlassQuality.premium,
                    onTap: toggle,
                    child: const Text('Reversal Popover'),
                  );
                },
                contentBuilder: (ctx, close) {
                  closePop = close;
                  return const Center(child: Text('Popover Reversal Body'));
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        openPop!();
        await tester.pumpAndSettle();
        closePop!();
        for (int f = 0; f <= 6; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
        }
        final popBeforeReopen = _findOverlayPlatterRect(tester)!;
        await tester.tap(find.byKey(revPopTrigKey));
        await tester.pump(_kFrame);
        final popAfterReopen = _findOverlayPlatterRect(tester)!;
        expect(
          (popAfterReopen.center.dx - popBeforeReopen.center.dx).abs(),
          lessThan(2.0),
        );
        expect(
          (popAfterReopen.width - popBeforeReopen.width).abs(),
          lessThan(12.0),
        );
        expect(popAfterReopen.width, greaterThan(100.0));
        await tester.pumpAndSettle();
        expect(find.text('Popover Reversal Body'), findsOneWidget);

        closePop!();
        for (int f = 0; f <= 21; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
        }
        await tester.tap(find.byKey(revPopTrigKey));
        await tester.pumpAndSettle();
        expect(find.text('Popover Reversal Body'), findsOneWidget);
        closePop!();
        await tester.pumpAndSettle();

        // C. Early mid-open GlassModalSheet dismissal non-squish (>= 0.90x)
        GlassModalSheet.debugMorphSupportsBlending = true;
        addTearDown(() => GlassModalSheet.debugMorphSupportsBlending = null);
        GlassMorphAnchor? sheetAnchor;
        BuildContext? sheetHostCtx;
        const earlySheetTrigKey = ValueKey('early_sheet_trig');

        await tester.pumpWidget(
          wrapStage(
            Positioned(
              top: 150,
              left: (393.0 - 220.0) / 2.0,
              child: Builder(
                builder: (ctx) {
                  sheetHostCtx = ctx;
                  return GlassMorphTrigger(
                    builder: (tCtx, anchor) {
                      sheetAnchor = anchor;
                      return GlassButton.custom(
                        key: earlySheetTrigKey,
                        width: 220,
                        height: 44,
                        shape:
                            const LiquidRoundedSuperellipse(borderRadius: 22),
                        useOwnLayer: true,
                        quality: GlassQuality.premium,
                        onTap: () {},
                        child: const Text('Early Sheet Trigger'),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        GlassModalSheet.show<void>(
          context: sheetHostCtx!,
          morphFrom: sheetAnchor,
          quality: GlassQuality.premium,
          initialState: GlassSheetState.half,
          builder: (sCtx) => const SizedBox(height: 200),
        );
        for (int f = 0; f <= 5; f++) {
          await tester.pump(f == 0 ? Duration.zero : _kFrame);
        }
        Navigator.of(sheetHostCtx!, rootNavigator: true).pop();

        for (int f = 1; f <= 36; f++) {
          await tester.pump(_kFrame);
          if (!sheetAnchor!.isPresenting) {
            final r = tester.getRect(find.byKey(earlySheetTrigKey));
            expect(
              r.width / 220.0,
              greaterThanOrEqualTo(0.895),
              reason:
                  'Early mid-open sheet dismissal squashed wide trigger scaleX below 0.90!',
            );
          }
        }
        await tester.pumpAndSettle();
      },
    );
  });
}
