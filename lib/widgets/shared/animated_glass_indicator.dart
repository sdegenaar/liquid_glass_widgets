import 'package:flutter/material.dart';
import '../../src/renderer/liquid_glass_renderer.dart';

import '../../constants/glass_defaults.dart';
import '../../types/glass_quality.dart';
import '../../utils/draggable_indicator_physics.dart';
import 'glass_effect.dart';

/// A shared component that renders the interactive "Jelly" indicator
/// used in [GlassTabBar], [GlassSegmentedControl], and [GlassBottomBar].
///
/// Handles:
/// - Jelly physics (squash and stretch)
/// - Thickness-based crossfade between background and glass
/// - Positioning and expansion
class AnimatedGlassIndicator extends StatelessWidget {
  /// Optional background key for Skia/Web refraction
  final GlobalKey? backgroundKey;

  /// Current velocity of the drag gesture.
  final double velocity;

  /// Number of items (tabs/segments).
  final int itemCount;

  /// Current alignment of the indicator.
  final Alignment alignment;

  /// Animation value (0.0 to 1.0) indicating drag state.
  /// 0 = resting, >0 = dragging/animating.
  final double thickness;

  /// Rendering quality (standard/premium).
  final GlassQuality quality;

  /// Base color for the indicator (used for background mode).
  final Color indicatorColor;

  /// Whether this is the background (non-glass) pass.
  final bool isBackgroundIndicator;

  /// Whether to render the solid background color pass.
  final bool paintBackground;

  /// Whether to render the glass effect shader pass.
  final bool paintGlass;

  /// Border radius of the indicator.
  final double borderRadius;

  /// Optional glass settings override.
  ///
  /// When non-null, fields in [settings] that differ from the
  /// [LiquidGlassSettings()] constructor defaults are applied **on top of**
  /// [baseIndicatorSettings] — not as a full replacement. This means
  /// `chromaticAberration: 0.15` (the iOS 26 iridescent rim default) is
  /// preserved unless the caller explicitly overrides it.
  ///
  /// Example — only change blur while keeping iOS 26 aberration:
  /// ```dart
  /// indicatorSettings: LiquidGlassSettings(blur: 2)
  /// ```
  ///
  /// To fully reset to the `LiquidGlassSettings()` constructor defaults,
  /// start from that and specify every field you want:
  /// ```dart
  /// indicatorSettings: AnimatedGlassIndicator.baseIndicatorSettings
  ///     .copyWith(blur: 2, chromaticAberration: 0.0)
  /// ```
  final LiquidGlassSettings? settings;

  /// Padding to apply around the indicator (e.g., for GlassBottomBar).
  final EdgeInsetsGeometry padding;

  /// How much to expand the indicator during drag.
  final EdgeInsetsGeometry expansion;

  /// Whether to use LiquidRoundedSuperellipse (Apple style) or standard RoundedRectangle.
  final bool useSuperellipse;

  /// Optional exact width for varying tab sizes (bypasses widthFactor).
  /// Used in scrollable mode where tabs have different widths.
  final double? exactWidth;

  /// Optional exact offset from the left (bypasses alignment).
  /// Used in scrollable mode where tabs have different widths.
  final double? exactOffset;

  /// Optional shadows for the solid background indicator.
  ///
  /// Shadows are applied only to the resting (non-glass) pill so they do not
  /// muddy the liquid glass animation. Pass `null` (default) for no shadow.
  final List<BoxShadow>? shadows;

  /// Maximum concave lens pinch strength for the active indicator pill.
  ///
  /// During a drag, the pill's left and right edges appear to pinch inward
  /// (iOS 26 "through a lens" effect). This value is the ceiling of that
  /// effect at [thickness] == 1.0.
  ///
  /// - `1.0` (default) — full Apple-calibrated pinch
  /// - `0.5` — half the pinch depth
  /// - `0.0` — pinch fully disabled
  ///
  /// Configure per-bar via [GlassBottomBar.indicatorPinchStrength],
  /// [GlassTabBar.indicatorPinchStrength], etc.
  final double pinchStrength;

  const AnimatedGlassIndicator({
    super.key,
    required this.velocity,
    required this.itemCount,
    required this.alignment,
    required this.thickness,
    required this.quality,
    required this.indicatorColor,
    required this.isBackgroundIndicator,
    required this.borderRadius,
    this.settings,
    this.padding = EdgeInsets.zero,
    this.expansion = const EdgeInsets.all(8.0),
    this.useSuperellipse = true,
    this.backgroundKey,
    this.paintBackground = true,
    this.paintGlass = true,
    this.exactWidth,
    this.exactOffset,
    this.shadows,
    this.pinchStrength = 1.0,
  });

