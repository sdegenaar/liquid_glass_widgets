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

  /// Simulator-calibrated native Apple Liquid Glass (`glassEffect(.regular)` &
  /// `_UILiquidLensView`):
  /// - Paraxial thin-prism bevel refraction ([GlassLensModel.paraxial])
  /// - Dual-pass frosted cloud (`frost: 14`) with luminance clamping
  /// - Top/bottom hairline `rimShade` and dual-lobe `rimLight`
  /// - Clear refractive indicator lens with top inner shadow and `colorBurn`
  ///   resting selection pill
  ///
  /// This is the default style.
  ios27,
}
