import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:liquid_glass_widgets/utils/liquid_morph_physics.dart';

// ─── Helpers ───────────────────────────────────────────────────────────────

/// Standard geometry used across most tests.
const double _finalDx = 80.0;
const double _finalDy = 160.0;
const double _hOffset = 8.0;
const double _vOffset = 4.0;

LiquidMorphState _compute(
  double rawValue, {
  double finalDx = _finalDx,
  double finalDy = _finalDy,
  double horizontalOffset = _hOffset,
  double verticalOffset = _vOffset,
}) =>
    LiquidMorphPhysics.compute(
      rawValue: rawValue,
      finalDx: finalDx,
      finalDy: finalDy,
      horizontalOffset: horizontalOffset,
      verticalOffset: verticalOffset,
    );

void main() {
  // ── Resting state ─────────────────────────────────────────────────────────

  group('LiquidMorphPhysics — resting state (rawValue = 0.0)', () {
    late LiquidMorphState s;
    setUp(() => s = _compute(0.0));

    test('pathT is 0.0 at rest', () => expect(s.pathT, equals(0.0)));
    test('sizeT is 0.0 at rest', () => expect(s.sizeT, equals(0.0)));
    test('currentDx is 0.0 at rest', () => expect(s.currentDx, equals(0.0)));
    test('currentDy is 0.0 at rest', () => expect(s.currentDy, equals(0.0)));
    test('pushDx and triggerPushDx are 0.0 at rest', () {
      expect(s.pushDx, equals(0.0));
      expect(s.triggerPushDx, equals(0.0));
    });
    test('pushDy and triggerPushDy are 0.0 at rest', () {
      expect(s.pushDy, equals(0.0));
      expect(s.triggerPushDy, equals(0.0));
    });
    test('triggerImpactScale is 1.0 at rest', () {
      expect(s.triggerImpactScale, equals(1.0));
    });
    test('triggerWidthProgress is 1.0 at rest', () {
      expect(s.triggerWidthProgress, equals(1.0));
    });
    test('platter is inactive and transparent at rest', () {
      expect(s.isPlatterActive, isFalse);
      expect(s.platterOpacity, equals(0.0));
      expect(s.contentOpacity, equals(0.0));
    });
    test('anchorScale is 1.0 at rest', () {
      expect(s.anchorScale, equals(1.0));
    });
    test('containerScale is 1.0 at rest', () {
      expect(s.containerScale, equals(1.0));
    });
    test('blend is 0.0 at rest (no separation)', () {
      expect(s.blend, equals(0.0));
    });
    test('phase is idle at rest', () {
      expect(s.phase, equals(MorphPhase.idle));
    });
  });

  // ── Fully settled state ───────────────────────────────────────────────────

  group('LiquidMorphPhysics — fully settled (rawValue = 1.0)', () {
    late LiquidMorphState s;
    setUp(() => s = _compute(1.0));

    test('anchorScale is 0.0 when fully open', () {
      expect(s.anchorScale, equals(0.0));
    });
    test('containerScale is 1.0 in normal travel range', () {
      expect(s.containerScale, equals(1.0));
    });
    test('currentDx equals finalDx * pathT', () {
      expect(s.currentDx, closeTo(_finalDx * s.pathT, 0.001));
    });
    test('phase is settled at rawValue = 1.0', () {
      expect(s.phase, equals(MorphPhase.settled));
    });
    test('pushDx is 0 when rawValue >= 0 (no close undershoot)', () {
      expect(s.pushDx, equals(0.0));
    });
    test('triggerWidthProgress is 0.0 when settled open', () {
      expect(s.triggerWidthProgress, equals(0.0));
    });
    test('platter and content are fully visible when settled open', () {
      expect(s.isPlatterActive, isTrue);
      expect(s.platterOpacity, equals(1.0));
      expect(s.contentOpacity, closeTo(1.0, 1e-6));
    });
  });

  // ── Phase transitions ─────────────────────────────────────────────────────

  group('LiquidMorphPhysics — phase state machine', () {
    test('0.001 → detaching', () {
      expect(_compute(0.001).phase, equals(MorphPhase.detaching));
    });
    test('0.1 → detaching', () {
      expect(_compute(0.1).phase, equals(MorphPhase.detaching));
    });
    test('0.4 → travelling', () {
      expect(_compute(0.4).phase, equals(MorphPhase.travelling));
    });
    test('0.6 → travelling', () {
      expect(_compute(0.6).phase, equals(MorphPhase.travelling));
    });
    test('0.8 → arriving', () {
      expect(_compute(0.8).phase, equals(MorphPhase.arriving));
    });
    test('0.99 → arriving (just below settled threshold)', () {
      expect(_compute(0.99).phase, equals(MorphPhase.arriving));
    });
    test('1.0 → settled', () {
      expect(_compute(1.0).phase, equals(MorphPhase.settled));
    });
    test('negative rawValue → detaching (close bounce)', () {
      expect(_compute(-0.1).phase, equals(MorphPhase.detaching));
    });
  });

  // ── Stateless close undershoot fallback (rawValue < 0, no elapsed clock) ──

  group('LiquidMorphPhysics — stateless close undershoot (rawValue < 0)', () {
    const undershoot = -0.2;
    late LiquidMorphState s;
    setUp(() => s = _compute(undershoot));

    test('containerScale drops below 1.0 during close undershoot', () {
      expect(s.containerScale, lessThan(1.0));
      expect(s.containerScale, closeTo(1.0 + undershoot * 0.55, 0.001));
    });

    test('pushDx is non-zero during close undershoot', () {
      final expected = (_finalDx + _hOffset) * undershoot;
      expect(s.pushDx, closeTo(expected, 0.001));
    });

    test('pushDy is non-zero during close undershoot', () {
      final expected = (_finalDy + _vOffset) * undershoot;
      expect(s.pushDy, closeTo(expected, 0.001));
    });

    test('pathT includes closeUndershoot additive term', () {
      expect(s.pathT, closeTo(-0.2, 0.001));
    });

    test('sizeT includes closeUndershoot additive term', () {
      expect(s.sizeT, closeTo(-0.2, 0.001));
    });

    test('containerScale clamps correctly for extreme undershoot', () {
      final extreme = _compute(-1.0);
      expect(extreme.containerScale, closeTo(0.45, 0.001));
    });
  });

  // ── Parallel close recoil & wide-trigger splash (iOS 27 parity) ───────────

  group('LiquidMorphPhysics — parallel close recoil & width splash', () {
    LiquidMorphState computeCloseAt(
      double seconds, {
      double rawValue = 0.25,
      double finalDx = 0.0,
      double finalDy = 125.0,
      bool hasHandedOff = false,
      bool isSettled = false,
      bool disableAnimations = false,
    }) =>
        LiquidMorphPhysics.compute(
          rawValue: rawValue,
          finalDx: finalDx,
          finalDy: finalDy,
          isClosing: true,
          elapsedSeconds: seconds,
          hasHandedOff: hasHandedOff,
          isSettled: isSettled,
          disableAnimations: disableAnimations,
          phaseStartTriggerWidth: 0.0,
          closeStartProgress: 1.0,
        );

    test('recoil starts immediately at t > 0 and peaks near ~180–185 ms', () {
      final at0 = computeCloseAt(0.0, rawValue: 1.0);
      final at67 = computeCloseAt(0.067, rawValue: 0.64);
      final at183 = computeCloseAt(0.183, rawValue: 0.09);
      final at350 = computeCloseAt(0.350, rawValue: -0.004, hasHandedOff: true);
      final at540 = computeCloseAt(0.540, rawValue: 0.0, isSettled: true);

      expect(at0.triggerPushDy, equals(0.0));
      expect(at67.triggerPushDy, lessThan(-2.0),
          reason: 'Recoil must already be active well before rawValue <= 0');
      expect(at183.triggerPushDy.abs(), greaterThan(at67.triggerPushDy.abs()));
      expect(at183.triggerPushDy.abs(), greaterThan(at350.triggerPushDy.abs()),
          reason: 'Peak recoil must happen at ~183 ms, not ~350–400 ms');
      expect(at183.triggerImpactScale, lessThan(0.98));
      expect(at540.triggerPushDy, equals(0.0));
      expect(at540.triggerImpactScale, equals(1.0));
    });

    test(
        'peak recoil is near-constant (~14–17.5 px) across menu sizes like native MM2 ty',
        () {
      final shortMenu = computeCloseAt(0.183, finalDy: 35.0);
      final mediumMenu = computeCloseAt(0.183, finalDy: 125.0);
      final tallMenu = computeCloseAt(0.183, finalDy: 220.0);
      final modalSheet = computeCloseAt(0.183, finalDy: 500.0);

      expect(shortMenu.triggerPushDy.abs(), inInclusiveRange(13.0, 15.5));
      expect(mediumMenu.triggerPushDy.abs(), inInclusiveRange(15.5, 17.5));
      expect(tallMenu.triggerPushDy.abs(), inInclusiveRange(16.5, 17.5));
      expect(modalSheet.triggerPushDy.abs(), inInclusiveRange(17.0, 17.5));
      // Never exceeds the traced native peak.
      expect(modalSheet.triggerPushDy.abs(), lessThanOrEqualTo(17.5));
    });

    test(
        'triggerWidthProgress expands 0 → 1, crosses 1 near ~320 ms, splashes +1.5..2.5% near ~400 ms',
        () {
      final at0 = computeCloseAt(0.0, rawValue: 1.0);
      final at183 = computeCloseAt(0.183, rawValue: 0.09);
      final at325 = computeCloseAt(0.325, rawValue: -0.004, hasHandedOff: true);
      final at400 = computeCloseAt(0.400, rawValue: -0.003, hasHandedOff: true);
      final settled = computeCloseAt(0.550, rawValue: 0.0, isSettled: true);

      expect(at0.triggerWidthProgress, closeTo(0.0, 1e-6));
      expect(at183.triggerWidthProgress, inInclusiveRange(0.70, 0.85));
      expect(at325.triggerWidthProgress, greaterThanOrEqualTo(1.0));
      expect(at400.triggerWidthProgress, inInclusiveRange(1.014, 1.025));
      expect(settled.triggerWidthProgress, equals(1.0));
    });

    test(
        'contentOpacity fades across close while platterOpacity stays 1.0 down to rawValue = 0.25',
        () {
      for (final raw in [1.0, 0.75, 0.5, 0.25, 0.10]) {
        final s = computeCloseAt(0.1, rawValue: raw);
        final expectedScale = 0.20 + 0.80 * raw;
        expect(s.platterScale, closeTo(expectedScale, 1e-6));
        expect(
          s.contentOpacity,
          closeTo((expectedScale - 0.20) / 0.80, 1e-6),
        );
        final expectedPlatterOpacity = (raw / 0.25).clamp(0.0, 1.0);
        expect(s.platterOpacity, closeTo(expectedPlatterOpacity, 1e-6));
        if (raw >= 0.25) {
          expect(s.platterOpacity, equals(1.0));
        } else {
          expect(s.platterOpacity, greaterThan(s.contentOpacity));
          expect(s.platterOpacity, lessThan(1.0));
        }
        expect(s.isPlatterActive, isTrue);
      }
      final handedOff =
          computeCloseAt(0.30, rawValue: -0.002, hasHandedOff: true);
      expect(handedOff.isPlatterActive, isFalse);
      expect(handedOff.platterOpacity, equals(0.0));
      expect(handedOff.contentOpacity, equals(0.0));
    });

    test('disableAnimations suppresses trigger recoil and splash', () {
      final s = computeCloseAt(0.183, disableAnimations: true);
      expect(s.triggerPushDx, equals(0.0));
      expect(s.triggerPushDy, equals(0.0));
      expect(s.triggerImpactScale, equals(1.0));
    });
  });

  // ── Open overshoot (rawValue > 1) ─────────────────────────────────────────

  group('LiquidMorphPhysics — open overshoot (rawValue > 1)', () {
    const overshoot = 1.05;
    late LiquidMorphState s;
    setUp(() => s = _compute(overshoot));

    test('containerScale slightly above 1.0 during open overshoot', () {
      expect(s.containerScale, greaterThan(1.0));
      expect(s.containerScale, closeTo(1.0 + (overshoot - 1.0) * 0.10, 0.001));
    });

    test('pushDx is 0 during open overshoot (positive rawValue)', () {
      expect(s.pushDx, equals(0.0));
    });

    test('pushDy is 0 during open overshoot', () {
      expect(s.pushDy, equals(0.0));
    });

    test('phase is settled for overshoot (rawValue >= 1)', () {
      expect(s.phase, equals(MorphPhase.settled));
    });
  });

  // ── Anchor scale ──────────────────────────────────────────────────────────

  group('LiquidMorphPhysics — anchorScale', () {
    test('is 1.0 at rawValue = 0.0 (trigger fully visible)', () {
      expect(_compute(0.0).anchorScale, equals(1.0));
    });

    test('is 0.5 at rawValue = 0.2 (halfway through 40% ease)', () {
      expect(_compute(0.2).anchorScale, closeTo(0.5, 0.001));
    });

    test('is 0.0 at rawValue = 0.4 (fully detached)', () {
      expect(_compute(0.4).anchorScale, closeTo(0.0, 0.001));
    });

    test('stays 0.0 for rawValue > 0.4', () {
      expect(_compute(0.6).anchorScale, equals(0.0));
      expect(_compute(1.0).anchorScale, equals(0.0));
    });

    test('grows back toward 1.0 as rawValue returns to 0 on close', () {
      final atClose = _compute(0.2);
      expect(atClose.anchorScale, closeTo(0.5, 0.001));
    });
  });

  // ── Blob B displacement ───────────────────────────────────────────────────

  group('LiquidMorphPhysics — Blob B displacement', () {
    test('currentDx = finalDx * pathT', () {
      final s = _compute(0.5);
      expect(s.currentDx, closeTo(_finalDx * s.pathT, 0.001));
    });

    test('currentDy = finalDy * pathT', () {
      final s = _compute(0.5);
      expect(s.currentDy, closeTo(_finalDy * s.pathT, 0.001));
    });

    test('finalDx = 0 → currentDx always 0 regardless of rawValue', () {
      for (final v in [0.0, 0.3, 0.7, 1.0]) {
        expect(
          _compute(v, finalDx: 0.0, finalDy: _finalDy).currentDx,
          equals(0.0),
          reason: 'rawValue=$v',
        );
      }
    });
  });

  // ── Blend (metaball merge intensity) ─────────────────────────────────────

  group('LiquidMorphPhysics — blend', () {
    test('blend is 0.0 at rest', () {
      expect(_compute(0.0).blend, equals(0.0));
    });

    test('blend is near-zero when fully settled (pathT ≈ sizeT ≈ 1.0)', () {
      expect(_compute(1.0).blend, lessThan(2.0));
    });

    test('blend is non-zero during mid-travel (separation between curves)', () {
      final s = _compute(0.5);
      expect(s.blend, greaterThan(0.0));
    });

    test('blend is clamped to a maximum of 28.0', () {
      for (int i = 0; i <= 100; i++) {
        final raw = i / 100.0;
        expect(
          _compute(raw).blend,
          lessThanOrEqualTo(28.0),
          reason: 'rawValue=$raw exceeded max blend',
        );
      }
    });

    test('blend is always non-negative (open path)', () {
      for (final v in [-0.3, 0.0, 0.25, 0.5, 0.75, 1.0, 1.1]) {
        expect(
          _compute(v).blend,
          greaterThanOrEqualTo(0.0),
          reason: 'rawValue=$v produced negative blend (open path)',
        );
      }
    });
  });

  // ── Spring constants (public contract — calibrated iOS 27) ───────────────

  group('LiquidMorphPhysics — spring constants', () {
    test('openSpring matches iOS 27 open profile (ω0 = 17, ζ ≈ 0.76)', () {
      expect(LiquidMorphPhysics.openSpring.stiffness, equals(289.0));
      expect(LiquidMorphPhysics.openSpring.damping, equals(25.8));
    });

    test('closeSpring matches iOS 27 dismissal profile (ω0 = 18, ζ ≈ 0.86)',
        () {
      expect(LiquidMorphPhysics.closeSpring.stiffness, equals(324.0));
      expect(LiquidMorphPhysics.closeSpring.damping, equals(31.0));
    });

    test('closeVelocityHint is 0.0 (smooth native launch)', () {
      expect(LiquidMorphPhysics.closeVelocityHint, equals(0.0));
    });
  });

  // ── Geometry scaling & helpers ────────────────────────────────────────────

  group('LiquidMorphPhysics — geometry scaling', () {
    test('doubling finalDx doubles currentDx at same rawValue', () {
      const v = 0.6;
      final s1 = _compute(v, finalDx: 100.0, finalDy: 0.0);
      final s2 = _compute(v, finalDx: 200.0, finalDy: 0.0);
      expect(s2.currentDx, closeTo(s1.currentDx * 2.0, 0.01));
    });

    test('doubling finalDy doubles currentDy at same rawValue', () {
      const v = 0.6;
      final s1 = _compute(v, finalDx: 0.0, finalDy: 100.0);
      final s2 = _compute(v, finalDx: 0.0, finalDy: 200.0);
      expect(s2.currentDy, closeTo(s1.currentDy * 2.0, 0.01));
    });

    test('horizontalOffset only affects pushDx (not currentDx)', () {
      const v = -0.1;
      final s1 = _compute(
        v,
        finalDx: 100.0,
        finalDy: 0.0,
        horizontalOffset: 0.0,
      );
      final s2 = _compute(
        v,
        finalDx: 100.0,
        finalDy: 0.0,
        horizontalOffset: 20.0,
      );
      expect(s1.currentDx, closeTo(s2.currentDx, 0.001));
      expect(s2.pushDx, isNot(closeTo(s1.pushDx, 0.001)));
    });
  });

  group('LiquidMorphPhysics.computeCornerRadius', () {
    test(
        'interpolates monotonically without ever exceeding max(triggerRadius, targetRadius)',
        () {
      double prev = 0.0;
      for (int i = 0; i <= 100; i++) {
        final t = i / 100.0;
        final w = lerpDouble(44.0, 220.0, t)!;
        final h = lerpDouble(44.0, 482.0, t)!;
        final r = LiquidMorphPhysics.computeCornerRadius(
          currentSize: Size(w, h),
          triggerRadius: 22.0,
          targetRadius: 32.0,
          progress: t,
        );
        expect(r, greaterThanOrEqualTo(prev - 1e-9));
        expect(r, lessThanOrEqualTo(32.0));
        prev = r;
      }
      expect(prev, closeTo(32.0, 1e-6));
    });

    test('clamps to shortestSide / 2 for sub-trigger / point-bloom droplets',
        () {
      final r = LiquidMorphPhysics.computeCornerRadius(
        currentSize: const Size(12.0, 16.0),
        triggerRadius: 22.0,
        targetRadius: 32.0,
        progress: 0.1,
      );
      expect(r, equals(6.0));
    });
  });

  // ── Monotonicity / smoothness smoke-test ──────────────────────────────────

  group('LiquidMorphPhysics — animation smoothness', () {
    test('sizeT increases monotonically from 0 to 1 during open', () {
      double prev = -1.0;
      for (int i = 0; i <= 100; i++) {
        final raw = i / 100.0;
        final cur = _compute(raw).sizeT;
        expect(cur, greaterThanOrEqualTo(prev),
            reason: 'sizeT not monotonic at rawValue=$raw');
        prev = cur;
      }
    });

    test('anchorScale decreases monotonically from 1.0 to 0.0 over [0, 0.4]',
        () {
      double prev = 1.1;
      for (int i = 0; i <= 40; i++) {
        final raw = i / 100.0;
        final cur = _compute(raw).anchorScale;
        expect(cur, lessThanOrEqualTo(prev),
            reason:
                'anchorScale not monotonically decreasing at rawValue=$raw');
        prev = cur;
      }
    });

    test('containerScale is exactly 1.0 throughout normal travel [0, 1]', () {
      for (int i = 0; i <= 100; i++) {
        final raw = i / 100.0;
        expect(
          _compute(raw).containerScale,
          equals(1.0),
          reason: 'containerScale ≠ 1.0 at rawValue=$raw',
        );
      }
    });
  });

  // ── Adaptive-mode helpers ──────────────────────────────────────────────────

  group('LiquidMorphPhysics.computeScaleDelta', () {
    test('returns 1.0 for identical square sizes', () {
      expect(
        LiquidMorphPhysics.computeScaleDelta(
          sourceSize: const Size(48, 48),
          targetSize: const Size(48, 48),
        ),
        closeTo(1.0, 1e-9),
      );
    });

    test('returns correct ratio for compose-button → full-sheet', () {
      final delta = LiquidMorphPhysics.computeScaleDelta(
        sourceSize: const Size(48, 48),
        targetSize: const Size(393, 852),
      );
      expect(delta, greaterThan(10.0));
      expect(delta, lessThan(15.0));
    });

    test('returns 1.0 for zero-area source (morphFromZero guard)', () {
      expect(
        LiquidMorphPhysics.computeScaleDelta(
          sourceSize: const Size(0, 0),
          targetSize: const Size(200, 300),
        ),
        equals(1.0),
      );
    });
  });

  group('LiquidMorphPhysics.computeAdaptiveBackOutAmplitude', () {
    test('returns 2.5 when Euclidean travel <= 100 px', () {
      expect(
        LiquidMorphPhysics.computeAdaptiveBackOutAmplitude(
          finalDx: 60.0,
          finalDy: 80.0,
        ),
        closeTo(2.5, 1e-9),
      );
    });

    test('attenuates when horizontal travel pushes hypot > 100 px', () {
      final amp = LiquidMorphPhysics.computeAdaptiveBackOutAmplitude(
        finalDx: 150.0,
        finalDy: 35.0,
      );
      expect(amp, lessThan(2.5));
      expect(amp, greaterThanOrEqualTo(0.7));
    });

    test('is attenuated for large vertical travel (|finalDy| = 388 px)', () {
      final amp = LiquidMorphPhysics.computeAdaptiveBackOutAmplitude(
        finalDy: -388.0,
      );
      expect(amp, closeTo(0.7, 1e-6));
    });

    test('never falls below the minimum amplitude (0.7)', () {
      final amp = LiquidMorphPhysics.computeAdaptiveBackOutAmplitude(
        finalDy: -10000.0,
      );
      expect(amp, greaterThanOrEqualTo(0.7));
    });

    test('never exceeds the base amplitude (2.5)', () {
      final amp = LiquidMorphPhysics.computeAdaptiveBackOutAmplitude(
        finalDy: -10.0,
      );
      expect(amp, lessThanOrEqualTo(2.5));
    });
  });

  group('LiquidMorphPhysics.computeBlendAttenuation', () {
    test('returns 1.0 for scaleDelta <= 3.0 (full blend)', () {
      expect(LiquidMorphPhysics.computeBlendAttenuation(1.0), equals(1.0));
      expect(LiquidMorphPhysics.computeBlendAttenuation(3.0), equals(1.0));
    });

    test('is attenuated for scaleDelta > 3.0', () {
      final att = LiquidMorphPhysics.computeBlendAttenuation(12.0);
      expect(att, closeTo(3.0 / 12.0, 1e-9));
      expect(att, lessThan(1.0));
    });

    test('never falls below 0.2', () {
      final att = LiquidMorphPhysics.computeBlendAttenuation(1000.0);
      expect(att, greaterThanOrEqualTo(0.2));
    });
  });

  group('LiquidMorphPhysics — adaptive mode (scaleDelta = 12.0)', () {
    const scaleDelta = 12.0;
    const finalDy = -388.0;
    const finalDx = 0.0;

    LiquidMorphState computeAdaptive(double rawValue) =>
        LiquidMorphPhysics.compute(
          rawValue: rawValue,
          finalDx: finalDx,
          finalDy: finalDy,
          scaleDelta: scaleDelta,
        );

    test('sizeT stays compact (< 0.40) through first 35% of open', () {
      for (int i = 0; i <= 35; i++) {
        final raw = i / 100.0;
        final s = computeAdaptive(raw);
        expect(s.sizeT, lessThan(0.40));
      }
    });

    test('sizeT reaches exactly 1.0 at rawValue = 1.0', () {
      expect(computeAdaptive(1.0).sizeT, closeTo(1.0, 1e-9));
    });

    test('sizeT is 0.0 at rawValue = 0.0', () {
      expect(computeAdaptive(0.0).sizeT, equals(0.0));
    });

    test('sizeT is monotonically increasing on [0, 1]', () {
      double prev = -1.0;
      for (int i = 0; i <= 100; i++) {
        final raw = i / 100.0;
        final cur = computeAdaptive(raw).sizeT;
        expect(cur, greaterThanOrEqualTo(prev));
        prev = cur;
      }
    });

    test('close undershoot pushDy magnitude is bounded (< 20 px)', () {
      final s = LiquidMorphPhysics.compute(
        rawValue: -0.15,
        finalDx: finalDx,
        finalDy: finalDy,
        scaleDelta: scaleDelta,
      );
      expect(s.pushDy.abs(), lessThan(20.0));
    });

    test('close undershoot pushDy is still non-zero (bounce is visible)', () {
      final s = LiquidMorphPhysics.compute(
        rawValue: -0.15,
        finalDx: finalDx,
        finalDy: finalDy,
        scaleDelta: scaleDelta,
      );
      expect(s.pushDy.abs(), greaterThan(0.0));
    });

    test('blend is attenuated for large-scale morph', () {
      final s = computeAdaptive(0.5);
      final fullBlend = LiquidMorphPhysics.compute(
        rawValue: 0.5,
        finalDx: finalDx,
        finalDy: finalDy,
        scaleDelta: 1.0,
      ).blend;
      expect(s.blend, lessThanOrEqualTo(fullBlend));
    });
  });

  // ── Closing trajectory (isClosing = true) ──────────────────────────────────

  group('LiquidMorphPhysics — closing trajectory (isClosing = true)', () {
    test(
        'pathT never exceeds 1.0 on close (no reverse launch in wrong direction)',
        () {
      for (int i = 0; i <= 100; i++) {
        final raw = i / 100.0;
        final s = LiquidMorphPhysics.compute(
          rawValue: raw,
          finalDx: _finalDx,
          finalDy: _finalDy,
          isClosing: true,
        );
        expect(s.pathT, lessThanOrEqualTo(1.0));
      }
    });

    test('sizeT stays coupled with pathT on close (no early flatline)', () {
      final atQuarter = LiquidMorphPhysics.compute(
        rawValue: 0.25,
        finalDx: _finalDx,
        finalDy: _finalDy,
        isClosing: true,
      );
      // Previously 1 - linearToEaseOut(0.75) collapsed sizeT to ~0.016 at 0.25,
      // stalling the platter 145 ms before landing. Now coupled (> 0.15).
      expect(atQuarter.sizeT, greaterThan(0.15));
    });

    test('pathT and sizeT increase monotonically with rawValue on [0, 1]', () {
      double prevPath = -0.1;
      double prevSize = -0.1;
      for (int i = 0; i <= 100; i++) {
        final raw = i / 100.0;
        final s = LiquidMorphPhysics.compute(
          rawValue: raw,
          finalDx: _finalDx,
          finalDy: _finalDy,
          isClosing: true,
        );
        expect(s.pathT, greaterThanOrEqualTo(prevPath));
        expect(s.sizeT, greaterThanOrEqualTo(prevSize));
        prevPath = s.pathT;
        prevSize = s.sizeT;
      }
    });

    test('pathT and sizeT include closeUndershoot when rawValue < 0.0', () {
      const undershoot = -0.15;
      final s = LiquidMorphPhysics.compute(
        rawValue: undershoot,
        finalDx: _finalDx,
        finalDy: _finalDy,
        isClosing: true,
      );
      expect(s.pathT, closeTo(undershoot, 1e-9));
      expect(s.sizeT, closeTo(undershoot, 1e-9));
    });
  });

  // ── Closing blend bell-curve (separation-driven) ──────────────────────────

  group('LiquidMorphPhysics — closing blend separation curve', () {
    LiquidMorphState closeCompute(double raw) => LiquidMorphPhysics.compute(
          rawValue: raw,
          finalDx: _finalDx,
          finalDy: _finalDy,
          isClosing: true,
        );

    test('blend is 0.0 at start of close (clampedValue = 1.0)', () {
      expect(closeCompute(1.0).blend, equals(0.0));
    });

    test('blend peaks in mid-close and returns to 0.0 at handoff (0.0)', () {
      final blendAtMid = closeCompute(0.45).blend;
      final blendAtEnd = closeCompute(0.0).blend;
      expect(blendAtMid, greaterThan(10.0),
          reason: 'Expected visible SDF bridge in mid-close');
      expect(blendAtEnd, equals(0.0),
          reason: 'Expected zero SDF inflation at handoff (clampedValue = 0)');
    });

    test('anchorScale on close ramps 0.0 → 1.0 over 0.40 → 0.0', () {
      expect(closeCompute(0.80).anchorScale, equals(0.0));
      expect(closeCompute(0.40).anchorScale, closeTo(0.0, 1e-6));
      expect(closeCompute(0.20).anchorScale, closeTo(0.5, 1e-6));
      expect(closeCompute(0.0).anchorScale, equals(1.0));
    });

    test('blend is always clamped to [0, 28] on entire close trajectory', () {
      for (int i = 0; i <= 100; i++) {
        final raw = i / 100.0;
        final b = closeCompute(raw).blend;
        expect(b, greaterThanOrEqualTo(0.0));
        expect(b, lessThanOrEqualTo(28.0));
      }
    });

    test('blend is non-negative during close undershoot (rawValue < 0)', () {
      for (final v in [-0.05, -0.1, -0.15, -0.2]) {
        expect(closeCompute(v).blend, greaterThanOrEqualTo(0.0));
      }
    });
  });

  // ── Close shape & content (native iOS 27 fit) ─────────────────────────────

  group('LiquidMorphPhysics — close corner radius (computeCloseCornerRadius)',
      () {
    const resting = Size(250, 251);
    const menuRadius = 32.0;

    double radiusAt(double s) {
      // blob size follows the platter scale (menu * (0.2 + 0.8 s))
      final k = 0.2 + 0.8 * s;
      return LiquidMorphPhysics.computeCloseCornerRadius(
        currentSize: Size(resting.width * k, resting.height * k),
        restingSize: resting,
        targetRadius: menuRadius,
        sizeProgress: s,
      );
    }

    test('equals the resting menu radius at sizeProgress = 1', () {
      expect(radiusAt(1.0), closeTo(menuRadius, 1e-6));
    });

    test('is a perfect circle (half the short side) at sizeProgress = 0', () {
      expect(radiusAt(0.0), closeTo(resting.width * 0.2 / 2, 1e-6));
    });

    test('roundness (r / halfShort) rises monotonically as the blob shrinks',
        () {
      double prevRoundness = 0.0;
      for (var s = 1.0; s >= 0.0; s -= 0.05) {
        final k = 0.2 + 0.8 * s;
        final half = resting.width * k / 2;
        final roundness = radiusAt(s) / half;
        expect(roundness, greaterThanOrEqualTo(prevRoundness - 1e-9));
        expect(roundness, lessThanOrEqualTo(1.0 + 1e-9));
        prevRoundness = roundness;
      }
    });

    test('matches the native silhouette: roundness ~0.8+ at half width', () {
      // Native 60 fps silhouettes: r / (min(w,h)/2) ≈ 0.77–0.89 once the
      // platter is ~45 % of its width (rawValue ≈ 0.3 → sizeProgress ≈ 0.3).
      const s = 0.45;
      final k = 0.2 + 0.8 * s;
      final roundness = radiusAt(s) / (resting.width * k / 2);
      expect(roundness, inInclusiveRange(0.70, 0.95));
    });
  });

  group('LiquidMorphPhysics — open bubble, content reveal & drift', () {
    const resting = Size(250, 251);

    double rnd(double t, {Size cur = const Size(250, 251)}) =>
        LiquidMorphPhysics.computeOpenCornerRadius(
          currentSize: cur,
          restingSize: resting,
          targetRadius: 32.0,
          elapsedSeconds: t,
        ) /
        (math.min(cur.width, cur.height) / 2);

    test('stays a near-circle until ~140 ms then relaxes to the menu radius',
        () {
      expect(rnd(0.05), closeTo(1.0, 1e-9));
      expect(rnd(0.14), closeTo(1.0, 1e-9));
      // native roundness: 0.86 @150, 0.62 @200, 0.37 @250, rho0 @285
      expect(rnd(0.17), inInclusiveRange(0.80, 0.98));
      expect(rnd(0.22), inInclusiveRange(0.50, 0.78));
      expect(rnd(0.27), inInclusiveRange(0.30, 0.50));
      expect(rnd(0.40), closeTo(32.0 / 125.0, 1e-9));
    });

    test('roundness is monotonically non-increasing', () {
      var prev = 2.0;
      for (var t = 0.0; t <= 0.5; t += 0.01) {
        final r = rnd(t);
        expect(r, lessThanOrEqualTo(prev + 1e-12));
        prev = r;
      }
    });

    test('rows appear late and resolve from a blur, like native', () {
      expect(LiquidMorphPhysics.computeOpenContentOpacity(elapsedSeconds: 0.1),
          equals(0.0));
      expect(LiquidMorphPhysics.computeOpenContentOpacity(elapsedSeconds: 0.2),
          inInclusiveRange(0.5, 0.95));
      expect(LiquidMorphPhysics.computeOpenContentOpacity(elapsedSeconds: 0.3),
          equals(1.0));
      expect(LiquidMorphPhysics.computeOpenContentBlur(elapsedSeconds: 0.05),
          equals(8.0));
      expect(LiquidMorphPhysics.computeOpenContentBlur(elapsedSeconds: 0.3),
          closeTo(0.0, 1e-9));
    });

    test(
        'open drift fits the traced MM1 ty: ~peak at ~110 ms, zero when settled',
        () {
      double d(double t) =>
          LiquidMorphPhysics.computeOpenDrift(elapsedSeconds: t);
      expect(d(0.0), inInclusiveRange(0.0, 8.0));
      var peak = 0.0;
      var peakT = 0.0;
      for (var t = 0.0; t <= 0.4; t += 0.005) {
        if (d(t) > peak) {
          peak = d(t);
          peakT = t;
        }
      }
      expect(peak, inInclusiveRange(50.0, 57.0));
      expect(peakT, inInclusiveRange(0.08, 0.14));
      // Exactly zero well before the open controller settles (~420 ms).
      expect(d(0.40), equals(0.0));
      expect(d(0.60), equals(0.0));
    });

    test('menu open size curve is faster than the shared smootherstep start',
        () {
      // spring values at 33/67/100/133/167 ms -> native size progress
      final spring = [0.12, 0.36, 0.59, 0.77, 0.90];
      final native = [0.37, 0.58, 0.77, 0.90, 0.99];
      for (var i = 0; i < spring.length; i++) {
        final v = LiquidMorphPhysics.computeMenuOpenSizeProgress(spring[i]);
        expect((v - native[i]).abs(), lessThan(0.10),
            reason: 'spring ${spring[i]} -> $v vs native ${native[i]}');
      }
      expect(LiquidMorphPhysics.computeMenuOpenSizeProgress(0.0), equals(0.0));
      expect(LiquidMorphPhysics.computeMenuOpenSizeProgress(1.0), equals(1.0));
      // The shared compute() keeps the compact smootherstep start that
      // popovers/sheets rely on for close<->open continuity.
      final shared = LiquidMorphPhysics.compute(
        rawValue: 0.35,
        finalDx: 0,
        finalDy: 400,
        scaleDelta: 12.0,
      );
      expect(shared.sizeT, lessThan(0.40));
    });

    test('open drift is single-peaked (no shake) with native-like frame steps',
        () {
      // Native MM1 ty moves ~10 px per 60 fps frame at its steepest.
      var prev = LiquidMorphPhysics.computeOpenDrift(elapsedSeconds: 0.0);
      var rising = true;
      // up to ~0.28 s: beyond it only the sub-2px traced undershoot remains
      for (var t = 1 / 60; t <= 0.28; t += 1 / 60) {
        final cur = LiquidMorphPhysics.computeOpenDrift(elapsedSeconds: t);
        expect((cur - prev).abs(), lessThan(14.0));
        if (cur < prev - 1e-9) rising = false;
        // once it starts falling it must never rise again (no double bounce)
        if (!rising) expect(cur, lessThanOrEqualTo(prev + 1e-9));
        prev = cur;
      }
    });
  });

  group('LiquidMorphPhysics — closing platter pivot geometry', () {
    // Native `_UIContextMenuView` trace (pill trigger, 5-item menu): resting
    // platter (32, 228.3, 250x195.3), trigger centre (93, 245.5).
    const resting = Rect.fromLTWH(32.0, 228.3, 250.0, 195.3);
    const pivot = Offset(93.0, 245.5);

    test('reproduces the traced CM rect at 0.709 / 0.529 / 0.301 scale', () {
      final cases = <double, Rect>{
        0.709: const Rect.fromLTWH(49.8, 233.3, 177.2, 138.5),
        0.529: const Rect.fromLTWH(60.7, 236.4, 132.3, 103.4),
        0.301: const Rect.fromLTWH(74.6, 240.3, 75.3, 58.8),
      };
      cases.forEach((scale, traced) {
        final r = LiquidMorphPhysics.computeClosingPlatterRect(
          pivot: pivot,
          restingRect: resting,
          platterScale: scale,
        );
        expect(r.left, closeTo(traced.left, 0.2));
        expect(r.top, closeTo(traced.top, 0.2));
        expect(r.width, closeTo(traced.width, 0.2));
        expect(r.height, closeTo(traced.height, 0.2));
      });
    });

    test('is the resting rect at scale 1 and keeps the pivot fixed', () {
      final full = LiquidMorphPhysics.computeClosingPlatterRect(
        pivot: pivot,
        restingRect: resting,
        platterScale: 1.0,
      );
      expect(full, equals(resting));
      for (final s in [0.2, 0.5, 0.9]) {
        final r = LiquidMorphPhysics.computeClosingPlatterRect(
          pivot: pivot,
          restingRect: resting,
          platterScale: s,
        );
        // pivot keeps its fractional position inside the scaled rect
        expect((pivot.dx - r.left) / r.width,
            closeTo((pivot.dx - resting.left) / resting.width, 1e-9));
        expect((pivot.dy - r.top) / r.height,
            closeTo((pivot.dy - resting.top) / resting.height, 1e-9));
      }
    });

    test('maxHeight clamps only the height', () {
      final r = LiquidMorphPhysics.computeClosingPlatterRect(
        pivot: pivot,
        restingRect: resting,
        platterScale: 0.6,
        maxHeight: 60.0,
      );
      expect(r.height, equals(60.0));
      expect(r.width, closeTo(resting.width * 0.6, 1e-9));
    });

    test('height envelope: ~trigger core at rest, ~109pt near rawValue 0.2',
        () {
      expect(
        LiquidMorphPhysics.computeCloseHeightEnvelope(
            coreHeight: 44.0, rawValue: 0.0),
        closeTo(44.0, 1e-9),
      );
      // Native: both 5- and 10-item menus are ≈109 pt tall at ~150 ms
      // (rawValue ≈ 0.2).
      expect(
        LiquidMorphPhysics.computeCloseHeightEnvelope(
            coreHeight: 44.0, rawValue: 0.2),
        inInclusiveRange(95.0, 125.0),
      );
      // Monotonic in rawValue.
      var prev = 0.0;
      for (var u = 0.0; u <= 1.0; u += 0.1) {
        final e = LiquidMorphPhysics.computeCloseHeightEnvelope(
            coreHeight: 44.0, rawValue: u);
        expect(e, greaterThanOrEqualTo(prev));
        prev = e;
      }
    });
  });

  group('LiquidMorphPhysics — close content opacity & blur', () {
    test('rows are fully visible at rawValue = 1 with no blur', () {
      expect(
        LiquidMorphPhysics.computeCloseContentOpacity(rawValue: 1.0),
        closeTo(1.0, 1e-9),
      );
      expect(
        LiquidMorphPhysics.computeCloseContentBlur(rawValue: 1.0),
        closeTo(0.0, 1e-9),
      );
    });

    test('is linear in platter scale (native op) and reaches 0 at rawValue = 0',
        () {
      expect(
        LiquidMorphPhysics.computeCloseContentOpacity(rawValue: 0.636),
        closeTo(0.636, 1e-9),
      );
      expect(
        LiquidMorphPhysics.computeCloseContentOpacity(rawValue: 0.0),
        equals(0.0),
      );
    });

    test('blur ramps quickly then caps at 8px', () {
      final b95 = LiquidMorphPhysics.computeCloseContentBlur(rawValue: 0.95);
      final b50 = LiquidMorphPhysics.computeCloseContentBlur(rawValue: 0.5);
      expect(b95, closeTo(1.4, 1e-9));
      expect(b50, equals(8.0));
    });

    test('closeStartProgress keeps a partial-open close continuous', () {
      // Closing from 60 % open: the first frame (rawValue == 0.6) must still
      // show fully opaque, un-blurred rows rather than popping.
      expect(
        LiquidMorphPhysics.computeCloseContentOpacity(
          rawValue: 0.6,
          closeStartProgress: 0.6,
        ),
        closeTo(1.0, 1e-9),
      );
      expect(
        LiquidMorphPhysics.computeCloseContentBlur(
          rawValue: 0.6,
          closeStartProgress: 0.6,
        ),
        closeTo(0.0, 1e-9),
      );
    });

    test('compute() exposes contentBlurSigma only while closing', () {
      final open = _compute(0.6);
      expect(open.contentBlurSigma, equals(0.0));
      final closing = LiquidMorphPhysics.compute(
        rawValue: 0.7,
        finalDx: 0,
        finalDy: 100,
        isClosing: true,
        elapsedSeconds: 0.08,
      );
      expect(closing.contentBlurSigma, greaterThan(0.0));
      expect(closing.contentOpacity, closeTo(0.7, 1e-9));
    });
  });
}
