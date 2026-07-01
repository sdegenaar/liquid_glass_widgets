import 'dart:ui' show ImageFilter;

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

  /// Sigma of the backdrop blur painted behind the RESTING selected pill
  /// (Apple-style "frost at rest"). Scaled internally by the resting opacity so
  /// it is full when settled and fades out as the pill morphs into the
  /// liquid-glass lens during a drag/tap — keeping motion crisp. `0.0` (default)
  /// disables it. Only renders on the background-painting indicator
  /// ([paintBackground] == true); reads through a translucent [indicatorColor].
  final double innerBlur;

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
    this.innerBlur = 0.0,
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
      lightIntensity:
          override.lightIntensity != _settingsDefaults.lightIntensity
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
      saturation: override.saturation != _settingsDefaults.saturation
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
      whitenStrength:
          override.whitenStrength != _settingsDefaults.whitenStrength
              ? override.whitenStrength
              : null,
      whitenGated: override.whitenGated != _settingsDefaults.whitenGated
          ? override.whitenGated
          : null,
      // backerColor was added to LiquidGlassSettings after this merge was
      // written; without it the indicator silently drops any backerColor passed
      // via indicatorSettings (e.g. the per-mode over-map stand-in colour).
      backerColor: override.backerColor != _settingsDefaults.backerColor
          ? override.backerColor
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
    final base =
        settings != null ? _mergeWithBase(settings!) : baseIndicatorSettings;

    // Stabilise the pinch UV shift against jelly spring micro-oscillation.
    //
    // The spring targets thickness=1.0 when active and overshoots, leaving
    // `fade` oscillating in the 0.9–1.0 range while the pill settles.
    // Using `fade` directly as the pinch multiplier amplifies this oscillation
    // into the UV warp, making icons/labels jitter visibly through the lens.
    //
    // The quadratic ease-out formula 1−(1−f)² compresses the near-1.0
    // oscillation range from ±0.10 → ±0.01 (≈10× reduction) while still
    // mapping 0→0 and 1→1 cleanly. `visibility` is left on the raw `fade`
    // so glass opacity still tracks the spring naturally — only the UV
    // distortion is stabilised.
    final stablePinchFade = 1.0 - (1.0 - fade) * (1.0 - fade);
    final effectiveSettings = base
        .copyWith(visibility: fade)
        .copyWithPinch(stablePinchFade * pinchStrength);

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
      rimThickness: (settings?.effectiveThickness ?? 0.8).clamp(0.8, 8.0),
      // iOS 26 Standard glass matching GlassSwitch/Slider pattern
      ambientRim: isStdPath ? 0.08 : 0.1,
      baseAlphaMultiplier:
          isStdPath ? 0.08 : 0.2, // Match GlassSlider (near clear center)
      edgeAlphaMultiplier:
          isStdPath ? 0.15 : 0.4, // Match GlassSlider/Switch (subtle rim)
      child: const GlassGlow(
        glowColor: Colors.transparent,
        child: SizedBox.expand(),
      ),
    );

    // Mount early (0.01) so geometry is built before the indicator is visible.
    // We MUST NOT wrap this in a RepaintBoundary because the jelly Transform
    // below will apply a sub-pixel shift/scale. If we pre-rasterise the glass
    // with a RepaintBoundary, the pre-computed AA will misalign with the pixel
    // grid during the transform, causing stair-stepping on the edges.
    final interactiveIndicator =
        thickness > 0.01 ? glassWidget : const SizedBox.expand();

    // Standard: background inside Transform to get jelly physics
    final glassChild = Stack(
      clipBehavior: Clip.none,
      children: [
        if (paintBackground && isStdPath && backgroundOpacity > 0)
          backgroundIndicator,
        if (paintGlass && fade > 0.05) interactiveIndicator,
      ],
    );

    final indicatorBody = Stack(
      clipBehavior: Clip.none,
      children: [
        // Rest-blur: an Apple-style backdrop frost behind the RESTING pill.
        // Sigma is scaled by backgroundOpacity so it is full when settled and
        // fades toward zero as the pill morphs into the glass lens (motion stays
        // crisp). Sits at the bottom of the stack so the (translucent) pill +
        // icons read on top of the frosted backdrop.
        //
        // The ClipRRect + BackdropFilter stay MOUNTED for the whole gesture — we
        // gate only on [innerBlur] > 0, never on backgroundOpacity. Adding or
        // removing a clip layer over an iOS PlatformView mid-gesture makes the
        // engine reconstruct the platform-view clip-view chain, which cancels
        // the in-flight touch and freezes an interactive bar overlaid on it.
        // Fading the sigma (rather than unmounting the layer) keeps the look
        // without the churn; a small sigma floor keeps it a real backdrop layer
        // so the engine can't drop it on its own either.
        if (paintBackground && innerBlur > 0)
          Positioned.fromRelativeRect(
            rect: rect!,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: (innerBlur * backgroundOpacity)
                      .clamp(0.001, double.infinity),
                  sigmaY: (innerBlur * backgroundOpacity)
                      .clamp(0.001, double.infinity),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        // Premium: background painted statically (no Transform), fading out
        if (paintBackground && !isStdPath && backgroundOpacity > 0)
          Positioned.fromRelativeRect(
            rect: rect!,
            child: backgroundIndicator,
          ),
        // Jelly-physics glass layer
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
