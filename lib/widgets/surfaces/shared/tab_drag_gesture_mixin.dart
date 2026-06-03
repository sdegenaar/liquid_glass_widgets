// Shared drag gesture state and handlers for bottom bar tab indicators.
//
// Eliminates duplication between [TabIndicatorState] and
// [SearchableTabIndicatorState]. Both had identical state fields, coordinate
// helpers, and gesture handlers — causing the same bugs (issue #22, #23) to
// exist in two places.
//
// NOT part of the public API — do not export from liquid_glass_widgets.dart.

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

  /// Current horizontal alignment of the indicator in the range [-1, 1].
  double tabXAlign = 0.0;

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
  void onBarDragUpdate(DragUpdateDetails d) {
    if (!mounted) return;
    setState(() {
      tabIsDragging = true;
      tabXAlign = alignmentFromGlobal(d.globalPosition);
    });
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

    if (!mounted) return;
    setState(() {
      tabIsDragging = false;
      tabIsDown = false;
      tabXAlign = computeTabAlignment(target);
    });
    notifyTabChanged(target);
  }

  /// `onHorizontalDragCancel` — snap to nearest tab without velocity.
  void onBarDragCancel() {
    if (tabIsDragging) {
      final relX = (tabXAlign + 1) / 2;
      final target = (relX * (tabCount - 1)).round().clamp(0, tabCount - 1);
      if (!mounted) return;
      setState(() {
        tabIsDragging = false;
        tabIsDown = false;
        tabXAlign = computeTabAlignment(target);
      });
      notifyTabChanged(target);
    } else {
      // Not dragging (e.g. same-tab tap): reset indicator to exact tab center.
      if (!mounted) return;
      setState(() => tabXAlign = computeTabAlignment(tabIndex));
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
}
