import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';

import 'liquid_morph_physics.dart';

export 'liquid_morph_physics.dart' show LiquidMorphState, MorphPhase;

/// Controls the speed profile of a liquid glass morph animation.
///
/// Each case maps to calibrated open and close spring descriptions that
/// preserve the native iOS 27 damping ratios (`ζ ≈ 0.76` open, `ζ ≈ 0.86`
/// close platter, plus scaled parallel trigger recoil and width springs).
enum MorphSpeed {
  /// Slow, deliberate morph (`0.65×` frequency). Suitable for tutorials.
  slow,

  /// Default iOS 27 native-parity speed (`1.0×` frequency).
  normal,

  /// Fast, snappy morph (`1.35×` frequency) for high-frequency interactions.
  fast,

  /// Near-instant transition (`2.5×` frequency). Used for Reduce Motion or tests.
  instant,
}

/// Describes the visual shape style of the liquid glass morph transition.
enum MorphStyle {
  /// Classic iOS 26/27 liquid teardrop — Blob B pulls away from Blob A along a
  /// J-curve trajectory while the SDF metaball shader creates the bridging neck.
  teardrop,

  /// Radial bloom expansion originating from the trigger center outward.
  bloom,
}

/// A Flutter-idiomatic controller for iOS 27 liquid glass morph animations.
///
/// Encapsulates the calibrated open/close springs, elapsed phase clock for
/// parallel trigger recoil (`~183 ms` peak) and centered wide-trigger
/// contraction/splash (`MagicMorphView` #2), and [LiquidMorphState] computation.
class GlassMorphController extends ChangeNotifier {
  /// Creates a [GlassMorphController].
  GlassMorphController({
    required TickerProvider vsync,
    MorphSpeed speed = MorphSpeed.normal,
    this.style = MorphStyle.teardrop,
  })  : _speed = speed,
        _animationController = AnimationController.unbounded(vsync: vsync) {
    _animationController.addListener(_onTick);
    _animationController.addStatusListener(_onStatusChange);
  }

  // ─── Public parameters ────────────────────────────────────────────────────

  /// Speed profile for the morph animation.
  MorphSpeed get speed => _speed;
  set speed(MorphSpeed value) => setSpeed(value);
  MorphSpeed _speed;

  /// Updates the speed profile on a live controller (takes effect on the next
  /// [open] or [close] call).
  void setSpeed(MorphSpeed speed) {
    _speed = speed;
  }

  /// Visual shape style of the morph transition.
  final MorphStyle style;

  // ─── Internal state ───────────────────────────────────────────────────────

  final AnimationController _animationController;
  bool _isClosing = false;
  bool _hasHandedOff = false;
  bool _disableAnimations = false;

  /// Unscaled elapsed seconds in the active open/close simulation, captured
  /// from [AnimationController.lastElapsedDuration] on every tick.
  double _lastElapsedSeconds = 0.0;

  /// Trigger width progress (`[0, 1]`) captured at the start of the current
  /// open or close phase so mid-flight reversals remain continuous.
  double _phaseStartTriggerWidth = 1.0;

  /// Half-saturation travel (px) of the close trigger recoil, see
  /// [LiquidMorphPhysics.defaultRecoilHalfTravelPx] (proportional kick, the
  /// default) and [LiquidMorphPhysics.menuRecoilHalfTravelPx] (near-constant
  /// `~17 px` native menu kick, used by `GlassMenu`).
  double recoilHalfTravelPx = LiquidMorphPhysics.defaultRecoilHalfTravelPx;

  /// When `true`, restricts close trigger recoil strictly to the vertical axis
  /// (`triggerPushDx == 0.0` whenever vertical travel is non-zero), matching
  /// native iOS 27 `MagicMorphView` #2 (`tx = 0.0`) on side-aligned menus.
  bool verticalOnlyRecoil = false;

  /// Open progress (`[0, 1]`) at the instant [open] was invoked (`0.0` when
  /// opening from rest, `> 0.0` when reversing mid-close), used to attenuate
  /// open-phase drift and roundness holds on partial reopens.
  double _openStartProgress = 0.0;

