import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
// [LOCAL PATCH]: GlassSpecularSharpness is our own type (not vendored).
// It lives in lib/types/ not lib/src/renderer/.
import '../../constants/glass_defaults.dart';
import '../../constants/glass_shadow.dart';
import '../../types/glass_specular_sharpness.dart';
import '../../types/glass_tint_blend.dart';
import 'liquid_glass_renderer.dart';
import 'liquid_glass_render_scope.dart';

/// Represents the settings for a liquid glass effect.
class LiquidGlassSettings with EquatableMixin {
  /// Creates a new [LiquidGlassSettings] with the given settings.
  const LiquidGlassSettings({
    this.visibility = 1.0,
    this.glassColor = const Color.fromARGB(0, 255, 255, 255),
    this.thickness = 20,
    this.blur = 5,
    this.chromaticAberration = .01,
    this.lightAngle = GlassDefaults.lightAngle,
    this.lightIntensity = .5,
    this.ambientStrength = 0,
    this.refractiveIndex = 1.2,
    this.saturation = 1.5,
    this.glowIntensity = 0.75,
    this.specularSharpness = GlassSpecularSharpness.medium,
    this.standardOpacityMultiplier = 1.0,
    this.shadowElevation = 1.0,
    this.shadow,
    this.whitenStrength = 0.0,
    this.whitenGated = true,
    this.tintBlend = GlassTintBlend.auto,
  });

  /// Creates [LiquidGlassSettings] using Figma-inspired parameter names.
  ///
  /// **Important — units are not Figma percentages:**
  ///
  /// | Parameter | Range | Maps to |
  /// |-----------|-------|---------|
  /// | [refraction] | 0–100 % | [refractiveIndex] via `1 + (v/100) × 0.2` |
  /// | [depth] | logical pixels | [thickness] **directly** (not a Figma %) |
  /// | [dispersion] | 0–100 % | [chromaticAberration] via `4 × (v/100)` |
  /// | [frost] | logical pixels | [blur] **directly** (not a Figma %) |
  ///
  /// Figma's internal `depth` and `frost` use proprietary units with no public
  /// pixel-equivalent formula. Pass [depth] and [frost] as the logical-pixel
  /// values you want — typical ranges: depth 10–40, frost 2–8.
  LiquidGlassSettings.figma({
    required double refraction,
    required double depth,
    required double dispersion,
    required double frost,
    double visibility = 1.0,
    double lightIntensity = 50,
    double lightAngle = GlassDefaults.lightAngle,
    Color glassColor = const Color.fromARGB(0, 255, 255, 255),
    GlassSpecularSharpness specularSharpness = GlassSpecularSharpness.medium,
    double standardOpacityMultiplier = 1.0,
  }) : this(
          visibility: visibility,
          refractiveIndex: 1 + (refraction / 100) * 0.2,
          thickness: depth,
          chromaticAberration: 4 * (dispersion / 100),
          lightIntensity: lightIntensity / 100,
          blur: frost,
          lightAngle: lightAngle,
          ambientStrength: 0.1,
          saturation: 1.5,
          glassColor: glassColor,
          specularSharpness: specularSharpness,
          standardOpacityMultiplier: standardOpacityMultiplier,
          // shadowElevation and shadow use their defaults (1.0 / null)
        );

  /// Retrieves the nearest [LiquidGlassSettings] from the widget tree.
  ///
  /// This will look for the nearest ancestor [LiquidGlassLayer] or
  /// [LiquidGlassRenderScope] widget in the widget tree.
  static LiquidGlassSettings of(BuildContext context) {
    return LiquidGlassRenderScope.of(context).settings;
  }

  /// A factor that can be used to scale all thickness-related properties.
  ///
  /// Defaults to 1.0.
  final double visibility;

  /// The color tint of the glass effect.
  ///
  /// Opacity defines the intensity of the tint.
  final Color glassColor;

