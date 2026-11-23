import 'dart:math' as math;

import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../widgets/shared/glass_accessibility_scope.dart';

/// Tunable physics for the iOS 26/27 tab-bar selection lens "jelly".
///
/// Pass it as `indicatorJelly` on [GlassTabBar] or [GlassSegmentedControl]
/// to change the motion, or use [IndicatorJellyPhysics.disabled] to keep the
/// classic velocity squash.
///
/// The defaults were measured from UIKit: a native `UITabBar` on the iOS 27.2
/// simulator, tapped through XCUITest, with the selection lens' presentation
/// geometry logged every frame. They describe three motions:
///
/// * **Travel stretch** — after a tap, the edge facing the destination is
///   pulled ahead of the moving pill ([travelStretch]) while the pill thins
///   vertically ([travelThinning], [travelFlatten]). It peaks ≈0.15 s into
///   the travel at ≈12 % of the lens width, whatever the distance.
/// * **Landing squish** — the trailing edge follows its own, slower spring
///   ([trailingDuration], [trailingBounce]) and overshoots the leading edge
///   as the pill lands, so the pill narrows and bulges ([compressionBulge]).
///   The squish grows with distance: ≈0.95× after one tab, ≈0.9× after two
///   and ≈0.8× after four, peaking ≈0.45 s after the tap. It comes almost
///   entirely from the trailing side ([squishAnchor]), and at the ends of
///   the bar the leading edge stays pinned to the last cell.
/// * **Drag** — while a finger drags the pill, an acceleration-driven damped
///   oscillator fitted to `_UILiquidLensView` stretches the pill on speed-up
///   ([maxDragStretch], [dragThinning]), relaxes back to rest at steady drag
///   speed, and squishes narrower while bulging vertically on deceleration or
///   direction reversal.
///
/// Lengths are fractions of the lens width.
@immutable
class IndicatorJellyPhysics {
  /// Creates jelly physics. Every value defaults to the measured native
  /// motion.
  const IndicatorJellyPhysics({
    this.enabled = true,
    this.travelStretch = 0.19,
    this.travelStretchDuration = const Duration(milliseconds: 410),
    this.travelStretchBounce = 0.15,
    this.travelStretchHold = const Duration(milliseconds: 120),
    this.travelStretchRelaxDuration = const Duration(milliseconds: 325),
    this.travelThinning = 0.55,
    this.travelFlatten = 0.04,
    this.travelFlattenDuration = const Duration(milliseconds: 350),
    this.travelFlattenHold = const Duration(milliseconds: 280),
    this.travelFlattenRelaxDuration = const Duration(milliseconds: 200),
    this.trailingDuration = const Duration(milliseconds: 660),
    this.trailingBounce = 0.31,
    this.squishAnchor = 0.95,
    this.compressionBulge = 1.15,
    this.maxCompression = 0.4,
    this.dragTrailingDuration = const Duration(milliseconds: 140),
    this.maxDragStretch = 0.12,
    this.dragThinning = 0.65,
  })  : assert(travelStretchBounce >= -1.0 && travelStretchBounce < 1.0,
            'travelStretchBounce must be in [-1.0, 1.0)'),
        assert(trailingBounce >= -1.0 && trailingBounce < 1.0,
            'trailingBounce must be in [-1.0, 1.0)'),
        assert(squishAnchor >= 0.0 && squishAnchor <= 1.0,
            'squishAnchor must be in [0.0, 1.0]'),
        assert(maxCompression >= 0.0 && maxCompression <= 0.9,
            'maxCompression must be in [0.0, 0.9]'),
        assert(maxDragStretch >= 0.0, 'maxDragStretch must be non-negative');

  /// The measured native motion (the default).
  static const IndicatorJellyPhysics native = IndicatorJellyPhysics();

  /// No jelly: the indicator keeps the classic velocity squash.
  static const IndicatorJellyPhysics disabled =
      IndicatorJellyPhysics(enabled: false);

  /// Whether the jelly runs at all. When `false` the indicator keeps the
  /// classic velocity squash.
  final bool enabled;

