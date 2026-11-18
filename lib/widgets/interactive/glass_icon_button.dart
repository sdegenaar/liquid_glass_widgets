import 'package:flutter/cupertino.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../types/glass_button_style.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_surface_style.dart';
import '../shared/glass_solid_surface.dart';
import 'glass_button.dart';

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
///   icon: Icon(Icons.favorite),
///   onPressed: () => print('Tapped'),
/// )
/// ```
///
/// ### Custom Size and Shape
/// ```dart
/// GlassIconButton(
///   icon: Icon(Icons.settings),
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
///   icon: Icon(Icons.star),
///   onPressed: () {},
///   glowColor: Colors.yellow,
///   glowRadius: 30,
/// )
/// ```
///
/// ### Standalone Mode
/// ```dart
/// GlassIconButton(
///   icon: Icon(Icons.add),
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
/// AdaptiveLiquidGlassLayer(
///   settings: LiquidGlassSettings(...),
///   child: Row(
///     children: [
///       GlassIconButton(icon: Icon(Icons.menu), onPressed: () {}),
///       Spacer(),
///       GlassIconButton(icon: Icon(Icons.search), onPressed: () {}),
///       GlassIconButton(icon: Icon(Icons.more_vert), onPressed: () {}),
///     ],
///   ),
/// )
/// ```
///
/// ### Disabled State
/// ```dart
/// GlassIconButton(
///   icon: Icon(Icons.delete),
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
    this.iconColor,
    this.shape = GlassIconButtonShape.circle,
    this.borderRadius = 12,
    this.glowColor,
    this.glowRadius = 20,
    this.interactionScale = 0.95,
    this.useOwnLayer = false,
    this.settings,
    this.quality,
    this.surfaceStyle,
    this.color,
    this.tintColor,
    this.style = GlassButtonStyle.filled,
    this.persistPressOnDrag = true,
    this.anchorStretch = true,
    this.anchorStretchSettings,
    this.platformViewBackdrop = false,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  // Default icon colors are resolved at build time from CupertinoColors.label
  // (or luminance-contrasted white/black for prominent/opaque fills) so they
  // adapt cleanly across light and dark appearances.

  // ===========================================================================
  // Content Properties
  // ===========================================================================

  /// The icon widget to display.
  ///
  /// Pass any widget — standard [Icon] widgets will inherit color and size
  /// from [IconTheme]. Custom widgets (SVG, PNG, etc.) handle their own styling.
  final Widget icon;

  /// Size of the icon within the button.
  ///
  /// If null, defaults to `size * 0.5` (half of button size).
  final double? iconSize;

  /// Explicit color override for the icon.
  ///
  /// Supports [CupertinoDynamicColor]. When null, defaults to a
  /// luminance-contrasted [CupertinoColors.black] or [CupertinoColors.white]
  /// for [GlassButtonStyle.prominent] and high-alpha solid [color] fills, or
  /// [CupertinoColors.label] (`tertiaryLabel` when disabled) otherwise.
  final Color? iconColor;

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
  /// If null, resolved via `GlassThemeHelpers.resolveQuality` — inherits from
  /// the nearest ancestor layer, then the theme, then the [GlassButton]
  /// widget-class default ([GlassQuality.standard]).
  final GlassQuality? quality;

  /// How the button's surface is painted.
  ///
  /// If null (the default), inherits from the nearest ancestor
  /// [InheritedGlassSurfaceStyle] (such as a `solid` `GlassContainer.card` or
  /// `GlassGroupedSection`), falling back to [GlassSurfaceStyle.glass].
  /// See [GlassButton.surfaceStyle] for details.
  final GlassSurfaceStyle? surfaceStyle;

  /// Explicit resting fill color override in [GlassSurfaceStyle.solid] mode.
  ///
  /// Supports [CupertinoDynamicColor]. Ignored in [GlassSurfaceStyle.glass]
  /// mode (use [tintColor] to tint glass). See [GlassButton.color].
  final Color? color;

  /// Accent tint color for [GlassSurfaceStyle.glass] buttons (and fallback
  /// accent for [GlassSurfaceStyle.solid] + [GlassButtonStyle.prominent] when
  /// [color] is null).
  ///
  /// Supports [CupertinoDynamicColor]. See [GlassButton.tintColor].
  final Color? tintColor;

  /// The visual style of the icon button (`filled`, `prominent`, or
  /// `transparent`).
  ///
  /// Defaults to [GlassButtonStyle.filled]. See [GlassButton.style].
  final GlassButtonStyle style;

  /// Whether the pressed glass distortion persists while the finger is held
  /// down, even if dragged far away from the button.
  ///
  /// Forwarded to the underlying [GlassButton.persistPressOnDrag].
  /// See [GlassButton.persistPressOnDrag] for full documentation.
  ///
  /// Defaults to true.
  final bool persistPressOnDrag;

  /// Whether to anchor the button in place while stretching toward the finger.
  ///
  /// Defaults to `true`. See [GlassButton.anchorStretch].
  final bool anchorStretch;

  /// Fine-tuning for the anchor stretch effect.
  ///
  /// Defaults to `null`. See [GlassButton.anchorStretchSettings].
  final AnchorStretchSettings? anchorStretchSettings;

  /// When true (typically for iOS PlatformViews), forces the BackdropFilter
  /// fallback render path instead of the Impeller-native shader. Forwarded to
  /// the underlying [GlassButton] (and on to its [AdaptiveGlass]).
  final bool platformViewBackdrop;

  /// Externally provided focus node.
  final FocusNode? focusNode;

  /// Whether to request focus immediately.
  final bool autofocus;

  /// The semantic label for screen readers.
  ///
  /// Critical for icon buttons which otherwise have no textual content.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveIconSize = iconSize ?? (size * 0.5);
    final isEnabled = onPressed != null;

    final effectiveSurfaceStyle = surfaceStyle ??
        InheritedGlassSurfaceStyle.maybeOf(context) ??
        GlassSurfaceStyle.glass;
    final isSolid = effectiveSurfaceStyle == GlassSurfaceStyle.solid;

    final resolvedExplicitIconColor =
        CupertinoDynamicColor.maybeResolve(iconColor, context);
    final resolvedColor = CupertinoDynamicColor.maybeResolve(color, context);
    final resolvedTint = CupertinoDynamicColor.maybeResolve(tintColor, context);

    // Build icon content wrapped in IconTheme so standard Icon widgets
    // inherit the correct size and color automatically.
    final Color effectiveIconColor;
    if (resolvedExplicitIconColor != null) {
      effectiveIconColor = resolvedExplicitIconColor;
    } else if (isSolid && style == GlassButtonStyle.prominent) {
      final bg = resolvedColor ??
          resolvedTint ??
          CupertinoDynamicColor.resolve(
            CupertinoTheme.of(context).primaryColor,
            context,
          );
      effectiveIconColor = bg.computeLuminance() > 0.55
          ? CupertinoColors.black
          : CupertinoColors.white;
    } else if (isSolid && resolvedColor != null && resolvedColor.a > 0.5) {
      effectiveIconColor = resolvedColor.computeLuminance() > 0.55
          ? CupertinoColors.black
          : CupertinoColors.white;
    } else if (!isSolid && style == GlassButtonStyle.prominent) {
      effectiveIconColor = resolvedTint != null
          ? (resolvedTint.computeLuminance() > 0.55
              ? CupertinoColors.black
              : CupertinoColors.white)
          : CupertinoColors.white;
    } else {
      effectiveIconColor = isEnabled
          ? CupertinoColors.label.resolveFrom(context)
          : CupertinoColors.tertiaryLabel.resolveFrom(context);
    }

    final iconWidget = IconTheme(
      data: IconThemeData(
        color: effectiveIconColor,
        size: effectiveIconSize,
      ),
      child: icon,
    );

    final glassShape = _buildShape();

    return GlassButton.custom(
      onTap: onPressed ?? () {},
      enabled: isEnabled,
      width: size,
      height: size,
      shape: glassShape,
      settings: settings,
      useOwnLayer: useOwnLayer,
      quality: quality,
      surfaceStyle: surfaceStyle,
      color: color,
      tintColor: tintColor,
      style: style,
      interactionScale: interactionScale,
      glowColor: glowColor, // Let GlassButton use theme if null
      glowRadius: glowRadius,
      persistPressOnDrag: persistPressOnDrag,
      anchorStretch: anchorStretch,
      anchorStretchSettings: anchorStretchSettings,
      platformViewBackdrop: platformViewBackdrop,
      focusNode: focusNode,
      autofocus: autofocus,
      label: semanticLabel ?? '',
      child: iconWidget,
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
