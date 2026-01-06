import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart'
    hide FakeGlass;

import '../../types/glass_quality.dart';
import '../shared/adaptive_glass.dart';
import '../shared/inherited_liquid_glass.dart';

/// A foundational glass container widget following Apple's liquid glass design.
///
/// This is the base primitive for all container-based glass widgets. It
/// provides a simple glass surface with configurable dimensions, padding,
/// and shape.
///
/// ## Usage Modes
///
/// ### Grouped Mode (default)
/// Uses [LiquidGlass.grouped] and inherits settings from parent
/// [LiquidGlassLayer]:
/// ```dart
/// AdaptiveLiquidGlassLayer(
///   settings: LiquidGlassSettings(...),
///   child: Column(
///     children: [
///       GlassContainer(
///         child: Text('Hello'),
///       ),
///       GlassContainer(
///         child: Text('World'),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ### Standalone Mode
/// Creates its own layer with [LiquidGlass.withOwnLayer]:
/// ```dart
/// GlassContainer(
///   useOwnLayer: true,
///   settings: LiquidGlassSettings(
///     thickness: 30,
///     blur: 10,
///   ),
///   child: Text('Standalone'),
/// )
/// ```
///
/// ## Customization Examples
///
/// ### Custom padding and shape:
/// ```dart
/// GlassContainer(
///   padding: EdgeInsets.all(20),
///   shape: LiquidRoundedSuperellipse(borderRadius: 16),
///   child: Text('Padded content'),
/// )
/// ```
///
/// ### With constraints:
/// ```dart
/// GlassContainer(
///   width: 200,
///   height: 100,
///   child: Center(child: Text('Fixed size')),
/// )
/// ```
///
/// ### With clipping:
/// ```dart
/// GlassContainer(
///   clipBehavior: Clip.antiAlias,
///   child: Image.network('...'),
/// )
/// ```
class GlassContainer extends StatelessWidget {
  /// Creates a glass container.
  const GlassContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.shape = const LiquidRoundedSuperellipse(borderRadius: 16),
    this.settings,
    this.useOwnLayer = false,
    this.quality = GlassQuality.standard,
    this.clipBehavior = Clip.none,
    this.alignment,
    this.allowElevation = false,
  });

  // ===========================================================================
  // Content Properties
  // ===========================================================================

  /// The widget below this widget in the tree.
  ///
  /// This is the content that will be displayed inside the glass container.
  final Widget? child;

  /// The alignment of the [child] within the container.
  ///
  /// If null, the child is positioned according to its natural size.
  final AlignmentGeometry? alignment;

  // ===========================================================================
  // Sizing Properties
  // ===========================================================================

  /// Width of the container in logical pixels.
  ///
  /// If null, the container will size itself to fit its child.
  final double? width;

  /// Height of the container in logical pixels.
  ///
  /// If null, the container will size itself to fit its child.
  final double? height;

  /// Empty space to inscribe inside the glass container.
  ///
  /// The child is placed inside this padding.
  final EdgeInsetsGeometry? padding;

  /// Empty space to surround the glass container.
  ///
  /// The glass effect is not applied to the margin area.
  final EdgeInsetsGeometry? margin;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Shape of the glass container.
  ///
  /// Can be [LiquidOval], [LiquidRoundedRectangle], or
  /// [LiquidRoundedSuperellipse].
  ///
  /// Defaults to [LiquidRoundedSuperellipse] with 16px border radius, matching
  /// Apple's standard corner radius for cards and containers.
  final LiquidShape shape;

  /// Glass effect settings (only used when [useOwnLayer] is true).
  ///
  /// Controls the visual appearance of the glass effect including thickness,
  /// blur radius, color tint, lighting, and more.
  ///
  /// If null when [useOwnLayer] is true, uses [LiquidGlassSettings] defaults.
  /// Ignored when [useOwnLayer] is false (inherits from parent layer).
  final LiquidGlassSettings? settings;

  /// Whether to create its own layer or use grouped glass within an existing
  /// layer.
  ///
  /// - `false` (default): Uses [LiquidGlass.grouped], must be inside a
  /// [LiquidGlassLayer]. This is more performant when you have multiple glass
  /// elements that can share the same rendering context.
  ///
  /// - `true`: Uses [LiquidGlass.withOwnLayer], can be used anywhere.
  ///   Creates an independent glass rendering context for this container.
  ///
  /// Defaults to false.
  final bool useOwnLayer;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.standard], which uses the lightweight fragment
  /// shader. This is 5-10x faster than BackdropFilter and works reliably in
  /// all contexts, including scrollable lists.
  ///
  /// Use [GlassQuality.premium] for full-pipeline shader with texture capture
  /// and chromatic aberration (Impeller only) in static layouts.
  final GlassQuality quality;

  /// The clipping behavior for the container.
  ///
  /// Controls how content is clipped at the container's bounds:
  /// - [Clip.none]: No clipping (default, best performance)
  /// - [Clip.antiAlias]: Smooth anti-aliased clipping
  /// - [Clip.hardEdge]: Sharp clipping without anti-aliasing
  ///
  /// Use [Clip.antiAlias] or [Clip.hardEdge] when the child extends beyond
  /// the container's bounds (e.g., images, overflowing content).
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  /// Whether to allow elevation effects when in a grouped context.
  ///
  /// When false (default), the container won't darken or add rim effects
  /// when inside another glass container. This is correct for most containers
  /// as they are surfaces, not interactive elements.
  ///
  /// Set to true only for special cases where elevation is needed.
  ///
  /// Defaults to false.
  final bool allowElevation;

  @override
  Widget build(BuildContext context) {
    // 1. Start with the child content
    var content = child ?? const SizedBox.shrink();

    // 2. Apply padding inside the container (before glass effect)
    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    // 3. Apply alignment if provided
    if (alignment != null) {
      content = Align(
        alignment: alignment!,
        child: content,
      );
    }

    // 4. Apply glass effect with adaptive fallback
    // Premium quality uses Impeller on iOS/macOS, falls back to lightweight shader on web
    // Standard quality always uses lightweight shader
    Widget glassWidget = AdaptiveGlass(
      shape: shape,
      settings: settings ?? InheritedLiquidGlass.ofOrDefault(context),
      quality: quality,
      useOwnLayer: useOwnLayer,
      clipBehavior: clipBehavior,
      allowElevation: allowElevation, // Configurable elevation behavior
      child: content,
    );

    // 5. Apply width/height constraints
    if (width != null || height != null) {
      glassWidget = SizedBox(
        width: width,
        height: height,
        child: glassWidget,
      );
    }

    // 6. Apply margin outside the glass effect
    if (margin != null) {
      glassWidget = Padding(
        padding: margin!,
        child: glassWidget,
      );
    }

    return glassWidget;
  }
}
