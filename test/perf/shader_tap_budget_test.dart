// Deterministic shader tap/ALU budget and numerical precision regression guards.
//
// Extends test/shaders/frost_early_out_test.dart and frost_ghost_taps_test.dart
// to verify Wave 1.2 & Wave 1.3 optimizations across all fragment shaders and
// verify the exact Dart-simulated pixel-error bounds of the IIR Gaussian weights
// and 2x-DPR 37-tap frostAt() kernel.

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';

String _body(String source, String signature) {
  final start = source.indexOf(signature);
  expect(start, isNonNegative, reason: '$signature is missing.');
  var depth = 0;
  for (var i = source.indexOf('{', start); i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}' && --depth == 0) return source.substring(start, i + 1);
  }
  fail('unbalanced braces after $signature');
}

void main() {
  final render = File('shaders/liquid_glass_render.frag').readAsStringSync();
  final renderGlsl = File('shaders/render.glsl').readAsStringSync();
  final sdf = File('shaders/sdf.glsl').readAsStringSync();
  final geo =
      File('shaders/liquid_glass_geometry_blended.frag').readAsStringSync();
  final lightweight = File('shaders/lightweight_glass.frag').readAsStringSync();
  final indicator =
      File('shaders/interactive_indicator.frag').readAsStringSync();
  final progBlur = File('shaders/progressive_blur.frag').readAsStringSync();
  final lensWarp = File('shaders/lens_content_warp.frag').readAsStringSync();

  group('Wave 1.2 — liquid_glass_render.frag & render.glsl', () {
    test('frostAt is skipped on pure hairline pixels (hairline >= 0.999)', () {
      final gate = render.indexOf('if (hairline < 0.999)');
      final call = render.indexOf('vec3 frost = frostAt(p, q, invTexSize);');
      expect(gate, isNonNegative);
      expect(call, greaterThan(gate));
    });

    test('frostAt uses IIR Gaussian weights (no per-column exp() loop)', () {
      final frostAt = _body(render, 'vec3 frostAt(');
      expect(frostAt, isNot(contains('exp(-dx * dx * inv2s2)')));
      expect(frostAt, contains('float e1 = exp(-inv2s2);'));
      expect(frostAt, contains('if (uFrost.z <= 1.25)'));
      expect(frostAt, contains('else if (uFrost.z <= 1.85)'));
    });

    test('IIR Gaussian weights match direct exp() to < 1e-12 across [0.3, 2.4]',
        () {
      var maxErr = 0.0;
      for (var si = 3; si <= 24; si++) {
        final sigma = si / 10.0;
        final inv2s2 = 1.0 / (2.0 * sigma * sigma);
        final e1 = math.exp(-inv2s2);
        final q = e1 * e1;
        for (var fxi = 0; fxi < 20; fxi++) {
          final d0 = 0.5 - fxi / 20.0;
          final ex = math.exp(-2.0 * d0 * inv2s2);
          final rPos = e1 * ex;
          final rNeg = e1 / ex;
          final w4 = math.exp(-d0 * d0 * inv2s2);
          final wx = List<double>.filled(9, 0.0);
          wx[4] = w4;
          var wp = w4 * rPos;
          wx[5] = wp;
          var rp = rPos * q;
          wp *= rp;
          wx[6] = wp;
          rp *= q;
          wp *= rp;
          wx[7] = wp;
          rp *= q;
          wx[8] = wp * rp;
          var wn = w4 * rNeg;
          wx[3] = wn;
          var rn = rNeg * q;
          wn *= rn;
          wx[2] = wn;
          rn *= q;
          wn *= rn;
          wx[1] = wn;
          rn *= q;
          wx[0] = wn * rn;
          for (var i = 0; i < 9; i++) {
            final dx = (i - 4) + d0;
            final ref = math.exp(-dx * dx * inv2s2);
            maxErr = math.max(maxErr, (wx[i] - ref).abs());
          }
        }
      }
      expect(maxErr, lessThan(1e-12));
    });

    test('2x-DPR 27-tap disk at sigma=1.25 matches 45 taps within bounds', () {
      const sigma = 1.25;
      const inv2s2 = 1.0 / (2.0 * sigma * sigma);
      var worstIos27 = 0.0;
      var worstExtreme = 0.0;
      for (final blurWeight in [0.8, 1.0, 1.25, 2.5]) {
        final slope = blurWeight - 1.0;
        for (var fxi = 0; fxi < 20; fxi++) {
          final fx = fxi / 20.0;
          for (var fyi = 0; fyi < 40; fyi++) {
            final dy0 = -1.0 + 2.0 * fyi / 40.0;
            for (final keptWhite in [true, false]) {
              var accF = 0.0;
              var wF = 0.0;
              var accD = 0.0;
              var wD = 0.0;
              for (var j = -2; j <= 2; j++) {
                final dy = 2.0 * j + dy0;
                final wy = math.exp(-dy * dy * inv2s2);
                for (var i = -4; i <= 4; i++) {
                  final dx = i + 0.5 - fx;
                  final inDisk = j.abs() <= 1 ? i.abs() <= 3 : i.abs() <= 1;
                  final c = (inDisk == keptWhite) ? 1.0 : 0.0;
                  final w =
                      wy * math.exp(-dx * dx * inv2s2) * (1.0 + slope * c);
                  accF += w * c;
                  wF += w;
                  if (inDisk) {
                    accD += w * c;
                    wD += w;
                  }
                }
              }
              final diff = (accF / wF - accD / wD).abs();
              worstExtreme = math.max(worstExtreme, diff);
              if (blurWeight <= 1.25) {
                worstIos27 = math.max(worstIos27, diff);
              }
            }
          }
        }
      }
      // At ios27Light (frostOpacity=0.82), ghost contributes 18% of final pixel.
      expect(worstIos27 * 0.18 * 255.0, lessThan(0.95));
      expect(worstExtreme * 0.18 * 255.0, lessThan(1.85));
    });

    test('3x-DPR 33-tap disk at sigma=1.80 matches 45 taps within 2.50/255',
        () {
      const sigma = 1.80;
      const inv2s2 = 1.0 / (2.0 * sigma * sigma);
      var worstGhostLight = 0.0;
      var worstGhostDark = 0.0;
      for (final (blurWeight, isDark) in [(0.8, false), (1.25, true)]) {
        final slope = blurWeight - 1.0;
        for (var fxi = 0; fxi < 10; fxi++) {
          final fx = fxi / 10.0;
          for (var fyi = 0; fyi < 20; fyi++) {
            final dy0 = -1.0 + 2.0 * fyi / 20.0;
            for (final keptWhite in [true, false]) {
              var accF = 0.0;
              var wF = 0.0;
              var accD = 0.0;
              var wD = 0.0;
              for (var j = -2; j <= 2; j++) {
                final dy = 2.0 * j + dy0;
                final wy = math.exp(-dy * dy * inv2s2);
                final maxCol = j == 0 ? 4 : (j.abs() == 1 ? 3 : 2);
                for (var i = -4; i <= 4; i++) {
                  final dx = i + 0.5 - fx;
                  final inDisk = i.abs() <= maxCol;
                  final c = (inDisk == keptWhite) ? 1.0 : 0.0;
                  final w =
                      wy * math.exp(-dx * dx * inv2s2) * (1.0 + slope * c);
                  accF += w * c;
                  wF += w;
                  if (inDisk) {
                    accD += w * c;
                    wD += w;
                  }
                }
              }
              final diff = (accF / wF - accD / wD).abs();
              if (isDark) {
                worstGhostDark = math.max(worstGhostDark, diff);
              } else {
                worstGhostLight = math.max(worstGhostLight, diff);
              }
            }
          }
        }
      }
      expect(worstGhostLight * 0.18 * 255.0, lessThan(2.50));
      expect(worstGhostDark * 0.10 * 255.0, lessThan(1.40));
    });

    test('flat interior live backdrop path uses single texture() fetch', () {
      expect(
        render,
        contains(
          'if (pinch <= 0.001 && dot(uCaptureOffset, uCaptureOffset) < 1e-6)',
        ),
      );
      expect(
        render,
        contains('vec4 bg = texture(uBackgroundTexture, screenUV);'),
      );
    });

    test('hairline avoids pow(x, 1.75) and reuses litness', () {
      expect(render, isNot(contains('pow(max(across, 0.0), 1.75)')));
      expect(
        render,
        contains('float across = acrossRaw * acrossSqrt * sqrt(acrossSqrt);'),
      );
    });

    test('render.glsl applyGlassColor exits early when alpha == 0', () {
      final fn = _body(renderGlsl, 'vec4 applyGlassColor(');
      expect(fn, contains('if (glassColor.a <= 0.001)'));
    });
  });

  group('Wave 1.3 — geometry, lightweight, indicator, progressive_blur', () {
    test('sdfRRectAsym short-circuits equal radii and sceneSDF nests bwd()',
        () {
      final asym = _body(sdf, 'float sdfRRectAsym(');
      expect(
          asym, contains('if (rTop == rBottom) return sdfRRect(p, b, rTop);'));

      final scene = _body(sdf, 'float sceneSDF(');
      expect(scene, contains('if (n == 2) return fwd;'));
      expect(scene, contains('if (k <= 0.0) return fwd;'));
      expect(scene, isNot(contains('float b16n')));
    });

    test('geometry shader guards deep-interior early-out against ellipses', () {
      expect(
        geo,
        contains(
          'bool unitGradBound = (numShapes == 1) && (uShapeData[0] != 2.0)',
        ),
      );
      expect(
        geo,
        contains(
          'if (unitGradBound && uThickness > 0.0 && sd < -(uThickness + edgePad + smoothing))',
        ),
      );
    });

    test('lightweight_glass reuses testRgb in flat interior and gates meniscus',
        () {
      expect(lightweight, contains('if (edgeInfluence < 1e-4)'));
      expect(lightweight, contains('bgRgb = testRgb;'));
      final meniscus = _body(lightweight, 'float meniscusAbsorption(');
      expect(
          meniscus, contains('if (strength <= 0.001 || distFromEdge >= zone)'));
    });

    test('interactive_indicator uses 1 hardware-filtered texture() with clamp',
        () {
      final bilinear = _body(indicator, 'vec4 textureBilinear(');
      final fetchCount = 'texture(uTexture'.allMatches(bilinear).length;
      expect(fetchCount, 1);
      expect(bilinear, contains('clamp(uv, halfTexel'));
    });

    test('progressive_blur breaks past 3*sigma', () {
      expect(progBlur, contains('if (d > 3.0 * sigma) break;'));
    });
  });

  group('Native tab-bar lens optics & tap budget', () {
    test('liquid_glass_render clamps nativeLens samples to the capsule spine',
        () {
      final clampUv = _body(render, 'vec2 nativeLensClampUV(');
      expect(clampUv, contains('vec2 spine = clamp(rel, -seg, seg);'));
      expect(clampUv, contains('if (dist > rIn)'));
      expect(render, contains('if (!nativeLens) {'));
    });

    test(
        'liquid_glass_render reuses greenSample at i == 2 and evaluates SDF once',
        () {
      final start = render.indexOf('} else if (nativeLens) {');
      final end = render.indexOf('} else if (dot(normalXY', start);
      expect(start, isNonNegative);
      expect(end, greaterThan(start));
      final branch = render.substring(start, end);
      expect(
        'nativeLensDistance('.allMatches(branch).length,
        1,
        reason: 'nativeLens branch must compute center SDF only once.',
      );
      expect(branch, contains('(i == 2)'));
      expect(branch, contains('greenSample.rgb'));
      expect(branch, contains('const vec3 invWeights'));
    });

    test(
        'lens_content_warp preserves outer rim bevel, uses branchless lensSd, '
        'reuses centre tap at i == 2, and gates backdrop fill on luminance',
        () {
      expect(lensWarp, contains('float lensSd(vec2 local)'));
      expect(lensWarp, contains('smoothstep(0.65, 2.0, d)'));
      expect(lensWarp, contains('(i == 2)'));
      expect(lensWarp, contains('? center'));
      expect(lensWarp, contains('const vec3 invWeights'));
      expect(lensWarp, contains('smoothstep(0.25, 0.65, backdropLuma)'));
    });

    test('single-pass isBarIndicator fallback avoids binary step(0.35) cliff',
        () {
      expect(render, isNot(contains('1.0 - step(0.35, dot(refPlatter')));
      expect(
        render,
        contains('1.0 - smoothstep(0.22, 0.48, dot(refPlatter, LUMA_WEIGHTS))'),
      );
    });
  });
}
