// ignore_for_file: comment_references

import 'dart:math' as math;

import 'package:flutter/animation.dart';

/// Semantic phase of the liquid glass morph lifecycle.
///
/// Consuming widgets can use this to react to *where* in the animation
/// lifecycle the morph currently is — without re-deriving it from raw
/// animation values.
///
/// State machine (open direction):
/// ```
/// idle → detaching → travelling → arriving → settled
/// ```
/// State machine (close direction, spring bounces back):
/// ```
/// settled → arriving → travelling → detaching → [bounce] → idle
/// ```
enum MorphPhase {
  /// The morph has not started or has fully settled at its origin.
  idle,

  /// The anchor blob is shrinking and Blob B is just beginning to pull away.
  /// In practice this covers animation values `0.0 – 0.4`.
  detaching,

  /// Blob B is in mid-travel — the teardrop neck is at maximum stretch.
  /// Animation values `0.4 – 0.8`.
  travelling,

  /// Blob B is approaching its destination and the neck is retracting.
  /// Animation values [0.8 – 1.0).
  arriving,

  /// Blob B has fully settled at its target position.
  /// Animation value ≥ 1.0.
  settled,
}

/// The fully computed render state for one frame of a liquid morph animation.
///
/// All values are pre-calculated and ready to be applied directly to widget
/// geometry. Consumers must not re-derive values from the raw animation value.
class LiquidMorphState {
  /// Creates a new [LiquidMorphState].
  const LiquidMorphState({
    required this.pathT,
    required this.sizeT,
    required this.currentDx,
    required this.currentDy,
    required this.pushDx,
    required this.pushDy,
    required this.anchorScale,
    required this.blend,
    required this.containerScale,
    required this.phase,
    this.triggerPushDx = 0.0,
    this.triggerPushDy = 0.0,
    this.triggerImpactScale = 1.0,
    this.triggerWidthProgress = 1.0,
    this.platterScale = 0.0,
    this.platterOpacity = 0.0,
    this.contentOpacity = 0.0,
    this.contentBlurSigma = 0.0,
    this.isPlatterActive = false,
  });

  /// Position interpolation value — drives the J-curve overshoot on open and
  /// coupled contraction on close.
  final double pathT;

  /// Size interpolation value — drives the teardrop size expansion and coupled
  /// close contraction.
  final double sizeT;

  /// Absolute horizontal displacement of the platter body (Blob B) from the
  /// trigger center, in logical pixels.
  final double currentDx;

  /// Absolute vertical displacement of the platter body (Blob B) from the
  /// trigger center, in logical pixels.
  final double currentDy;

  /// Horizontal recoil displacement applied to the anchor/trigger on close.
  ///
  /// When driven via [GlassMorphController], mirrors [triggerPushDx] (parallel
  /// recoil starting at `t = 0 ms` of close, peaking at `~183 ms`).
  final double pushDx;

  /// Vertical recoil displacement applied to the anchor/trigger on close.
  ///
  /// When driven via [GlassMorphController], mirrors [triggerPushDy] (parallel
  /// recoil starting at `t = 0 ms` of close, peaking at `~183 ms`).
  final double pushDy;

  /// Parallel horizontal recoil displacement for the trigger button on close,
  /// in logical pixels.
  ///
  /// Starts immediately when `close()` begins (`t = 0 ms`), peaks around
  /// `~183 ms` (matching iOS 27 `_kickView` / `MagicMorphView` #2), crosses
  /// zero around `~483 ms`, and settles smoothly by `~530–550 ms`. Bounded via
  /// a smooth soft-saturation curve so every menu/popover/sheet travel produces
  /// a constant `~16–17 px` physical catch (see `_maxRecoilPx`).
  final double triggerPushDx;

  /// Parallel vertical recoil displacement for the trigger button on close,
  /// in logical pixels.
  ///
  /// Starts immediately when `close()` begins (`t = 0 ms`), peaks around
  /// `~183 ms`, and settles smoothly by `~530–550 ms`.
  final double triggerPushDy;

  /// Tactile impact compression scale (`~0.96–1.0`) applied to the trigger in
  /// parallel with [triggerPushDx] / [triggerPushDy] during close.
  ///
  /// `1.0` at rest and throughout open; compresses smoothly toward `~0.965` at
  /// peak catch (`~183 ms`) and rebounds to `1.0` as the trigger settles.
  final double triggerImpactScale;

  /// Centered horizontal width progress for wide/pill triggers (`tw > th`),
  /// matching native iOS 27 `MagicMorphView` #2:
  ///
  /// - `1.0` at rest (full `triggerWidth`).
  /// - Contracts `1.0 → 0.0` (`tw → min(tw, th)` centered on `trigger.center`)
  ///   on open (`ω₀ ≈ 25 rad/s, ζ ≈ 0.94`).
  /// - `0.0` while settled open (compact circle at `trigger.center`).
  /// - Re-expands `0.0 → 1.0` (`min(tw, th) → tw` centered on `trigger.center`)
  ///   on close (`ω₀ ≈ 13 rad/s, ζ ≈ 0.795`), crossing `1.0` around `~320 ms`,
  ///   overshooting `+1.6%` (`~1.016`) horizontal splash around `~400 ms`, and
  ///   settling to `1.0` by `~530–550 ms`.
  final double triggerWidthProgress;

  /// Uniform platter scale factor (`1.0 → 0.20` on close around
  /// `trigger.center`, matching iOS 27 `_UIContextMenuView`; `sizeT` on open).
  final double platterScale;

  /// Glass material visibility factor (`[0.0 – 1.0]`) for the morphing platter
  /// (Blob B).
  ///
  /// - `0.0` when idle at rest or after the closing platter vanishes (`~280 ms`).
  /// - `1.0` during open and when settled open.
  /// - On close: stays `1.0` (dense, fully refractive liquid glass) down to
  ///   `rawValue = 0.25` (`0..~165 ms`) while menu rows fade via
  ///   [contentOpacity], and dissolves smoothly `(rawValue / 0.25).clamp(0.0, 1.0)`
  ///   only over the final SDF merge window `rawValue ∈ [0.0, 0.25]`
  ///   (`~165..283 ms`).
  ///
  /// **Important:** Apply this through `GlassMaterializeScope(glassProgress:)`
  /// or shader visibility — never wrap `AdaptiveLiquidGlassLayer` in a
  /// fractional `Opacity` widget, which pushes an offscreen `saveLayer` and
  /// breaks Impeller `BackdropFilter` backdrop sampling.
  final double platterOpacity;

  /// Opacity (`[0.0 – 1.0]`) for the platter's inner items / content.
  ///
  /// - On open: ramps `0.0 → 1.0` across `sizeT ∈ [0.15, 1.0]`.
  /// - On close: `((platterScale - 0.20) / 0.80)`, matching the traced iOS 27
  ///   `_UIContextMenuView` opacity (see
  ///   [LiquidMorphPhysics.computeCloseContentOpacity]). Combined with
  ///   [contentBlurSigma] so a soft ghost of the rows remains inside the
  ///   collapsing platter instead of an empty frosted blob.
  final double contentOpacity;

