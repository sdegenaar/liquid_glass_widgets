import 'package:flutter/cupertino.dart' show CupertinoColors;
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';

/// Glass morphism button with scale animation and glow effects.
///
/// This button provides a complete liquid glass experience with:
/// - Liquid glass visual effect with customizable settings
/// - Scale animation (squash & stretch) when pressed
/// - Touch-responsive glow effect on interaction
/// - Full control over all animation and visual properties
/// - Accessibility support with semantic labels
/// - Flexible content support (icon or custom child)
///
/// ## Usage Modes
///
/// ### Grouped Mode (default)
/// Uses [LiquidGlass.grouped] and inherits settings from parent
/// [LiquidGlassLayer]:
/// ```dart
/// LiquidGlassLayer(
///   settings: LiquidGlassSettings(...),
///   child: Column(
///     children: [
///       GlassButton(
///         icon: CupertinoIcons.heart,
///         onTap: () => print('Favorite'),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ### Standalone Mode
/// Creates its own layer with [LiquidGlass.withOwnLayer]:
/// ```dart
/// GlassButton(
///   icon: CupertinoIcons.play,
///   onTap: () => print('Play'),
///   useOwnLayer: true,
///   settings: LiquidGlassSettings(
///     thickness: 0.3,
///     blurRadius: 20,
///   ),
/// )
/// ```
///
/// ## Customization Examples
///
/// ### Custom stretch behavior:
/// ```dart
/// GlassButton(
///   icon: CupertinoIcons.star,
///   onTap: () {},
///   interactionScale: 1.1,  // Grow 10% when pressed
///   stretch: 0.8,           // More dramatic stretch
///   resistance: 0.15,       // Higher drag resistance
/// )
/// ```
///
/// ### Custom glow effect:
/// ```dart
/// GlassButton(
///   icon: CupertinoIcons.bolt,
///   onTap: () {},
///   glowColor: Colors.blue.withOpacity(0.4),
///   glowRadius: 1.5,  // Larger glow
/// )
/// ```
///
/// ### Custom content:
/// ```dart
/// GlassButton.custom(
///   onTap: () {},
///   width: 120,
///   height: 48,
///   child: Text('Click Me', style: TextStyle(color: Colors.white)),
/// )
/// ```
class GlassButton extends StatelessWidget {
  /// Creates a glass button with an icon.
  const GlassButton({
    required this.icon,
    required this.onTap,
    super.key,
    this.label = '',
    this.width = 56,
    this.height = 56,
    this.iconSize = 24.0,
    this.iconColor = Colors.white,
    this.shape = const LiquidOval(),
    this.settings,
    this.useOwnLayer = false,
    this.quality = GlassQuality.standard,
    // LiquidStretch properties
    this.interactionScale = 1.05,
    this.stretch = 0.5,
    this.resistance = 0.08,
    this.stretchHitTestBehavior = HitTestBehavior.opaque,
    // GlassGlow properties
    this.glowColor = Colors.white24,
    this.glowRadius = 1.0,
    this.glowHitTestBehavior = HitTestBehavior.opaque,
    this.enabled = true,
  }) : child = null;

  /// Creates a glass button with custom content.
  ///
  /// This allows you to use any widget as the button's content instead of
  /// just an icon. Useful for text buttons, composite content, etc.
  ///
  /// Example:
  /// ```dart
  /// GlassButton.custom(
  ///   onTap: () {},
  ///   width: 120,
  ///   height: 48,
  ///   child: Row(
  ///     mainAxisAlignment: MainAxisAlignment.center,
  ///     children: [
  ///       Icon(CupertinoIcons.play, size: 16),
  ///       SizedBox(width: 8),
  ///       Text('Play'),
  ///     ],
  ///   ),
  /// )
  /// ```
  const GlassButton.custom({
    required this.child,
    required this.onTap,
    super.key,
    this.label = '',
    this.width = 56,
    this.height = 56,
    this.shape = const LiquidOval(),
    this.settings,
    this.useOwnLayer = false,
    this.quality = GlassQuality.standard,
    // LiquidStretch properties
    this.interactionScale = 1.05,
    this.stretch = 0.5,
    this.resistance = 0.08,
    this.stretchHitTestBehavior = HitTestBehavior.opaque,
    // GlassGlow properties
    this.glowColor = Colors.white24,
    this.glowRadius = 1.0,
    this.glowHitTestBehavior = HitTestBehavior.opaque,
    this.enabled = true,
  })  : icon = null,
        iconSize = 24.0,
        iconColor = Colors.white;

  // ===========================================================================
  // Content Properties
  // ===========================================================================

  /// The icon to display in the button.
  ///
  /// Mutually exclusive with [child]. Use the default constructor for icon
  /// buttons, or [GlassButton.custom] for custom content.
  final IconData? icon;

  /// Custom widget to display in the button.
  ///
  /// Mutually exclusive with [icon]. Use [GlassButton.custom] constructor
  /// to provide custom content.
  final Widget? child;

  /// Size of the icon (only used when [icon] is provided).
  ///
  /// Defaults to 24.0.
  final double iconSize;

  /// Color of the icon (only used when [icon] is provided).
  ///
  /// Defaults to [CupertinoColors.white].
  final Color iconColor;

  // ===========================================================================
  // Button Properties
  // ===========================================================================

  /// Callback when the button is tapped.
  ///
  /// If [enabled] is false, this callback will not be invoked.
  final VoidCallback onTap;

  /// Whether the button is enabled.
  ///
  /// When false, the button will be visually disabled and [onTap] will not
  /// be invoked. The button will render with reduced opacity.
  ///
  /// Defaults to true.
  final bool enabled;