  /// The effective glass color taking visibility into account.
  Color get effectiveGlassColor =>
      glassColor.withValues(alpha: glassColor.a * visibility);

  /// The thickness of the glass surface.
  ///
  /// Thicker surfaces refract the light more intensely.
  final double thickness;

  /// The effective thickness taking visibility into account.
  double get effectiveThickness => thickness * visibility;

  /// The blur of the glass effect.
  ///
  /// Higher values create a more frosted appearance.
  ///
  /// Defaults to 0.
  final double blur;

  /// The effective blur taking visibility into account.
  double get effectiveBlur => blur * visibility;

  /// The chromatic aberration of the glass effect (WIP).
  ///
  /// This is a little ugly still.
  ///
  /// Higher values create more pronounced color fringes.
  final double chromaticAberration;

  /// The effective chromatic aberration taking visibility into account.
  double get effectiveChromaticAberration => chromaticAberration * visibility;

  /// The angle of the light source in radians.
  ///
  /// This determines where the highlights on shapes will come from.
  final double lightAngle;

  /// The intensity of the light source.
  ///
  /// Higher values create more pronounced highlights.
  final double lightIntensity;

  /// The effective light intensity taking visibility into account.
  double get effectiveLightIntensity => lightIntensity * visibility;

  /// The strength of the ambient light.
  ///
  /// Higher values create more pronounced ambient light.
  final double ambientStrength;

  /// The effective ambient strength taking visibility into account.
  double get effectiveAmbientStrength => ambientStrength * visibility;

  /// The strength of the refraction.
  ///
  /// Higher values create more pronounced refraction.
  /// Defaults to 1.51
  final double refractiveIndex;

  /// The saturation adjustment for pixels that shine through the glass.
  ///
  /// 1.0 means no change, values < 1.0 desaturate the background,
  /// values > 1.0 increase saturation.
  /// Defaults to 1.0
  final double saturation;

  /// The intensity of the fresnel edge glow on the glass rim.
  ///
  /// Controls how visible the glass-edge luminosity is on the Standard
  /// (2D shader) rendering path. Higher values create a more pronounced
  /// glowing edge. Premium (Impeller) path ignores this value.
  ///
  /// Defaults to 0.75.
  final double glowIntensity;

  /// The sharpness of the specular highlight on the glass rim.
  ///
  /// Controls how tightly focused the specular lobe is. Each variant maps to
  /// a fixed power-of-2 exponent the shader computes with a zero-transcendental
  /// multiply chain — 3–5× faster than `pow()` on mobile GPUs.
  ///
  /// Defaults to [GlassSpecularSharpness.medium] which matches iOS 26.
  final GlassSpecularSharpness specularSharpness;

  /// A multiplier applied to the alpha channel of [glassColor] when rendering
  /// in Standard mode. This allows tuning the Standard 2D compositing opacity
  /// to achieve parity with the Premium 3D volumetric refraction, without
  /// needing separate color values for each mode.
  ///
  /// Defaults to 1.0. A common "magic number" for light mode is ~0.4.
  final double standardOpacityMultiplier;

  /// Scales the built-in light-mode drop shadow on glass surfaces.
  ///
  /// The shadow only appears in light mode and uses Apple's iOS 26 elevation
  /// values as the baseline. This multiplier scales opacity and blur
  /// proportionally:
  ///
  /// - `0.0` — no shadow (flat glass)
  /// - `1.0` — default Apple-matching elevation (6% opacity, 8px blur)
  /// - `2.0` — double intensity (12% opacity, 16px blur)
  ///
  /// Has no effect in dark mode.
  ///
  /// For full control over shadow appearance, use [shadow] instead.
  /// If [shadow] is non-null, [shadowElevation] is ignored.
  ///
  /// Defaults to 1.0.
  final double shadowElevation;