  /// Gaussian blur sigma (logical px) for the platter's inner items while it
  /// collapses on close (`0.0` at rest and throughout open).
  ///
  /// Native iOS 27 softens the rows immediately on dismissal; see
  /// [LiquidMorphPhysics.computeCloseContentBlur].
  final double contentBlurSigma;

  /// Whether the morphing platter (Blob B) is currently active and should be
  /// painted in the overlay.
  ///
  /// Turns `false` around `~280 ms` into a close once the platter vanishes at
  /// `platterScale <= 0.20`, while `GlassMorphController.isShowing` remains
  /// `true` until `~550 ms` so the trigger completes its recoil and horizontal
  /// width splash.
  final bool isPlatterActive;

  /// Scale factor for the anchor (ghost trigger) blob in `[0.0 – 1.0]`.
  ///
  /// Shrinks to `0.0` over the first 40 % of the opening animation so the
  /// liquid bridge detaches cleanly. Grows back during closing so the trigger
  /// blob catches the returning platter.
  final double anchorScale;

  /// Metaball merge intensity in SDF blur units, clamped to `[0.0 – 28.0]`.
  ///
  /// Derived from the separation between [pathT] and [sizeT]: zero when the
  /// blobs perfectly overlap, and maximum when the teardrop bridge is at peak
  /// stretch. Attenuated proportionally for large-scale morphs.
  final double blend;

  /// Scale pulse applied to the platter container (Blob B) during spring
  /// overshoot phases.
  final double containerScale;

  /// Semantic lifecycle phase of the morph for this frame.
  final MorphPhase phase;
}

/// Pure, stateless math engine for iOS 27 liquid glass morphing animations.
///
/// Calibrated directly against 60 fps `CADisplayLink` `CALayer.presentation()`
/// traces of native iOS 27 SwiftUI `Menu`, `.popover`, and `.sheet` morphs
/// (`_UIMorphAnimationContainerView`, `MagicMorphView`, `_UIContextMenuView`).
class LiquidMorphPhysics {
  // Pure utility class — no instances.
  const LiquidMorphPhysics._();

  // ─── Calibrated iOS 27 Spring Constants ────────────────────────────────────
  //
  // Open platter morph (MagicMorphView #1 / _UIReparentingView):
  //   ω₀ = 17.0 rad/s, ζ ≈ 0.76  →  stiffness = 289.0, damping = 25.8
  //
  // Close platter contraction (_UIContextMenuView):
  //   ω₀ = 18.0 rad/s, ζ ≈ 0.86  →  stiffness = 324.0, damping = 31.0

  /// Spring profile for the iOS 27 liquid morph **opening** animation
  /// (`ω₀ = 17.0 rad/s`, `ζ ≈ 0.76`, `response ≈ 0.37 s`).
  static const SpringDescription openSpring = SpringDescription(
    mass: 1.0,
    stiffness: 289.0,
    damping: 25.8,
  );

  /// Spring profile for the iOS 27 liquid morph **closing** platter animation
  /// (`ω₀ = 18.0 rad/s`, `ζ ≈ 0.86`, `response ≈ 0.35 s`).
  static const SpringDescription closeSpring = SpringDescription(
    mass: 1.0,
    stiffness: 324.0,
    damping: 31.0,
  );

  /// Initial velocity hint injected when the close animation starts.
  ///
  /// Native iOS 27 `_UIContextMenuView` dismissal (`ω₀ = 18.0 rad/s, ζ = 0.86`)
  /// launches smoothly from `0.0` velocity while the trigger's parallel
  /// `_kickView` recoil spring peaks at `~183 ms`.
  static const double closeVelocityHint = 0.0;

  // ─── Secondary Parallel Spring Constants (iOS 27 MagicMorphView #2) ────────

  /// Open wide-trigger contraction (`tw → min(tw, th)` around `trigger.center`):
  /// `ω₀ = 25.0 rad/s, ζ = 0.94` (`response = 0.25 s`).
  static const double _openTriggerWidthOmega0 = 25.0;
  static const double _openTriggerWidthZeta = 0.94;

  /// Close wide-trigger re-expansion (`min(tw, th) → tw` around `trigger.center`):
  /// `ω₀ = 13.0 rad/s, ζ = 0.795` (`response = 0.48 s`, `+1.6%` splash at `~400 ms`).
  static const double _closeTriggerWidthOmega0 = 13.0;
  static const double _closeTriggerWidthZeta = 0.795;

  /// Parallel close recoil coupled springs (`_kickView`):
  /// `S(t; ω=17.0, ζ=0.70) - S(t; ω=18.0, ζ=1.0)` peaks at `t ≈ 180–183 ms`
  /// with raw amplitude `0.139711`, crossing zero at `~483 ms`.
  static const double _recoilUnderOmega0 = 17.0;
  static const double _recoilUnderZeta = 0.70;
  static const double _recoilCritOmega0 = 18.0;
  static const double _recoilRawPeak = 0.139711;

  /// Asymptotic ceiling (logical px) and half-saturation travel distance (px)
  /// for the parallel close trigger recoil:
  /// `peakPush = _maxRecoilPx * D / (D + recoilHalfTravelPx)`.
  ///
  /// Native iOS 27's `GlassMenu` trigger kick (`MagicMorphView` #2, `ty`)
  /// peaks at `-17.5 pt` and is **independent of menu height**: the same `MM2`
  /// curve explains 60 fps silhouettes of both a 5- and a 10-item menu, so
  /// [menuRecoilHalfTravelPx] is tiny (`8 px`): `~16.3 px` at `D = 104`,
  /// `~16.9 px` at `D = 219`. Popovers and sheets keep the original
  /// proportional calibration ([defaultRecoilHalfTravelPx], `75 px`) because
  /// their native kick has not been measured.
  static const double _maxRecoilPx = 17.5;

  /// Half-saturation travel for menus (near-constant native kick).
  static const double menuRecoilHalfTravelPx = 8.0;

  /// Half-saturation travel for popovers, sheets and custom morphs
  /// (proportional kick, the original calibration).
  static const double defaultRecoilHalfTravelPx = 75.0;

  /// Half-saturation travel (px) of the tactile impact compression depth
  /// (unchanged from the original proportional calibration).
  static const double _impactHalfTravelPx = 75.0;

  // ─── Tuning constants (intentionally not public) ───────────────────────────

  /// Amplitude of the J-curve back-out overshoot for position interpolation.
  static const double _backOutAmplitude = 2.5;

  /// The minimum adaptive back-out amplitude.
  static const double _minBackOutAmplitude = 0.7;

  /// Euclidean travel threshold below which full [_backOutAmplitude] applies.
  static const double _adaptiveThresholdTravel = 100.0;

  /// Fraction of the animation over which the anchor blob shrinks to zero.
  static const double _anchorEaseDuration = 0.4;

  /// Multiplier from path/size separation to SDF blur units.
  static const double _blendMultiplier = 150.0;

  /// Maximum SDF blend value to prevent excessive merging on small movements.
  static const double _maxBlend = 28.0;

  /// Peak SDF blend value on close so the teardrop neck stays slender and
  /// concave without bloating the trigger/tail waist.
  static const double _closeMaxBlend = 22.0;

  /// Maximum travel distance (logical pixels) for stateless legacy `rawValue < 0` push.
  static const double _maxPushTravelPx = 80.0;