  /// Open progress (`[0, 1]`) at the instant [close] was invoked, scaling
  /// trigger recoil and close drift proportionally when an incomplete open is
  /// reversed early.
  double _closeStartProgress = 0.0;

  // ─── Public accessors ─────────────────────────────────────────────────────

  /// The raw, unclamped spring simulation value.
  double get value => _animationController.value;

  /// Instantaneous velocity of the spring simulation.
  double get velocity => _animationController.velocity;

  /// Current [AnimationStatus] of the underlying controller.
  AnimationStatus get status => _animationController.status;

  /// The underlying [AnimationController].
  AnimationController get animation => _animationController;

  /// Frequency multiplier of the current [speed] relative to [MorphSpeed.normal].
  double get speedMultiplier {
    if (_disableAnimations) return 2.5;
    switch (_speed) {
      case MorphSpeed.slow:
        return 0.65;
      case MorphSpeed.normal:
        return 1.0;
      case MorphSpeed.fast:
        return 1.35;
      case MorphSpeed.instant:
        return 2.5;
    }
  }

  /// Elapsed time in seconds within the current open/close phase, scaled by
  /// [speedMultiplier] (`0.0` when [disableAnimations] is active).
  double get phaseElapsedSeconds =>
      _disableAnimations ? 0.0 : _lastElapsedSeconds * speedMultiplier;

  /// Trigger width progress (`0.0 – 1.0`) captured at the start of the current
  /// open/close phase. Used with
  /// [LiquidMorphPhysics.closeTriggerWidthForElapsed] to evaluate the close
  /// width spring at an offset time.
  double get phaseStartTriggerWidth => _phaseStartTriggerWidth;

  /// Animation progress (`0.0 – 1.0`) captured at the start of the current
  /// [open] phase (`0.0` when opening from rest).
  double get openStartProgress => _openStartProgress;

  /// Animation progress (`0.0 – 1.0`) captured at the start of the current
  /// [close] phase (`1.0` when closing from settled open).
  double get closeStartProgress => _closeStartProgress;

  /// Whether the morph lifecycle is currently active.
  ///
  /// `true` from [open] until the closing spring — including the parallel
  /// trigger recoil and horizontal width splash (~`530–550 ms`) — has fully
  /// settled back at rest. Use [LiquidMorphState.isPlatterActive] to know when
  /// the floating platter itself (Blob B) has vanished (~`280 ms` on close).
  bool get isShowing =>
      _animationController.value > 0.001 || (_isClosing && !_hasSettled);

  /// Whether the controller is in the closing phase.
  bool get isClosing => _isClosing;

  /// Whether the closing platter spring has reached/crossed `0.0` (~`280 ms` at
  /// [MorphSpeed.normal]), signaling that the floating platter has finished
  /// collapsing into the trigger.
  bool get hasHandedOff => _hasHandedOff;

  // ─── Accessibility ────────────────────────────────────────────────────────

  /// Updates the reduced-motion override.
  void setDisableAnimations(bool disableAnimations) {
    if (_disableAnimations == disableAnimations) return;
    _disableAnimations = disableAnimations;
  }

  /// Whether reduced-motion override is currently active.
  bool get disableAnimations => _disableAnimations;

  // ─── Control methods ──────────────────────────────────────────────────────

  /// Opens the morph animation from the current position.
  void open() {
    final bool inFlight =
        _animationController.value > 0.001 && !(_isClosing && _hasHandedOff);
    _openStartProgress =
        inFlight ? _animationController.value.clamp(0.0, 1.0) : 0.0;
    _phaseStartTriggerWidth = _currentTriggerWidthProgress().clamp(0.0, 1.0);
    _isClosing = false;
    _hasHandedOff = false;
    _lastElapsedSeconds = 0.0;
    _runSpring(
      1.0,
      velocityHint: 0.0,
      tolerance:
          _isInstantProfile ? _instantSettleTolerance : _openSettleTolerance,
    );
  }