  /// Forward stretch the travel pulse heads for after a tap. The pulse is
  /// released after [travelStretchHold], so the visible peak is lower
  /// (≈0.12 with the default timing).
  final double travelStretch;

  /// Duration of the spring that raises the travel stretch.
  final Duration travelStretchDuration;

  /// Bounce of the spring that raises the travel stretch.
  final double travelStretchBounce;

  /// How long after the tap the travel stretch starts to relax.
  final Duration travelStretchHold;

  /// Duration of the critically damped spring that relaxes the travel
  /// stretch.
  final Duration travelStretchRelaxDuration;

  /// Vertical thinning per unit of travel stretch.
  final double travelThinning;

  /// Extra vertical flattening while the pill travels after a tap.
  final double travelFlatten;

  /// Duration of the critically damped spring that raises [travelFlatten].
  final Duration travelFlattenDuration;

  /// How long after the tap the flattening starts to relax.
  final Duration travelFlattenHold;

  /// Duration of the critically damped spring that relaxes the flattening.
  final Duration travelFlattenRelaxDuration;

  /// Duration of the trailing-edge spring after a tap or a drag release.
  final Duration trailingDuration;

  /// Bounce of the trailing-edge spring; its overshoot past the leading edge
  /// is the landing squish.
  final double trailingBounce;

  /// Where the landing squish is anchored, from `0` (the centre) to `1` (the
  /// leading edge stays fully pinned).
  final double squishAnchor;

  /// Vertical bulge per unit of landing squish.
  final double compressionBulge;

  /// Largest landing squish.
  final double maxCompression;

  /// Duration of the critically damped trailing-edge spring while dragging.
  final Duration dragTrailingDuration;

  /// Largest drag stretch; the trailing edge's lag is soft-limited toward it.
  final double maxDragStretch;

  /// Vertical thinning per unit of drag stretch.
  final double dragThinning;

  SpringDescription get _travelStretchSpring =>
      SpringDescription.withDurationAndBounce(
        duration: travelStretchDuration,
        bounce: travelStretchBounce,
      );

  SpringDescription get _travelStretchRelaxSpring =>
      SpringDescription.withDurationAndBounce(
        duration: travelStretchRelaxDuration,
      );

  SpringDescription get _travelFlattenSpring =>
      SpringDescription.withDurationAndBounce(
        duration: travelFlattenDuration,
      );

  SpringDescription get _travelFlattenRelaxSpring =>
      SpringDescription.withDurationAndBounce(
        duration: travelFlattenRelaxDuration,
      );

  SpringDescription get _trailingSpring =>
      SpringDescription.withDurationAndBounce(
        duration: trailingDuration,
        bounce: trailingBounce,
      );

