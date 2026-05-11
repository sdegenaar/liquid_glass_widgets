import 'package:flutter/material.dart';

import '../../constants/glass_defaults.dart';
import '../../src/renderer/liquid_glass_renderer.dart';
import '../../src/types/glass_interaction_behavior.dart';
import '../../theme/glass_theme_helpers.dart';
import '../../types/glass_quality.dart';
import '../shared/adaptive_liquid_glass_layer.dart';
import 'shared/segmented_control_internal.dart';

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
    this.quality,
    this.backgroundKey,
    // ── iOS 26 interaction ──────────────────────────────────────────────────
    this.interactionBehavior = GlassInteractionBehavior.full,
    this.glowColor,
    this.glowRadius = 1.5,
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
  ///
  /// > **Note (iOS-style behaviour):** This callback may fire during a
  /// > *cancelled* gesture if the drag indicator travelled far enough to
  /// > snap to a different segment before the cancel arrived. This matches
  /// > `UISegmentedControl` semantics. If you need strict tap-only selection,
  /// > compare the received index against `selectedIndex` before acting.
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
  final GlassQuality? quality;

  /// Optional background key for Skia/Web refraction.
  final GlobalKey? backgroundKey;

  // ── iOS 26 interaction ────────────────────────────────────────────────────

  /// Controls which iOS 26 interaction effects are active on the indicator.
  ///
  /// | Value | Glow on press/drag |
  /// |---|---|
  /// | `none` | ✗ |
  /// | `glowOnly` | ✓ |
  /// | `scaleOnly` | ✗ |
  /// | `full` *(default)* | ✓ |
  ///
  /// Set to [GlassInteractionBehavior.none] to suppress the glow entirely.
  final GlassInteractionBehavior interactionBehavior;

  /// Colour of the press/drag glow on the indicator pill.
  ///
  /// Only active when [interactionBehavior] includes glow. Defaults to a
  /// soft white (~12% opacity) — same as [GlassTextField].
  final Color? glowColor;

  /// Spread radius of the glow relative to the indicator's shorter dimension.
  ///
  /// Defaults to `1.5` (150%), matching [GlassTextField].
  final double glowRadius;

  @override
  State<GlassSegmentedControl> createState() => _GlassSegmentedControlState();
}

class _GlassSegmentedControlState extends State<GlassSegmentedControl> {
  // Cache default background color to avoid allocations
  static const _defaultBackgroundColor = Color(0x1FFFFFFF); // Colors.white12

  @override
  Widget build(BuildContext context) {
    // Inherit quality from parent layer if not explicitly set
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
    );

    // Use custom glass settings or optimized defaults
    final glassSettings = widget.glassSettings ??
        const LiquidGlassSettings(
          thickness: GlassDefaults.thickness,
          blur: GlassDefaults.blur,
          chromaticAberration: GlassDefaults.chromaticAberration,
          lightIntensity: GlassDefaults.lightIntensity,
          refractiveIndex: GlassDefaults.refractiveIndex,
          lightAngle: GlassDefaults.lightAngle,
        );

    final backgroundColor = widget.backgroundColor ?? _defaultBackgroundColor;

    // Build the control
    final control = Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      padding: widget.padding,
      child: SegmentedControlContent(
        segments: widget.segments,
        selectedIndex: widget.selectedIndex,
        onSegmentSelected: widget.onSegmentSelected,
        selectedTextStyle: widget.selectedTextStyle,
        unselectedTextStyle: widget.unselectedTextStyle,
        indicatorColor: widget.indicatorColor,
        indicatorSettings: widget.indicatorSettings,
        borderRadius: widget.borderRadius,
        quality: effectiveQuality,
        backgroundKey: widget.backgroundKey,
        interactionBehavior: widget.interactionBehavior,
        glowColor: widget.glowColor,
        glowRadius: widget.glowRadius,
      ),
    );

    // Isolate from parent glass containers (e.g., GlassCard)
    // Prevents indicator animations from triggering parent BackdropFilter recomposition
    final isolatedControl = RepaintBoundary(child: control);

    // Wrap with layer if needed
    if (widget.useOwnLayer) {
      return AdaptiveLiquidGlassLayer(
        settings: glassSettings,
        quality: effectiveQuality,
        child: isolatedControl,
      );
    }

    return isolatedControl;
  }
}
