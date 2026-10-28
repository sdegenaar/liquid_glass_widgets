import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';

import '../constants/glass_defaults.dart';
import '../src/engine/liquid_glass_settings.dart';
import '../types/glass_specular_sharpness.dart';

/// A partial override of [LiquidGlassSettings] for use in [GlassThemeVariant].
///
/// Unlike [LiquidGlassSettings], every field here is optional (`null`).
/// A `null` value means "do not override — use the widget's own default".
///
/// This solves the footgun where setting a single property like `thickness`
/// in the theme would silently zero out all other settings (e.g. `glassColor`
/// would revert to fully transparent because the constructor default is
/// `Color.fromARGB(0, …)`).
///
/// ## Usage
///
/// ```dart
/// GlassTheme(
///   data: GlassThemeData(
///     light: GlassThemeVariant(
///       // Only thickness and blur are overridden — glassColor, refractiveIndex,
///       // lightIntensity, etc. continue to use each widget's own defaults.
///       settings: GlassThemeSettings(
///         thickness: 40,
///         blur: 6,
///       ),
///     ),
///   ),
///   child: …,
/// )
/// ```
///
/// ## Merge order
///
/// 1. Widget's own explicit `settings` parameter (highest priority)
/// 2. Theme `GlassThemeSettings` — only non-null fields applied
/// 3. Widget's built-in per-widget defaults (lowest priority)
@immutable
class GlassThemeSettings {
  /// Creates a partial settings override.
  ///
  /// Every parameter is optional. Omitted (null) parameters leave the
  /// corresponding property on the target widget unchanged.
  const GlassThemeSettings({
    this.visibility,
    this.glassColor,
    this.thickness,
    this.blur,
    this.frost,
    this.frostOpacity,
    this.frostClamp,
    this.frostWeight,
    this.blurWeight,
    this.chromaticAberration,
    this.lightAngle,
    this.lightIntensity,
    this.ambientStrength,
    this.fresnelStrength,
    this.refractiveIndex,
    this.saturation,
    this.specularSharpness,
    this.edgeAbsorption,
    this.rimShade,
    this.rimShadeEnds,
    this.rimLight,
    this.bodyShade,
    this.lensModel,
    this.shadowElevation,
    this.shadow,
  });

  /// iOS 26 surface preset in the light appearance, matching
  /// [LiquidGlassSettings.ios26Light].
  static const GlassThemeSettings ios26Light = GlassThemeSettings(
    thickness: 12.0,
    blur: 5.0,
    glassColor: Color.fromRGBO(210, 220, 240, 0.12),
    lightAngle: 2.356,
    lightIntensity: 0.85,
    ambientStrength: 0.15,
    refractiveIndex: 1.2,
    saturation: 1.2,
    chromaticAberration: 0.02,
  );

  /// iOS 26 surface preset in the dark appearance, matching
  /// [LiquidGlassSettings.ios26Dark].
  static const GlassThemeSettings ios26Dark = GlassThemeSettings(
    thickness: 10.0,
    blur: 4.0,
    glassColor: Color.fromRGBO(255, 255, 255, 0.08),
    lightAngle: 2.356,
    lightIntensity: 0.7,
    ambientStrength: 0.0,
    refractiveIndex: 1.2,
    saturation: 1.2,
    chromaticAberration: 0.01,
  );

  /// iOS 26 interactive indicator lens preset, matching
  /// [LiquidGlassSettings.ios26Indicator].
  static const GlassThemeSettings ios26Indicator = GlassThemeSettings(
    glassColor: Color.from(alpha: 0.0, red: 1, green: 1, blue: 1),
    thickness: 20,
    refractiveIndex: 1.10,
    lightIntensity: GlassDefaults.lightIntensity,
    chromaticAberration: 0.0,
    lightAngle: GlassDefaults.lightAngle,
    blur: 0,
  );