  /// The iOS 26-calibrated default glass settings for all indicator pills.
  ///
  /// Used as the merge base when the caller provides [settings]. Fields the
  /// caller leaves at [LiquidGlassSettings()] defaults are filled in from
  /// here, so `chromaticAberration: 0.15` persists unless explicitly changed.
  ///
  /// Pass this as a starting point when you need partial overrides while
  /// keeping iOS 26 parity:
  /// ```dart
  /// indicatorSettings: AnimatedGlassIndicator.baseIndicatorSettings
  ///     .copyWith(blur: 2)
  /// ```
  static const baseIndicatorSettings = LiquidGlassSettings(
    glassColor: Color.from(
      alpha: 0.0,
      red: 1,
      green: 1,
      blue: 1,
    ),
    refractiveIndex: GlassDefaults.refractiveIndex,
    lightIntensity: GlassDefaults.lightIntensity,
    // Real iOS 26 glass has visible iridescent/rainbow fringing at edges.
    chromaticAberration: 0.15,
    lightAngle: GlassDefaults.lightAngle,
    blur: 0,
  );

  // Sentinel representing the LiquidGlassSettings() constructor defaults, used
  // by _mergeWithBase to detect which fields the caller explicitly changed.
  static const _settingsDefaults = LiquidGlassSettings();

  /// Merges [override] on top of [baseIndicatorSettings].
  ///
  /// Only fields that differ from [LiquidGlassSettings()] defaults are
  /// treated as intentional overrides. Fields the caller left at the
  /// constructor default are filled from [baseIndicatorSettings] instead.
  ///
  /// Edge-case: if a caller explicitly wants a field value that happens to
  /// equal the [LiquidGlassSettings()] default (e.g. `chromaticAberration:
  /// 0.01`), they should start from [baseIndicatorSettings] and use
  /// [LiquidGlassSettings.copyWith] directly to express the intent clearly.
  static LiquidGlassSettings _mergeWithBase(LiquidGlassSettings override) {
    return baseIndicatorSettings.copyWith(
      glassColor: override.glassColor != _settingsDefaults.glassColor
          ? override.glassColor
          : null,
      thickness: override.thickness != _settingsDefaults.thickness
          ? override.thickness
          : null,
      blur: override.blur != _settingsDefaults.blur ? override.blur : null,
      chromaticAberration:
          override.chromaticAberration != _settingsDefaults.chromaticAberration
              ? override.chromaticAberration
              : null,
      lightAngle: override.lightAngle != _settingsDefaults.lightAngle
          ? override.lightAngle
          : null,
      lightIntensity: override.lightIntensity != _settingsDefaults.lightIntensity
          ? override.lightIntensity
          : null,
      ambientStrength:
          override.ambientStrength != _settingsDefaults.ambientStrength
              ? override.ambientStrength
              : null,
      refractiveIndex:
          override.refractiveIndex != _settingsDefaults.refractiveIndex
              ? override.refractiveIndex
              : null,
      saturation:
          override.saturation != _settingsDefaults.saturation
              ? override.saturation
              : null,
      glowIntensity: override.glowIntensity != _settingsDefaults.glowIntensity
          ? override.glowIntensity
          : null,
      specularSharpness:
          override.specularSharpness != _settingsDefaults.specularSharpness
              ? override.specularSharpness
              : null,
      standardOpacityMultiplier: override.standardOpacityMultiplier !=
              _settingsDefaults.standardOpacityMultiplier
          ? override.standardOpacityMultiplier
          : null,
      shadowElevation:
          override.shadowElevation != _settingsDefaults.shadowElevation
              ? override.shadowElevation
              : null,
      shadow: override.shadow,
      whitenStrength: override.whitenStrength != _settingsDefaults.whitenStrength
          ? override.whitenStrength
          : null,
      whitenGated: override.whitenGated != _settingsDefaults.whitenGated
          ? override.whitenGated
          : null,
    );
  }

