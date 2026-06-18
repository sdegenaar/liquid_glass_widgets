/// How a glass surface blends its tint (`glassColor`) with the refracted
/// backdrop.
///
/// Liquid glass has two tint blending paths with different jobs:
///
/// - **Flat blend** — every backdrop pixel is pulled toward the tint's color
///   *and brightness*, like a colored film. This is the only path that can
///   impose luminance: a white tint frosts dark content toward white (the
///   dark-mode sheen), a dark tint dims bright content (dimming sheets,
///   backing scrims). Its cost is that it compresses the backdrop's own
///   light/dark detail — over bright content a white film reads as fog
///   rather than glass.
/// - **Luminosity-preserving blend** — only the *color* shifts toward the
///   tint; every backdrop pixel keeps its own brightness, so content
///   structure stays crisp under the glass. This is what reads as "real
///   glass", but by construction it can never brighten or darken: a white
///   tint over dark content adjusts itself down to the content's darkness
///   and effectively disappears.
///
/// By default ([auto]) the renderer picks the path from the tint's chroma:
/// colorful tints take the luminosity-preserving path, achromatic
/// (white/gray/black) tints take the flat blend. That heuristic matches
/// most recipes, but some intents need an explicit choice — most notably a
/// **near-neutral tint that should still render as glass** (a light-mode
/// bar whose blue has been dialed out), which the chroma gate would
/// otherwise flatten into a film. The reverse intent also exists: a
/// *colorful* dimming layer that should impose its brightness.
///
/// Applies to the Premium (Impeller) and Standard tint paths. The Frosted
/// fallback tier renders a flat tint overlay by construction and ignores
/// this setting.
enum GlassTintBlend {
  /// Pick the blend from the tint's chroma (the default).
  ///
  /// Colorful tints preserve backdrop luminosity; achromatic tints use the
  /// flat blend. This is the historical behavior — existing recipes render
  /// identically.
  auto,

  /// Always preserve backdrop luminosity, regardless of tint chroma.
  ///
  /// Use for near-neutral tints that must keep the glassy look — e.g. a
  /// light-mode bar recipe with the color dialed almost out, paired with
  /// `whitenStrength` for legibility.
  luminosity,

  /// Always use the flat blend, regardless of tint chroma.
  ///
  /// Use when imposing the tint's brightness is the point — dimming
  /// surfaces, shape-matched backing scrims behind controls over busy
  /// content, or a deliberate frosted-film look.
  flat;

  /// Value passed to the fragment shaders (0 = auto, 1 = luminosity,
  /// 2 = flat).
  double get glslValue => index.toDouble();
}
