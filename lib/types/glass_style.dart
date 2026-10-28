/// Design-era presets for Apple Liquid Glass optics and component styling.
///
/// Used by [GlassThemeData] to coordinate surface platter materials,
/// interactive indicator lenses, resting selection treatments, and inner
/// shadows across all glass widgets from a single central setting.
enum GlassStyle {
  /// iOS 26 Liquid Glass aesthetic:
  /// - Spherical bevel refraction ([GlassLensModel.spherical])
  /// - Gaussian backdrop blur (`blur: 3–5`)
  /// - Upper-left 135° directional specular key light
  /// - Flat translucent resting selection pills
  ios26,

  /// iOS 27 Liquid Glass aesthetic (`glassEffect(.regular)` & `_UILiquidLensView`):
  /// - Paraxial thin-prism bevel refraction ([GlassLensModel.paraxial])
  /// - Dual-pass frosted cloud (`frost: 14`) with luminance clamping
  /// - Top/bottom hairline `rimShade` and dual-lobe `rimLight`
  /// - Clear refractive indicator lens with top inner shadow and `colorBurn`
  ///   resting selection pill
  ios27,
}
