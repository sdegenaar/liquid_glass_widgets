/// Design-style presets for Liquid Glass optics and component styling.
///
/// Used by [GlassThemeData] to coordinate surface platter materials,
/// interactive indicator lenses, resting selection treatments, and inner
/// shadows across all glass widgets from a single central setting.
enum GlassStyle {
  /// The package's original pre-calibration `v1.x` Liquid Glass aesthetic:
  /// - Spherical bevel refraction ([GlassLensModel.spherical])
  /// - Gaussian backdrop blur (`blur: 3–5`)
  /// - Upper-left 135° directional specular key light and chromatic dispersion
  /// - Classic refractive indicator lens
  classic,

  /// Modeled on Apple's iOS 26.0 Liquid Glass (`glassEffect(.regular)` &
  /// `_UILiquidLensView`, tuned against iOS 26.0 simulator references):
  /// - Paraxial thin-prism bevel refraction ([GlassLensModel.paraxial])
  /// - Dual-pass frosted cloud (`frost: 14`) with bright white specular rims
  ///   (`rimShade: 0`) in light mode and deep uniform dark platters (`rgb(25,25,26)`)
  /// - Clear refractive indicator lens with bright white specular rim (`rimShade: 0`)
  ios26,

  /// Modeled on Apple's iOS 27.0 Liquid Glass (`glassEffect(.regular)` &
  /// `_UILiquidLensView`, tuned against iOS 27.0 simulator references):
  /// - Paraxial thin-prism bevel refraction ([GlassLensModel.paraxial])
  /// - Dual-pass frosted cloud (`frost: 14`) with luminance clamping
  /// - Top/bottom hairline `rimShade` and dual-lobe `rimLight`
  /// - Clear refractive indicator lens with top inner shadow and `colorBurn`
  ///   resting selection pill
  ///
  /// This is the default style.
  ios27,
}