  /// Custom light-mode drop shadow for glass surfaces.
  ///
  /// When non-null, this replaces the built-in elevation shadow entirely.
  /// The shadows are inverse-clipped to only appear outside the glass
  /// boundary, preventing the glass from blurring its own shadow.
  ///
  /// When null (the default), the built-in Apple-matching shadow is used,
  /// scaled by [shadowElevation].
  ///
  /// Has no effect in dark mode.
  final List<BoxShadow>? shadow;

  /// Returns the effective shadow list for light-mode rendering.
  ///
  /// Resolves [shadow] (full override) vs [shadowElevation] (scalar).
  /// Returns an empty list when the shadow is effectively disabled.
  List<BoxShadow> get effectiveShadow {
    if (shadow != null) return shadow!;
    return GlassShadow.scaled(shadowElevation);
  }

  /// Light-mode whitening ("legibility veil") amount, from 0 to 1.
  ///
  /// On the Premium (Impeller) path this is applied as the last step of the
  /// render: the finished glass is mixed uniformly toward white,
  /// `mix(glass, white, whitenStrength)`. Because it is a single control-wide
  /// value (not per-pixel) there is no spatial seam, so no halo or outline
  /// artifacts. This models iOS 26 light-mode glass, which lays an even
  /// whitening layer over the refracted content for legibility on bright
  /// backgrounds — content stays visible, just whiter.
  ///
  /// The Standard and Frosted paths approximate the same knob by lifting the
  /// glass tint toward white (a "veil"), so a single value reads consistently
  /// across all quality tiers.
  ///
  /// Defaults to 0.0, which disables whitening entirely.
  final double whitenStrength;

  /// Whether [whitenStrength] is luminance-gated (true, the default) or
  /// applied uniformly (false).
  ///
  /// Gated: the lift only affects brighter pixels and leaves dark content
  /// (text, icons) crisp — the light-mode behaviour. Ungated: an even lift
  /// across the whole control — useful in dark mode to give dark glass a
  /// subtle frost, where a per-pixel gate over an all-dark backdrop would
  /// zero the whitening out entirely.
  ///
  /// Only affects the Premium (Impeller) path; the Standard and Frosted
  /// approximations are always uniform.
  final bool whitenGated;

  /// How [glassColor] blends with the refracted backdrop.
  ///
  /// [GlassTintBlend.auto] (the default) picks the path from the tint's
  /// chroma — colorful tints preserve backdrop luminosity, achromatic tints
  /// use the flat blend — which is the historical behavior. Force
  /// [GlassTintBlend.luminosity] for near-neutral tints that must keep the
  /// glassy look (e.g. a light-mode recipe with the color dialed almost
  /// out), or [GlassTintBlend.flat] when imposing the tint's brightness is
  /// the point (dimming layers, shape-matched backing scrims).
  ///
  /// Applies to the Premium and Standard paths; the Frosted fallback tier
  /// renders a flat tint by construction and ignores this setting.
  final GlassTintBlend tintBlend;

  /// The effective saturation taking visibility into account.
  double get effectiveSaturation => 1 + (saturation - 1) * visibility;

  /// The effective refractive index taking visibility into account.
  ///
  /// Lerps from 1.0 (no refraction) at [visibility]=0 toward the configured
  /// [refractiveIndex] as visibility increases. This matches how [Opacity]
  /// would fade the refraction distortion — at zero visibility there is no
  /// lens warp, at full visibility the warp is at its configured strength.
  double get effectiveRefractiveIndex =>
      1.0 + (refractiveIndex - 1.0) * visibility;

