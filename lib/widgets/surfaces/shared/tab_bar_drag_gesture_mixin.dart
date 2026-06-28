// Shared drag gesture state and handlers for bottom bar tab indicators.
//
// Eliminates duplication between [TabIndicatorState] and
// [SearchableTabIndicatorState]. Both had identical state fields, coordinate
// helpers, and gesture handlers — causing the same bugs (issue #22, #23) to
// exist in two places.
//
// NOT part of the public API — do not export from liquid_glass_widgets.dart.

import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/widgets.dart';

import '../../../utils/draggable_indicator_physics.dart';

/// Shared drag gesture state and handlers for bottom bar indicators.
///
/// Apply to a [State] subclass with `with TabDragGestureMixin<MyWidget>`.
/// Implement the three abstract getters to wire up the mixin.
///
/// Exposes handler methods that map directly to [GestureDetector] callbacks:
/// - [onBarDragDown] → `onHorizontalDragDown`
/// - [onBarDragStart] → `onHorizontalDragStart`
/// - [onBarDragUpdate] → `onHorizontalDragUpdate`
/// - [onBarDragEnd] → `onHorizontalDragEnd`
/// - [onBarDragCancel] → `onHorizontalDragCancel`
/// - [onBarTapDown] → `onTapDown`
mixin TabDragGestureMixin<T extends StatefulWidget> on State<T> {
  // ── Abstract interface ────────────────────────────────────────────────────

  /// Total number of tabs.
  int get tabCount;

  /// Index of the currently selected tab.
  int get tabIndex;

  /// Called once per gesture lifecycle when the active tab should change.
  ///
  /// Always invoked unconditionally — callers may use repeat-tap to trigger
  /// scroll-to-top or refresh on the active tab (issue #22).
  void notifyTabChanged(int index);

  // ── Shared state ──────────────────────────────────────────────────────────

  /// True while the pointer is physically held down.
  ///
  /// Drives jelly thickness animation. Set by [onBarDragDown] and also by
  /// the raw [Listener] in the concrete class's build method.
  bool tabIsDown = false;

  /// True while a horizontal drag gesture is in progress.
  bool tabIsDragging = false;

  /// Bumped to force the interactive [GestureDetector] — and its underlying
  /// framework gesture recognizer — to be torn down and recreated. Used by
  /// [recoverIfGestureStuck] to clear a recognizer left wedged after a dropped
  /// terminal callback over a PlatformView. Concrete classes must key the
  /// detector on this value.
  int gestureEpoch = 0;

  /// True from [onBarDragDown] until a terminal callback ([onBarDragEnd] or
  /// [onBarDragCancel]) runs. If the raw pointer-up/cancel arrives with this
  /// still set, the terminal callback was dropped (PlatformView gesture-arena
  /// race) and the recognizer is wedged — covers both the `down`-without-cancel
  /// (tap) and `START`-without-end (drag) freeze signatures.
  bool _gestureActive = false;

  /// Current horizontal alignment of the indicator in the range [-1, 1].
  double tabXAlign = 0.0;

  /// Lateral sway offset in logical pixels.
  ///
  /// Driven by horizontal drag velocity — gives the bar body a subtle
  /// physical response when the interactive pill is dragged left/right,
  /// mimicking iOS 26 bottom bar behaviour. Animated back to `0.0` via
  /// a spring when the drag ends or is cancelled.
  ///
  /// Maximum magnitude is clamped to [_maxSwayPx].
  double barSwayOffset = 0.0;

  /// Maximum lateral sway in logical pixels — keeps the effect subtle.
  static const double _maxSwayPx = 0.75;

  /// Scale factor mapping instantaneous drag delta to sway offset.
  static const double _swayScale = 0.08;

  /// Minimum drag delta magnitude (px/frame) required to trigger sway.
  /// Below this threshold the bar stays still — only fast flicks cause sway.
  static const double _swayVelocityThreshold = 4.0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    tabXAlign = computeTabAlignment(tabIndex);
  }

  /// Call from [didUpdateWidget] when tabIndex or tabCount may have changed.
  void updateTabAlignIfNeeded(int oldTabIndex, int oldTabCount) {
    if (oldTabIndex != tabIndex || oldTabCount != tabCount) {
      if (mounted) setState(() => tabXAlign = computeTabAlignment(tabIndex));
    }
  }

  // ── Coordinate helpers ────────────────────────────────────────────────────

  /// Maps a tab index to horizontal alignment in [-1, 1].
  double computeTabAlignment(int index) =>
      DraggableIndicatorPhysics.computeAlignment(index, tabCount);

  /// Maps a global pointer position to alignment in [-1, 1] with rubber-band
  /// resistance applied at the edges.
  double alignmentFromGlobal(Offset globalPosition) =>
      DraggableIndicatorPhysics.getAlignmentFromGlobalPosition(
        globalPosition,
        context,
        tabCount,
      );

  // ── Gesture handlers ──────────────────────────────────────────────────────

  /// `onHorizontalDragDown` — marks pointer as pressed for jelly activation.
  void onBarDragDown(DragDownDetails d) {
    if (!mounted) return;
    _gestureActive = true;
    setState(() => tabIsDown = true);
  }

  /// `onHorizontalDragStart` — drag confirmed; lock position to pointer.
  void onBarDragStart(DragStartDetails d) {
    if (!mounted) return;
    setState(() {
      tabIsDragging = true;
      tabXAlign = alignmentFromGlobal(d.globalPosition);
    });
  }

  /// `onHorizontalDragUpdate` — track pointer during drag.
  ///
  /// Also updates [barSwayOffset] based on instantaneous drag velocity,
  /// giving the bar a subtle lateral sway when the interactive pill is
  /// flicked quickly — mimicking iOS 26 bottom bar physics.
  ///
  /// Slow drags (below [_swayVelocityThreshold]) produce zero sway;
  /// only fast flicks cause the bar to shift.
  void onBarDragUpdate(DragUpdateDetails d) {
    if (!mounted) return;
    setState(() {
      tabIsDragging = true;
      tabXAlign = alignmentFromGlobal(d.globalPosition);
      // Velocity-gated lateral sway: only fast flicks cause movement.
      if (d.delta.dx.abs() > _swayVelocityThreshold) {
        barSwayOffset =
            (d.delta.dx * _swayScale).clamp(-_maxSwayPx, _maxSwayPx);
      } else {
        barSwayOffset = 0.0;
      }
    });
  }

  /// Applies a drag-resolution state change safely.
  ///
  /// [onBarDragEnd]/[onBarDragCancel] can be invoked synchronously while the
  /// element tree is locked — specifically when the indicator's
  /// [RawGestureDetector] is disposed mid-gesture as its subtree is torn down
  /// during a rebuild (the press-hold freeze observed at non-premium quality,
  /// where the fallback render path reparents the interactive subtree). In that
  /// window the [State] is still `mounted` but `setState()` is illegal, so
  /// calling it throws, the cancel cleanup aborts, and the drag state is left
  /// stuck (the bar freezes). Defer to the next frame when invoked during the
  /// build/finalize phase; a genuinely disposing State no-ops via `mounted`.
  void _applyDragResolution(VoidCallback body) {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) body();
      });
    } else {
      body();
    }
  }

  /// `onHorizontalDragEnd` — snap to target tab with velocity fling support.
  ///
  /// Uses the alignment-coordinate inverse formula (issue #23 fix):
  ///   `computeAlignment(i, n)` → `-1 + 2i/(n-1)`
  ///   inverse: `i = ((tabXAlign + 1) / 2) * (n - 1)`
  ///
  /// This corrects the coordinate-space mismatch that caused off-by-one
  /// snapping when the old `relX / (1/tabCount)` formula was used.
  /// Velocity fling is layered on top so a fast swipe carries the indicator
  /// past the nearest-position tab.
  void onBarDragEnd(DragEndDetails d) {
    final relX = (tabXAlign + 1) / 2;
    final positionIndex =
        (relX * (tabCount - 1)).round().clamp(0, tabCount - 1);

    final box = context.findRenderObject()! as RenderBox;
    final rawVelX = d.velocity.pixelsPerSecond.dx / box.size.width;
    const velocityThreshold = 0.5;
    int target = positionIndex;
    if (rawVelX > velocityThreshold && positionIndex < tabCount - 1) {
      target = positionIndex + 1;
    } else if (rawVelX < -velocityThreshold && positionIndex > 0) {
      target = positionIndex - 1;
    }

    _gestureActive = false;
    _applyDragResolution(() {
      setState(() {
        tabIsDragging = false;
        tabIsDown = false;
        tabXAlign = computeTabAlignment(target);
        barSwayOffset = 0.0; // spring back to center
      });
      notifyTabChanged(target);
    });
  }

  /// `onHorizontalDragCancel` — snap to nearest tab without velocity.
  void onBarDragCancel() {
    _gestureActive = false;
    if (tabIsDragging) {
      final relX = (tabXAlign + 1) / 2;
      final target = (relX * (tabCount - 1)).round().clamp(0, tabCount - 1);
      _applyDragResolution(() {
        setState(() {
          tabIsDragging = false;
          tabIsDown = false;
          tabXAlign = computeTabAlignment(target);
          barSwayOffset = 0.0; // spring back to center
        });
        notifyTabChanged(target);
      });
    } else {
      // Not dragging (e.g. same-tab tap): reset indicator to exact tab center.
      _applyDragResolution(
          () => setState(() => tabXAlign = computeTabAlignment(tabIndex)));
    }
  }

  /// `onTapDown` — selects tab on tap, including repeat-tap on the active tab.
  ///
  /// DX1: fires immediately (before gesture arena resolution) so [tabIsDown]
  /// is set on the same frame as the touch, keeping jelly visible on desktop
  /// where tapDown+tapUp arrive in the same frame.
  void onBarTapDown(TapDownDetails d) {
    final alignment = alignmentFromGlobal(d.globalPosition);
    final relX = (alignment + 1) / 2;
    final index = (relX * tabCount).floor().clamp(0, tabCount - 1);
    notifyTabChanged(index);
  }

  /// Safety net for a dropped gesture terminal callback while the bar floats
  /// over an iOS PlatformView.
  ///
  /// Over a PlatformView (e.g. a map), an interactive Flutter widget's gesture
  /// recognizer can have its terminal callback dropped in a race with the
  /// platform view's native gesture handling — a long-standing iOS
  /// PlatformView gesture-arena limitation, reproducible with this indicator
  /// dragged/tapped over a Mapbox map. The recognizer is then left wedged with
  /// [_gestureActive] still set and the bar stops receiving touches until
  /// something disposes it. Two signatures: `down` with no `onCancel` (a tap)
  /// and `START` with no `onEnd` (a drag).
  ///
  /// The raw [Listener] in the concrete class fires `onPointerUp` /
  /// `onPointerCancel` regardless of arena resolution, so it calls this on each
  /// with the [upPosition] (the lift point). If a gesture is still flagged
  /// active on the next frame (its real terminal callback never ran), dispose
  /// the wedged recognizer via [gestureEpoch] (a state reset alone won't clear
  /// it — only disposal does, which is why the search morph un-freezes) and
  /// select the tab **under the lift point**.
  ///
  /// We resolve to [upPosition], never [tabXAlign]: a gesture that wedged
  /// mid-drag stops reporting finger movement, so [tabXAlign] is frozen at the
  /// press point and would snap the user back to where they started. The lift
  /// point is the only trustworthy signal for where they actually intended to
  /// go. (Recovery is a correctness backstop, not a substitute for smooth
  /// drag-tracking — which over a PlatformView requires a native pointer
  /// barrier the framework can't provide from Dart.)
  void recoverIfGestureStuck(Offset upPosition) {
    if (!_gestureActive) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_gestureActive) return;
      final relX = (alignmentFromGlobal(upPosition) + 1) / 2;
      final target = (relX * tabCount).floor().clamp(0, tabCount - 1);
      setState(() {
        _gestureActive = false;
        tabIsDragging = false;
        tabIsDown = false;
        tabXAlign = computeTabAlignment(target);
        barSwayOffset = 0.0;
        gestureEpoch++; // dispose the wedged recognizer
      });
      notifyTabChanged(target);
    });
  }
}