  /// Returns a copy with the given values replaced.
  IndicatorJellyPhysics copyWith({
    bool? enabled,
    double? travelStretch,
    Duration? travelStretchDuration,
    double? travelStretchBounce,
    Duration? travelStretchHold,
    Duration? travelStretchRelaxDuration,
    double? travelThinning,
    double? travelFlatten,
    Duration? travelFlattenDuration,
    Duration? travelFlattenHold,
    Duration? travelFlattenRelaxDuration,
    Duration? trailingDuration,
    double? trailingBounce,
    double? squishAnchor,
    double? compressionBulge,
    double? maxCompression,
    Duration? dragTrailingDuration,
    double? maxDragStretch,
    double? dragThinning,
  }) {
    return IndicatorJellyPhysics(
      enabled: enabled ?? this.enabled,
      travelStretch: travelStretch ?? this.travelStretch,
      travelStretchDuration:
          travelStretchDuration ?? this.travelStretchDuration,
      travelStretchBounce: travelStretchBounce ?? this.travelStretchBounce,
      travelStretchHold: travelStretchHold ?? this.travelStretchHold,
      travelStretchRelaxDuration:
          travelStretchRelaxDuration ?? this.travelStretchRelaxDuration,
      travelThinning: travelThinning ?? this.travelThinning,
      travelFlatten: travelFlatten ?? this.travelFlatten,
      travelFlattenDuration:
          travelFlattenDuration ?? this.travelFlattenDuration,
      travelFlattenHold: travelFlattenHold ?? this.travelFlattenHold,
      travelFlattenRelaxDuration:
          travelFlattenRelaxDuration ?? this.travelFlattenRelaxDuration,
      trailingDuration: trailingDuration ?? this.trailingDuration,
      trailingBounce: trailingBounce ?? this.trailingBounce,
      squishAnchor: squishAnchor ?? this.squishAnchor,
      compressionBulge: compressionBulge ?? this.compressionBulge,
      maxCompression: maxCompression ?? this.maxCompression,
      dragTrailingDuration: dragTrailingDuration ?? this.dragTrailingDuration,
      maxDragStretch: maxDragStretch ?? this.maxDragStretch,
      dragThinning: dragThinning ?? this.dragThinning,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is IndicatorJellyPhysics &&
      other.enabled == enabled &&
      other.travelStretch == travelStretch &&
      other.travelStretchDuration == travelStretchDuration &&
      other.travelStretchBounce == travelStretchBounce &&
      other.travelStretchHold == travelStretchHold &&
      other.travelStretchRelaxDuration == travelStretchRelaxDuration &&
      other.travelThinning == travelThinning &&
      other.travelFlatten == travelFlatten &&
      other.travelFlattenDuration == travelFlattenDuration &&
      other.travelFlattenHold == travelFlattenHold &&
      other.travelFlattenRelaxDuration == travelFlattenRelaxDuration &&
      other.trailingDuration == trailingDuration &&
      other.trailingBounce == trailingBounce &&
      other.squishAnchor == squishAnchor &&
      other.compressionBulge == compressionBulge &&
      other.maxCompression == maxCompression &&
      other.dragTrailingDuration == dragTrailingDuration &&
      other.maxDragStretch == maxDragStretch &&
      other.dragThinning == dragThinning;

  @override
  int get hashCode => Object.hashAll([
        enabled,
        travelStretch,
        travelStretchDuration,
        travelStretchBounce,
        travelStretchHold,
        travelStretchRelaxDuration,
        travelThinning,
        travelFlatten,
        travelFlattenDuration,
        travelFlattenHold,
        travelFlattenRelaxDuration,
        trailingDuration,
        trailingBounce,
        squishAnchor,
        compressionBulge,
        maxCompression,
        dragTrailingDuration,
        maxDragStretch,
        dragThinning,
      ]);
}

/// Shape deformation of a sliding indicator pill at one moment: a scale
/// about the pill's centre plus a horizontal shift of that centre.
///
/// Produced every frame by `IndicatorJellyBuilder` from
/// [IndicatorJellyPhysics]; see there for the motion it describes.
@immutable
class IndicatorJelly {
  /// Creates an [IndicatorJelly].
  const IndicatorJelly({
    required this.scaleX,
    required this.scaleY,
    this.offsetX = 0.0,
  });

  /// No deformation.
  static const IndicatorJelly identity = IndicatorJelly(scaleX: 1, scaleY: 1);

  /// Horizontal scale factor (1 = rest width).
  final double scaleX;

  /// Vertical scale factor (1 = rest height).
  final double scaleY;

  /// Horizontal shift of the pill's centre, as a fraction of its width
  /// (positive = right).
  final double offsetX;

  /// Whether this deformation is visually a no-op.
  bool get isIdentity =>
      (scaleX - 1).abs() < 1e-4 &&
      (scaleY - 1).abs() < 1e-4 &&
      offsetX.abs() < 1e-4;

  /// The same deformation reflected horizontally, for indicators whose
  /// position is directional ([AlignmentDirectional]) in RTL.
  IndicatorJelly get mirrored =>
      IndicatorJelly(scaleX: scaleX, scaleY: scaleY, offsetX: -offsetX);

  /// The scale for a [Transform] aligned to [Alignment.center]; apply
  /// [offsetX] with a [FractionalTranslation].
  ///
  /// Never returns an exact identity: a sub-pixel translation keeps the
  /// TransformLayer mounted, matching [DraggableIndicatorPhysics].
  Matrix4 get matrix {
    if ((scaleX - 1).abs() < 1e-4 && (scaleY - 1).abs() < 1e-4) {
      return Matrix4.identity()..translateByDouble(0.0001, 0.0, 0.0, 1.0);
    }
    return Matrix4.diagonal3Values(scaleX, scaleY, 1.0);
  }

  /// The whole deformation as one matrix for geometry laid out in [rect]
  /// (used by path clippers).
  Matrix4 matrixFor(Rect rect) {
    final center = rect.center;
    return Matrix4.identity()
      ..translateByDouble(
        center.dx + offsetX * rect.width,
        center.dy,
        0.0,
        1.0,
      )
      ..multiply(matrix)
      ..translateByDouble(-center.dx, -center.dy, 0.0, 1.0);
  }

  /// Computes the deformation from the springs driven by
  /// `IndicatorJellyBuilder`.
  ///
  /// * [lead] / [trail] — current alignment (−1…1) of the position spring
  ///   and of the trailing-edge spring.
  /// * [itemCount] — number of equal-width cells the indicator moves between.
  /// * [travelDirection] — `+1` (rightwards) or `−1` (leftwards): the
  ///   direction of the most recent released travel.
  /// * [dragging] — while dragging the trailing edge only lags; it never
  ///   squishes.
  /// * [stretch] — the signed travel stretch (positive pulls the right edge
  ///   rightwards).
  /// * [flatten] — the travel flattening.
  /// * [dragDeformation] — optional signed horizontal deformation produced by
  ///   `IndicatorJellyBuilder`'s native acceleration-driven drag oscillator
  ///   (positive = accelerating stretch, negative = decelerating/reversal
  ///   squish & vertical bulge). When `null` while [dragging], falls back to
  ///   trailing-edge lag from [lead] and [trail].
  static IndicatorJelly resolve({
    required double lead,
    required double trail,
    required int itemCount,
    required double travelDirection,
    required bool dragging,
    double stretch = 0.0,
    double flatten = 0.0,
    double? dragDeformation,
    IndicatorJellyPhysics physics = IndicatorJellyPhysics.native,
  }) {
    if (!physics.enabled ||
        itemCount < 2 ||
        !lead.isFinite ||
        !trail.isFinite ||
        !stretch.isFinite ||
        !flatten.isFinite ||
        (dragDeformation != null && !dragDeformation.isFinite)) {
      return identity;
    }

    // Alignment → multiples of the cell width. One alignment unit spans
    // (itemCount − 1) / 2 cells.
    final separation = (lead - trail) * (itemCount - 1) / 2;

    // Movement of each edge, as a fraction of the width (positive = right).
    var right = math.max(stretch, 0.0);
    var left = math.min(stretch, 0.0);
    var scaleY = 1.0 - physics.travelThinning * stretch.abs() - flatten;

    void applyDragDeformation(double u) {
      if (u >= 0) {
        final dx = _softLimit(u, physics.maxDragStretch);
        left -= dx / 2;
        right += dx / 2;
        scaleY -= physics.dragThinning * dx;
      } else {
        // Native iOS 27 deceleration/reversal squish & vertical bulge
        // (measured peak scaleX ≈ 0.870, scaleY ≈ 1.149 -> bulge slope 1.55).
        final squish = _softLimit(-u, 0.13);
        left += squish / 2;
        right -= squish / 2;
        scaleY += 1.55 * squish;
      }
    }

    if (dragging) {
      if (dragDeformation != null) {
        applyDragDeformation(dragDeformation);
      } else {
        final lag = _softLimit(separation.abs(), physics.maxDragStretch);
        if (separation >= 0) {
          left -= lag;
        } else {
          right += lag;
        }
        scaleY -= physics.dragThinning * lag;
      }
    } else {
      final direction = travelDirection >= 0 ? 1.0 : -1.0;
      final overshoot = -separation * direction;
      if (overshoot > 0) {
        final squish = math.min(overshoot, physics.maxCompression);
        final anchor = physics.squishAnchor.clamp(0.0, 1.0);
        final trailing = squish * (1 + anchor) / 2;
        final leading = squish * (1 - anchor) / 2;
        if (direction > 0) {
          left += trailing;
          right -= leading;
        } else {
          right -= trailing;
          left += leading;
        }
        scaleY *= 1 + physics.compressionBulge * squish;
      }

      if (dragDeformation != null && dragDeformation.abs() > 1e-6) {
        applyDragDeformation(dragDeformation);
      }

      // Pin the leading edge at the end of the track, as UIKit does: the
      // position spring's overshoot and the relaxing travel stretch become
      // squish instead of pushing the pill past the last cell.
      final cells = (itemCount - 1) / 2;
      if (direction > 0) {
        final past = (lead - 1) * cells + right;
        if (past > 0) right -= past;
      } else {
        final past = (-1 - lead) * cells - left;
        if (past > 0) left += past;
      }
    }

    return IndicatorJelly(
      scaleX: math.max(1 + right - left, 0.05),
      scaleY: math.max(scaleY, 0.05),
      offsetX: (right + left) / 2,
    );
  }

  static double _softLimit(double x, double cap) {
    if (cap <= 0) return 0;
    final e = math.exp(-2 * x / cap);
    return cap * (1 - e) / (1 + e);
  }

  @override
  bool operator ==(Object other) =>
      other is IndicatorJelly &&
      other.scaleX == scaleX &&
      other.scaleY == scaleY &&
      other.offsetX == offsetX;

  @override
  int get hashCode => Object.hash(scaleX, scaleY, offsetX);

  @override
  String toString() => 'IndicatorJelly(scaleX: ${scaleX.toStringAsFixed(3)}, '
      'scaleY: ${scaleY.toStringAsFixed(3)}, '
      'offsetX: ${offsetX.toStringAsFixed(3)})';
}

/// Signature for [IndicatorJellyBuilder.builder].
typedef IndicatorJellyWidgetBuilder = Widget Function(
  BuildContext context,
  IndicatorJelly jelly,
  Widget? child,
);

/// Runs the jelly springs for an indicator whose position spring is driven
/// elsewhere, and hands the resulting [IndicatorJelly] to [builder].
///
/// Place it inside the builder of the position spring so [lead] is the
/// current animated position each frame. One lazily allocated ticker drives
/// every spring; it stops as soon as the shape has settled and only rebuilds
/// when the shape visibly changes.
class IndicatorJellyBuilder extends StatefulWidget {
  /// Creates an [IndicatorJellyBuilder].
  const IndicatorJellyBuilder({
    required this.target,
    required this.lead,
    required this.itemCount,
    required this.dragging,
    required this.builder,
    this.physics = IndicatorJellyPhysics.native,
    this.teleportEpoch = 0,
    this.child,
    super.key,
  });

  /// The position the indicator is heading to (same value the position
  /// spring is animating toward).
  final double target;

  /// The position spring's current value.
  final double lead;

  /// Number of equal-width cells.
  final int itemCount;

  /// Whether a finger is dragging the indicator.
  final bool dragging;

  /// The jelly physics.
  final IndicatorJellyPhysics physics;

  /// Snap (no motion) when this changes, mirroring
  /// [VelocitySpringBuilder.teleportEpoch].
  final int teleportEpoch;

  /// Called with the current deformation whenever it changes.
  final IndicatorJellyWidgetBuilder builder;

  /// Optional pre-built subtree passed through to [builder].
  final Widget? child;

  @override
  State<IndicatorJellyBuilder> createState() => _IndicatorJellyBuilderState();
}

class _IndicatorJellyBuilderState extends State<IndicatorJellyBuilder>
    with SingleTickerProviderStateMixin {
  static const double _shapeTolerance = 5e-4;
  static const double _settleTolerance = 5e-4;

  Ticker? _ticker;
  late final _JellySpring _trail;
  final _JellySpring _stretch = _JellySpring(0);
  final _JellySpring _flatten = _JellySpring(0);
  final _DragJellyOscillator _dragOsc = _DragJellyOscillator();
  double? _stretchRelaxAt;
  double? _flattenRelaxAt;
  double _direction = 1.0;
  double? _pendingDirection;
  double _clock = 0;
  bool _reduceMotion = false;
  IndicatorJelly _shown = IndicatorJelly.identity;

  IndicatorJellyPhysics get _physics => widget.physics;

  @override
  void initState() {
    super.initState();
    _trail = _JellySpring(widget.target);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = GlassAccessibilityData.of(context).reduceMotion;
    if (reduceMotion != _reduceMotion) {
      _reduceMotion = reduceMotion;
      if (reduceMotion) {
        _snapAll();
      }
    }
  }

  double get _cellsPerUnit => math.max(1, widget.itemCount - 1) / 2;

  double get _trailTolerance => _settleTolerance / _cellsPerUnit;

  double _now() {
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase != SchedulerPhase.idle) {
      _clock = binding.currentFrameTimeStamp.inMicroseconds /
          Duration.microsecondsPerSecond;
    }
    return _clock;
  }

  static double _seconds(Duration d) =>
      d.inMicroseconds / Duration.microsecondsPerSecond;

  void _latchDirection(double next) {
    if (next == _direction) {
      _pendingDirection = null;
      return;
    }
    if ((widget.lead - _trail.value) * next >= 0) {
      _direction = next;
      _pendingDirection = null;
    } else {
      _pendingDirection = next;
    }
  }

  void _snapAll() {
    _trail.jumpTo(widget.target);
    _stretch.jumpTo(0);
    _flatten.jumpTo(0);
    _dragOsc.reset();
    _stretchRelaxAt = null;
    _flattenRelaxAt = null;
    _pendingDirection = null;
    if (_ticker?.isActive ?? false) _ticker!.stop();
  }

  @override
  void didUpdateWidget(IndicatorJellyBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final physics = _physics;
    if (!physics.enabled ||
        widget.teleportEpoch != oldWidget.teleportEpoch ||
        _reduceMotion) {
      _snapAll();
      return;
    }

    final now = _now();
    final startedDrag = widget.dragging && !oldWidget.dragging;
    final released = oldWidget.dragging && !widget.dragging;

    if (startedDrag) {
      _stretch.animateTo(
          0, physics._travelStretchRelaxSpring, now, _settleTolerance);
      _flatten.animateTo(
          0, physics._travelFlattenRelaxSpring, now, _settleTolerance);
      _stretchRelaxAt = null;
      _flattenRelaxAt = null;
      _dragOsc.prime(now, widget.lead);
    }

    if (widget.dragging) {
      // During drag, the native acceleration/deceleration oscillator owns the
      // shape deformation; keep _trail synced to lead so finger lift never
      // triggers a stale second squish from drag lag.
      _trail.jumpTo(widget.lead);
      _dragOsc.advance(
        now,
        widget.lead,
        widget.itemCount,
        dragging: true,
        tauHp: _seconds(physics.dragTrailingDuration),
      );
    } else {
      if (_dragOsc.isActive || released) {
        _dragOsc.advance(
          now,
          widget.lead,
          widget.itemCount,
          dragging: false,
          tauHp: _seconds(physics.dragTrailingDuration),
        );
      }

      if (released) {
        _trail.jumpTo(widget.lead);
        final delta = widget.target - _trail.value;
        if (delta.abs() > 1e-6) {
          _latchDirection(delta.sign);
          _trail.animateTo(
            widget.target,
            physics._trailingSpring,
            now,
            _trailTolerance,
          );
        }
      } else if (widget.target != oldWidget.target) {
        final heading = (widget.target - widget.lead).sign;
        if (heading != 0) {
          _stretch.animateTo(heading * physics.travelStretch,
              physics._travelStretchSpring, now, _settleTolerance);
          _flatten.animateTo(physics.travelFlatten,
              physics._travelFlattenSpring, now, _settleTolerance);
          _stretchRelaxAt = now + _seconds(physics.travelStretchHold);
          _flattenRelaxAt = now + _seconds(physics.travelFlattenHold);
        }
        final delta = widget.target - _trail.value;
        if (delta.abs() > 1e-6) _latchDirection(delta.sign);
        _trail.animateTo(
          widget.target,
          physics._trailingSpring,
          now,
          _trailTolerance,
        );
      } else if (physics != oldWidget.physics) {
        _trail.animateTo(
          _trail.target,
          physics._trailingSpring,
          now,
          _trailTolerance,
        );
      }
    }

    if (_isAnimating) {
      final ticker = _ticker ??= createTicker(_onTick);
      if (!ticker.isActive) ticker.start();
    }
  }

  bool get _isAnimating =>
      _trail.isActive ||
      _stretch.isActive ||
      _flatten.isActive ||
      _dragOsc.isActive ||
      _stretchRelaxAt != null ||
      _flattenRelaxAt != null;

  void _onTick(Duration _) {
    final physics = _physics;
    final now = _now();
    final stretchRelaxAt = _stretchRelaxAt;
    if (stretchRelaxAt != null && now >= stretchRelaxAt) {
      _stretchRelaxAt = null;
      _stretch.animateTo(
          0, physics._travelStretchRelaxSpring, now, _settleTolerance);
    }
    final flattenRelaxAt = _flattenRelaxAt;
    if (flattenRelaxAt != null && now >= flattenRelaxAt) {
      _flattenRelaxAt = null;
      _flatten.animateTo(
          0, physics._travelFlattenRelaxSpring, now, _settleTolerance);
    }
    _trail.advance(now, _trailTolerance);
    _stretch.advance(now, _settleTolerance);
    _flatten.advance(now, _settleTolerance);
    if (widget.dragging || _dragOsc.isActive) {
      _dragOsc.advance(
        now,
        widget.lead,
        widget.itemCount,
        dragging: widget.dragging,
        tauHp: _seconds(physics.dragTrailingDuration),
      );
    }

    final settled = !_isAnimating;
    if (settled) _ticker?.stop();
    final next = _resolve();
    if (settled ? next != _shown : !_isClose(next, _shown)) {
      setState(() {});
    }
  }

  static bool _isClose(IndicatorJelly a, IndicatorJelly b) =>
      (a.scaleX - b.scaleX).abs() < _shapeTolerance &&
      (a.scaleY - b.scaleY).abs() < _shapeTolerance &&
      (a.offsetX - b.offsetX).abs() < _shapeTolerance;

  IndicatorJelly _resolve() {
    final pending = _pendingDirection;
    if (pending != null && (widget.lead - _trail.value) * pending >= 0) {
      _direction = pending;
      _pendingDirection = null;
    }
    return IndicatorJelly.resolve(
      lead: widget.lead,
      trail: _trail.value,
      itemCount: widget.itemCount,
      travelDirection: _direction,
      dragging: widget.dragging,
      stretch: _stretch.value,
      flatten: _flatten.value,
      dragDeformation:
          (widget.dragging || _dragOsc.isActive) ? _dragOsc.value : null,
      physics: _physics,
    );
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _shown = (_physics.enabled && !_reduceMotion)
        ? _resolve()
        : IndicatorJelly.identity;
    return widget.builder(context, _shown, widget.child);
  }
}

/// One spring-driven value of [IndicatorJellyBuilder], evaluated against the
/// frame clock so every spring shares the position spring's timeline.
class _JellySpring {
  _JellySpring(this.value) : target = value;