  /// Closes the morph animation with the calibrated iOS 27 platter collapse,
  /// parallel `~183 ms` trigger recoil, and centered wide-trigger splash.
  void close() {
    _closeStartProgress = _animationController.value.clamp(0.0, 1.0);
    _phaseStartTriggerWidth = _currentTriggerWidthProgress().clamp(0.0, 1.0);
    _isClosing = true;
    _lastElapsedSeconds = 0.0;
    if (_animationController.value <= 0.0 && _closeStartProgress <= 0.001) {
      _hasHandedOff = true;
    }
    _runSpring(
      0.0,
      velocityHint: LiquidMorphPhysics.closeVelocityHint,
      tolerance:
          _isInstantProfile ? _instantSettleTolerance : _closeSettleTolerance,
    );
  }

  /// Immediately resets the controller to its resting closed state (`0.0`).
  void reset() {
    _animationController.stop();
    _isClosing = false;
    _hasHandedOff = false;
    _lastElapsedSeconds = 0.0;
    _phaseStartTriggerWidth = 1.0;
    _openStartProgress = 0.0;
    _closeStartProgress = 0.0;
    _animationController.value = 0.0;
    notifyListeners();
  }

  // ─── Static geometry helpers (convenience passthroughs) ───────────────────

  /// Computes the geometric scale ratio `√(targetArea / sourceArea)`.
  static double computeScaleDelta({
    required Size sourceSize,
    required Size targetSize,
  }) =>
      LiquidMorphPhysics.computeScaleDelta(
        sourceSize: sourceSize,
        targetSize: targetSize,
      );

  /// Computes a monotonic corner radius that never balloons above
  /// `max(triggerRadius, targetRadius)`.
  static double computeCornerRadius({
    required Size currentSize,
    required double triggerRadius,
    required double targetRadius,
    required double progress,
  }) =>
      LiquidMorphPhysics.computeCornerRadius(
        currentSize: currentSize,
        triggerRadius: triggerRadius,
        targetRadius: targetRadius,
        progress: progress,
      );

  // ─── Physics computation ──────────────────────────────────────────────────

