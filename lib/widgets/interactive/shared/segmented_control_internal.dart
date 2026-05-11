// Internal state widget for [GlassSegmentedControl].
//
// Mirrors the [tab_bar_internal.dart] pattern:
//   — keeps [GlassSegmentedControl] as a pure public-API widget file
//   — houses all gesture, animation, and layout state here
//
// NOT part of the public API — do not export from liquid_glass_widgets.dart.
//
// Architecture note: This widget deliberately does NOT use [TabDragGestureMixin]
// because its gesture architecture differs in two key ways:
//   1. Tap handling uses per-segment GestureDetectors (correct for equal-width
//      segments) rather than a single global-position→index mapping.
//   2. Drag-end snapping uses DraggableIndicatorPhysics.computeTargetIndex
//      (floor-based bin selection, consistent with tab_bar_internal.dart),
//      whereas the mixin uses a round-based formula tuned for GlassBottomBar.
// Both the tab bar and segmented control already share the right abstractions:
// DraggableIndicatorPhysics, AnimatedGlassIndicator, and GlassSpring.

import 'package:flutter/material.dart';

import '../../../src/renderer/liquid_glass_renderer.dart';
import '../../../src/types/glass_interaction_behavior.dart';
import '../../../types/glass_quality.dart';
import '../../../utils/draggable_indicator_physics.dart';
import '../../../utils/glass_spring.dart';
import '../../shared/animated_glass_indicator.dart';

// =============================================================================
// Widget
// =============================================================================

/// Internal content widget for [GlassSegmentedControl].
///
/// Manages all gesture handling, spring animations, and indicator rendering.
/// Separated to keep [GlassSegmentedControl] a clean public-API-only file.
class SegmentedControlContent extends StatefulWidget {
  const SegmentedControlContent({
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentSelected,
    required this.selectedTextStyle,
    required this.unselectedTextStyle,
    required this.indicatorColor,
    required this.borderRadius,
    required this.quality,
    this.indicatorSettings,
    this.backgroundKey,
    this.interactionBehavior = GlassInteractionBehavior.full,
    this.glowColor,
    this.glowRadius = 1.5,
    super.key,
  });

  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onSegmentSelected;
  final TextStyle? selectedTextStyle;
  final TextStyle? unselectedTextStyle;
  final Color? indicatorColor;
  final LiquidGlassSettings? indicatorSettings;
  final double borderRadius;
  final GlassQuality quality;
  final GlobalKey? backgroundKey;
  final GlassInteractionBehavior interactionBehavior;
  final Color? glowColor;
  final double glowRadius;

  @override
  State<SegmentedControlContent> createState() =>
      SegmentedControlContentState();
}

// =============================================================================
// State
// =============================================================================

class SegmentedControlContentState extends State<SegmentedControlContent> {
  // ── Default colours ──────────────────────────────────────────────────────
  static const _defaultIndicatorColor =
      Color(0x33FFFFFF); // white.withValues(alpha: 0.2)
  static const _defaultUnselectedTextColor =
      Color(0x99FFFFFF); // white.withValues(alpha: 0.6)

  // ── Gesture state ─────────────────────────────────────────────────────────
  bool _isDown = false;
  bool _isDragging = false;

