// ignore_for_file: require_trailing_commas
// Coverage tests for AnimatedGlassIndicator.
//
// Targets the following new-in-0.17.0 code paths:
//   - _mergeWithBase(): called when settings != null; tests both override and
//     no-op (all-defaults) paths, covering every field comparison branch.
//   - thickness > 0.01 branch: renders glassWidget (not SizedBox.expand).
//   - stablePinchFade calculation: exercises the quadratic ease-out formula.
//   - pinchStrength = 0.0 / 0.4 / 1.0 variations.
//   - expansion resolving (custom EdgeInsets → Directionality).
//   - paintBackground: false (skips background pill → backgroundOpacity guard).
//   - exactWidth + exactOffset pixel-precise positioning.
//   - baseIndicatorSettings public constant inspection.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:liquid_glass_widgets/widgets/shared/glass_effect.dart';

import '../../shared/test_helpers.dart';

// AnimatedGlassIndicator is a Positioned.fill widget — must be inside a Stack.
Widget _wrap(Widget indicator) => createTestApp(
      child: SizedBox(
        width: 400,
        height: 80,
        child: Stack(children: [indicator]),
      ),
    );

AnimatedGlassIndicator _make({
  double thickness = 0.5,
  LiquidGlassSettings? settings,
  double pinchStrength = 1.0,
  EdgeInsetsGeometry expansion = const EdgeInsets.all(8.0),
  bool paintBackground = true,
  bool paintGlass = true,
  double? exactWidth,
  double? exactOffset,
  double velocity = 0.0,
  double innerBlur = 0.0,
  GlassQuality quality = GlassQuality.standard,
}) =>
    AnimatedGlassIndicator(
      velocity: velocity,
      itemCount: 3,
      alignment: Alignment.center,
      thickness: thickness,
      quality: quality,
      indicatorColor: Colors.blue,
      isBackgroundIndicator: false,
      borderRadius: 20.0,
      settings: settings,
      pinchStrength: pinchStrength,
      expansion: expansion,
      paintBackground: paintBackground,
      paintGlass: paintGlass,
      exactWidth: exactWidth,
      exactOffset: exactOffset,
      innerBlur: innerBlur,
    );

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  // ── _mergeWithBase coverage ──────────────────────────────────────────────
  // _mergeWithBase is called when settings != null. Each test exercises the
  // true branch of at least one field comparison inside _mergeWithBase.

  group('AnimatedGlassIndicator — _mergeWithBase (settings != null)', () {
    testWidgets('non-default blur overrides baseIndicatorSettings.blur',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5, // > 0.01 → full build path
        settings: const LiquidGlassSettings(blur: 10), // blur != default (5)
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('non-default chromaticAberration overrides base value',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        settings: const LiquidGlassSettings(
          chromaticAberration: 0.5, // != default 0.01
        ),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('multiple non-default fields exercise several branches',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.8,
        settings: const LiquidGlassSettings(
          blur: 8,
          saturation: 2.0, // != default 1.5
          glowIntensity: 0.3, // != default 0.0
          ambientStrength: 0.2, // != default 0.0
          refractiveIndex: 1.3, // != default 1.2
          lightIntensity: 0.9, // != default 0.5
          whitenStrength: 0.5, // != default 0.0
          shadowElevation: 2.0, // != default 1.0
        ),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'all fields at constructor defaults — every branch takes the null arm',
        (tester) async {
      // All fields equal LiquidGlassSettings() defaults → _mergeWithBase
      // returns baseIndicatorSettings unchanged (every ternary takes null).
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.4,
        settings: const LiquidGlassSettings(), // no overrides
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('non-default glassColor exercises glassColor branch',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        settings: const LiquidGlassSettings(
          glassColor: Color(0x40FF0000), // != default transparent white
        ),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('non-default backerColor survives onto the built glass',
        (tester) async {
      // Regression: _mergeWithBase rebuilds settings field-by-field and used to
      // OMIT backerColor, silently dropping any backerColor set via
      // indicatorSettings. It must now reach the rendered GlassEffect.
      const backer = Color(0xFF123456);
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        settings: const LiquidGlassSettings(backerColor: backer),
      )));
      await tester.pump();
      final glass =
          tester.widget<GlassEffect>(find.byType(GlassEffect).first);
      expect(glass.settings.backerColor, backer);
    });

    testWidgets('non-default thickness exercises thickness branch',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        settings: const LiquidGlassSettings(
          thickness: 30, // != default 20
        ),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('non-default standardOpacityMultiplier exercises that branch',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        settings: const LiquidGlassSettings(
          standardOpacityMultiplier: 0.5, // != default 1.0
        ),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('shadow list overrides shadow field', (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        settings: LiquidGlassSettings(
          shadow: [
            const BoxShadow(color: Colors.black26, blurRadius: 8),
          ],
        ),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('non-default whitenGated exercises whitenGated branch',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        settings: const LiquidGlassSettings(
          whitenGated: false, // != default true
        ),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ── thickness branch coverage ────────────────────────────────────────────

  group('AnimatedGlassIndicator — thickness branches', () {
    testWidgets('thickness > 0.01 renders glassWidget (stablePinchFade path)',
        (tester) async {
      // With thickness = 0.9, stablePinchFade = 1 - (0.1)^2 = 0.99.
      // The glassWidget branch is taken → GlassEffect is built.
      await tester.pumpWidget(_wrap(_make(thickness: 0.9)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('thickness = 1.0 (max active): glassWidget branch and pinch=1',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(thickness: 1.0)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('thickness <= 0.01 takes SizedBox.expand branch',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(thickness: 0.005)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('thickness = 0.0 (resting): backgroundOpacity = 1.0',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(thickness: 0.0)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ── pinchStrength parameter ──────────────────────────────────────────────

  group('AnimatedGlassIndicator — pinchStrength', () {
    testWidgets('pinchStrength = 0.0 disables pinch (stablePinchFade * 0 = 0)',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(thickness: 0.5, pinchStrength: 0.0)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('pinchStrength = 0.4 (typical bar default)', (tester) async {
      await tester.pumpWidget(_wrap(_make(thickness: 0.5, pinchStrength: 0.4)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('pinchStrength = 1.0 (full Apple pinch)', (tester) async {
      await tester.pumpWidget(_wrap(_make(thickness: 0.7, pinchStrength: 1.0)));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ── expansion and paint flags ────────────────────────────────────────────

  group('AnimatedGlassIndicator — expansion and paint flags', () {
    testWidgets('custom symmetric expansion resolves in LTR context',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        expansion: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('non-uniform expansion resolves directional insets',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        expansion: const EdgeInsetsDirectional.fromSTEB(4, 2, 8, 6),
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('paintBackground: false skips background pill', (tester) async {
      // backgroundOpacity guard: paintBackground=false → Positioned not added.
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        paintBackground: false,
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('paintGlass: false skips glass layer', (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        paintGlass: false,
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('exactWidth + exactOffset uses Positioned pixel layout',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        exactWidth: 100.0,
        exactOffset: 50.0,
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ── velocity / jelly transform ───────────────────────────────────────────

  group('AnimatedGlassIndicator — velocity (jelly transform)', () {
    testWidgets('positive velocity exercises jelly squash transform',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.6,
        velocity: 200.0,
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('negative velocity (reverse drag) exercises opposite transform',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.6,
        velocity: -150.0,
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ── innerBlur (rest-blur) ────────────────────────────────────────────────

  group('AnimatedGlassIndicator — innerBlur (rest-blur)', () {
    testWidgets('innerBlur > 0 at rest renders the rest-blur BackdropFilter',
        (tester) async {
      // paintBackground=true + innerBlur>0 + backgroundOpacity>0 (thickness 0 →
      // backgroundOpacity 1.0) → the rest-gated BackdropFilter block renders.
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.0,
        innerBlur: 6.0,
        paintBackground: true,
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(BackdropFilter), findsWidgets);
    });

    testWidgets('innerBlur > 0 mid-morph (backgroundOpacity 0) skips the blur',
        (tester) async {
      // thickness 0.5 → backgroundOpacity clamps to 0 → the guard short-circuits
      // even with innerBlur set, so the rest-blur block is not added.
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.5,
        innerBlur: 6.0,
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('innerBlur with paintBackground: false adds no rest-blur',
        (tester) async {
      await tester.pumpWidget(_wrap(_make(
        thickness: 0.0,
        innerBlur: 6.0,
        paintBackground: false,
      )));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  // ── baseIndicatorSettings public constant ────────────────────────────────

  group('AnimatedGlassIndicator.baseIndicatorSettings', () {
    test('chromaticAberration is the iOS 26 iridescent value (0.15)', () {
      expect(
        AnimatedGlassIndicator.baseIndicatorSettings.chromaticAberration,
        closeTo(0.15, 1e-10),
      );
    });

    test('blur is 0 (no frosting on the indicator pill)', () {
      expect(AnimatedGlassIndicator.baseIndicatorSettings.blur, 0);
    });

    test('glassColor is fully transparent (alpha = 0)', () {
      expect(
        AnimatedGlassIndicator.baseIndicatorSettings.glassColor.a,
        closeTo(0.0, 0.01),
      );
    });
  });
}
