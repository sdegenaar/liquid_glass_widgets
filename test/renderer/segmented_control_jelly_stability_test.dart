import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

// Regression test: during a slow drag on a default-height (32 pt)
// GlassSegmentedControl with native IndicatorJellyPhysics, vertical jelly
// thinning drops the lifted lens height below 48 pt (~50.6 pt * 0.94 = 47.6 pt).
// Previously liquid_glass_render.frag gated isBarIndicator and compact-thumb
// lensLift solely on uGeometrySize.y >= 48 pt, causing a violent single-frame
// (~67k px at 3x DPR) strobe between clear dark glass and milky thumb lift.
//
// Run under Impeller:
//   flutter test --enable-impeller test/renderer/segmented_control_jelly_stability_test.dart
void main() {
  testWidgets(
      'GlassSegmentedControl slow drag stays optically stable across vertical '
      'jelly thinning (no 48 pt thumb-lift flicker)',
      skip: !ui.ImageFilter.isShaderFilterSupported, (tester) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(1200, 600);
    addTearDown(tester.view.reset);

    await tester.runAsync(() => LiquidGlassWidgets.initialize(
          enablePerformanceMonitor: false,
          warmUpMode: GlassWarmUpMode.always,
        ));

    var selected = 0;
    final boundary = GlobalKey();

    await tester.pumpWidget(
      LiquidGlassWidgets.wrap(
        child: StatefulBuilder(
          builder: (context, setState) {
            return GlassTheme(
              data: selected == 0
                  ? GlassThemeData.ios27(brightness: Brightness.dark)
                  : GlassThemeData.ios26(brightness: Brightness.dark),
              child: CupertinoApp(
                theme: const CupertinoThemeData(brightness: Brightness.dark),
                home: RepaintBoundary(
                  key: boundary,
                  child: ColoredBox(
                    color: const Color(0xFF0A0A1A),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: GlassSegmentedControl(
                          useOwnLayer: true,
                          selectedIndex: selected,
                          onSegmentSelected: (i) =>
                              setState(() => selected = i),
                          // Stress-test strong vertical thinning so uGeometrySize.y
                          // explicitly crosses the legacy 48 pt threshold both ways.
                          indicatorJelly: IndicatorJellyPhysics.native.copyWith(
                            dragTrailingDuration:
                                const Duration(milliseconds: 260),
                            dragThinning: 1.6,
                          ),
                          segments: const [
                            GlassSegment(label: 'iOS 27'),
                            GlassSegment(label: 'iOS 26'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final segRect = tester.getRect(find.byType(GlassSegmentedControl));

    Future<Uint8List> snap() async {
      final ro =
          boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      return (await tester.runAsync(() async {
        final img = await ro.toImage(pixelRatio: 3.0);
        final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
        img.dispose();
        return bd!.buffer.asUint8List();
      }))!;
    }

    final start =
        Offset(segRect.left + segRect.width * 0.25, segRect.center.dy);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(const Offset(20, 0));
    for (int i = 0; i < 15; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    Uint8List? prev;
    var maxDiffPx = 0;
    var sawThinnedBelow095 = false;
    var sawRecoveredAbove095 = false;

    for (int step = 0; step < 30; step++) {
      // Accelerate briskly for 10 frames so vertical thinning crosses the
      // legacy 48 pt (scaleY ≈ 0.953) cliff downward, then hold still so it
      // rebounds back upward across 48 pt.
      final dx = step < 10 ? 12.0 : 0.0;
      if (dx != 0) await gesture.moveBy(Offset(dx, 0));
      await tester.pump(const Duration(milliseconds: 16));

      final indicator = tester
          .widgetList<AnimatedGlassIndicator>(
            find.byType(AnimatedGlassIndicator),
          )
          .first;
      final sy = indicator.jelly?.scaleY ?? 1.0;
      if (sy < 0.945) sawThinnedBelow095 = true;
      if (sawThinnedBelow095 && sy > 0.955) sawRecoveredAbove095 = true;

      final cur = await snap();
      if (prev != null) {
        var diffPx = 0;
        for (int i = 0; i < cur.length; i += 4) {
          final d = (cur[i] - prev[i]).abs() +
              (cur[i + 1] - prev[i + 1]).abs() +
              (cur[i + 2] - prev[i + 2]).abs();
          if (d > 20) diffPx++;
        }
        if (diffPx > maxDiffPx) maxDiffPx = diffPx;
      }
      prev = cur;
    }

    await gesture.up();
    await tester.pumpAndSettle();

    // Ensure the drag actually crossed the old 48 pt (scaleY ≈ 0.953) cliff
    // both downward and back upward.
    expect(sawThinnedBelow095, isTrue);
    expect(sawRecoveredAbove095, isTrue);
    // Previously this hit ~67,358 px on the frames crossing scaleY ≈ 0.953.
    expect(
      maxDiffPx,
      lessThan(20000),
      reason: 'Expected smooth frame-to-frame motion without a full-pill '
          'milky thumb-lift strobe (maxDiffPx=$maxDiffPx)',
    );
  });
}