  /// Exponent of the close-roundness curve fitted to native iOS 27 silhouettes
  /// (see [computeCloseCornerRadius]).
  static const double _closeRoundnessExponent = 2.2;

  /// Maximum blur sigma (logical px) of the menu rows during close.
  static const double _closeContentBlurMaxSigma = 8.0;

  /// Height gained above the trigger core per `rawValue^1.1` by the closing
  /// glass blob (see [computeCloseHeightEnvelope]).
  static const double _closeHeightEnvelopePx = 400.0;

  /// Seconds between `open()` and the first visible growth in native
  /// recordings, subtracted from the elapsed time of the open-phase curves
  /// ([computeOpenCornerRadius], [computeOpenContentOpacity],
  /// [computeOpenContentBlur]).
  static const double _openOnsetLagSeconds = 0.02;

  /// Open roundness stays at `1.0` for this long, then relaxes over
  /// [_openRoundnessRelaxSeconds] (see [computeOpenCornerRadius]).
  static const double _openRoundnessHoldSeconds = 0.14;
  static const double _openRoundnessRelaxSeconds = 0.145;

  /// Peak of `S(τ; 20, 1) · (1 − S(τ; 24, 1))` (`≈ 0.2047`), used to normalise
  /// [computeCloseDrift].
  static const double _closeDriftUnitPeak = 0.2047;

  /// Peak close drift (px) for menus up to 250 pt tall / 521 pt tall.
  static const double _closeDriftPeakPx = 49.0;
  static const double _closeDriftPeakTallPx = 62.0;

  /// Peak of `S(τ; 24, 0.6) − S(τ; 20, 0.9)` (`≈ 0.2865`), used to normalise
  /// [computeOpenDrift] to a unit pulse.
  static const double _openDriftUnitPeak = 0.2865;

  /// Peak vertical drift (px) of the opening platter (see [computeOpenDrift]).
  /// Native silhouette centres lead the size-synchronous centre by
  /// `36 / 46 / 51 / 34 / 24 pt` at `33 / 67 / 100 / 133 / 167 ms`.
  static const double _openDriftPeakPx = 56.0;

  /// Peak drift for 5-item (~250 pt) and 2-item (~104 pt) menus
  /// (see [computeOpenDrift]).
  static const double _openDriftPeakMediumPx = 66.0;
  static const double _openDriftPeakCompactPx = 12.0;

  // ─── Public helpers ────────────────────────────────────────────────────────

  /// Computes the geometric scale ratio from [sourceSize] to [targetSize]:
  /// `Δ_scale = √(targetArea / sourceArea)`.
  ///
  /// Returns `1.0` when [sourceSize] is zero-area (zero-sized triggers).
  static double computeScaleDelta({
    required Size sourceSize,
    required Size targetSize,
  }) {
    final sourceArea = sourceSize.width * sourceSize.height;
    final targetArea = targetSize.width * targetSize.height;
    if (sourceArea <= 0.0) return 1.0;
    return math.sqrt(targetArea / sourceArea);
  }

  /// Computes the adaptive J-curve back-out amplitude for a given Euclidean
  /// travel distance `hypot(finalDx, finalDy)`.
  ///
  /// For travel `<= 100 px`, returns [baseAmplitude] (`2.5`) unchanged. For
  /// larger travel distances, reduces inversely so physical overshoot stays
  /// within a tight native envelope on both horizontal and vertical axes,
  /// floored at [_minBackOutAmplitude] (`0.7`).
  static double computeAdaptiveBackOutAmplitude({
    required double finalDy,
    double finalDx = 0.0,
    double baseAmplitude = _backOutAmplitude,
  }) {
    final travel = math.sqrt(finalDx * finalDx + finalDy * finalDy);
    if (travel <= _adaptiveThresholdTravel) return baseAmplitude;
    return (baseAmplitude * _adaptiveThresholdTravel / travel)
        .clamp(_minBackOutAmplitude, baseAmplitude);
  }

  /// Computes a monotonic corner radius for a morphing glass surface of
  /// [currentSize], interpolating smoothly from [triggerRadius] (`progress = 0`)
  /// to [targetRadius] (`progress = 1`).
  ///
  /// Clamped by `min(currentSize.width, currentSize.height) / 2` so small
  /// droplets remain true circles/pills, and guaranteed **never** to balloon
  /// above `max(triggerRadius, targetRadius)` mid-flight.
  static double computeCornerRadius({
    required Size currentSize,
    required double triggerRadius,
    required double targetRadius,
    required double progress,
  }) {
    final shortestHalf =
        math.max(0.0, math.min(currentSize.width, currentSize.height) / 2.0);
    final t = progress.clamp(0.0, 1.0);
    final interpolated = triggerRadius + (targetRadius - triggerRadius) * t;
    final upperBound = math.max(triggerRadius, targetRadius);
    return math.min(shortestHalf, interpolated.clamp(0.0, upperBound));
  }

  /// Computes the corner radius of the closing platter (Blob B) while it
  /// collapses back into its trigger.
  ///
  /// Native iOS 27 does **not** keep the menu's corner radius while the
  /// platter shrinks: measured on 60 fps silhouettes the roundness
  /// `r / (min(w, h) / 2)` climbs from `ρ₀ ≈ 0.29` (resting menu) to `≈ 0.85`
  /// by the time the platter is ~45 % of its width, i.e. the blob is a
  /// near-circle for most of the collapse. Holding the resting radius makes
  /// the shrinking platter read as a rounded square.
  ///
  /// This follows `ρ(s) = 1 − (1 − ρ₀) · s^[_closeRoundnessExponent]` where
  /// `s` is [sizeProgress] (`1` = resting menu, `0` = trigger core) and
  /// `ρ₀ = targetRadius / (min(restingSize) / 2)`. It is `targetRadius`
  /// exactly at `s = 1` and a perfect circle/pill at `s = 0`.
  static double computeCloseCornerRadius({
    required Size currentSize,
    required Size restingSize,
    required double targetRadius,
    required double sizeProgress,
  }) {
    final shortestHalf =
        math.max(0.0, math.min(currentSize.width, currentSize.height) / 2.0);
    final restingHalf =
        math.max(1e-3, math.min(restingSize.width, restingSize.height) / 2.0);
    final rho0 = (targetRadius / restingHalf).clamp(0.0, 1.0);
    final s = sizeProgress.clamp(0.0, 1.0);
    final roundness = 1.0 - (1.0 - rho0) * math.pow(s, _closeRoundnessExponent);
    return shortestHalf * roundness.clamp(0.0, 1.0);
  }

  /// Computes the menu-row opacity while the platter collapses on close.
  ///
  /// Native iOS 27 fades the whole `_UIContextMenuView` exactly linearly in
  /// platter scale: `op = (scale − 0.2) / 0.8` (traced `0.872 @ 67 ms`,
  /// `0.636 @ 100 ms`, `0.319 @ 150 ms`, `0.126 @ 200 ms`). Crisp text still
  /// vanishes within `~35 ms` because the rows are blurred at the same time
  /// (see [computeCloseContentBlur]).
  ///
  /// Normalised by [closeStartProgress] so a close that interrupts a
  /// partially-open menu keeps the rows continuous.
  static double computeCloseContentOpacity({
    required double rawValue,
    double closeStartProgress = 1.0,
  }) {
    final c = closeStartProgress.clamp(0.05, 1.0);
    return (rawValue / c).clamp(0.0, 1.0);
  }

