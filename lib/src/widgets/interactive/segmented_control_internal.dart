// ignore_for_file: public_member_api_docs
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
//      whereas the mixin uses a round-based formula tuned for GlassTabBar.
// Both the tab bar and segmented control already share the right abstractions:
// DraggableIndicatorPhysics, AnimatedGlassIndicator, and GlassSpring.

import 'package:cupertino_ui/cupertino_ui.dart';

import '../../../constants/glass_defaults.dart';
import '../../renderer/liquid_glass_renderer.dart';
import '../../types/glass_interaction_behavior.dart';
import '../../../theme/glass_theme.dart';
import '../../../types/glass_quality.dart';
import '../../../types/glass_style.dart';
import '../../../utils/draggable_indicator_physics.dart';
import '../../../utils/glass_spring.dart';
import '../../../widgets/shared/animated_glass_indicator.dart';
import '../../../widgets/surfaces/glass_tab_bar.dart' show GlassSegment;
import '../../../widgets/shared/glass_focus_region.dart';

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
    this.activeSelectedColor,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.indicatorBorderRadius,
    required this.quality,
    this.direction = Axis.horizontal,
    this.indicatorSettings,
    this.indicatorPinchStrength = 0.4,
    this.indicatorExpansion = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ),
    this.backgroundKey,
    this.interactionBehavior = GlassInteractionBehavior.full,
    this.glowColor,
    this.glowRadius = 1.5,
    super.key,
  });

  /// List of segments to display. Each [GlassSegment] may have a label, an icon,
  /// or both. Minimum 2 segments required.
  final List<GlassSegment> segments;
  final int selectedIndex;
  final ValueChanged<int> onSegmentSelected;
  final TextStyle? selectedTextStyle;
  final TextStyle? unselectedTextStyle;
  final Color? activeSelectedColor;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final Color? indicatorColor;
  final LiquidGlassSettings? indicatorSettings;

  /// Maximum concave lens pinch strength. Forwarded to [AnimatedGlassIndicator].
  final double indicatorPinchStrength;

  /// Expansion padding applied to the pill during drag — mirrors [GlassTabBar.bottom].
  final EdgeInsetsGeometry indicatorExpansion;
  final double borderRadius;
  final double? indicatorBorderRadius;
  final GlassQuality quality;
  final Axis direction;
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
  // Colours are resolved dynamically in build() based on CupertinoTheme

  // ── Gesture state ─────────────────────────────────────────────────────────
  bool _isDown = false;
  bool _isDragging = false;

  /// Current main-axis alignment of the indicator in the range [-1, 1].
  late double _mainAlign = _computeAlignmentForSegment(widget.selectedIndex);

  late List<ValueNotifier<bool>> _focusNotifiers;
  late List<ValueNotifier<bool>> _hoverNotifiers;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initNotifiers();
  }

  void _initNotifiers() {
    _focusNotifiers = List.generate(
      widget.segments.length,
      (_) => ValueNotifier<bool>(false),
    );
    _hoverNotifiers = List.generate(
      widget.segments.length,
      (_) => ValueNotifier<bool>(false),
    );
  }

  void _disposeNotifiers() {
    for (final notifier in _focusNotifiers) {
      notifier.dispose();
    }
    for (final notifier in _hoverNotifiers) {
      notifier.dispose();
    }
  }

  @override
  void dispose() {
    _disposeNotifiers();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SegmentedControlContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.segments.length != widget.segments.length) {
      setState(() {
        _mainAlign = _computeAlignmentForSegment(widget.selectedIndex);
      });
    }
    if (oldWidget.segments.length != widget.segments.length) {
      _disposeNotifiers();
      _initNotifiers();
    }
  }

  // ── Coordinate helpers ────────────────────────────────────────────────────

  /// Converts a segment index to main-axis alignment (-1 to 1).
  double _computeAlignmentForSegment(int segmentIndex) {
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
      direction: widget.direction,
    );
  }

  // ── Gesture handlers ──────────────────────────────────────────────────────

  void _onDragDown(DragDownDetails details) {
    setState(() => _isDown = true);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final nextAlignment = _getAlignmentFromGlobalPosition(
      details.globalPosition,
    );
    setState(() {
      _isDragging = true;
      _mainAlign = nextAlignment;
    });
  }

  void _onDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _isDown = false;
    });

    final box = context.findRenderObject()! as RenderBox;
    final currentRelative = (_mainAlign + 1) / 2;
    final segmentWidth = 1.0 / widget.segments.length;
    final indicatorWidth = 1.0 / widget.segments.length;
    final draggableRange = 1.0 - indicatorWidth;
    final mainVelocity = widget.direction == Axis.horizontal
        ? details.velocity.pixelsPerSecond.dx
        : details.velocity.pixelsPerSecond.dy;
    final mainExtent = widget.direction == Axis.horizontal
        ? box.size.width
        : box.size.height;
    final velocityX = (mainVelocity / mainExtent) / draggableRange;

    final targetSegmentIndex = DraggableIndicatorPhysics.computeTargetIndex(
      currentRelativeX: currentRelative,
      velocityX: velocityX,
      itemWidth: segmentWidth,
      itemCount: widget.segments.length,
    );

    _mainAlign = _computeAlignmentForSegment(targetSegmentIndex);

    if (targetSegmentIndex != widget.selectedIndex) {
      widget.onSegmentSelected(targetSegmentIndex);
    }
  }

  void _onDragCancel() {
    if (_isDragging) {
      final currentRelative = (_mainAlign + 1) / 2;
      final targetSegmentIndex = DraggableIndicatorPhysics.computeTargetIndex(
        currentRelativeX: currentRelative,
        velocityX: 0,
        itemWidth: 1.0 / widget.segments.length,
        itemCount: widget.segments.length,
      );
      setState(() {
        _isDragging = false;
        _isDown = false;
        _mainAlign = _computeAlignmentForSegment(targetSegmentIndex);
      });
      if (targetSegmentIndex != widget.selectedIndex) {
        widget.onSegmentSelected(targetSegmentIndex);
      }
    } else {
      setState(
        () => _mainAlign = _computeAlignmentForSegment(widget.selectedIndex),
      );
    }
  }

  void _onSegmentTap(int index) {
    if (!widget.segments[index].enabled) return;
    if (index != widget.selectedIndex) {
      widget.onSegmentSelected(index);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  static const _defaultDarkIndicatorColor = Color(
    0x4DEBEBF5,
  ); // rgba(235, 235, 245, 0.30)
  static const _defaultLightIndicatorShadow = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    final isLight = GlassTheme.brightnessOf(context) == Brightness.light;
    final themeStyle = GlassTheme.maybeOf(context)?.data.style;
    final isNativeTheme =
        themeStyle == GlassStyle.ios27 || themeStyle == GlassStyle.ios26;
    final rawIndicatorColor =
        widget.indicatorColor ??
        (isLight ? CupertinoColors.white : _defaultDarkIndicatorColor);
    final indicatorColor = CupertinoDynamicColor.resolve(
      rawIndicatorColor,
      context,
    );
    final restingShadows =
        (!isNativeTheme &&
            isLight &&
            widget.indicatorColor == null &&
            !_isDragging &&
            !_isDown)
        ? _defaultLightIndicatorShadow
        : null;
    final targetAlignment = _computeAlignmentForSegment(widget.selectedIndex);

    // Indicator is slightly less rounded than the container to account for
    // the inset padding (2 px), unless explicitly overridden.
    // If the outer container is a perfect capsule (e.g. 9999.0), the indicator
    // is also a perfect capsule.
    final indicatorRadius =
        widget.indicatorBorderRadius ??
        (widget.borderRadius >= GlassDefaults.capsuleRadius
            ? GlassDefaults.capsuleRadius
            : (widget.borderRadius - 2.0).clamp(
                0.0,
                GlassDefaults.capsuleRadius,
              ));

    final dynamicLabelColor = CupertinoDynamicColor.resolve(
      CupertinoTheme.of(context).textTheme.textStyle.color ??
          CupertinoColors.label,
      context,
    );

    final baseSelectedTextStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: dynamicLabelColor,
    ).merge(widget.selectedTextStyle);
    final restingSelectedTextColor = CupertinoDynamicColor.resolve(
      baseSelectedTextStyle.color ?? dynamicLabelColor,
      context,
    );
    final selectedTextStyle = baseSelectedTextStyle.copyWith(
      color: restingSelectedTextColor,
    );

    final defaultUnselectedColor = isNativeTheme
        ? dynamicLabelColor
        : dynamicLabelColor.withValues(alpha: 0.6);
    final unselectedTextStyle = TextStyle(
      fontSize: 13,
      fontWeight: isNativeTheme ? FontWeight.w400 : FontWeight.w500,
      color: defaultUnselectedColor,
    ).merge(widget.unselectedTextStyle);
    final restingUnselectedTextColor = CupertinoDynamicColor.resolve(
      unselectedTextStyle.color ?? defaultUnselectedColor,
      context,
    );

    final restingSelectedIconColor = CupertinoDynamicColor.resolve(
      widget.selectedIconColor ?? restingSelectedTextColor,
      context,
    );
    final unselectedIconColor = CupertinoDynamicColor.resolve(
      widget.unselectedIconColor ?? restingUnselectedTextColor,
      context,
    );

    // Active-lens foreground contrast: as the solid resting pill dissolves into
    // the clear refractive glass lens (thickness: 0.0 → 0.15), an opaque
    // luminance-inverted pill (dark pill in Light Mode or light pill in Dark
    // Mode) automatically interpolates the selected text/icon color to
    // dynamicLabelColor unless overridden via activeSelectedColor.
    final isIndicatorInverted =
        widget.indicatorColor != null &&
        indicatorColor.a >= 0.5 &&
        (isLight
            ? indicatorColor.computeLuminance() < 0.5
            : indicatorColor.computeLuminance() > 0.5);
    final isTextColorInverted = isLight
        ? restingSelectedTextColor.computeLuminance() > 0.5
        : restingSelectedTextColor.computeLuminance() < 0.5;
    final isIconColorInverted = isLight
        ? restingSelectedIconColor.computeLuminance() > 0.5
        : restingSelectedIconColor.computeLuminance() < 0.5;
    final resolvedActiveSelectedColor = widget.activeSelectedColor != null
        ? CupertinoDynamicColor.resolve(widget.activeSelectedColor!, context)
        : null;
    final lensSelectedTextColor =
        resolvedActiveSelectedColor ??
        (isIndicatorInverted && isTextColorInverted
            ? dynamicLabelColor
            : restingSelectedTextColor);
    final lensSelectedIconColor =
        resolvedActiveSelectedColor ??
        (isIndicatorInverted && isIconColorInverted
            ? dynamicLabelColor
            : restingSelectedIconColor);
    final needsLensColorShift =
        lensSelectedTextColor != restingSelectedTextColor ||
        lensSelectedIconColor != restingSelectedIconColor;

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
        excludeFromSemantics: true,
        onHorizontalDragDown: widget.direction == Axis.horizontal
            ? _onDragDown
            : null,
        onHorizontalDragUpdate: widget.direction == Axis.horizontal
            ? _onDragUpdate
            : null,
        onHorizontalDragEnd: widget.direction == Axis.horizontal
            ? _onDragEnd
            : null,
        onHorizontalDragCancel: widget.direction == Axis.horizontal
            ? _onDragCancel
            : null,
        onVerticalDragDown: widget.direction == Axis.vertical
            ? _onDragDown
            : null,
        onVerticalDragUpdate: widget.direction == Axis.vertical
            ? _onDragUpdate
            : null,
        onVerticalDragEnd: widget.direction == Axis.vertical
            ? _onDragEnd
            : null,
        onVerticalDragCancel: widget.direction == Axis.vertical
            ? _onDragCancel
            : null,
        child: VelocitySpringBuilder(
          value: _mainAlign,
          springWhenActive: GlassSpring.interactive(),
          springWhenReleased: GlassSpring.snappy(
            duration: const Duration(milliseconds: 350),
          ),
          active: _isDragging,
          builder: (context, value, velocity, _) {
            final alignment = widget.direction == Axis.horizontal
                ? AlignmentDirectional(value, 0)
                : Alignment(0, value);
            final alignmentDelta = value - targetAlignment;
            final isMoving = alignmentDelta.abs() > 0.05;

            return SpringBuilder(
              spring: GlassSpring.snappy(
                duration: const Duration(milliseconds: 300),
              ),
              // Show glass bloom when: pressed, dragging, OR indicator is still
              // settling toward its target. Threshold 0.05 matches
              // tab_bar_internal.dart for consistent cross-component behaviour.
              value: _isDown || isMoving ? 1.0 : 0.0,
              builder: (context, thickness, child) {
                final isPremiumQuality = widget.quality == GlassQuality.premium;
                // While the indicator is in transit to a newly selected segment
                // (isMoving), the resting pill is not underneath selectedIndex
                // yet even on the first frame before thickness ramps to 0.15.
                final glassPhase = isMoving
                    ? 1.0
                    : (thickness / 0.15).clamp(0.0, 1.0);
                final effectiveSegmentsChild =
                    (needsLensColorShift && glassPhase > 0.0)
                    ? _buildSegmentsFlex(
                        selectedStyle: selectedTextStyle.copyWith(
                          color: Color.lerp(
                            restingSelectedTextColor,
                            lensSelectedTextColor,
                            glassPhase,
                          ),
                        ),
                        unselectedStyle: unselectedTextStyle,
                        selectedIconColor: Color.lerp(
                          restingSelectedIconColor,
                          lensSelectedIconColor,
                          glassPhase,
                        )!,
                        unselectedIconColor: unselectedIconColor,
                        animateSelectedTextStyle: false,
                      )
                    : child!;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Pass 1 — solid background pill, always below labels.
                    // For non-premium quality the glass effect is also included
                    // here (single-pass, cheaper path).
                    AnimatedGlassIndicator(
                      velocity: velocity,
                      itemCount: widget.segments.length,
                      alignment: alignment,
                      direction: widget.direction,
                      thickness: thickness,
                      quality: widget.quality,
                      indicatorColor: indicatorColor,
                      isBackgroundIndicator: false,
                      borderRadius: indicatorRadius,
                      paintBackground: true,
                      paintGlass: !isPremiumQuality,
                      shadows: restingShadows,
                      settings: widget.indicatorSettings,
                      pinchStrength: widget.indicatorPinchStrength,
                      expansion: widget.indicatorExpansion,
                      backgroundKey: widget.backgroundKey,
                    ),
                    // Segment labels paint between the two indicator passes so
                    // the premium glass layer above can refract them.
                    effectiveSegmentsChild,
                    // Pass 2 (premium only) — glass-only pass rendered ABOVE
                    // the labels so the shader samples and refracts them,
                    // matching the iOS 26 refraction seen in GlassTabBar.
                    if (isPremiumQuality)
                      AnimatedGlassIndicator(
                        velocity: velocity,
                        itemCount: widget.segments.length,
                        alignment: alignment,
                        direction: widget.direction,
                        thickness: thickness,
                        quality: widget.quality,
                        indicatorColor: indicatorColor,
                        isBackgroundIndicator: false,
                        borderRadius: indicatorRadius,
                        paintBackground: false,
                        paintGlass: true,
                        settings: widget.indicatorSettings,
                        pinchStrength: widget.indicatorPinchStrength,
                        expansion: widget.indicatorExpansion,
                        backgroundKey: widget.backgroundKey,
                      ),
                  ],
                );
              },
              child: _buildSegmentsFlex(
                selectedStyle: selectedTextStyle,
                unselectedStyle: unselectedTextStyle,
                selectedIconColor: restingSelectedIconColor,
                unselectedIconColor: unselectedIconColor,
                animateSelectedTextStyle: true,
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Segment content builder ───────────────────────────────────────────────

  Widget _buildSegmentsFlex({
    required TextStyle selectedStyle,
    required TextStyle unselectedStyle,
    required Color selectedIconColor,
    required Color unselectedIconColor,
    required bool animateSelectedTextStyle,
  }) {
    return Flex(
      direction: widget.direction,
      children: [
        for (var i = 0; i < widget.segments.length; i++)
          Expanded(
            child: RepaintBoundary(
              child: GestureDetector(
                excludeFromSemantics: true,
                onTap: () => _onSegmentTap(i),
                onTapDown: (_) {
                  if (!widget.segments[i].enabled) return;
                  if (i != widget.selectedIndex) {
                    widget.onSegmentSelected(i);
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: GlassFocusRegion(
                  enabled: widget.segments[i].enabled,
                  isButton: true,
                  tracksSelection: true,
                  isSelected: widget.selectedIndex == i,
                  semanticLabel:
                      widget.segments[i].semanticLabel ??
                      widget.segments[i].label,
                  onKeyboardActivate: () => _onSegmentTap(i),
                  semanticOnTap: () => _onSegmentTap(i),
                  isFocusedNotifier: _focusNotifiers[i],
                  isHoveredNotifier: _hoverNotifiers[i],
                  shape: const LiquidRoundedRectangle(borderRadius: 8.0),
                  child: Center(
                    child: IgnorePointer(
                      ignoring: !widget.segments[i].enabled,
                      child: Opacity(
                        opacity: widget.segments[i].enabled ? 1.0 : 0.38,
                        child: _buildSegmentContent(
                          widget.segments[i],
                          isSelected: widget.selectedIndex == i,
                          selectedStyle: selectedStyle,
                          unselectedStyle: unselectedStyle,
                          selectedIconColor: selectedIconColor,
                          unselectedIconColor: unselectedIconColor,
                          animateStyle:
                              !(widget.selectedIndex == i &&
                                  !animateSelectedTextStyle),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Builds the content for a single segment — label only, icon only, or both.
  Widget _buildSegmentContent(
    GlassSegment tab, {
    required bool isSelected,
    required TextStyle selectedStyle,
    required TextStyle unselectedStyle,
    required Color selectedIconColor,
    required Color unselectedIconColor,
    required bool animateStyle,
  }) {
    final style = isSelected ? selectedStyle : unselectedStyle;
    final iconColor = isSelected ? selectedIconColor : unselectedIconColor;
    final styleDuration = animateStyle
        ? const Duration(milliseconds: 200)
        : Duration.zero;
    final hasLabel = tab.label != null && tab.label!.isNotEmpty;
    final hasIcon = tab.icon != null;

    if (hasIcon && hasLabel) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconTheme(
            data: IconThemeData(color: iconColor, size: 16),
            child: tab.icon!,
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: styleDuration,
            style: style,
            child: Text(
              tab.label!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }

    if (hasIcon) {
      return IconTheme(
        data: IconThemeData(color: iconColor, size: 20),
        child: tab.icon!,
      );
    }

    return AnimatedDefaultTextStyle(
      duration: styleDuration,
      style: style,
      child: Text(
        tab.label ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