  /// Current horizontal alignment of the indicator in the range [-1, 1].
  late double _xAlign = _computeXAlignmentForSegment(widget.selectedIndex);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didUpdateWidget(covariant SegmentedControlContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.segments.length != widget.segments.length) {
      setState(() {
        _xAlign = _computeXAlignmentForSegment(widget.selectedIndex);
      });
    }
  }

  // ── Coordinate helpers ────────────────────────────────────────────────────

  /// Converts a segment index to horizontal alignment (-1 to 1).
  double _computeXAlignmentForSegment(int segmentIndex) {
    return DraggableIndicatorPhysics.computeAlignment(
      segmentIndex,
      widget.segments.length,
    );
  }

  /// Converts a global drag position to horizontal alignment (-1 to 1).
  double _getAlignmentFromGlobalPosition(Offset globalPosition) {
    return DraggableIndicatorPhysics.getAlignmentFromGlobalPosition(
      globalPosition,
      context,
      widget.segments.length,
    );
  }

  // ── Gesture handlers ──────────────────────────────────────────────────────

  void _onDragDown(DragDownDetails details) {
    setState(() => _isDown = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _xAlign = _getAlignmentFromGlobalPosition(details.globalPosition);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _isDown = false;
    });

    final box = context.findRenderObject()! as RenderBox;
    final currentRelativeX = (_xAlign + 1) / 2;
    final segmentWidth = 1.0 / widget.segments.length;
    final indicatorWidth = 1.0 / widget.segments.length;
    final draggableRange = 1.0 - indicatorWidth;
    final velocityX =
        (details.velocity.pixelsPerSecond.dx / box.size.width) / draggableRange;

    final targetSegmentIndex = DraggableIndicatorPhysics.computeTargetIndex(
      currentRelativeX: currentRelativeX,
      velocityX: velocityX,
      itemWidth: segmentWidth,
      itemCount: widget.segments.length,
    );

    _xAlign = _computeXAlignmentForSegment(targetSegmentIndex);

    if (targetSegmentIndex != widget.selectedIndex) {
      widget.onSegmentSelected(targetSegmentIndex);
    }
  }

  void _onDragCancel() {
    if (_isDragging) {
      final currentRelativeX = (_xAlign + 1) / 2;
      final targetSegmentIndex = DraggableIndicatorPhysics.computeTargetIndex(
        currentRelativeX: currentRelativeX,
        velocityX: 0,
        itemWidth: 1.0 / widget.segments.length,
        itemCount: widget.segments.length,
      );
      setState(() {
        _isDragging = false;
        _isDown = false;
        _xAlign = _computeXAlignmentForSegment(targetSegmentIndex);
      });
      if (targetSegmentIndex != widget.selectedIndex) {
        widget.onSegmentSelected(targetSegmentIndex);
      }
    } else {
      setState(
        () => _xAlign = _computeXAlignmentForSegment(widget.selectedIndex),
      );
    }
  }

  void _onSegmentTap(int index) {
    if (index != widget.selectedIndex) {
      widget.onSegmentSelected(index);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final indicatorColor = widget.indicatorColor ?? _defaultIndicatorColor;
    final targetAlignment = _computeXAlignmentForSegment(widget.selectedIndex);

    // Indicator is slightly less rounded than the container to account for
    // the inset padding.
    final indicatorRadius = widget.borderRadius - 3;

    final selectedTextStyle = widget.selectedTextStyle ??
        const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        );

    final unselectedTextStyle = widget.unselectedTextStyle ??
        const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: _defaultUnselectedTextColor,
        );

    return Listener(
      // Raw pointer events fire BEFORE gesture recognizers and never compete
      // in the gesture arena, so _isDown is always set on the very first event.
      onPointerDown: (_) => setState(() => _isDown = true),
      // On finger/button lift, clear _isDown if not mid-drag.
      onPointerUp: (_) {
        if (!_isDragging) setState(() => _isDown = false);
      },
      onPointerCancel: (_) {
        if (!_isDragging) setState(() => _isDown = false);
      },
      child: GestureDetector(
        onHorizontalDragDown: _onDragDown,
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        onHorizontalDragCancel: _onDragCancel,
        child: VelocitySpringBuilder(
          value: _xAlign,
          springWhenActive: GlassSpring.interactive(),
          springWhenReleased: GlassSpring.snappy(
            duration: const Duration(milliseconds: 350),
          ),
          active: _isDragging,
          builder: (context, value, velocity, child) {
            final alignment = Alignment(value, 0);

            return SpringBuilder(
              spring: GlassSpring.snappy(
                duration: const Duration(milliseconds: 300),
              ),
              // Show glass bloom when: pressed, dragging, OR indicator is still
              // settling toward its target. Threshold 0.05 matches
              // tab_bar_internal.dart for consistent cross-component behaviour.
              value: _isDown || (alignment.x - targetAlignment).abs() > 0.05
                  ? 1.0
                  : 0.0,
              builder: (context, thickness, child) {
                return RepaintBoundary(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedGlassIndicator(
                        velocity: velocity,
                        itemCount: widget.segments.length,
                        alignment: alignment,
                        thickness: thickness,
                        quality: widget.quality,
                        indicatorColor: indicatorColor,
                        isBackgroundIndicator: false,
                        borderRadius: indicatorRadius,
                        glassSettings: widget.indicatorSettings,
                        backgroundKey: widget.backgroundKey,
                      ),
                      // Segment labels always paint above the glass indicator.
                      child!,
                    ],
                  ),
                );
              },
              child: Row(
                children: [
                  for (var i = 0; i < widget.segments.length; i++)
                    Expanded(
                      child: RepaintBoundary(
                        child: GestureDetector(
                          onTap: () => _onSegmentTap(i),
                          onTapDown: (_) {
                            // Trigger selection immediately on touch down.
                            if (i != widget.selectedIndex) {
                              widget.onSegmentSelected(i);
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Semantics(
                            button: true,
                            selected: widget.selectedIndex == i,
                            label: widget.segments[i],
                            child: Center(
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 200),
                                style: widget.selectedIndex == i
                                    ? selectedTextStyle
                                    : unselectedTextStyle,
                                child: Text(
                                  widget.segments[i],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          child: Row(
            children: [
              for (var i = 0; i < widget.segments.length; i++)
                Expanded(
                  child: Center(
                    child: Text(widget.segments[i]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