  /// Gaussian blur sigma (logical px) applied to the menu rows while the
  /// platter collapses on close.
  ///
  /// Native rows go soft almost immediately (crisp bright glyph pixels fall
  /// `0.61 → 0.06` in one frame). `σ = 28 · (1 − u)` capped at
  /// [_closeContentBlurMaxSigma] reproduces that without a visual pop at
  /// `u = 1`.
  static double computeCloseContentBlur({
    required double rawValue,
    double closeStartProgress = 1.0,
  }) {
    final c = closeStartProgress.clamp(0.05, 1.0);
    final u = (rawValue / c).clamp(0.0, 1.0);
    return (28.0 * (1.0 - u)).clamp(0.0, _closeContentBlurMaxSigma);
  }

  /// Computes the rect of the closing platter (Blob B) as native iOS 27 does:
  /// a **uniform scale** of the resting menu rect by [platterScale]
  /// (`0.2 + 0.8·rawValue`) about the *trigger centre* [pivot], where the pivot
  /// keeps its fractional position inside [restingRect].
  ///
  /// Verified against the `_UIContextMenuView` trace to `0.1 pt`: its
  /// `anchorPoint` is exactly the trigger centre expressed in platter-local
  /// fractions (`0.244, 0.088` for the traced menu), and
  /// `rect = pivot − anchor · size · scale`. Because the pivot sits near the
  /// platter's top for top-anchored menus, the top edge sweeps toward the
  /// trigger centre while the platter shrinks, instead of staying glued to
  /// the trigger top.
  static Rect computeClosingPlatterRect({
    required Offset pivot,
    required Rect restingRect,
    required double platterScale,
    double? maxHeight,
  }) {
    final s = platterScale.clamp(0.0, 1.0);
    final fx = restingRect.width > 0.0
        ? (pivot.dx - restingRect.left) / restingRect.width
        : 0.5;
    final fy = restingRect.height > 0.0
        ? (pivot.dy - restingRect.top) / restingRect.height
        : 0.5;
    final w = restingRect.width * s;
    final h = math.min(restingRect.height * s, maxHeight ?? double.infinity);
    return Rect.fromLTWH(pivot.dx - fx * w, pivot.dy - fy * h, w, h);
  }

  /// Absolute height envelope (logical px) of the closing glass blob:
  /// `coreHeight + 400 · u^1.1` with `u = rawValue`, plus any excess
  /// [restingHeight] above `coreHeight + 400` decaying rapidly as `u^2.5`.
  ///
  /// Native glass collapses faster in height than the uniform platter scale
  /// for tall menus and converges to the *same absolute height regardless of
  /// the menu size* (`≈109 pt @ 150 ms` for both a 5- and a 10-item menu in
  /// 60 fps silhouettes), so a tall menu retracts as a droplet of fixed length
  /// instead of hanging as a tall pill — without snapping height at `u = 1.0`
  /// when `restingHeight > 444 pt`. Short menus (`H · scale` below the
  /// envelope) are unaffected. Pass the result as
  /// [computeClosingPlatterRect]'s `maxHeight`.
  static double computeCloseHeightEnvelope({
    required double coreHeight,
    required double rawValue,
    double restingHeight = 0.0,
  }) {
    final u = rawValue.clamp(0.0, 1.0);
    final baseEnvelope =
        coreHeight + _closeHeightEnvelopePx * math.pow(u, 1.1).toDouble();
    final extraAboveEnvelope =
        math.max(0.0, restingHeight - (coreHeight + _closeHeightEnvelopePx));
    return baseEnvelope + extraAboveEnvelope * math.pow(u, 2.5).toDouble();
  }

  /// Computes the corner radius of the **opening** platter from the time since
  /// the open began.
  ///
  /// Native iOS 27 inflates the menu as a near-circular bubble and only
  /// relaxes it into the squircle once the size is essentially done: measured
  /// silhouette roundness `r / (min(w, h) / 2)` is `≈ 0.99` until
  /// `~140 ms`, then falls `0.86 @ 150 → 0.62 @ 200 → 0.37 @ 250 → ρ₀ @ 285 ms`.
  /// Holding the resting radius during growth reads as a rounded square.
  ///
  /// `ρ(t) = ρ₀ + (1 − ρ₀)·(1 − (t − 0.14) / 0.145)^1.3` for `t > 0.14 s`
  /// (clamped), with `ρ₀ = targetRadius / (min(restingSize) / 2)`. [elapsedSeconds]
  /// is the speed-scaled phase time (`GlassMorphController.phaseElapsedSeconds`),
  /// shifted forward proportionally by [openStartProgress] on mid-close reopens.
  static double computeOpenCornerRadius({
    required Size currentSize,
    required Size restingSize,
    required double targetRadius,
    required double elapsedSeconds,
    double openStartProgress = 0.0,
  }) {
    final shortestHalf =
        math.max(0.0, math.min(currentSize.width, currentSize.height) / 2.0);
    final restingHalf =
        math.max(1e-3, math.min(restingSize.width, restingSize.height) / 2.0);
    final rho0 = (targetRadius / restingHalf).clamp(0.0, 1.0);
    // Taller menus leave the bubble shape sooner: native roundness at 133 ms is
    // ~1.0 for a 251 pt menu but 0.62 for a 521 pt one. Interpolate the hold
    // (0.14 → 0.07 s) and relax (0.145 → 0.18 s) windows between those two
    // measured heights (flat outside [250, 520]).
    final heightF = ((restingSize.height - 250.0) / 270.0).clamp(0.0, 1.0);
    final hold = _openRoundnessHoldSeconds * (1.0 - 0.5 * heightF);
    final relax = _openRoundnessRelaxSeconds * (1.0 + 0.24 * heightF);
    final reopenAdvance = openStartProgress.clamp(0.0, 1.0) * (hold + relax);
    final t = elapsedSeconds + reopenAdvance - _openOnsetLagSeconds;
    final k = ((t - hold) / relax).clamp(0.0, 1.0);
    final roundness = rho0 + (1.0 - rho0) * math.pow(1.0 - k, 1.3);
    return shortestHalf * roundness.clamp(0.0, 1.0);
  }

  /// Menu-row opacity while the platter **opens**, driven by phase time.
  ///
  /// Native shows the rows only after the bubble is almost full size: crisp
  /// glyph pixels are `≈ 0.04 @ 183 ms`, `0.48 @ 200 ms`, `0.81 @ 217 ms`.
  /// Smoothstep over `t ∈ [0.12, 0.22] s` (after [_openOnsetLagSeconds]),
  /// advanced proportionally by [openStartProgress] on mid-close reopens.
  static double computeOpenContentOpacity({
    required double elapsedSeconds,
    double openStartProgress = 0.0,
  }) {
    final t = elapsedSeconds +
        openStartProgress.clamp(0.0, 1.0) * 0.22 -
        _openOnsetLagSeconds;
    return _smoothstep01((t - 0.12) / 0.10);
  }