  /// Clip budget for the Impeller BackdropFilterLayer.
  ///
  /// A constant margin is used rather than a velocity-proportional one:
  /// the proportional approach changes [clipExpansion] every frame, which
  /// triggers [markNeedsPaint] every frame via the setter's change detection,
  /// causing constant geometry rebuilds and showing stale geometry during fast
  /// drags. A constant value lets the setter's equality check short-circuit
  /// with no repaint.
  ///
  ///  - Horizontal 20 px: covers glass shader antialiased edge rendering.
  ///  - Vertical 15 px: covers max jelly scaleY plus headroom for the concave 
  ///    vertical pinch shader to sample the bar behind it without hitting the clamp edge.
  static const _jellyClipExpansion = EdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 15.0,
  );

  @override
  Widget build(BuildContext context) {
    // Calculate expansion rectangle based on thickness
    final resolvedExpansion = expansion.resolve(Directionality.of(context));
    final rect = RelativeRect.lerp(
      RelativeRect.fill,
      RelativeRect.fromLTRB(
        -resolvedExpansion.left,
        -resolvedExpansion.top,
        -resolvedExpansion.right,
        -resolvedExpansion.bottom,
      ),
      thickness,
    );

    // 1. Background Indicator (Resting state)
    // Fade out as the drag spring thickness increases toward 0.15.
    final backgroundOpacity = (1.0 - (thickness / 0.15)).clamp(0.0, 1.0);
    final backgroundIndicator = IgnorePointer(
      child: Opacity(
        opacity: backgroundOpacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: indicatorColor,
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: shadows,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );

    // 2. Glass Indicator (Active/Dragging state)
    // We fade the glass in/out by setting `visibility` on the settings rather
    // than wrapping the widget in `Opacity`.
    final fade = thickness.clamp(0.0, 1.0);
    final base = settings != null
        ? _mergeWithBase(settings!)
        : baseIndicatorSettings;
    final effectiveSettings = base
        .copyWith(visibility: fade)
        .copyWithPinch(fade * pinchStrength);

    final shape = useSuperellipse
        ? LiquidRoundedSuperellipse(borderRadius: borderRadius * 2)
        : LiquidRoundedRectangle(borderRadius: borderRadius);

    final bool isStdPath =
        quality == GlassQuality.standard || quality == GlassQuality.minimal;

    final glassWidget = GlassEffect(
      shape: shape,
      settings: effectiveSettings,
      quality: quality,
      interactionIntensity: thickness,
      backgroundKey: backgroundKey,
      clipExpansion: _jellyClipExpansion,
      // Map settings.thickness → rimThickness (logical px rim width).
      // uThickness is declared but unused in interactive_indicator.frag;
      // uRimThickness is what actually controls the visible hairline rim width.
      // Minimum 0.8 (was 0.5): the wider SDF AA band covers the gap between the
      // shader's SDF edge and the Dart-side ClipPath AA. At 0.5 the boundary
      // was too thin to absorb the jelly-transform distortion and the concave
      // pinch UV shift, producing a visible pixelated/aliased rim at the pill
      // edges — especially at the horizontal pinch curves.
      // Clamp ceiling 8 px: beyond 8 the rim bleeds into the pill body.
      rimThickness: (settings?.effectiveThickness ?? 0.8).clamp(0.8, 8.0),
      // Calibrate standard-tier indicator styling in Dart space instead of the shader:
      // Soften the forced rim outline to match premium's elegance and keep the body translucent.
      ambientRim: isStdPath ? 0.08 : 0.1,
      baseAlphaMultiplier: isStdPath ? 0.15 : 0.2,
      edgeAlphaMultiplier: isStdPath ? 0.35 : 0.4,
      child: const GlassGlow(
        glowColor: Colors
            .transparent, // caused grey rectangle flicker if clicking multiple times
        child: SizedBox.expand(),
      ),
    );

    // Mount early (0.01) so geometry is built before the indicator is visible.
    // We MUST NOT wrap this in a RepaintBoundary because the jelly Transform
    // below will apply a sub-pixel shift/scale. If we pre-rasterise the glass
    // with a RepaintBoundary, the pre-computed AA will misalign with the pixel
    // grid during the transform, causing stair-stepping on the edges.
    final interactiveIndicator = thickness > 0.01
        ? glassWidget
        : const SizedBox.expand();

    // Only the active glass effect needs jelly physics — the solid
    // background pill is always at rest and must NOT go through the
    // Transform chain.
    final glassChild = Stack(
      children: [
        if (paintGlass && fade > 0.05) interactiveIndicator,
      ],
    );

    final indicatorBody = Stack(
      clipBehavior: Clip.none,
      children: [
        // Background painted directly — no RepaintBoundary, no Transform.
        // This guarantees sub-pixel border-radius AA at the GPU composition step.
        if (paintBackground && backgroundOpacity > 0)
          Positioned.fromRelativeRect(
            rect: rect!,
            child: backgroundIndicator,
          ),
        // Jelly-physics glass layer — apply Transform directly so GPU
        // computes anti-aliasing dynamically.
        Positioned.fromRelativeRect(
          rect: rect!,
          child: Transform(
            alignment: Alignment.center,
            transform: DraggableIndicatorPhysics.buildJellyTransform(
              velocity: Offset(velocity, 0),
              maxDistortion: 0.8,
              velocityScale: 10,
            ),
            child: glassChild,
          ),
        ),
      ],
    );

    Widget positioning;
    if (exactWidth != null && exactOffset != null) {
      // Exact pixel positioning for scrollable mode with variable-width tabs
      positioning = Positioned(
        left: exactOffset,
        top: 0,
        bottom: 0,
        width: exactWidth,
        child: indicatorBody,
      );
    } else {
      // Fractional positioning for fixed-width tabs
      positioning = Positioned.fill(
        child: FractionallySizedBox(
          widthFactor: 1 / itemCount,
          alignment: alignment,
          child: indicatorBody,
        ),
      );
    }

    return Positioned.fill(
      child: Padding(
        padding: padding,
        child: Stack(
          clipBehavior: Clip.none,
          children: [positioning],
        ),
      ),
    );
  }
}
