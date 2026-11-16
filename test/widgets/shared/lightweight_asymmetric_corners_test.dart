import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() {
  testWidgets('standard glass preserves independent vertical corner radii',
      (tester) async {
    LightweightLiquidGlass.resetForTesting();
    addTearDown(LightweightLiquidGlass.resetForTesting);
    await tester.runAsync(LightweightLiquidGlass.preWarm);
    final boundaryKey = GlobalKey();

    for (final (shape, expectedTopSmall, expectedBotSmall) in <(
      LiquidShape,
      bool,
      bool,
    )>[
      (
        const LiquidVerticalRoundedRectangle(topRadius: 28, bottomRadius: 56),
        true,
        false,
      ),
      (
        const LiquidVerticalRoundedRectangle(topRadius: 28, bottomRadius: 0),
        true,
        true,
      ),
      (
        const LiquidVerticalRoundedRectangle(topRadius: 56, bottomRadius: 28),
        false,
        true,
      ),
      (
        const LiquidVerticalRoundedRectangle(topRadius: 0, bottomRadius: 28),
        true,
        true,
      ),
      (
        const LiquidVerticalRoundedRectangle(topRadius: 28, bottomRadius: 28),
        true,
        true,
      ),
      (
        const LiquidVerticalRoundedRectangle(
          topRadius: 28,
          bottomRadius: double.infinity,
        ),
        true,
        false,
      ),
      (
        const LiquidVerticalRoundedRectangle(
          topRadius: -10,
          bottomRadius: double.nan,
        ),
        true,
        false,
      ),
      (
        const LiquidVerticalRoundedSuperellipse(
          topRadius: 28,
          bottomRadius: 56,
        ),
        true,
        false,
      ),
      (
        const LiquidVerticalRoundedSuperellipse(
          topRadius: 56,
          bottomRadius: 28,
        ),
        false,
        true,
      ),
      // Symmetric transitions on the shared native FragmentShader verify that
      // switching out of asymmetric mode (-1.0) back to >= 0.0 (including 0.0)
      // never leaks stale uData6 per-corner radii.
      (const LiquidRoundedRectangle(borderRadius: 0), true, true),
      (const LiquidRoundedRectangle(borderRadius: 28), true, true),
      (const LiquidRoundedRectangle(borderRadius: double.nan), false, false),
      (const LiquidRoundedSuperellipse(borderRadius: 56), false, false),
      (const LiquidOval(), false, false),
    ]) {
      await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: boundaryKey,
            child: LightweightLiquidGlass(
              shape: shape,
              settings: const LiquidGlassSettings(
                glassColor: Color(0xFFFFFFFF),
                bodyMode: GlassBodyMode.clear,
                blur: 0,
                thickness: 0,
                lightIntensity: 0,
                ambientStrength: 0,
                fresnelStrength: 0,
              ),
              child: const SizedBox(width: 240, height: 240),
            ),
          ),
        ),
      ));
      await tester.pump();

      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final pixels = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        image.dispose();
        return data!;
      });
      int alpha(int x, int y) => pixels!.getUint8((y * 240 + x) * 4 + 3);

      // Center must always be opaque; this also verifies the fragment shader
      // actually executed (the null-shader fallback paints at alpha 0.15 ≈ 38,
      // whereas lightweight_glass.frag in clear mode outputs 255).
      expect(alpha(120, 120), greaterThan(200), reason: '$shape center');

      // Probe pixels at (10, 10) / (229, 10) / (10, 229) / (229, 229) sit inside
      // radius ≤ 28 (dist ≈ 24.75 < 28) and outside radius ≥ 56 (dist ≈ 64.35 > 56).
      for (final x in [10, 229]) {
        expect(
          alpha(x, 10),
          expectedTopSmall ? greaterThan(200) : lessThan(20),
          reason: '$shape top corner ($x, 10)',
        );
        expect(
          alpha(x, 229),
          expectedBotSmall ? greaterThan(200) : lessThan(20),
          reason: '$shape bottom corner ($x, 229)',
        );
      }

      // Exact top-left pixel (0, 0) is opaque iff top corner radius clamps to 0.
      final hasSharpTopCorner = switch (shape) {
        LiquidVerticalRoundedRectangle(:final topRadius) ||
        LiquidVerticalRoundedSuperellipse(:final topRadius) =>
          topRadius.isFinite && topRadius <= 0,
        LiquidRoundedRectangle(:final borderRadius) ||
        LiquidRoundedSuperellipse(:final borderRadius) =>
          borderRadius.isFinite && borderRadius <= 0,
        LiquidOval() => false,
      };
      expect(
        alpha(0, 0),
        hasSharpTopCorner ? greaterThan(200) : lessThan(20),
        reason: '$shape exact (0, 0)',
      );
      expect(tester.takeException(), isNull);
    }
  });
}