  /// Linearly interpolates between two [LiquidGlassSettings].
  static LiquidGlassSettings lerp(
    LiquidGlassSettings? a,
    LiquidGlassSettings? b,
    double t,
  ) {
    if (a == null && b == null) return const LiquidGlassSettings();
    if (a == null) return b!;
    if (b == null) return a;

    return LiquidGlassSettings(
      visibility: lerpDouble(a.visibility, b.visibility, t)!,
      glassColor: Color.lerp(a.glassColor, b.glassColor, t)!,
      thickness: lerpDouble(a.thickness, b.thickness, t)!,
      blur: lerpDouble(a.blur, b.blur, t)!,
      chromaticAberration:
          lerpDouble(a.chromaticAberration, b.chromaticAberration, t)!,
      lightAngle: lerpDouble(a.lightAngle, b.lightAngle, t)!,
      lightIntensity: lerpDouble(a.lightIntensity, b.lightIntensity, t)!,
      ambientStrength: lerpDouble(a.ambientStrength, b.ambientStrength, t)!,
      refractiveIndex: lerpDouble(a.refractiveIndex, b.refractiveIndex, t)!,
      saturation: lerpDouble(a.saturation, b.saturation, t)!,
      glowIntensity: lerpDouble(a.glowIntensity, b.glowIntensity, t)!,
      specularSharpness: t < 0.5 ? a.specularSharpness : b.specularSharpness,
      standardOpacityMultiplier: lerpDouble(
          a.standardOpacityMultiplier, b.standardOpacityMultiplier, t)!,
      shadowElevation: lerpDouble(a.shadowElevation, b.shadowElevation, t)!,
      shadow: t < 0.5 ? a.shadow : b.shadow,
      whitenStrength: lerpDouble(a.whitenStrength, b.whitenStrength, t)!,
      whitenGated: t < 0.5 ? a.whitenGated : b.whitenGated,
      tintBlend: t < 0.5 ? a.tintBlend : b.tintBlend,
    );
  }

  /// Helper for linear interpolation of doubles.
  static double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    a ??= 0.0;
    b ??= 0.0;
    return a + (b - a) * t;
  }

  /// Creates a new [LiquidGlassSettings] with the given settings.
  LiquidGlassSettings copyWith({
    double? visibility,
    Color? glassColor,
    double? thickness,
    double? blur,
    double? chromaticAberration,
    double? blend,
    double? lightAngle,
    double? lightIntensity,
    double? ambientStrength,
    double? refractiveIndex,
    double? saturation,
    double? glowIntensity,
    GlassSpecularSharpness? specularSharpness,
    double? standardOpacityMultiplier,
    double? shadowElevation,
    List<BoxShadow>? shadow,
    double? whitenStrength,
    bool? whitenGated,
    GlassTintBlend? tintBlend,
  }) =>
      LiquidGlassSettings(
        visibility: visibility ?? this.visibility,
        glassColor: glassColor ?? this.glassColor,
        thickness: thickness ?? this.thickness,
        blur: blur ?? this.blur,
        chromaticAberration: chromaticAberration ?? this.chromaticAberration,
        lightAngle: lightAngle ?? this.lightAngle,
        lightIntensity: lightIntensity ?? this.lightIntensity,
        ambientStrength: ambientStrength ?? this.ambientStrength,
        refractiveIndex: refractiveIndex ?? this.refractiveIndex,
        saturation: saturation ?? this.saturation,
        glowIntensity: glowIntensity ?? this.glowIntensity,
        specularSharpness: specularSharpness ?? this.specularSharpness,
        standardOpacityMultiplier:
            standardOpacityMultiplier ?? this.standardOpacityMultiplier,
        shadowElevation: shadowElevation ?? this.shadowElevation,
        shadow: shadow ?? this.shadow,
        whitenStrength: whitenStrength ?? this.whitenStrength,
        whitenGated: whitenGated ?? this.whitenGated,
        tintBlend: tintBlend ?? this.tintBlend,
      );

  @override
  List<Object?> get props => [
        visibility,
        glassColor,
        thickness,
        blur,
        chromaticAberration,
        lightAngle,
        lightIntensity,
        ambientStrength,
        refractiveIndex,
        saturation,
        glowIntensity,
        specularSharpness,
        standardOpacityMultiplier,
        shadowElevation,
        shadow,
        whitenStrength,
        whitenGated,
        tintBlend,
      ];
}
