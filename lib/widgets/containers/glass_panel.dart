import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import 'glass_container.dart';

/// A glass panel widget for larger surface areas following Apple's design.
///
/// [GlassPanel] builds upon [GlassContainer] with styling optimized for
/// larger content areas, modal surfaces, and full-screen containers.
///
/// This widget provides panel-specific styling:
/// - Default padding of 24px (more generous than cards)
/// - Rounded superellipse corners with 20px radius
/// - Suitable for modal dialogs, settings panels, detail views
///
/// ## Usage Modes
///
/// ### Grouped Mode (default)
/// Uses [LiquidGlass.grouped] and inherits settings from parent
/// [LiquidGlassLayer]:
/// ```dart
/// LiquidGlassLayer(
///   settings: LiquidGlassSettings(...),
///   child: Center(
///     child: GlassPanel(
///       child: Column(
///         mainAxisSize: MainAxisSize.min,
///         children: [
///           Text('Panel Title', style: TextStyle(fontSize: 24)),
///           SizedBox(height: 16),
///           Text('Panel content goes here...'),
///         ],
///       ),
///     ),
///   ),
/// )
/// ```
///
/// ### Standalone Mode
/// Creates its own layer with [LiquidGlass.withOwnLayer]:
/// ```dart
/// GlassPanel(
///   useOwnLayer: true,
///   settings: LiquidGlassSettings(
///     thickness: 40,
///     blur: 15,
///   ),
///   child: SettingsForm(),
/// )
/// ```
///
/// ## Customization Examples
///
/// ### Full-screen panel:
/// ```dart
/// GlassPanel(
///   padding: EdgeInsets.all(32),
///   shape: LiquidRoundedRectangle(borderRadius: 0), // No rounding
///   width: double.infinity,
///   height: double.infinity,
///   child: DetailView(),
/// )
/// ```
///
/// ### Modal panel:
/// ```dart
/// GlassPanel(
///   width: 400,
///   padding: EdgeInsets.all(24),
///   child: Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       Text('Confirmation'),
///       SizedBox(height: 16),
///       Text('Are you sure?'),
///       SizedBox(height: 24),
///       Row(
///         children: [
///           GlassButton(...),
///           GlassButton(...),
///         ],
///       ),
///     ],
///   ),
/// )
/// ```
class GlassPanel extends StatelessWidget {
  /// Creates a glass panel.
  const GlassPanel({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(24),
    this.margin,
    this.shape = const LiquidRoundedSuperellipse(borderRadius: 20),
    this.settings,
    this.useOwnLayer = false,
    this.quality = GlassQuality.standard,
    this.clipBehavior = Clip.none,
    this.width,
    this.height,
  });

  // ===========================================================================
  // Content Properties
  // ===========================================================================

  /// The widget below this widget in the tree.
  ///
  /// This is the content that will be displayed inside the panel.
  final Widget? child;

  // ===========================================================================
  // Sizing Properties
  // ===========================================================================

  /// Width of the panel in logical pixels.
  ///
  /// If null, the panel will size itself to fit its child.
  final double? width;

  /// Height of the panel in logical pixels.
  ///
  /// If null, the panel will size itself to fit its child.
  final double? height;

  /// Empty space to inscribe inside the panel.
  ///
  /// The child is placed inside this padding.
  ///
  /// Defaults to 24px on all sides (more generous than cards).
  final EdgeInsetsGeometry padding;

  /// Empty space to surround the panel.
  ///
  /// The glass effect is not applied to the margin area.
  ///
  /// Defaults to null (no margin).
  final EdgeInsetsGeometry? margin;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Shape of the panel.
  ///
  /// Can be [LiquidOval], [LiquidRoundedRectangle], or
  /// [LiquidRoundedSuperellipse].
  ///
  /// Defaults to [LiquidRoundedSuperellipse] with 20px border radius,
  /// suitable for larger surfaces.
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
  /// [LiquidGlassLayer].
  ///   This is more performant when you have multiple glass elements that can
  ///   share the same rendering context.
  ///
  /// - `true`: Uses [LiquidGlass.withOwnLayer], can be used anywhere.
  ///   Creates an independent glass rendering context for this panel.
  ///
  /// Defaults to false.
  final bool useOwnLayer;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.standard], which uses backdrop filter rendering.
  /// This works reliably in all contexts, including scrollable lists.
  ///
  /// Use [GlassQuality.premium] for shader-based glass in static layouts only.
  final GlassQuality quality;

  /// The clipping behavior for the panel.
  ///
  /// Controls how content is clipped at the panel's bounds:
  /// - [Clip.none]: No clipping (default, best performance)
  /// - [Clip.antiAlias]: Smooth anti-aliased clipping
  /// - [Clip.hardEdge]: Sharp clipping without anti-aliasing
  ///
  /// Use [Clip.antiAlias] or [Clip.hardEdge] when the child extends beyond
  /// the panel's bounds (e.g., images, overflowing content).
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    // Build upon GlassContainer with panel-specific defaults
    return GlassContainer(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      shape: shape,
      settings: settings,
      useOwnLayer: useOwnLayer,
      quality: quality,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