  /// Gaussian blur sigma (logical px) of the menu rows while the platter
  /// **opens**: soft until `~130 ms`, sharp by `~230 ms` (native text arrives
  /// smeared and resolves as the bubble relaxes), capped at
  /// [_closeContentBlurMaxSigma].
  static double computeOpenContentBlur({
    required double elapsedSeconds,
    double openStartProgress = 0.0,
  }) {
    final t = elapsedSeconds +
        openStartProgress.clamp(0.0, 1.0) * 0.23 -
        _openOnsetLagSeconds;
    return _closeContentBlurMaxSigma * (1.0 - _smoothstep01((t - 0.13) / 0.10));
  }

  /// Vertical open drift (logical px, signed by nothing — callers multiply by
  /// the travel direction) of the opening platter past its resting position.
  ///
  /// Native iOS 27's visible glass is dragged by the background `CASDFLayer`
  /// neck container (`MM1` `TransformView`), whose traced `ty` rises to
  /// `+46.9 pt` and springs back with a small `−2 pt` undershoot. A
  /// closed-form two-spring fit to the 60 fps trace (`0.8 px` RMS) is
  /// `A · [S(τ; ω = 24, ζ = 0.6) − S(τ; ω = 20, ζ = 0.9)]`, peaking `~110 ms`
  /// after onset. Starting strictly at `0.0` (`elapsedSeconds == 0`) and
  /// scaling down for compact (`< 250 pt`) menus (`~13.7 pt` native peak on a
  /// 2-item `104 pt` menu) and partial mid-close reopens ([openStartProgress])
  /// keeps open trajectories C¹ smooth and proportional across all heights.
  static double computeOpenDrift({
    required double elapsedSeconds,
    double menuHeight = 520.0,
    double openStartProgress = 0.0,
  }) {
    if (elapsedSeconds <= 0.0) return 0.0;
    final diff = _stepResponse(elapsedSeconds, 24.0, 0.6) -
        _stepResponse(elapsedSeconds, 20.0, 0.9);
    // The traced tail undershoots by ~2 pt and decays over ~700 ms, but the
    // open controller settles at ~420 ms. Fade the pulse to exactly zero by
    // 0.40 s so a settled menu never rests off its true position.
    final fade = 1.0 - _smoothstep01((elapsedSeconds - 0.26) / 0.14);
    final double peak;
    if (menuHeight < 250.0) {
      // Compact menus (< 250 pt): native 2-item (104 pt) peaks at ~13.7 pt
      // rather than 66 pt; taper smoothly down to 0 below trigger height (48 pt).
      final tinyScale = ((menuHeight - 48.0) / 56.0).clamp(0.0, 1.0);
      final compactBase = _openDriftPeakCompactPx * tinyScale;
      final shortF = ((menuHeight - 104.0) / 146.0).clamp(0.0, 1.0);
      peak = compactBase + (_openDriftPeakMediumPx - compactBase) * shortF;
    } else {
      final heightF = ((menuHeight - 250.0) / 270.0).clamp(0.0, 1.0);
      peak = _openDriftPeakMediumPx +
          (_openDriftPeakPx - _openDriftPeakMediumPx) * heightF;
    }
    final remainingTravel = 1.0 - openStartProgress.clamp(0.0, 1.0);
    return peak * diff / _openDriftUnitPeak * fade * remainingTravel;
  }

  /// Open size progress of a large `GlassMenu` morph (`scaleDelta > 3`) as a
  /// function of the open spring's [rawValue] (`0 – 1`).
  ///
  /// Native grows the menu faster than the spring's ease-in: size progress is
  /// `0.37 / 0.58 / 0.77 / 0.90 / 0.99` at `33 / 67 / 100 / 133 / 167 ms`
  /// against spring values `0.12 / 0.36 / 0.59 / 0.77 / 0.90`. `raw^0.55`
  /// maps one onto the other (`0.30 / 0.57 / 0.75 / 0.87 / 0.94`). Only
  /// `GlassMenu` applies it; [compute]'s shared `sizeT` keeps the smootherstep
  /// that popovers and sheets rely on for close↔open continuity.
  static double computeMenuOpenSizeProgress(double rawValue) =>
      math.pow(rawValue.clamp(0.0, 1.0), 0.55).toDouble();

  /// Effective uniform glass scale for a closing menu platter (Blob B) of
  /// [menuWidth] returning into a trigger of shortest side [minTriggerSide].
  ///
  /// Matches `_UIContextMenuView`'s `0.20 + 0.80 · u` down to `u = 0.24`, then
  /// tapers the `0.20` floor smoothly down to `0.56 · minTriggerSide / menuWidth`
  /// (`~25 px` for a `44 px` trigger) so the retracting SDF droplet forms a
  /// slender tail narrower than the trigger instead of stalling at `50 px`.
  static double computeCloseGlassScale({
    required double rawValue,
    required double minTriggerSide,
    required double menuWidth,
  }) {
    final u = rawValue.clamp(0.0, 1.0);
    if (menuWidth <= 0.0) return (0.20 + 0.80 * u).clamp(0.08, 1.0);
    final tailScale = (0.56 * minTriggerSide / menuWidth).clamp(0.08, 0.20);
    final floor = tailScale + (0.20 - tailScale) * _smoothstep01(u / 0.24);
    return (floor + (1.0 - floor) * u).clamp(0.08, 1.0);
  }

  /// SDF smooth-union strength (blur units) between the closing platter and
  /// the trigger blob.
  ///
  /// Native retracts as **one continuous teardrop**: the platter tapers into a
  /// pointed neck that flows into the trigger. Ramps in over `rawValue ∈ [0.97, 0.77]`
  /// to [_closeMaxBlend] (`22.0`) and tapers smoothly over the final `0.16`
  /// as the slender tail is absorbed so smooth-union never bloats the waist.
  static double computeCloseBlend({required double rawValue}) {
    final u = rawValue.clamp(0.0, 1.0);
    final rampIn = _smoothstep01((0.97 - u) / 0.20);
    final rampOut = 1.0 - _smoothstep01((0.16 - u) / 0.16);
    return _closeMaxBlend * rampIn * rampOut;
  }

  /// Close-phase displacement (logical px, always `>= 0`; callers multiply by
  /// the travel direction) of the retracting platter *away from the trigger*.
  ///
  /// Native's visible glass (`MM1` neck container) is pushed ~`49 pt` away
  /// from the trigger within ~`75 ms` of the close starting, then springs back
  /// by ~`300 ms` (traced `MM1 ty`: `31.8 @ 67 ms, 48.6 @ 100, 36.6 @ 150,
  /// 17.7 @ 200, 6.7 @ 250`). That gap is what the metaball bridge stretches
  /// into the teardrop's narrow neck; without it the platter overlaps the
  /// trigger and reads as a round egg.
  ///
  /// Closed form fitted to the 60 fps trace (`0.35 px` RMS):
  /// `A · S(τ; ω = 20, ζ = 1) · (1 − S(τ; ω = 24, ζ = 1))`, peaking
  /// `≈ 49 px` at `250 pt` (`≈ 62 px` at `521 pt`), tapering smoothly toward
  /// `0` for compact (`< 250 pt`) menus so short 1–2 item platters never dip
  /// past their resting bottom, and scaled by [closeStartProgress] on partial
  /// mid-open cancellations.
  static double computeCloseDrift({
    required double elapsedSeconds,
    double menuHeight = 250.0,
    double closeStartProgress = 1.0,
  }) {
    if (elapsedSeconds <= 0.0 || closeStartProgress <= 0.001) return 0.0;
    final unit = _stepResponse(elapsedSeconds, 20.0, 1.0) *
        (1.0 - _stepResponse(elapsedSeconds, 24.0, 1.0));
    final double peak;
    if (menuHeight < 250.0) {
      final shortF = ((menuHeight - 95.0) / 155.0).clamp(0.0, 1.0);
      peak = _closeDriftPeakPx * shortF;
    } else {
      final heightF = ((menuHeight - 250.0) / 270.0).clamp(0.0, 1.0);
      peak = _closeDriftPeakPx +
          (_closeDriftPeakTallPx - _closeDriftPeakPx) * heightF;
    }
    return peak *
        unit /
        _closeDriftUnitPeak *
        closeStartProgress.clamp(0.0, 1.0);
  }