  /// iOS 27 `glassEffect(.regular)` in the light appearance, matching
  /// [LiquidGlassSettings.ios27Light].
  static const GlassThemeSettings ios27Light = GlassThemeSettings(
    glassColor: Color(0x87F8F8F8),
    saturation: 2.1,
    blur: 0.6,
    blurWeight: 0.8,
    frost: 14,
    frostOpacity: 0.73,
    frostClamp: 0.4,
    frostWeight: 2.0,
    thickness: 32,
    refractiveIndex: 1.24,
    lensModel: GlassLensModel.paraxial,
    lightAngle: 1.5707963267948966,
    lightIntensity: 0,
    fresnelStrength: 0,
    chromaticAberration: 0,
    edgeAbsorption: 0.035,
    rimShade: 1,
    rimLight: 1,
    shadow: [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 10,
        offset: Offset(0, 7),
      ),
    ],
  );

  /// iOS 27 `glassEffect(.regular)` in the dark appearance, matching
  /// [LiquidGlassSettings.ios27Dark].
  static const GlassThemeSettings ios27Dark = GlassThemeSettings(
    glassColor: Color(0x1FFFFFFF),
    saturation: 1.4,
    blur: 0.6,
    blurWeight: 2.5,
    frost: 14,
    frostOpacity: 0.85,
    frostClamp: -0.45,
    frostWeight: 0.5,
    thickness: 32,
    refractiveIndex: 1.24,
    lensModel: GlassLensModel.paraxial,
    lightAngle: -1.5707963267948966,
    lightIntensity: 0,
    fresnelStrength: 0,
    chromaticAberration: 0,
    edgeAbsorption: 0.035,
    rimShade: 1,
    rimShadeEnds: 0,
    rimLight: 1.15,
    bodyShade: 0.28,
    shadowElevation: 0,
  );

  /// iOS 27 interactive indicator lens preset, matching
  /// [LiquidGlassSettings.ios27Indicator].
  static const GlassThemeSettings ios27Indicator = GlassThemeSettings(
    glassColor: Color.from(alpha: 0.0, red: 1, green: 1, blue: 1),
    thickness: 28,
    refractiveIndex: 1.17,
    lensModel: GlassLensModel.paraxial,
    lightIntensity: 0.0,
    ambientStrength: 0.0,
    fresnelStrength: 0.0,
    saturation: 1.0,
    chromaticAberration: 0.0,
    lightAngle: 1.5707963267948966,
    rimShade: 1.0,
    rimShadeEnds: 0.56,
    rimLight: 1.0,
    blur: 0,
  );

  /// See [LiquidGlassSettings.visibility].
  final double? visibility;

  /// See [LiquidGlassSettings.glassColor].
  final Color? glassColor;

  /// See [LiquidGlassSettings.thickness].
  final double? thickness;

  /// See [LiquidGlassSettings.blur].
  final double? blur;

  /// See [LiquidGlassSettings.frost].
  final double? frost;

  /// See [LiquidGlassSettings.frostOpacity].
  final double? frostOpacity;

  /// See [LiquidGlassSettings.frostClamp].
  final double? frostClamp;

  /// See [LiquidGlassSettings.frostWeight].
  final double? frostWeight;

  /// See [LiquidGlassSettings.blurWeight].
  final double? blurWeight;

  /// See [LiquidGlassSettings.chromaticAberration].
  final double? chromaticAberration;

  /// See [LiquidGlassSettings.lightAngle].
  final double? lightAngle;

  /// See [LiquidGlassSettings.lightIntensity].
  final double? lightIntensity;

  /// See [LiquidGlassSettings.ambientStrength].
  final double? ambientStrength;

  /// See [LiquidGlassSettings.fresnelStrength].
  final double? fresnelStrength;

  /// See [LiquidGlassSettings.refractiveIndex].
  final double? refractiveIndex;

  /// See [LiquidGlassSettings.saturation].
  final double? saturation;

  /// See [LiquidGlassSettings.specularSharpness].
  final GlassSpecularSharpness? specularSharpness;

  /// See [LiquidGlassSettings.edgeAbsorption].
  final double? edgeAbsorption;

  /// See [LiquidGlassSettings.rimShade].
  final double? rimShade;

  /// See [LiquidGlassSettings.rimShadeEnds].
  final double? rimShadeEnds;

  /// See [LiquidGlassSettings.rimLight].
  final double? rimLight;

  /// See [LiquidGlassSettings.bodyShade].
  final double? bodyShade;

  /// See [LiquidGlassSettings.lensModel].
  final GlassLensModel? lensModel;

  /// See [LiquidGlassSettings.shadowElevation].
  final double? shadowElevation;

  /// See [LiquidGlassSettings.shadow].
  final List<BoxShadow>? shadow;

  /// Returns a new [LiquidGlassSettings] by applying this override onto [base].
  ///
  /// Only non-null fields in this override replace the corresponding
  /// value in [base]. Null fields leave [base]'s value untouched.
  LiquidGlassSettings applyTo(LiquidGlassSettings base) {
    return LiquidGlassSettings(
      visibility: visibility ?? base.visibility,
      glassColor: glassColor ?? base.glassColor,
      thickness: thickness ?? base.thickness,
      blur: blur ?? base.blur,
      frost: frost ?? base.frost,
      frostOpacity: frostOpacity ?? base.frostOpacity,
      frostClamp: frostClamp ?? base.frostClamp,
      chromaticAberration: chromaticAberration ?? base.chromaticAberration,
      lightAngle: lightAngle ?? base.lightAngle,
      lightIntensity: lightIntensity ?? base.lightIntensity,
      ambientStrength: ambientStrength ?? base.ambientStrength,
      ambientRim: base.ambientRim,
      fresnelStrength: fresnelStrength ?? base.fresnelStrength,
      refractiveIndex: refractiveIndex ?? base.refractiveIndex,
      saturation: saturation ?? base.saturation,
      glowIntensity: base.glowIntensity,
      specularSharpness: specularSharpness ?? base.specularSharpness,
      standardOpacityMultiplier: base.standardOpacityMultiplier,
      shadowElevation: shadowElevation ?? base.shadowElevation,
      shadow: shadow ?? base.shadow,
      whitenStrength: base.whitenStrength,
      whitenGated: base.whitenGated,
      edgeAbsorption: edgeAbsorption ?? base.edgeAbsorption,
      rimShade: rimShade ?? base.rimShade,
      rimShadeEnds: rimShadeEnds ?? base.rimShadeEnds,
      rimLight: rimLight ?? base.rimLight,
      bodyShade: bodyShade ?? base.bodyShade,
      lensModel: lensModel ?? base.lensModel,
      frostWeight: frostWeight ?? base.frostWeight,
      blurWeight: blurWeight ?? base.blurWeight,
      backerColor: base.backerColor,
      platformViewFallbackColor: base.platformViewFallbackColor,
    );
  }

  /// Applies only the fields of this override that differ from [baseline] onto
  /// [base].
  ///
  /// [baseline] is the legacy default surface the override was derived from
  /// (for example [GlassThemeSettings.ios26Light] for the built-in
  /// [GlassThemeVariant.light], which is also what [GlassThemeData.simple]
  /// copies and tweaks). A field that still equals [baseline] is treated as
  /// "not set by the app" and left to [base], so a dedicated preset such as
  /// [LiquidGlassSettings.ios27Light] is not overwritten by general surface
  /// defaults it was never meant to inherit.
  ///
  /// Fields that differ from [baseline] are applied exactly as [applyTo]
  /// would. Consequently an override cannot express "set this field to the
  /// baseline value" — pass explicit `settings` to the widget for that.
  LiquidGlassSettings applyDeltaTo(
    LiquidGlassSettings base,
    GlassThemeSettings baseline,
  ) {
    T? pick<T>(T? value, T? baselineValue) =>
        (value != null && value != baselineValue) ? value : null;
    return base.copyWith(
      visibility: pick(visibility, baseline.visibility),
      glassColor: pick(glassColor, baseline.glassColor),
      thickness: pick(thickness, baseline.thickness),
      blur: pick(blur, baseline.blur),
      frost: pick(frost, baseline.frost),
      frostOpacity: pick(frostOpacity, baseline.frostOpacity),
      frostClamp: pick(frostClamp, baseline.frostClamp),
      frostWeight: pick(frostWeight, baseline.frostWeight),
      blurWeight: pick(blurWeight, baseline.blurWeight),
      chromaticAberration:
          pick(chromaticAberration, baseline.chromaticAberration),
      lightAngle: pick(lightAngle, baseline.lightAngle),
      lightIntensity: pick(lightIntensity, baseline.lightIntensity),
      ambientStrength: pick(ambientStrength, baseline.ambientStrength),
      fresnelStrength: pick(fresnelStrength, baseline.fresnelStrength),
      refractiveIndex: pick(refractiveIndex, baseline.refractiveIndex),
      saturation: pick(saturation, baseline.saturation),
      specularSharpness: pick(specularSharpness, baseline.specularSharpness),
      edgeAbsorption: pick(edgeAbsorption, baseline.edgeAbsorption),
      rimShade: pick(rimShade, baseline.rimShade),
      rimShadeEnds: pick(rimShadeEnds, baseline.rimShadeEnds),
      rimLight: pick(rimLight, baseline.rimLight),
      bodyShade: pick(bodyShade, baseline.bodyShade),
      lensModel: pick(lensModel, baseline.lensModel),
      shadowElevation: pick(shadowElevation, baseline.shadowElevation),
      shadow: listEquals(shadow, baseline.shadow) ? null : shadow,
    );
  }

  /// Linearly interpolates between two partial overrides.
  ///
  /// Because every field is an *optional* override, interpolation has to
  /// respect the meaning of `null` ("use the widget's own default") rather
  /// than treating it as zero:
  ///
  /// - When a field is non-null on **both** sides it is smoothly
  ///   interpolated.
  /// - When a field is null on **either** side it switches discretely at the
  ///   midpoint (`t < 0.5` keeps [a]'s value, otherwise [b]'s). Interpolating
  ///   against an unknown widget default would produce a visible flash
  ///   through zero.
  /// - [specularSharpness] and [lensModel] are enums and always switch at the
  ///   midpoint.
  ///
  /// Returns null when both [a] and [b] are null. Used by
  /// [GlassThemeVariant.lerp] to cross-fade between light and dark theme
  /// variants during content-aware brightness flips.
  static GlassThemeSettings? lerp(
    GlassThemeSettings? a,
    GlassThemeSettings? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null || b == null) return t < 0.5 ? a : b;
    return GlassThemeSettings(
      visibility: _lerpDoubleField(a.visibility, b.visibility, t),
      glassColor: _lerpColorField(a.glassColor, b.glassColor, t),
      thickness: _lerpDoubleField(a.thickness, b.thickness, t),
      blur: _lerpDoubleField(a.blur, b.blur, t),
      frost: _lerpDoubleField(a.frost, b.frost, t),
      frostOpacity: _lerpDoubleField(a.frostOpacity, b.frostOpacity, t),
      frostClamp: _lerpDoubleField(a.frostClamp, b.frostClamp, t),
      frostWeight: _lerpDoubleField(a.frostWeight, b.frostWeight, t),
      blurWeight: _lerpDoubleField(a.blurWeight, b.blurWeight, t),
      chromaticAberration:
          _lerpDoubleField(a.chromaticAberration, b.chromaticAberration, t),
      lightAngle: _lerpDoubleField(a.lightAngle, b.lightAngle, t),
      lightIntensity: _lerpDoubleField(a.lightIntensity, b.lightIntensity, t),
      ambientStrength:
          _lerpDoubleField(a.ambientStrength, b.ambientStrength, t),
      fresnelStrength:
          _lerpDoubleField(a.fresnelStrength, b.fresnelStrength, t),
      refractiveIndex:
          _lerpDoubleField(a.refractiveIndex, b.refractiveIndex, t),
      saturation: _lerpDoubleField(a.saturation, b.saturation, t),
      specularSharpness: t < 0.5 ? a.specularSharpness : b.specularSharpness,
      edgeAbsorption: _lerpDoubleField(a.edgeAbsorption, b.edgeAbsorption, t),
      rimShade: _lerpDoubleField(a.rimShade, b.rimShade, t),
      rimShadeEnds: _lerpDoubleField(a.rimShadeEnds, b.rimShadeEnds, t),
      rimLight: _lerpDoubleField(a.rimLight, b.rimLight, t),
      bodyShade: _lerpDoubleField(a.bodyShade, b.bodyShade, t),
      lensModel: t < 0.5 ? a.lensModel : b.lensModel,
      shadowElevation:
          _lerpDoubleField(a.shadowElevation, b.shadowElevation, t),
      shadow: (a.shadow == null || b.shadow == null)
          ? (t < 0.5 ? a.shadow : b.shadow)
          : BoxShadow.lerpList(a.shadow, b.shadow, t),
    );
  }

  static double? _lerpDoubleField(double? a, double? b, double t) {
    if (a != null && b != null) return lerpDouble(a, b, t);
    return t < 0.5 ? a : b;
  }

  static Color? _lerpColorField(Color? a, Color? b, double t) {
    if (a != null && b != null) return Color.lerp(a, b, t);
    return t < 0.5 ? a : b;
  }

  /// Creates a copy with overridden values.
  GlassThemeSettings copyWith({
    double? visibility,
    Color? glassColor,
    double? thickness,
    double? blur,
    double? frost,
    double? frostOpacity,
    double? frostClamp,
    double? frostWeight,
    double? blurWeight,
    double? chromaticAberration,
    double? lightAngle,
    double? lightIntensity,
    double? ambientStrength,
    double? fresnelStrength,
    double? refractiveIndex,
    double? saturation,
    GlassSpecularSharpness? specularSharpness,
    double? edgeAbsorption,
    double? rimShade,
    double? rimShadeEnds,
    double? rimLight,
    double? bodyShade,
    GlassLensModel? lensModel,
    double? shadowElevation,
    List<BoxShadow>? shadow,
  }) {
    return GlassThemeSettings(
      visibility: visibility ?? this.visibility,
      glassColor: glassColor ?? this.glassColor,
      thickness: thickness ?? this.thickness,
      blur: blur ?? this.blur,
      frost: frost ?? this.frost,
      frostOpacity: frostOpacity ?? this.frostOpacity,
      frostClamp: frostClamp ?? this.frostClamp,
      frostWeight: frostWeight ?? this.frostWeight,
      blurWeight: blurWeight ?? this.blurWeight,
      chromaticAberration: chromaticAberration ?? this.chromaticAberration,
      lightAngle: lightAngle ?? this.lightAngle,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      ambientStrength: ambientStrength ?? this.ambientStrength,
      fresnelStrength: fresnelStrength ?? this.fresnelStrength,
      refractiveIndex: refractiveIndex ?? this.refractiveIndex,
      saturation: saturation ?? this.saturation,
      specularSharpness: specularSharpness ?? this.specularSharpness,
      edgeAbsorption: edgeAbsorption ?? this.edgeAbsorption,
      rimShade: rimShade ?? this.rimShade,
      rimShadeEnds: rimShadeEnds ?? this.rimShadeEnds,
      rimLight: rimLight ?? this.rimLight,
      bodyShade: bodyShade ?? this.bodyShade,
      lensModel: lensModel ?? this.lensModel,
      shadowElevation: shadowElevation ?? this.shadowElevation,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassThemeSettings &&
          runtimeType == other.runtimeType &&
          visibility == other.visibility &&
          glassColor == other.glassColor &&
          thickness == other.thickness &&
          blur == other.blur &&
          frost == other.frost &&
          frostOpacity == other.frostOpacity &&
          frostClamp == other.frostClamp &&
          frostWeight == other.frostWeight &&
          blurWeight == other.blurWeight &&
          chromaticAberration == other.chromaticAberration &&
          lightAngle == other.lightAngle &&
          lightIntensity == other.lightIntensity &&
          ambientStrength == other.ambientStrength &&
          fresnelStrength == other.fresnelStrength &&
          refractiveIndex == other.refractiveIndex &&
          saturation == other.saturation &&
          specularSharpness == other.specularSharpness &&
          edgeAbsorption == other.edgeAbsorption &&
          rimShade == other.rimShade &&
          rimShadeEnds == other.rimShadeEnds &&
          rimLight == other.rimLight &&
          bodyShade == other.bodyShade &&
          lensModel == other.lensModel &&
          shadowElevation == other.shadowElevation &&
          listEquals(shadow, other.shadow);

  @override
  int get hashCode => Object.hashAll([
        visibility,
        glassColor,
        thickness,
        blur,
        frost,
        frostOpacity,
        frostClamp,
        frostWeight,
        blurWeight,
        chromaticAberration,
        lightAngle,
        lightIntensity,
        ambientStrength,
        fresnelStrength,
        refractiveIndex,
        saturation,
        specularSharpness,
        edgeAbsorption,
        rimShade,
        rimShadeEnds,
        rimLight,
        bodyShade,
        lensModel,
        shadowElevation,
        shadow == null ? null : Object.hashAll(shadow!),
      ]);

  @override
  String toString() => 'GlassThemeSettings('
      'visibility: $visibility, '
      'thickness: $thickness, '
      'blur: $blur, '
      'glassColor: $glassColor, '
      'edgeAbsorption: $edgeAbsorption'
      ')';
}
