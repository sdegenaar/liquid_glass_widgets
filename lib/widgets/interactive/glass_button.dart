import 'package:flutter/cupertino.dart' show CupertinoColors;
import 'package:flutter/material.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../theme/glass_theme_data.dart';
import '../../types/glass_quality.dart';
import '../../types/glass_button_style.dart';
import '../shared/adaptive_glass.dart';
import '../../theme/glass_theme_helpers.dart';

/// Glass morphism button with scale animation and glow effects.
///
/// This button provides a complete liquid glass experience with:
/// - Liquid glass visual effect with customizable settings
/// - Scale animation (squash & stretch) when pressed
/// - Touch-responsive glow effect on interaction (Impeller) or shader-based
///   glow (Skia)
/// - Full control over all animation and visual properties
/// - Accessibility support with semantic labels
/// - Flexible content support (icon or custom child)
///
/// ## Platform Rendering
///
/// The glow effect adapts to the platform:
/// - **Impeller**: Uses advanced compositing via [GlassGlow]
/// - **Skia/Web**: Animates shader saturation parameter for frosted glow
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
///       GlassButton(
///         icon: Icon(CupertinoIcons.heart),
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
///   icon: Icon(CupertinoIcons.play),
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
///   icon: Icon(CupertinoIcons.star),
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
///   icon: Icon(CupertinoIcons.bolt),
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
///
/// ## Navigation bar / toolbar usage
///
/// When multiple buttons share a [LiquidGlassBlendGroup] (e.g. inside an
/// [AdaptiveLiquidGlassLayer]), the drag-follow animation physically moves each
/// button's glass shape in the shader's coordinate space. Because the blend
/// group treats all shapes as a connected liquid surface, dragging one button
/// causes neighboring buttons to visually respond — this is intentional for
/// isolated floating buttons, but can feel jarring in a nav bar.
///
/// Reduce [stretch] for tightly-grouped buttons to keep the tactile press feel
/// without excessive cross-button coupling:
///
/// ```dart
/// // Nav bar / toolbar — subtle liquid feel, minimal coupling
/// GlassButton(
///   stretch: 0.15,
///   icon: Icon(CupertinoIcons.home),
///   onTap: () {},
/// )
///
/// // Standalone FAB — full liquid feel (default)
/// GlassButton(
///   icon: Icon(CupertinoIcons.add),
///   onTap: () {},
/// )
/// ```
///
/// Setting [stretch] to `0.0` disables drag-following entirely while keeping
/// the press-scale effect ([interactionScale]).
class GlassButton extends StatefulWidget {
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
    this.quality,
    // LiquidStretch properties
    this.interactionScale = 1.05,
    this.stretch = 0.5,
    this.resistance = 0.08,
    this.stretchHitTestBehavior = HitTestBehavior.opaque,
    // GlassGlow properties
    this.glowColor,
    this.glowRadius = 1.0,
    this.glowBlurRadius,
    this.glowSpreadRadius,
    this.glowOpacity,
    this.glowHitTestBehavior = HitTestBehavior.opaque,
    this.enabled = true,
    this.style = GlassButtonStyle.filled,
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
    this.quality,
    // LiquidStretch properties
    this.interactionScale = 1.05,
    this.stretch = 0.5,
    this.resistance = 0.08,
    this.stretchHitTestBehavior = HitTestBehavior.opaque,
    // GlassGlow properties
    this.glowColor,
    this.glowRadius = 1.0,
    this.glowBlurRadius,
    this.glowSpreadRadius,
    this.glowOpacity,
    this.glowHitTestBehavior = HitTestBehavior.opaque,
    this.enabled = true,
    this.style = GlassButtonStyle.filled,
  })  : icon = null,
        iconSize = 24.0,
        iconColor = Colors.white;

  // ===========================================================================
  // Content Properties
  // ===========================================================================

  /// The widget to display in the button.
  ///
  /// Mutually exclusive with [child]. Pass any widget — standard [Icon]
  /// widgets will inherit color and size from [iconColor] and [iconSize]
  /// via [IconTheme]. Custom widgets handle their own styling.
  final Widget? icon;

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
  /// Use [GlassQuality.premium] for the full Impeller shader pipeline. When using
  /// premium quality on a standalone button (outside of an [AdaptiveLiquidGlassLayer]
  /// or [LiquidGlassLayer]), you **must** also set [useOwnLayer] to `true`.
  /// Without it, the button has no ancestor layer to render against and will show
  /// an assertion error in debug mode (graceful pass-through in release).
  ///
  /// ```dart
  /// // ✓ Correct — standalone premium button
  /// GlassButton(
  ///   quality: GlassQuality.premium,
  ///   useOwnLayer: true,
  ///   icon: Icon(CupertinoIcons.play),
  ///   onTap: () {},
  /// )
  ///
  /// // ✓ Also correct — inside an AdaptiveLiquidGlassLayer (no useOwnLayer needed)
  /// AdaptiveLiquidGlassLayer(
  ///   quality: GlassQuality.premium,
  ///   child: GlassButton(
  ///     icon: Icon(CupertinoIcons.play),
  ///     onTap: () {},
  ///   ),
  /// )
  /// ```
  final GlassQuality? quality;

  /// The visual style of the button.
  ///
  /// Use [GlassButtonStyle.transparent] when grouping buttons to avoid
  /// double-drawing glass backgrounds.
  final GlassButtonStyle style;

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
  /// If null, uses the primary glow color from [GlassTheme].
  ///
  /// Common values:
  /// - [Colors.white24]: Subtle white glow
  /// - [Colors.blue.withOpacity(0.3)]: Blue glow
  /// - [Colors.transparent]: Disables glow effect
  ///
  /// Defaults to null (uses theme).
  final Color? glowColor;

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

  /// Additional Gaussian blur sigma applied to the glow halo.
  ///
  /// If null, the value from [GlassThemeData.glowColorsFor] is used.
  /// Pass 0 to disable blur. Values of 4–16 create a diffuse halo.
  final double? glowBlurRadius;

  /// Extra glow circle spread as a fraction of the layer's shortest side.
  ///
  /// If null, the value from [GlassThemeData.glowColorsFor] is used.
  final double? glowSpreadRadius;

  /// Master opacity multiplier (0–1) applied on top of [glowColor]'s alpha.
  ///
  /// If null, the value from [GlassThemeData.glowColorsFor] is used.
  final double? glowOpacity;

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
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _saturationController;
  late final Animation<double> _saturationAnimation;

  @override
  void initState() {
    super.initState();
    _saturationController = AnimationController(
      duration: const Duration(milliseconds: 50), // Fast, instant response
      vsync: this,
    );
    _saturationAnimation = CurvedAnimation(
      parent: _saturationController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _saturationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.enabled) return;
    _saturationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.enabled) return;
    _saturationController.reverse();
  }

  void _handleTapCancel() {
    if (!widget.enabled) return;
    _saturationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    // Resolve quality and theme — hoisted here so stretchWidget can branch on quality
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: widget.quality,
    );

    final resolvedGlowColors =
        GlassThemeData.of(context).glowColorsFor(context);
    final effectiveGlowColor =
        widget.glowColor ?? resolvedGlowColors.primary ?? Colors.white24;
    final effectiveGlowBlurRadius =
        widget.glowBlurRadius ?? resolvedGlowColors.glowBlurRadius;
    final effectiveGlowSpreadRadius =
        widget.glowSpreadRadius ?? resolvedGlowColors.glowSpreadRadius;
    final effectiveGlowOpacity =
        widget.glowOpacity ?? resolvedGlowColors.glowOpacity;

    // Build the content widget (either icon or custom child)
    final contentWidget = SizedBox(
      height: widget.height,
      width: widget.width,
      child: Center(
        child: widget.child ??
            IconTheme(
              data: IconThemeData(
                color: widget.iconColor,
                size: widget.iconSize,
              ),
              child: widget.icon ?? const SizedBox.shrink(),
            ),
      ),
    );

    // 2. Build the inner content (Glow + Icon/Child)
    // This part is static relative to the glass saturation pulse
    final glowContent = GlassGlow(
      glowColor: effectiveGlowColor,
      glowRadius: widget.glowRadius,
      glowBlurRadius: effectiveGlowBlurRadius,
      glowSpreadRadius: effectiveGlowSpreadRadius,
      glowOpacity: effectiveGlowOpacity,
      hitTestBehavior: widget.glowHitTestBehavior,
      child: contentWidget,
    );

    // 3. Animate ONLY the glass settings that change during interaction
    final glassWidget = AnimatedBuilder(
      animation: _saturationAnimation,
      child: glowContent,
      builder: (context, child) {
        if (widget.style == GlassButtonStyle.transparent) {
          return child!;
        }

        final baseSettings = GlassThemeHelpers.resolveSettings(
          context,
          explicit: widget.settings,
        );

        // Pass glow intensity directly to AdaptiveGlass for Skia shader feedback.
        // On Impeller, GlassGlow widget is used instead (separate from glass effect).
        // On Skia/Web, glowIntensity controls shader-based additive brightness.
        return AdaptiveGlass(
          shape: widget.shape,
          settings: baseSettings, // Preserve user's saturation setting!
          quality: effectiveQuality,
          useOwnLayer: widget.useOwnLayer,
          glowIntensity: _saturationAnimation.value, // 0.0-1.0 animation
          child: child!,
        );
      },
    );

    // 4. Wrap with stretch animation and interaction containers
    // These remain outside the AnimatedBuilder to prevent redundant rebuilds.
    //
    // We explicitly skip wrapping RepaintBoundary in minimal quality to
    // prevent sub-pixel edge jitter ("flicker-on-rest"). When a shape is tightly
    // cached inside a RepaintBoundary and subjected to fractional scaling by the
    // LiquidStretch spring, the texture's bilinear interpolation edge snaps abruptly
    // to physical pixels exactly when velocity hits 0. Omitting the boundary
    // forces pure vector shape computation every frame, bypassing texture pixel-snapping.
    final stretchContent = LiquidStretch(
      interactionScale: widget.interactionScale,
      stretch: widget.stretch,
      resistance: widget.resistance,
      hitTestBehavior: widget.stretchHitTestBehavior,
      child: Semantics(
        button: true,
        label: widget.label.isNotEmpty ? widget.label : null,
        enabled: widget.enabled,
        child: glassWidget,
      ),
    );

    final stretchWidget = effectiveQuality == GlassQuality.minimal
        ? stretchContent // No RepaintBoundary — forces smooth vector anti-aliasing
        : RepaintBoundary(child: stretchContent);

    // Apply opacity when disabled
    final finalWidget = widget.enabled
        ? stretchWidget
        : Opacity(
            opacity: 0.5,
            child: stretchWidget,
          );

    // Wrap with gesture detector
    return GestureDetector(
      onTap: widget.enabled ? widget.onTap : null,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      behavior: HitTestBehavior.opaque,
      child: finalWidget,
    );
  }
}
