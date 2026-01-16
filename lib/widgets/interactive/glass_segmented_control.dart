import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:motor/motor.dart';

import '../../constants/glass_defaults.dart';
import '../../types/glass_quality.dart';
import '../../utils/draggable_indicator_physics.dart';
import '../shared/adaptive_liquid_glass_layer.dart';
import '../shared/animated_glass_indicator.dart';

/// A glass morphism segmented control following Apple's design patterns.
///
/// [GlassSegmentedControl] provides a sophisticated segmented control with
/// an animated glass indicator, jelly physics, and smooth transitions between
/// segments. It matches iOS's UISegmentedControl appearance and behavior.
///
/// ## Key Features
///
/// - **Animated Glass Indicator**: Smoothly animates between segments
/// - **Jelly Physics**: Organic squash and stretch effects during movement
/// - **Drag Support**: Swipe between segments with velocity-based snapping
/// - **Sharp Text**: Selected text stays sharp above the glass
/// - **Flexible Sizing**: Automatically sizes segments evenly
/// - **Customizable Appearance**: Full control over colors, sizes, and effects
///
/// ## Performance Note
///
/// When placing inside glass containers (GlassCard, GlassPanel) with blur,
/// use one of these approaches for best performance:
/// - Set parent container to `quality: GlassQuality.premium` (no BackdropFilter)
/// - Or set parent settings to `blur: 0` (skips BackdropFilter)
/// - Or place outside glass containers (like bottom bars)
///
/// Standard quality glass containers with blur may show minor flicker during
/// indicator animations due to BackdropFilter recomposition.
///
/// ## Usage
///
/// ### Basic Usage
/// ```dart
/// int selectedIndex = 0;
///
/// GlassSegmentedControl(
///   segments: ['Daily', 'Weekly', 'Monthly'],
///   selectedIndex: selectedIndex,
///   onSegmentSelected: (index) {
///     setState(() => selectedIndex = index);
///   },
/// )
/// ```
///
/// ### Within LiquidGlassLayer (Grouped Mode)
/// ```dart
/// AdaptiveLiquidGlassLayer(
///   settings: LiquidGlassSettings(
///     thickness: 30,
///     blur: 3,
///     refractiveIndex: 1.59,
///   ),
///   child: Column(
///     children: [
///       GlassSegmentedControl(
///         segments: ['One', 'Two', 'Three'],
///         selectedIndex: _selectedIndex,
///         onSegmentSelected: (index) {
///           setState(() => _selectedIndex = index);
///         },
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ### Standalone Mode
/// ```dart
/// GlassSegmentedControl(
///   segments: ['Option A', 'Option B'],
///   selectedIndex: _selectedIndex,
///   onSegmentSelected: (index) {
///     setState(() => _selectedIndex = index);
///   },
///   useOwnLayer: true,
///   settings: LiquidGlassSettings(
///     thickness: 30,
///     blur: 3,
///   ),
/// )
/// ```
///
/// ### Custom Styling
/// ```dart
/// GlassSegmentedControl(
///   segments: ['Small', 'Medium', 'Large'],
///   selectedIndex: _selectedIndex,
///   onSegmentSelected: (index) {
///     setState(() => _selectedIndex = index);
///   },
///   height: 36,
///   borderRadius: 18,
///   selectedTextStyle: TextStyle(
///     fontSize: 14,
///     fontWeight: FontWeight.w600,
///     color: Colors.white,
///   ),
///   unselectedTextStyle: TextStyle(
///     fontSize: 14,
///     fontWeight: FontWeight.w500,
///     color: Colors.white.withOpacity(0.6),
///   ),
/// )
/// ```
class GlassSegmentedControl extends StatefulWidget {
  /// Creates a glass segmented control.
  const GlassSegmentedControl({
    required this.segments,
    required this.selectedIndex,
    required this.onSegmentSelected,
    super.key,
    this.height = GlassDefaults.heightControl,
    this.borderRadius = GlassDefaults.borderRadius,
    this.padding = const EdgeInsets.all(2),
    this.selectedTextStyle,
    this.unselectedTextStyle,
    this.backgroundColor,
    this.indicatorColor,
    this.indicatorSettings,
    this.glassSettings,
    this.useOwnLayer = false,
    this.quality = GlassQuality.standard,
    this.backgroundKey,
  })  : assert(
          segments.length >= 2,
          'GlassSegmentedControl requires at least 2 segments',
        ),
        assert(
          selectedIndex >= 0 && selectedIndex < segments.length,
          'selectedIndex must be within bounds of segments list',
        );

  // ===========================================================================
  // Segment Configuration
  // ===========================================================================

  /// List of segment labels to display.
  ///
  /// Each string represents a segment option. Minimum 2 segments required.
  final List<String> segments;