  /// Semantic label for accessibility.
  ///
  /// This label is announced by screen readers to describe the button's
  /// purpose. If empty, the button's visual content is used instead.
  ///
  /// Defaults to an empty string.
  final String label;

  /// Width of the button in logical pixels.
  ///
  /// Defaults to 56.0.
  final double width;

  /// Height of the button in logical pixels.
  ///
  /// Defaults to 56.0.
  final double height;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Shape of the glass button.
  ///
  /// Can be [LiquidOval], [LiquidRoundedRectangle], or
  /// [LiquidRoundedSuperellipse].
  ///
  /// Defaults to [LiquidOval].
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
  ///   This is more performant when you have multiple glass elements that
  ///   can share the same rendering context.
  ///
  /// - `true`: Uses [LiquidGlass.withOwnLayer], can be used anywhere.
  ///   Creates an independent glass rendering context for this button.
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

  // ===========================================================================
  // LiquidStretch Properties (Animation & Interaction)
  // ===========================================================================

  /// The scale factor to apply when the user is interacting with the button.
  ///
  /// - 1.0 means no scaling
  /// - Greater than 1.0 means the button will grow (e.g., 1.05 = 5% larger)
  /// - Less than 1.0 means the button will shrink
  ///
  /// This creates a satisfying "press down" effect when the button is touched.
  ///
  /// Defaults to 1.05.
  final double interactionScale;

  /// The factor to multiply the drag offset by to determine the stretch amount.
  ///
  /// Controls how much the button stretches in response to drag gestures:
  /// - 0.0 means no stretch
  /// - 1.0 means the stretch matches the drag offset exactly (usually too much)
  /// - 0.5 (default) provides a balanced, natural stretch effect
  ///
  /// Higher values create more dramatic squash and stretch animations.
  ///
  /// Defaults to 0.5.
  final double stretch;

  /// The resistance factor to apply to the drag offset.
  ///
  /// Controls how "sticky" the drag feels. Higher values create more
  /// resistance, making the button feel heavier and more sluggish. Lower
  /// values make it feel lighter and more responsive.
  ///
  /// Uses non-linear damping that increases with distance from the rest
  /// position.
  ///
  /// Defaults to 0.08.
  final double resistance;

  /// The hit test behavior for the stretch gesture listener.
  ///
  /// Controls how the stretch effect responds to touches:
  /// - [HitTestBehavior.opaque]: Consumes all touches (default)
  /// - [HitTestBehavior.translucent]: Allows touches to pass through
  /// - [HitTestBehavior.deferToChild]: Only responds when touching the child
  ///
  /// Defaults to [HitTestBehavior.opaque].
  final HitTestBehavior stretchHitTestBehavior;

  // ===========================================================================
  // GlassGlow Properties (Touch Effects)
  // ===========================================================================

  /// The color of the glow effect.
  ///
  /// The glow will have this color's opacity at the center and fade to fully
  /// transparent at the edge. Use semi-transparent colors for best results.
  ///
  /// Common values:
  /// - [Colors.white24]: Subtle white glow (default)
  /// - [Colors.blue.withOpacity(0.3)]: Blue glow
  /// - [Colors.transparent]: Disables glow effect
  ///
  /// Defaults to [Colors.white24].
  final Color glowColor;

  /// The radius of the glow effect relative to the layer's shortest side.
  ///
  /// - 1.0 (default): Glow radius equals the shortest dimension of the button
  /// - 0.5: Glow radius is half the shortest dimension
  /// - 2.0: Glow radius is twice the shortest dimension
  ///
  /// Larger values create a more diffuse, spread-out glow.
  ///
  /// Defaults to 1.0.
  final double glowRadius;

  /// The hit test behavior for the glow gesture listener.
  ///
  /// Controls how the glow effect responds to touches:
  /// - [HitTestBehavior.opaque]: Consumes all touches (default)
  /// - [HitTestBehavior.translucent]: Allows touches to pass through
  /// - [HitTestBehavior.deferToChild]: Only responds when touching the child
  ///
  /// Defaults to [HitTestBehavior.opaque].
  final HitTestBehavior glowHitTestBehavior;

  @override
  Widget build(BuildContext context) {
    // Build the content widget (either icon or custom child)
    final contentWidget = SizedBox(
      height: height,
      width: width,
      child: Center(
        child: child ??
            Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
      ),
    );

    // Build the glass effect widget
    final glassWidget = useOwnLayer
        ? LiquidGlass.withOwnLayer(
            shape: shape,
            settings: settings ?? const LiquidGlassSettings(),
            fake: quality.usesBackdropFilter,
            child: GlassGlow(
              glowColor: glowColor,
              glowRadius: glowRadius,
              hitTestBehavior: glowHitTestBehavior,
              child: contentWidget,
            ),
          )
        : LiquidGlass.grouped(
            shape: shape,
            child: GlassGlow(
              glowColor: glowColor,
              glowRadius: glowRadius,
              hitTestBehavior: glowHitTestBehavior,
              child: contentWidget,
            ),
          );

    // Wrap with stretch animation
    final stretchWidget = LiquidStretch(
      interactionScale: interactionScale,
      stretch: stretch,
      resistance: resistance,
      hitTestBehavior: stretchHitTestBehavior,
      child: Semantics(
        button: true,
        label: label.isNotEmpty ? label : null,
        enabled: enabled,
        child: glassWidget,
      ),
    );

    // Apply opacity when disabled
    final finalWidget = enabled
        ? stretchWidget
        : Opacity(
            opacity: 0.5,
            child: stretchWidget,
          );

    // Wrap with gesture detector
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: finalWidget,
    );
  }
}