  /// Computes the gap-gated scale factor (`0.0`, or `0.45 → 1.0`) for the
  /// trigger's ghost blob (Blob A) during close so it stays hidden while the
  /// droplet pulls away and emerges inside the smooth-union bridge reach with
  /// zero detached-dot frames.
  static double computeCloseBlobAEmergence({
    required Rect platterRect,
    required double platterRadius,
    required Offset triggerCenter,
    required double rawValue,
  }) {
    final u = rawValue.clamp(0.0, 1.0);
    final r = math.min(
      platterRadius,
      math.min(platterRect.width, platterRect.height) * 0.5,
    );
    final inner = platterRect.deflate(r);
    final ddx = math.max(
      math.max(inner.left - triggerCenter.dx, triggerCenter.dx - inner.right),
      0.0,
    );
    final ddy = math.max(
      math.max(inner.top - triggerCenter.dy, triggerCenter.dy - inner.bottom),
      0.0,
    );
    final gap = math.max(0.0, math.sqrt(ddx * ddx + ddy * ddy) - r);
    final byTime = _smoothstep01((0.40 - u) / 0.12);
    final byGap = _smoothstep01((24.0 - gap) / 11.0);
    final emerge = math.min(byTime, byGap);
    return emerge <= 0.001 ? 0.0 : (0.45 + 0.55 * emerge);
  }

  /// Shared analytical close-phase geometry (`rect` and `borderRadius`) for
  /// trigger-anchored platters (`GlassMenu` and `GlassPopover`), combining
  /// uniform pivot scaling ([computeClosingPlatterRect]), slender tail taper
  /// ([computeCloseGlassScale]), tall-platter droplet height envelope
  /// ([computeCloseHeightEnvelope]), close neck drift ([computeCloseDrift]),
  /// diagonal-to-vertical tail convergence, and outer-edge non-overshoot.
  static ({Rect rect, double borderRadius}) computeClosingTeardropGeometry({
    required double rawValue,
    required double pathT,
    required Offset triggerCenter,
    required Size triggerSize,
    required Rect restingRect,
    required double targetRadius,
    required Offset effectivePush,
    required double elapsedSeconds,
    double closeStartProgress = 1.0,
    double alignX = 0.0,
    bool disableAnimations = false,
    bool morphFromZero = false,
  }) {
    final u = rawValue.clamp(0.0, 1.0);
    final tw = triggerSize.width;
    final th = triggerSize.height;
    final minTriggerSide = math.min(tw, th);
    final menuWidth = restingRect.width;
    final targetHeight = restingRect.height;

    final closeGlassScale = morphFromZero
        ? (0.20 + 0.80 * u).clamp(0.18, 1.0)
        : computeCloseGlassScale(
            rawValue: rawValue,
            minTriggerSide: minTriggerSide,
            menuWidth: menuWidth,
          );
    final baseCoreH = minTriggerSide;
    final taperedCoreH = baseCoreH * (0.65 + 0.35 * _smoothstep01(u / 0.24));
    final closeBase = computeClosingPlatterRect(
      pivot: triggerCenter,
      restingRect: restingRect,
      platterScale: closeGlassScale,
      maxHeight: computeCloseHeightEnvelope(
        coreHeight: taperedCoreH,
        rawValue: rawValue,
        restingHeight: targetHeight,
      ),
    );
    final baseWidth = closeBase.width.clamp(0.0, menuWidth);
    final baseHeight = closeBase.height.clamp(0.0, targetHeight);

    final tailScale = menuWidth > 0.0
        ? (0.56 * minTriggerSide / menuWidth).clamp(0.08, 0.20)
        : 0.20;
    final closeSizeProgress =
        ((closeGlassScale - tailScale) / (1.0 - tailScale)).clamp(0.0, 1.0);
    final baseRadius = computeCloseCornerRadius(
      currentSize: Size(baseWidth, baseHeight),
      restingSize: Size(menuWidth, targetHeight),
      targetRadius: targetRadius,
      sizeProgress: closeSizeProgress,
    );

    final posT = pathT.clamp(0.0, 1.0);
    final recoilCatch = effectivePush * (1.0 - posT);
    final closeDriftY = (!disableAnimations && !morphFromZero)
        ? (restingRect.center.dy - triggerCenter.dy).sign *
            computeCloseDrift(
              elapsedSeconds: elapsedSeconds,
              menuHeight: targetHeight,
              closeStartProgress: closeStartProgress,
            )
        : 0.0;
    final rawPivotCenter =
        closeBase.center + recoilCatch + Offset(0.0, closeDriftY);
    final convergeX = _smoothstep01((0.36 - u) / 0.28);
    final trigCenterX = triggerCenter.dx + effectivePush.dx;
    double closedCenterX =
        rawPivotCenter.dx + (trigCenterX - rawPivotCenter.dx) * convergeX;
    if (alignX < -0.1) {
      final triggerLeft = trigCenterX - tw * 0.5;
      closedCenterX = math.max(closedCenterX, triggerLeft + baseWidth * 0.5);
    } else if (alignX > 0.1) {
      final triggerRight = trigCenterX + tw * 0.5;
      closedCenterX = math.min(closedCenterX, triggerRight - baseWidth * 0.5);
    }

    return (
      rect: Rect.fromCenter(
        center: Offset(closedCenterX, rawPivotCenter.dy),
        width: baseWidth,
        height: baseHeight,
      ),
      borderRadius: baseRadius,
    );
  }

  static double _smoothstep01(double x) {
    final c = x.clamp(0.0, 1.0);
    return c * c * (3.0 - 2.0 * c);
  }

  /// Computes the SDF blend attenuation factor for a given scale ratio.
  static double computeBlendAttenuation(double scaleDelta) {
    if (scaleDelta <= 3.0) return 1.0;
    return (3.0 / scaleDelta).clamp(0.2, 1.0);
  }

