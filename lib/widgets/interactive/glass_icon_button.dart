import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';

/// A glass morphism icon button following Apple's iOS 26 design patterns.
///
/// [GlassIconButton] provides an icon-only button with liquid glass effect,
/// optimized for toolbars, app bars, and navigation elements.
///
/// ## Key Features
///
/// - Icon-only button (no text/labels)
/// - Liquid glass effect with interactive glow
/// - Squash and stretch animation on tap
/// - Two rendering modes (grouped/standalone)
/// - Circular or rounded square shapes
/// - Disabled state support
///
/// ## Usage
///
/// ### Basic Icon Button
/// ```dart
/// GlassIconButton(
///   icon: Icons.favorite,
///   onPressed: () => print('Tapped'),
/// )
/// ```
///
/// ### Custom Size and Shape
/// ```dart
/// GlassIconButton(
///   icon: Icons.settings,
///   onPressed: () {},
///   size: 48,
///   shape: GlassIconButtonShape.roundedSquare,
///   borderRadius: 12,
/// )
/// ```
///
/// ### With Custom Glow
/// ```dart
/// GlassIconButton(
///   icon: Icons.star,
///   onPressed: () {},
///   glowColor: Colors.yellow,
///   glowRadius: 30,
/// )
/// ```
///
/// ### Standalone Mode
/// ```dart
/// GlassIconButton(
///   icon: Icons.add,
///   onPressed: () {},
///   useOwnLayer: true,
///   settings: LiquidGlassSettings(
///     thickness: 40,
///     blur: 15,
///   ),
/// )
/// ```
///
/// ### In a Toolbar (Grouped Mode)
/// ```dart
/// LiquidGlassLayer(
///   settings: LiquidGlassSettings(...),
///   child: Row(
///     children: [
///       GlassIconButton(icon: Icons.menu, onPressed: () {}),
///       Spacer(),
///       GlassIconButton(icon: Icons.search, onPressed: () {}),
///       GlassIconButton(icon: Icons.more_vert, onPressed: () {}),
///     ],
///   ),
/// )
/// ```
///
/// ### Disabled State
/// ```dart
/// GlassIconButton(
///   icon: Icons.delete,
///   onPressed: null,  // null = disabled
/// )
/// ```
class GlassIconButton extends StatelessWidget {
  /// Creates a glass icon button.
  const GlassIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.size = 44,
    this.iconSize,
    this.shape = GlassIconButtonShape.circle,
    this.borderRadius = 12,
    this.glowColor,
    this.glowRadius = 20,
    this.interactionScale = 0.95,
    this.useOwnLayer = false,
    this.settings,
    this.quality = GlassQuality.standard,
  });

  // Cache default colors to avoid allocations
  static const _defaultIconColorEnabled =
      Color(0xFFFFFFFF); // white.withValues(alpha: 1.0)
  static const _defaultIconColorDisabled =
      Color(0x4DFFFFFF); // white.withValues(alpha: 0.3)
  static const _defaultGlowColor =
      Color(0x4DFFFFFF); // white.withValues(alpha: 0.3)

  // ===========================================================================
  // Content Properties
  // ===========================================================================

  /// The icon to display.
  ///
  /// Typically an [IconData] from [Icons] or `[CupertinoIcons]`.
  final IconData icon;

  /// Size of the icon within the button.
  ///
  /// If null, defaults to `size * 0.5` (half of button size).
  final double? iconSize;

  // ===========================================================================
  // Interaction Properties
  // ===========================================================================

  /// Callback when the button is pressed.
  ///
  /// If null, the button is disabled and interaction effects are disabled.
  final VoidCallback? onPressed;

  /// Scale factor when pressed.
  ///
  /// Values less than 1.0 create a "squash" effect on tap.
  /// Defaults to 0.95 (95% of original size).
  final double interactionScale;

  // ===========================================================================
  // Size and Shape Properties
  // ===========================================================================

  /// Size of the button (width and height).
  ///
  /// Defaults to 44 (iOS standard touch target).
  final double size;

  /// Shape of the button.
  ///
  /// Defaults to [GlassIconButtonShape.circle].
  final GlassIconButtonShape shape;

  /// Border radius for rounded square shape.
  ///
  /// Only used when [shape] is [GlassIconButtonShape.roundedSquare].
  /// Defaults to 12.
  final double borderRadius;

  // ===========================================================================
  // Glow Effect Properties
  // ===========================================================================

  /// Color of the glow effect.
  ///
  /// If null, uses white with low opacity.
  final Color? glowColor;

  /// Radius of the glow effect in logical pixels.
  ///
  /// Defaults to 20.
  final double glowRadius;

  // ===========================================================================
  // Glass Effect Properties
  // ===========================================================================

  /// Whether to create its own [LiquidGlassLayer].
  ///
  /// If false (default), the button must be inside a [LiquidGlassLayer].
  /// If true, creates an independent glass layer with [settings].
  ///
  /// Defaults to false (grouped mode).
  final bool useOwnLayer;

  /// Glass effect settings for standalone mode.
  ///
  /// Only used when [useOwnLayer] is true.
  /// If null, uses [LiquidGlassSettings] defaults.
  final LiquidGlassSettings? settings;

  /// Rendering quality for the glass effect.
  ///
  /// Defaults to [GlassQuality.standard] (backdrop filter).
  final GlassQuality quality;

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? (size * 0.5);
    final isEnabled = onPressed != null;

    // Build icon content
    final iconWidget = Icon(
      icon,
      size: effectiveIconSize,
      color: isEnabled ? _defaultIconColorEnabled : _defaultIconColorDisabled,
    );

    // Build glow layer
    final withGlow = GlassGlow(
      glowColor: glowColor ?? _defaultGlowColor,
      glowRadius: glowRadius,
      child: iconWidget,
    );

    // Build glass shape
    final glassShape = _buildShape();
    final withGlass = useOwnLayer
        ? LiquidGlass.withOwnLayer(
            shape: glassShape,
            settings: settings ?? const LiquidGlassSettings(),
            fake: quality.usesBackdropFilter,
            child: withGlow,
          )
        : LiquidGlass.grouped(
            shape: glassShape,
            child: withGlow,
          );

    // Build stretch animation
    final withStretch = LiquidStretch(
      interactionScale: isEnabled ? interactionScale : 1.0,
      child: Semantics(
        button: true,
        enabled: isEnabled,
        child: withGlass,
      ),
    );

    // Build gesture handling
    return GestureDetector(
      onTap: isEnabled ? onPressed : null,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: withStretch,
      ),
    );
  }

  static const _defaultOval = LiquidOval();

  LiquidShape _buildShape() {
    switch (shape) {
      case GlassIconButtonShape.circle:
        return _defaultOval;
      case GlassIconButtonShape.roundedSquare:
        return LiquidRoundedSuperellipse(
          borderRadius: borderRadius,
        );
    }
  }
}

/// Shape options for [GlassIconButton].
enum GlassIconButtonShape {
  /// Circular button (iOS standard for icon buttons).
  circle,

  /// Rounded square button.
  roundedSquare,
}
