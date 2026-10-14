import 'package:flutter/widgets.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../types/glass_quality.dart';
import '../../types/glass_surface_style.dart';
import '../shared/adaptive_glass.dart';
import '../shared/glass_solid_surface.dart';
import '../shared/inherited_liquid_glass.dart';
import '../../theme/glass_theme_helpers.dart';

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
///
/// ## Card preset: [GlassContainer.card]
///
/// [GlassContainer.card] is the card preset (16px padding, 12px superellipse
/// corners for [GlassSurfaceStyle.glass]). It is the replacement for the
/// deprecated `GlassCard`, and adds a `surfaceStyle`:
///
/// ```dart
/// // Native iOS inset-grouped card: flat, opaque, no blur / rim / shadow.
/// GlassContainer.card(
///   surfaceStyle: GlassSurfaceStyle.solid,
///   child: Text('Hello'),
/// )
/// ```
///
/// iOS renders inset-grouped list cards as flat opaque surfaces, so use
/// [GlassSurfaceStyle.solid] for cards inside lists and reserve glass for
/// chrome that floats above content.
///
/// ## ⚠️ Anti-Pattern: Do Not Place Glass Controls Inside a GlassContainer
///
/// [GlassContainer] is a **foundational surface**, not a generic wrapper.
/// Placing interactive glass controls inside it causes two problems:
///
/// 1. **Visual degradation** — [GlassContainer] sets
///    [InheritedLiquidGlass.avoidsRefraction] to `true` for its entire child
///    subtree. Any [GlassEffect] descendant falls back to a non-refracting
///    path — the inner glass effect is degraded by design.
///
/// 2. **Jelly-physics clipping** — With [useOwnLayer] `= true` on Impeller,
///    the container routes through `LiquidGlass.withOwnLayer` which applies
///    its own internal shape clip. Interactive indicator widgets overshoot
///    their bounds during spring animations — that overshoot gets cut.
///
/// Interactive glass controls already manage their own surface appearance via
/// `backgroundColor` and `indicatorColor` — no outer container is needed.
///
/// ```dart
/// // ✅ Correct — control manages its own surface
/// GlassSegmentedControl(
///   segments: [...],
///   selectedIndex: _index,
///   onSegmentSelected: (i) => setState(() => _index = i),
/// )
///
/// // ❌ Anti-pattern — degrades refraction, clips jelly animation
/// GlassContainer(
///   child: GlassSegmentedControl(...),
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
    this.quality,
    this.clipBehavior = Clip.none,
    this.alignment,
    this.allowElevation = false,
    this.glowIntensity = 0.0,
    this.platformViewBackdrop = false,
  }) : _surfaceStyle = GlassSurfaceStyle.glass;

  /// Creates a card-like container with opinionated defaults.
  ///
  /// Defaults match the (deprecated) `GlassCard`: [padding] of 16 on all sides
  /// and, for [GlassSurfaceStyle.glass], a 12px [LiquidRoundedSuperellipse].
  ///
  /// [surfaceStyle] chooses how the card is painted:
  ///
  /// - [GlassSurfaceStyle.glass] (default in 1.x): the normal glass surface.
  /// - [GlassSurfaceStyle.solid]: a flat opaque fill (white in light mode,
  ///   `#1C1C1E` in dark mode) with no blur, rim, refraction or shadow,
  ///   matching native iOS inset-grouped list cards. When [shape] is null the
  ///   solid card uses a 26px [LiquidRoundedSuperellipse]. [settings],
  ///   [useOwnLayer] and [quality] are ignored for solid cards. The dark fill
  ///   is always `#1C1C1E`; the lighter "elevated" grey iOS uses for cards
  ///   inside sheets is not implemented.
  ///
  /// iOS draws list cards flat; prefer [GlassSurfaceStyle.solid] for cards
  /// inside lists.
  const GlassContainer.card({
    super.key,
    this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    LiquidShape? shape,
    this.settings,
    this.useOwnLayer = false,
    this.quality,
    this.clipBehavior = Clip.none,
    this.width,
    this.height,
    GlassSurfaceStyle surfaceStyle = GlassSurfaceStyle.glass,
  })  : shape = shape ??
            (surfaceStyle == GlassSurfaceStyle.solid
                ? _solidCardShape
                : _glassCardShape),
        alignment = null,
        allowElevation = false,
        glowIntensity = 0.0,
        platformViewBackdrop = false,
        _surfaceStyle = surfaceStyle;

  static const _glassCardShape = LiquidRoundedSuperellipse(borderRadius: 12);

  /// Native inset-grouped list cards use ~26pt continuous corners.
  static const _solidCardShape = LiquidRoundedSuperellipse(borderRadius: 26);

  final GlassSurfaceStyle _surfaceStyle;

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

  /// Glass effect settings for this container.
  ///
  /// Controls the visual appearance of the glass effect including thickness,
  /// blur radius, color tint, lighting, and more.
  ///
  /// **Important:** In grouped mode (default), per-widget settings are
  /// ignored — the parent layer's settings are used instead. To apply
  /// per-widget settings, set `useOwnLayer: true`.
  ///
  /// For the best of both worlds, set `settings` on [GlassPage] or
  /// [AdaptiveLiquidGlassLayer] — all grouped children inherit them
  /// without the performance cost of separate layers.
  ///
  /// If null, inherits settings from the nearest parent layer or theme.
  final LiquidGlassSettings? settings;

  /// Whether to create its own layer or use grouped glass within an existing
  /// layer.
  ///
  /// - `false` (default): Uses [LiquidGlass.grouped], must be inside a
  /// [LiquidGlassLayer]. This is more performant when you have multiple glass
  /// elements that can share the same rendering context. Per-widget [settings]
  /// are ignored in this mode.
  ///
  /// - `true`: Uses [LiquidGlass.withOwnLayer], can be used anywhere.
  ///   Creates an independent glass rendering context. Per-widget [settings]
  ///   are applied in this mode.
  ///
  /// Defaults to false.
  final bool useOwnLayer;

  /// Rendering quality for the glass effect.
  ///
  /// If null, inherits from parent [InheritedLiquidGlass] or defaults to
  /// [GlassQuality.standard], which uses the lightweight fragment shader.
  /// This is 5-10x faster than BackdropFilter and works reliably in all
  /// contexts, including scrollable lists.
  ///
  /// Use [GlassQuality.premium] for full-pipeline shader with texture capture
  /// and chromatic aberration (Impeller only) in static layouts.
  final GlassQuality? quality;

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

  /// Interactive glow intensity for Skia/Web (0.0–1.0).
  ///
  /// On Impeller, [GlassGlow] is the preferred mechanism. On Skia/Web this
  /// drives a shader-based highlight layer. Defaults to 0.0 (no glow).
  final double glowIntensity;

  /// When true (typically for iOS PlatformViews), forces the BackdropFilter
  /// fallback render path instead of the Impeller-native shader. Forwarded to
  /// the underlying [AdaptiveGlass].
  final bool platformViewBackdrop;

  @override
  Widget build(BuildContext context) {
    // Inherit quality from parent layer if not explicitly set
    final effectiveQuality = GlassThemeHelpers.resolveQuality(
      context,
      widgetQuality: quality,
    );

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

    // Solid surfaces are a plain filled/clipped shape — no AdaptiveGlass, so no
    // shader, backdrop sampling or rim can render.
    if (_surfaceStyle == GlassSurfaceStyle.solid) {
      return _applyLayout(_buildSolid(context, content, effectiveQuality));
    }

    // 4. Apply glass effect with adaptive fallback
    // Premium quality uses Impeller on iOS/macOS, falls back to lightweight shader on web
    // Standard quality always uses lightweight shader

    // Debug-only: warn when per-widget settings differ from the parent layer's
    // settings in grouped mode. This catches the common mistake of passing
    // custom settings to a grouped container and expecting them to apply.
    // Internal widgets that pass through resolved settings won't trigger this.
    assert(() {
      if (settings != null && !useOwnLayer) {
        final inherited = InheritedLiquidGlass.of(context);
        if (inherited != null && inherited != settings) {
          debugPrint(
            'GlassContainer: `settings` provided without `useOwnLayer: true`. '
            'In grouped mode, per-widget settings are ignored — the parent '
            'layer\'s settings are used instead.\n'
            '  → To apply these settings, add `useOwnLayer: true` (creates a '
            'separate rendering layer).\n'
            '  → For better performance, set `settings` on GlassPage or '
            'AdaptiveLiquidGlassLayer so all grouped children inherit them.',
          );
        }
      }
      return true;
    }());

    final effectiveSettings = GlassThemeHelpers.resolveSettings(
      context,
      explicit: settings,
    );
    Widget glassWidget = AdaptiveGlass(
      shape: shape,
      settings: effectiveSettings,
      quality: effectiveQuality,
      useOwnLayer: useOwnLayer,
      clipBehavior: clipBehavior,
      allowElevation: allowElevation, // Configurable elevation behavior
      glowIntensity: glowIntensity,
      platformViewBackdrop: platformViewBackdrop,
      child: InheritedGlassSurfaceStyle(
        surfaceStyle: _surfaceStyle,
        child: InheritedLiquidGlass(
          settings: effectiveSettings,
          quality: effectiveQuality,
          avoidsRefraction:
              true, // Containers block children from refracting background
          child: content,
        ),
      ),
    );

    return _applyLayout(glassWidget);
  }

  /// Paints a flat opaque card: a [ShapeDecoration] fill (with the same
  /// [shape]'s path, so corners match the glass variant) and, when
  /// [clipBehavior] is not [Clip.none], a [ShapeBorderClipper] for the content.
  ///
  /// The [InheritedLiquidGlass] wrapper is kept so descendants behave exactly
  /// as they do inside a glass container (nested glass avoids refraction).
  Widget _buildSolid(
    BuildContext context,
    Widget content,
    GlassQuality effectiveQuality,
  ) {
    // Debug-only: `settings` and `quality` configure the glass shader, which a
    // solid card never uses. Passing them is almost certainly a leftover from a
    // glass card, and a `glassColor` there will NOT tint the card.
    assert(() {
      if (settings != null || quality != null) {
        debugPrint(
          'GlassContainer.card: `settings` / `quality` have no effect when '
          '`surfaceStyle` is GlassSurfaceStyle.solid (a solid card is a flat '
          'opaque fill and does not use the glass shader).',
        );
      }
      return true;
    }());

    final effectiveSettings = GlassThemeHelpers.resolveSettings(
      context,
      explicit: settings,
    );

    Widget inner = InheritedGlassSurfaceStyle(
      surfaceStyle: GlassSurfaceStyle.solid,
      child: InheritedLiquidGlass(
        settings: effectiveSettings,
        quality: effectiveQuality,
        avoidsRefraction: true,
        child: content,
      ),
    );

    if (clipBehavior != Clip.none) {
      inner = ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        clipBehavior: clipBehavior,
        child: inner,
      );
    }

    return DecoratedBox(
      decoration: ShapeDecoration(
        color: resolveGlassSolidSurfaceColor(context),
        shape: shape,
      ),
      child: inner,
    );
  }

  /// Applies width/height constraints, then margin outside the surface.
  Widget _applyLayout(Widget surface) {
    // 5. Apply width/height constraints
    if (width != null || height != null) {
      surface = SizedBox(
        width: width,
        height: height,
        child: surface,
      );
    }

    // 6. Apply margin outside the glass effect
    if (margin != null) {
      surface = Padding(
        padding: margin!,
        child: surface,
      );
    }

    return surface;
  }
}