  double value;
  double target;
  double velocity = 0;
  SpringSimulation? _simulation;
  double _start = 0;

  bool get isActive => _simulation != null;

  void advance(double now, double tolerance) {
    final simulation = _simulation;
    if (simulation == null) return;
    final t = math.max(0.0, now - _start);
    value = simulation.x(t);
    velocity = simulation.dx(t);
    if ((value - target).abs() <= tolerance &&
        velocity.abs() <= tolerance * 10) {
      jumpTo(target);
    }
  }

  void animateTo(
    double next,
    SpringDescription spring,
    double now,
    double tolerance,
  ) {
    advance(now, tolerance);
    target = next;
    if ((value - next).abs() <= tolerance && velocity.abs() <= tolerance * 10) {
      jumpTo(next);
      return;
    }
    _simulation = SpringSimulation(spring, value, next, velocity);
    _start = now;
  }

  void jumpTo(double next) {
    value = next;
    target = next;
    velocity = 0;
    _simulation = null;
  }
}

/// Acceleration/deceleration damped oscillator fitted to native iOS 27
/// `_UILiquidLensView` drag frames (`R² ≈ 0.954`, `RMSE ≈ 0.008` across 1,542
/// 120 Hz frames):
///
/// 1. Low-pass filters signed velocity (`tau_in = 35 ms`) so reversals pass
///    smoothly through zero and touch-sample jitter is rejected.
/// 2. High-passes `|vSmooth|` against a slower running average (`tau_hp`,
///    default `140 ms`) so acceleration stretches (`u > 0`), steady drag
///    relaxes back toward rest (`u → 0`), and deceleration/reversal drives
///    horizontal squish + vertical bulge (`u < 0`).
/// 3. Integrates a damped harmonic oscillator (`ω = 26 rad/s`, `ζ = 0.36`,
///    `gain = 0.014`) with fixed `≤ 1/120 s` sub-steps for frame-rate
///    independence across 60 Hz, 120 Hz, and slow frames.
class _DragJellyOscillator {
  static const double _tauIn = 0.035;
  static const double _omega = 26.0;
  static const double _zeta = 0.36;
  static const double _omega2 = _omega * _omega;
  static const double _twoZetaOmega = 2.0 * _zeta * _omega;
  static const double _gain = 0.014;
  static const double _maxSubStep = 1.0 / 120.0;
  static const double _maxDt = 0.05;