  /// Index of the currently selected segment.
  ///
  /// Must be between 0 and segments.length - 1.
  final int selectedIndex;

  /// Called when a segment is selected.
  ///
  /// Provides the index of the newly selected segment.
  final ValueChanged<int> onSegmentSelected;

  // ===========================================================================
  // Layout Properties
  // ===========================================================================

  /// Height of the segmented control.
  ///
  /// Defaults to 32 (matching iOS UISegmentedControl).
  final double height;

  /// Border radius of the segmented control.
  ///
  /// Defaults to 16 (height / 2) for a pill shape.
  final double borderRadius;

  /// Padding around the indicator inside the background.
  ///
  /// Defaults to 2 pixels on all sides.
  final EdgeInsetsGeometry padding;

  // ===========================================================================
  // Style Properties
  // ===========================================================================

  /// Text style for the selected segment.
  ///
  /// If null, uses default style with fontSize 13, fontWeight w600,
  /// and white color.
  final TextStyle? selectedTextStyle;

  /// Text style for unselected segments.
  ///
  /// If null, uses default style with fontSize 13, fontWeight w500,
  /// and white color at 60% opacity.
  final TextStyle? unselectedTextStyle;

  /// Background color of the segmented control.
  ///
  /// If null, uses a semi-transparent white (Colors.white12).
  final Color? backgroundColor;

  /// Color of the indicator when not being dragged.
  ///
  /// If null, uses a semi-transparent color from the theme.
  final Color? indicatorColor;

  /// Glass settings for the draggable indicator.
  ///
  /// If null, uses optimized defaults for the indicator:
  /// - glassColor: Color.from(alpha: 0.1, red: 1, green: 1, blue: 1)
  /// - saturation: 1.5
  /// - refractiveIndex: 1.15
  /// - thickness: 20
  /// - lightIntensity: 2
  /// - chromaticAberration: 0.5
  /// - blur: 0
  final LiquidGlassSettings? indicatorSettings;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Glass effect settings (only used when [useOwnLayer] is true).
  ///
  /// If null when [useOwnLayer] is true, uses optimized defaults:
  /// - thickness: 30
  /// - blur: 3
  /// - chromaticAberration: 0.5
  /// - lightIntensity: 2
  /// - refractiveIndex: 1.15
  final LiquidGlassSettings? glassSettings;

  /// Whether to create its own layer or use grouped glass.
  ///
  /// - `false` (default): Uses grouped glass, must be inside [LiquidGlassLayer]
  /// - `true`: Creates own layer with [LiquidGlass.withOwnLayer]
  ///
  /// Defaults to false.
  final bool useOwnLayer;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.standard] (backdrop filter).
  final GlassQuality quality;

  /// Optional background key for Skia/Web refraction.
  final GlobalKey? backgroundKey;

  @override
  State<GlassSegmentedControl> createState() => _GlassSegmentedControlState();
}

class _GlassSegmentedControlState extends State<GlassSegmentedControl> {
  // Cache default background color to avoid allocations
  static const _defaultBackgroundColor = Color(0x1FFFFFFF); // Colors.white12

  @override
  Widget build(BuildContext context) {
    // Use custom glass settings or optimized defaults
    final glassSettings = widget.glassSettings ??
        const LiquidGlassSettings(
            thickness: GlassDefaults.thickness,
            blur: GlassDefaults.blur,
            chromaticAberration: GlassDefaults.chromaticAberration,
            lightIntensity: GlassDefaults.lightIntensity,
            refractiveIndex: GlassDefaults.refractiveIndex,
            lightAngle: GlassDefaults.lightAngle);

    final backgroundColor = widget.backgroundColor ?? _defaultBackgroundColor;

    // Build the control
    final control = Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      padding: widget.padding,
      child: _SegmentedControlContent(
        segments: widget.segments,
        selectedIndex: widget.selectedIndex,
        onSegmentSelected: widget.onSegmentSelected,
        selectedTextStyle: widget.selectedTextStyle,
        unselectedTextStyle: widget.unselectedTextStyle,
        indicatorColor: widget.indicatorColor,
        indicatorSettings: widget.indicatorSettings,
        borderRadius: widget.borderRadius,
        quality: widget.quality,
        backgroundKey: widget.backgroundKey,
      ),
    );

    // Isolate from parent glass containers (e.g., GlassCard)
    // Prevents indicator animations from triggering parent BackdropFilter recomposition
    final isolatedControl = RepaintBoundary(child: control);

    // Wrap with layer if needed
    if (widget.useOwnLayer) {
      return AdaptiveLiquidGlassLayer(
        settings: glassSettings,
        quality: widget.quality,
        child: isolatedControl,
      );
    }

    return isolatedControl;
  }
}

// =============================================================================
// Internal Content Widget
// =============================================================================

