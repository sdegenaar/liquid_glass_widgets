/// Rendering quality for glass effects.
///
/// Controls the rendering method used for glass effects, balancing
/// visual quality with performance and compatibility.
enum GlassQuality {
  /// Lightweight shader-based rendering for optimal performance.
  ///
  /// **Use when:**
  /// - Widget is in a scrollable list (ListView, GridView, etc.)
  /// - Inside forms or settings pages
  /// - Performance is important
  /// - Widget needs to work reliably in all contexts
  ///
  /// **Characteristics:**
  /// - Uses lightweight fragment shader
  /// - 5-10x faster than BackdropFilter
  /// - Better visual quality than BackdropFilter
  /// - Works correctly during scrolling
  /// - Suitable for interactive widgets
  /// - Universal platform support (Skia, Impeller, Web)
  ///
  /// This is the recommended default for most use cases.
  standard,

  /// High-quality shader-based glass rendering.
  ///
  /// **Use when:**
  /// - Widget is in a static header or footer
  /// - Creating hero sections or showcase UI
  /// - Visual quality is paramount
  /// - Widget won't be scrolled
  ///
  /// **Characteristics:**
  /// - Uses custom shaders and texture capture
  /// - Higher visual quality
  /// - More computationally expensive
  /// - May not render correctly in scrollable contexts
  ///
  /// Only use in static, non-scrollable layouts.
  premium,
}

/// Extension to convert [GlassQuality] to the underlying rendering method.
extension GlassQualityExtension on GlassQuality {
  /// Whether to use lightweight shader (standard) or full shader (premium).
  ///
  /// - [GlassQuality.standard] → true (uses lightweight shader)
  /// - [GlassQuality.premium] → false (uses full LiquidGlass shader)
  bool get usesLightweightShader {
    switch (this) {
      case GlassQuality.standard:
        return true;
      case GlassQuality.premium:
        return false;
    }
  }

  /// Whether to use backdrop filter (deprecated, kept for compatibility).
  ///
  /// This is now an alias for [usesLightweightShader] for backward
  /// compatibility. The lightweight shader provides better performance
  /// than BackdropFilter while maintaining visual quality.
  ///
  /// - [GlassQuality.standard] → true (uses lightweight shader)
  /// - [GlassQuality.premium] → false (uses full shader)
  @Deprecated('Use usesLightweightShader instead')
  bool get usesBackdropFilter => usesLightweightShader;
}