  double _u = 0.0;
  double _ud = 0.0;
  double _vSmooth = 0.0;
  double _speedAvg = 0.0;
  double _lastNow = 0.0;
  double _lastLead = 0.0;
  bool _primed = false;

  double get value => _u;

  bool get isActive =>
      _u.abs() >= 2e-4 ||
      _ud.abs() >= 2e-3 ||
      _vSmooth.abs() >= 1e-3 ||
      _speedAvg >= 1e-3;

  void prime(double now, double lead) {
    _lastNow = now;
    _lastLead = lead;
    _primed = true;
  }

  void advance(
    double now,
    double lead,
    int itemCount, {
    required bool dragging,
    required double tauHp,
  }) {
    if (!_primed) {
      prime(now, lead);
      return;
    }
    final rawDt = now - _lastNow;
    if (rawDt <= 1e-6) return;
    final dt = rawDt.clamp(0.0, _maxDt);
    final cellsPerUnit = math.max(1, itemCount - 1) / 2.0;
    final vCells = dragging ? (lead - _lastLead) * cellsPerUnit / dt : 0.0;
    _lastNow = now;
    _lastLead = lead;

    final clampedTauHp = tauHp.clamp(0.03, 1.0);
    final steps = (dt / _maxSubStep).ceil().clamp(1, 8);
    final h = dt / steps;
    final alphaIn = 1.0 - math.exp(-h / _tauIn);
    final alphaHp = 1.0 - math.exp(-h / clampedTauHp);

    for (var s = 0; s < steps; s++) {
      _vSmooth += alphaIn * (vCells - _vSmooth);
      final speed = _vSmooth.abs();
      _speedAvg += alphaHp * (speed - _speedAvg);
      final target = _gain * (speed - _speedAvg);
      final accel = _omega2 * (target - _u) - _twoZetaOmega * _ud;
      _ud += accel * h;
      _u += _ud * h;
    }

    if (!isActive) {
      _u = 0.0;
      _ud = 0.0;
      _vSmooth = 0.0;
      _speedAvg = 0.0;
      if (!dragging) _primed = false;
    }
  }

  void reset() {
    _u = 0.0;
    _ud = 0.0;
    _vSmooth = 0.0;
    _speedAvg = 0.0;
    _primed = false;
  }
}
