import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import 'glass_container.dart';

/// A glass card widget following Apple's card design patterns.
///
/// [GlassCard] builds upon [GlassContainer] with opinionated defaults for
/// card-like content containers, matching iOS design guidelines.
///
/// This widget provides standard card styling:
/// - Default padding of 16px (matching iOS card insets)
/// - Rounded superellipse corners with 12px radius
/// - Suitable for displaying grouped content
///
/// ## Usage Modes
///
/// ### Grouped Mode (default)
/// Uses [LiquidGlass.grouped] and inherits settings from parent
/// [LiquidGlassLayer]:
/// ```dart
/// AdaptiveLiquidGlassLayer(
///   settings: LiquidGlassSettings(...),
///   child: ListView(
///     children: [
///       GlassCard(
///         child: ListTile(
///           title: Text('Item 1'),
///           subtitle: Text('Description'),
///         ),
///       ),
///       GlassCard(
///         child: ListTile(
///           title: Text('Item 2'),
///           subtitle: Text('Description'),
///         ),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ### Standalone Mode
/// Creates its own layer with [LiquidGlass.withOwnLayer]:
/// ```dart
/// GlassCard(
///   useOwnLayer: true,
///   settings: LiquidGlassSettings(
///     thickness: 30,
///     blur: 10,
///   ),
///   child: Column(
///     children: [
///       Text('Title'),
///       Text('Content'),
///     ],
///   ),
/// )
/// ```
///
/// ## Customization Examples
///
/// ### No padding (full-width content):
/// ```dart
/// GlassCard(
///   padding: EdgeInsets.zero,
///   child: Image.network('...'),
/// )
/// ```
///
/// ### Custom shape and padding:
/// ```dart
/// GlassCard(
///   padding: EdgeInsets.all(24),
///   shape: LiquidRoundedSuperellipse(borderRadius: 20),
///   child: Text('Custom card'),
/// )
/// ```
///
/// ### With margin between cards:
/// ```dart
/// GlassCard(
///   margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
///   child: Text('Card with margin'),
/// )
/// ```
class GlassCard extends StatelessWidget {
  /// Creates a glass card.
  const GlassCard({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.shape = _defaultShape,
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
  /// This is the content that will be displayed inside the card.
  final Widget? child;

  // ===========================================================================
  // Sizing Properties
  // ===========================================================================

  /// Width of the card in logical pixels.
  ///
  /// If null, the card will size itself to fit its child.
  final double? width;

  /// Height of the card in logical pixels.
  ///
  /// If null, the card will size itself to fit its child.
  final double? height;

  /// Empty space to inscribe inside the card.
  ///
  /// The child is placed inside this padding.
  ///
  /// Defaults to 16px on all sides (matching iOS card insets).
  final EdgeInsetsGeometry padding;

  /// Empty space to surround the card.
  ///
  /// The glass effect is not applied to the margin area.
  ///
  /// Defaults to null (no margin).
  final EdgeInsetsGeometry? margin;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Shape of the card.
  ///
  /// Can be [LiquidOval], [LiquidRoundedRectangle], or
  /// [LiquidRoundedSuperellipse].
  ///
  /// Defaults to [LiquidRoundedSuperellipse] with 12px border radius, matching
  /// Apple's standard card corner radius.
  final LiquidShape shape;

  static const _defaultShape = LiquidRoundedSuperellipse(borderRadius: 12);

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
  ///   Creates an independent glass rendering context for this card.
  ///
  /// Defaults to false.
  final bool useOwnLayer;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.standard], which uses the lightweight fragment
  /// shader. This works reliably in all contexts, including scrollable lists.
  ///
  /// Use [GlassQuality.premium] for full-pipeline shader with texture capture
  /// and chromatic aberration (Impeller only) in static layouts.
  final GlassQuality quality;

  /// The clipping behavior for the card.
  ///
  /// Controls how content is clipped at the card's bounds:
  /// - [Clip.none]: No clipping (default, best performance)
  /// - [Clip.antiAlias]: Smooth anti-aliased clipping
  /// - [Clip.hardEdge]: Sharp clipping without anti-aliasing
  ///
  /// Use [Clip.antiAlias] or [Clip.hardEdge] when the child extends beyond
  /// the card's bounds (e.g., images, overflowing content).
  ///
  /// Defaults to [Clip.none].
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    // Build upon GlassContainer with card-specific defaults
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