/// Internal widget that manages segments and indicator.
class _SegmentedControlContent extends StatefulWidget {
  const _SegmentedControlContent({
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

  @override
  State<_SegmentedControlContent> createState() =>
      _SegmentedControlContentState();
}

class _SegmentedControlContentState extends State<_SegmentedControlContent> {
  // Cache default colors to avoid allocations
  static const _defaultIndicatorColor =
      Color(0x33FFFFFF); // white.withValues(alpha: 0.2)
  static const _defaultUnselectedTextColor =
      Color(0x99FFFFFF); // white.withValues(alpha: 0.6)

  bool _isDown = false;
  bool _isDragging = false;

  // Current horizontal alignment of the indicator (-1 to 1)
  late double _xAlign = _computeXAlignmentForSegment(widget.selectedIndex);

  @override
  void didUpdateWidget(covariant _SegmentedControlContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update alignment when segment index or count changes
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.segments.length != widget.segments.length) {
      setState(() {
        _xAlign = _computeXAlignmentForSegment(widget.selectedIndex);
      });
    }
  }

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

  void _onDragDown(DragDownDetails details) {
    setState(() {
      _isDown = true;
      _xAlign = _getAlignmentFromGlobalPosition(details.globalPosition);
    });
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

    // Convert alignment to 0-1 range
    final currentRelativeX = (_xAlign + 1) / 2;
    final segmentWidth = 1.0 / widget.segments.length;

    // Calculate velocity in relative units
    final indicatorWidth = 1.0 / widget.segments.length;
    final draggableRange = 1.0 - indicatorWidth;
    final velocityX =
        (details.velocity.pixelsPerSecond.dx / box.size.width) / draggableRange;

    // Determine target segment based on position and velocity
    final targetSegmentIndex = _computeTargetSegment(
      currentRelativeX: currentRelativeX,
      velocityX: velocityX,
      segmentWidth: segmentWidth,
    );

    // Update alignment to target segment
    _xAlign = _computeXAlignmentForSegment(targetSegmentIndex);

    // Notify parent if segment changed
    if (targetSegmentIndex != widget.selectedIndex) {
      widget.onSegmentSelected(targetSegmentIndex);
    }
  }

  /// Computes the target segment index based on drag position and velocity.
  int _computeTargetSegment({
    required double currentRelativeX,
    required double velocityX,
    required double segmentWidth,
  }) {
    return DraggableIndicatorPhysics.computeTargetIndex(
      currentRelativeX: currentRelativeX,
      velocityX: velocityX,
      itemWidth: segmentWidth,
      itemCount: widget.segments.length,
    );
  }

  void _onSegmentTap(int index) {
    if (index != widget.selectedIndex) {
      widget.onSegmentSelected(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicatorColor = widget.indicatorColor ?? _defaultIndicatorColor;
    final targetAlignment = _computeXAlignmentForSegment(widget.selectedIndex);

    // Indicator should be slightly less rounded than container for proper
    // padding
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

    return GestureDetector(
      onHorizontalDragDown: _onDragDown,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: () => setState(() {
        _isDragging = false;
        _isDown = false;
      }),
      child: VelocityMotionBuilder(
        converter: const SingleMotionConverter(),
        value: _xAlign,
        motion: _isDragging
            ? const Motion.interactiveSpring(snapToEnd: true)
            : const Motion.bouncySpring(snapToEnd: true),
        builder: (context, value, velocity, child) {
          final alignment = Alignment(value, 0);

          return SingleMotionBuilder(
            motion: const Motion.snappySpring(
              snapToEnd: true,
              duration: Duration(milliseconds: 300),
            ),
            // Show glass indicator when dragging or far from target
            value: _isDown || (alignment.x - targetAlignment).abs() > 0.15
                ? 1.0
                : 0.0,
            builder: (context, thickness, child) {
              // Wrap entire indicator stack in RepaintBoundary to prevent
              // background and glass indicators from causing separate flickers
              return RepaintBoundary(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Subtle background indicator (shown when not dragging)
                    // Parent isolation prevents flickering with GlassCard
                    // Unified Glass Indicator with jelly physics
                    // The internal cross-fade in AnimatedGlassIndicator prevents flickering
                    AnimatedGlassIndicator(
                      velocity: velocity,
                      itemCount: widget.segments.length,
                      alignment: alignment,
                      thickness: thickness,
                      quality: widget.quality,
                      indicatorColor: indicatorColor,
                      isBackgroundIndicator:
                          false, // Internal logic now handles both
                      borderRadius: indicatorRadius,
                      glassSettings: widget.indicatorSettings,
                      backgroundKey: widget.backgroundKey,
                    ),

                    // Segment labels (always on top, not affected by glass)
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
    );
  }
}

// =============================================================================
// Jelly Physics Transform
// =============================================================================

/// Applies jelly transform with organic squash and stretch based on velocity.