  /// Computes the parallel close trigger recoil offset (logical px) at
  /// speed-scaled [elapsedSeconds] (`>= 0`) for a trigger-to-platter [travel]
  /// vector, using a near-constant `~17 px` peak at `~183 ms`.
  static Offset recoilOffsetForElapsed({
    required Offset travel,
    required double elapsedSeconds,
    double closeStartProgress = 1.0,
    double recoilHalfTravelPx = defaultRecoilHalfTravelPx,
    bool verticalOnlyRecoil = false,
  }) {
    if (elapsedSeconds <= 0.0 || closeStartProgress <= 0.001) {
      return Offset.zero;
    }
    final pulse =
        _recoilPulse(elapsedSeconds) * closeStartProgress.clamp(0.0, 1.0);
    final bool pureY = verticalOnlyRecoil && travel.dy.abs() > 1.0;
    final effDx = pureY ? 0.0 : travel.dx;
    final effDist = pureY ? travel.dy.abs() : travel.distance;
    final denom = effDist + recoilHalfTravelPx;
    return Offset(
      -(_maxRecoilPx * effDx / denom) * pulse,
      -(_maxRecoilPx * travel.dy / denom) * pulse,
    );
  }

  /// Computes the tactile trigger impact scale (`~0.96–1.0`) at speed-scaled
  /// [elapsedSeconds] (`>= 0`) during close.
  static double impactScaleForElapsed({
    required Offset travel,
    required double elapsedSeconds,
    double closeStartProgress = 1.0,
  }) {
    if (elapsedSeconds <= 0.0 || closeStartProgress <= 0.001) return 1.0;
    final pulse =
        _recoilPulse(elapsedSeconds) * closeStartProgress.clamp(0.0, 1.0);
    final travelMag = travel.distance;
    final impactDepth =
        0.025 + 0.015 * (travelMag / (travelMag + _impactHalfTravelPx));
    return (1.0 - impactDepth * pulse).clamp(0.92, 1.02);
  }

  /// Computes the wide-trigger centered width re-expansion progress
  /// (`0.0 → 1.0` with `+1.6%` horizontal splash at `~400 ms`) at speed-scaled
  /// [elapsedSeconds] (`>= 0`) during close.
  static double closeTriggerWidthForElapsed(
    double elapsedSeconds, {
    double startWidthProgress = 0.0,
  }) {
    final sWidth = _stepResponse(
      elapsedSeconds,
      _closeTriggerWidthOmega0,
      _closeTriggerWidthZeta,
    );
    final startW = startWidthProgress.clamp(0.0, 1.0);
    return startW + (1.0 - startW) * sWidth;
  }

  // ─── Core computation ──────────────────────────────────────────────────────

  /// Computes the full [LiquidMorphState] for a single animation frame.
  static LiquidMorphState compute({
    required double rawValue,
    required double finalDx,
    required double finalDy,
    double horizontalOffset = 0.0,
    double verticalOffset = 0.0,
    double scaleDelta = 1.0,
    bool? adaptiveDamping,
    bool isClosing = false,
    double? elapsedSeconds,
    bool hasHandedOff = false,
    bool isSettled = false,
    bool disableAnimations = false,
    double phaseStartTriggerWidth = 1.0,
    double closeStartProgress = 1.0,
    double recoilHalfTravelPx = defaultRecoilHalfTravelPx,
    bool verticalOnlyRecoil = false,
  }) {
    final clampedValue = rawValue.clamp(0.0, 1.0);

    // Preserve close undershoot additive term for direct/stateless callers.
    final closeUndershoot = rawValue < 0.0 ? rawValue : 0.0;

    // ── Adaptive mode detection ───────────────────────────────────────────────
    final bool adaptive = adaptiveDamping ?? (scaleDelta > 1.5);

    // ── Effective J-curve amplitude (Euclidean travel) ────────────────────────
    final double amplitude = adaptive
        ? computeAdaptiveBackOutAmplitude(
            finalDx: finalDx + horizontalOffset,
            finalDy: finalDy + verticalOffset,
          )
        : _backOutAmplitude;

    // ── J-Curve / Close Position ──────────────────────────────────────────────
    final double pathT;
    if (isClosing) {
      pathT = clampedValue + closeUndershoot;
    } else {
      pathT =
          _BackOutCurve(amplitude).transform(clampedValue) + closeUndershoot;
    }

    // ── Size ─────────────────────────────────────────────────────────────────
    // On close: tightly coupled quadratic curve (`u * (0.62 + 0.38 * u)`) that
    // stays in lockstep with `pathT` all the way to landing (~280 ms) without
    // early flatlining, while opening enough mid-flight |pathT - sizeT|
    // separation to drive the SDF metaball bridge.
    final double rawSizeT;
    if (isClosing) {
      rawSizeT = clampedValue * (0.62 + 0.38 * clampedValue);
    } else if (adaptive && scaleDelta > 3.0) {
      rawSizeT = _smootherStep(clampedValue);
    } else {
      rawSizeT = Curves.linearToEaseOut.transform(clampedValue);
    }
    final sizeT = rawSizeT + closeUndershoot;

    // ── Trigger Recoil & Push Momentum ────────────────────────────────────────
    final travelDx = finalDx + horizontalOffset;
    final travelDy = finalDy + verticalOffset;
    final travelMag = math.sqrt(travelDx * travelDx + travelDy * travelDy);

    double pushDx;
    double pushDy;
    double triggerPushDx;
    double triggerPushDy;
    double triggerImpactScale;

    if (elapsedSeconds != null) {
      if (isClosing &&
          !disableAnimations &&
          !isSettled &&
          closeStartProgress > 0.001) {
        final recoilPulse =
            _recoilPulse(elapsedSeconds) * closeStartProgress.clamp(0.0, 1.0);
        final bool pureY = verticalOnlyRecoil && travelDy.abs() > 1.0;
        final effDx = pureY ? 0.0 : travelDx;
        final effMag = pureY ? travelDy.abs() : travelMag;
        final denom = effMag + recoilHalfTravelPx;
        triggerPushDx = -(_maxRecoilPx * effDx / denom) * recoilPulse;
        triggerPushDy = -(_maxRecoilPx * travelDy / denom) * recoilPulse;
        pushDx = triggerPushDx;
        pushDy = triggerPushDy;

        final impactDepth =
            0.025 + 0.015 * (travelMag / (travelMag + _impactHalfTravelPx));
        triggerImpactScale =
            (1.0 - impactDepth * recoilPulse).clamp(0.92, 1.02);
      } else {
        pushDx = 0.0;
        pushDy = 0.0;
        triggerPushDx = 0.0;
        triggerPushDy = 0.0;
        triggerImpactScale = 1.0;
      }
    } else {
      // Stateless fallback when called without a controller elapsed clock.
      final double pushFactor;
      if (adaptive) {
        pushFactor = travelMag > 0.0
            ? (_maxPushTravelPx / travelMag).clamp(0.0, 1.0)
            : 1.0;
      } else {
        pushFactor = 1.0;
      }
      pushDx = rawValue < 0.0 ? travelDx * rawValue * pushFactor : 0.0;
      pushDy = rawValue < 0.0 ? travelDy * rawValue * pushFactor : 0.0;
      triggerPushDx = pushDx;
      triggerPushDy = pushDy;
      triggerImpactScale =
          rawValue < 0.0 ? (1.0 + rawValue * 0.35).clamp(0.88, 1.0) : 1.0;
    }

    // ── Wide-Trigger Centered Width Progress (MagicMorphView #2) ─────────────
    final double triggerWidthProgress;
    if (isClosing) {
      if (disableAnimations || isSettled) {
        triggerWidthProgress = isSettled ? 1.0 : (1.0 - clampedValue);
      } else if (elapsedSeconds != null) {
        final sWidth = _stepResponse(
          elapsedSeconds,
          _closeTriggerWidthOmega0,
          _closeTriggerWidthZeta,
        );
        final startW = phaseStartTriggerWidth.clamp(0.0, 1.0);
        triggerWidthProgress = startW + (1.0 - startW) * sWidth;
      } else {
        triggerWidthProgress = 1.0 - clampedValue - closeUndershoot;
      }
    } else {
      if (clampedValue <= 0.001 &&
          (elapsedSeconds == null || elapsedSeconds <= 0.0)) {
        triggerWidthProgress = 1.0;
      } else if (disableAnimations || isSettled) {
        triggerWidthProgress = clampedValue >= 0.999 ? 0.0 : 1.0 - clampedValue;
      } else if (elapsedSeconds != null) {
        final sWidth = _stepResponse(
          elapsedSeconds,
          _openTriggerWidthOmega0,
          _openTriggerWidthZeta,
        );
        final startW = phaseStartTriggerWidth.clamp(0.0, 1.0);
        triggerWidthProgress = (startW * (1.0 - sWidth)).clamp(0.0, 1.0);
      } else {
        triggerWidthProgress = (1.0 - (clampedValue / 0.55)).clamp(0.0, 1.0);
      }
    }

    // ── Platter Scale, Opacity, & Active Window (_UIContextMenuView) ─────────
    final double platterScale;
    final double platterOpacity;
    final double contentOpacity;
    double contentBlurSigma = 0.0;
    final bool isPlatterActive;

    if (isClosing) {
      platterScale = (0.20 + 0.80 * rawValue).clamp(0.18, 1.0);
      final bool active = !hasHandedOff && !isSettled && rawValue > 0.001;
      isPlatterActive = active;
      final fade = active
          ? computeCloseContentOpacity(
              rawValue: rawValue,
              closeStartProgress: closeStartProgress,
            )
          : 0.0;
      platterOpacity = active ? (rawValue / 0.25).clamp(0.0, 1.0) : 0.0;
      contentOpacity = fade;
      contentBlurSigma = active
          ? computeCloseContentBlur(
              rawValue: rawValue,
              closeStartProgress: closeStartProgress,
            )
          : 0.0;
    } else {
      platterScale = sizeT.clamp(0.0, 1.0);
      isPlatterActive = rawValue > 0.001;
      platterOpacity = isPlatterActive ? 1.0 : 0.0;
      contentOpacity = isPlatterActive
          ? ((platterScale - 0.15) / 0.85).clamp(0.0, 1.0)
          : 0.0;
    }

    // ── Blob B Displacement ───────────────────────────────────────────────────
    final currentDx = finalDx * pathT;
    final currentDy = finalDy * pathT;

    // ── Anchor Scale ─────────────────────────────────────────────────────────
    final anchorScale =
        (1.0 - (clampedValue / _anchorEaseDuration)).clamp(0.0, 1.0);

    // ── Metaball Blend ────────────────────────────────────────────────────────
    final blendAttenuation = computeBlendAttenuation(scaleDelta);
    final separation = (pathT - sizeT).abs();
    final blend = (separation * _blendMultiplier * blendAttenuation)
        .clamp(0.0, _maxBlend);

    // ── Container Scale Pulse ─────────────────────────────────────────────────
    final containerScale = rawValue > 1.0
        ? 1.0 + (rawValue - 1.0) * 0.10
        : rawValue < 0.0
            ? 1.0 + rawValue * 0.55
            : 1.0;

    // ── Phase ─────────────────────────────────────────────────────────────────
    final phase = _derivePhase(rawValue, clampedValue);

    return LiquidMorphState(
      pathT: pathT,
      sizeT: sizeT,
      currentDx: currentDx,
      currentDy: currentDy,
      pushDx: pushDx,
      pushDy: pushDy,
      anchorScale: anchorScale,
      blend: blend,
      containerScale: containerScale,
      phase: phase,
      triggerPushDx: triggerPushDx,
      triggerPushDy: triggerPushDy,
      triggerImpactScale: triggerImpactScale,
      triggerWidthProgress: triggerWidthProgress,
      platterScale: platterScale,
      platterOpacity: platterOpacity,
      contentOpacity: contentOpacity,
      contentBlurSigma: contentBlurSigma,
      isPlatterActive: isPlatterActive,
    );
  }