  /// Computes the current [LiquidMorphState] for the given layout geometry.
  LiquidMorphState computeState({
    required double finalDx,
    required double finalDy,
    double horizontalOffset = 0.0,
    double verticalOffset = 0.0,
    double scaleDelta = 1.0,
    bool? adaptiveDamping,
    bool? isClosing,
  }) {
    final bool effectiveClosing = isClosing ?? _isClosing;
    final bool settled = !_animationController.isAnimating &&
        (effectiveClosing
            ? _animationController.value <= 0.001
            : _animationController.value >= 0.999);
    return LiquidMorphPhysics.compute(
      rawValue: _animationController.value,
      finalDx: finalDx,
      finalDy: finalDy,
      horizontalOffset: horizontalOffset,
      verticalOffset: verticalOffset,
      scaleDelta: scaleDelta,
      adaptiveDamping: adaptiveDamping,
      isClosing: effectiveClosing,
      elapsedSeconds: phaseElapsedSeconds,
      hasHandedOff: _hasHandedOff,
      isSettled: settled,
      disableAnimations: _disableAnimations,
      phaseStartTriggerWidth: _phaseStartTriggerWidth,
      closeStartProgress: _closeStartProgress,
      recoilHalfTravelPx: recoilHalfTravelPx,
      verticalOnlyRecoil: verticalOnlyRecoil,
    );
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  bool get _isInstantProfile =>
      _disableAnimations || _speed == MorphSpeed.instant;

  bool get _hasSettled =>
      !_animationController.isAnimating && _animationController.value <= 0.001;

  double _currentTriggerWidthProgress() {
    if (!_animationController.isAnimating &&
        !_isClosing &&
        _animationController.value <= 0.001) {
      return 1.0;
    }
    return computeState(finalDx: 0.0, finalDy: 0.0).triggerWidthProgress;
  }

  SpringDescription get _effectiveSpring {
    if (_isInstantProfile) {
      return const SpringDescription(
        mass: 1.0,
        stiffness: 1800.0,
        damping: 80.0,
      );
    }
    switch (_speed) {
      case MorphSpeed.slow:
        // 0.65× frequency scaling of normal open/close profiles
        return _isClosing
            ? const SpringDescription(
                mass: 1.0,
                stiffness: 137.0,
                damping: 20.2,
              )
            : const SpringDescription(
                mass: 1.0,
                stiffness: 122.0,
                damping: 16.8,
              );
      case MorphSpeed.normal:
        return _isClosing
            ? LiquidMorphPhysics.closeSpring
            : LiquidMorphPhysics.openSpring;
      case MorphSpeed.fast:
        // 1.35× frequency scaling of normal open/close profiles
        return _isClosing
            ? const SpringDescription(
                mass: 1.0,
                stiffness: 590.0,
                damping: 41.9,
              )
            : const SpringDescription(
                mass: 1.0,
                stiffness: 527.0,
                damping: 34.8,
              );
      case MorphSpeed.instant:
        return const SpringDescription(
          mass: 1.0,
          stiffness: 1800.0,
          damping: 80.0,
        );
    }
  }

  /// Tightened open settle tolerance (~420 ms at normal speed): stops once
  /// post-1.0 overshoot falls below ~0.4 %, avoiding 20+ invisible frames.
  static const Tolerance _openSettleTolerance =
      Tolerance(distance: 0.004, velocity: 0.10);

  /// Close settle tolerance (~540–550 ms at normal speed): keeps the ticker
  /// alive past platter vanish (~283 ms) so parallel trigger recoil and wide
  /// horizontal splash (~400 ms peak) complete smoothly before [isShowing]
  /// becomes false.
  static const Tolerance _closeSettleTolerance =
      Tolerance(distance: 0.0003, velocity: 0.008);

  /// Near-instant settle tolerance for Reduce Motion and [MorphSpeed.instant].
  static const Tolerance _instantSettleTolerance =
      Tolerance(distance: 0.002, velocity: 0.05);

  /// Elapsed-time floor applied when the underlying [AnimationController] has
  /// settled at its open or close endpoint.
  ///
  /// Flutter's `AnimationController._tick` invokes `stop(canceled: false)` —
  /// clearing `lastElapsedDuration` to `null` — *before* `notifyListeners()`.
  /// If a slow first frame (e.g. cold shader compilation under
  /// `GlassWarmUpMode.never`) jumps straight past `Simulation.isDone`,
  /// `_lastElapsedSeconds` would stay frozen at `0.0` forever, leaving
  /// `phaseElapsedSeconds`-driven curves (row opacity, blur, corner radius,
  /// drift, recoil) stuck at `t = 0` (#522). Ten seconds exceeds every phase
  /// curve's settle window even at [MorphSpeed.slow] (`0.65×`).
  static const double _kSettledElapsedSeconds = 10.0;

  void _runSpring(
    double target, {
    required double velocityHint,
    required Tolerance tolerance,
  }) {
    _animationController.animateWith(
      SpringSimulation(
        _effectiveSpring,
        _animationController.value,
        target,
        velocityHint,
        snapToEnd: true,
        tolerance: tolerance,
      ),
    );
  }

  void _onTick() {
    final elapsed = _animationController.lastElapsedDuration;
    if (elapsed != null) {
      _lastElapsedSeconds =
          elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    } else if (!_animationController.isAnimating &&
        (_isClosing
            ? _animationController.value <= 0.001
            : _animationController.value >= 0.999)) {
      _lastElapsedSeconds = math.max(
        _lastElapsedSeconds,
        _kSettledElapsedSeconds,
      );
    }
    if (_isClosing && _animationController.value <= 0.0 && !_hasHandedOff) {
      _hasHandedOff = true;
    }
    notifyListeners();
  }

  void _onStatusChange(AnimationStatus status) {
    notifyListeners();
  }
}