  static MorphPhase _derivePhase(double rawValue, double clampedValue) {
    if (rawValue < 0.0) return MorphPhase.detaching; // close bounce
    if (clampedValue < 0.001) return MorphPhase.idle;
    if (clampedValue < 0.4) return MorphPhase.detaching;
    if (clampedValue < 0.8) return MorphPhase.travelling;
    if (clampedValue < 0.999) return MorphPhase.arriving;
    return MorphPhase.settled;
  }

  /// Closed-form unit step response `0.0 → 1.0` with `v(0) = 0` for a damped
  /// harmonic oscillator of natural frequency [omega0] and damping [zeta].
  static double _stepResponse(double t, double omega0, double zeta) {
    if (t <= 0.0) return 0.0;
    if (zeta < 1.0 - 1e-6) {
      final r = zeta * omega0;
      final w = omega0 * math.sqrt(1.0 - zeta * zeta);
      const c1 = -1.0;
      final c2 = -r / w;
      return 1.0 +
          math.exp(-r * t) * (c1 * math.cos(w * t) + c2 * math.sin(w * t));
    }
    if (zeta > 1.0 + 1e-6) {
      final s = math.sqrt(zeta * zeta - 1.0);
      final r1 = -omega0 * (zeta - s);
      final r2 = -omega0 * (zeta + s);
      final c2 = r1 / (r2 - r1);
      final c1 = -1.0 - c2;
      return 1.0 + c1 * math.exp(r1 * t) + c2 * math.exp(r2 * t);
    }
    // Critically damped (ζ == 1.0):
    return 1.0 - (1.0 + omega0 * t) * math.exp(-omega0 * t);
  }

  /// Normalized parallel close recoil pulse (`0.0` at `t=0`, `1.0` peak at
  /// `t ≈ 180–183 ms`, `0.0` zero-crossing at `~483 ms`, settling by `~550 ms`).
  static double _recoilPulse(double t) {
    if (t <= 0.0) return 0.0;
    final sUnder = _stepResponse(t, _recoilUnderOmega0, _recoilUnderZeta);
    final sCrit = _stepResponse(t, _recoilCritOmega0, 1.0);
    return (sUnder - sCrit) / _recoilRawPeak;
  }

  /// Smootherstep sigmoid: `t^3 * (10 − 15t + 6t^2)`.
  static double _smootherStep(double t) {
    final tc = t.clamp(0.0, 1.0);
    return tc * tc * tc * (tc * (tc * 6.0 - 15.0) + 10.0);
  }
}

/// Back-out easing curve for the J-curve position overshoot.
class _BackOutCurve extends Curve {
  const _BackOutCurve(this.amplitude);
  final double amplitude;

  @override
  double transformInternal(double t) {
    return (t -= 1.0) * t * ((amplitude + 1.0) * t + amplitude) + 1.0;
  }
}
