/// Rendering quality for glass effects.
///
/// Controls the rendering method used for glass effects, balancing
/// visual quality with performance and compatibility.
enum GlassQuality {
  /// Lightweight rendering using backdrop filter.
  ///
  /// **Use when:**
  /// - Widget is in a scrollable list (ListView, GridView, etc.)
  /// - Inside forms or settings pages
  /// - Performance is important
  /// - Widget needs to work reliably in all contexts
  ///
  /// **Characteristics:**
  /// - Uses Flutter's BackdropFilter
  /// - Lightweight and performant
  /// - Works correctly during scrolling
  /// - Suitable for interactive widgets
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

/// Extension to convert [GlassQuality] to the underlying `fake` parameter.
extension GlassQualityExtension on GlassQuality {
  /// Whether to use fake glass (backdrop filter).
  ///
  /// - [GlassQuality.standard] → true (uses backdrop filter)
  /// - [GlassQuality.premium] → false (uses shader-based glass)
  bool get usesBackdropFilter {
    switch (this) {
      case GlassQuality.standard:
        return true;
      case GlassQuality.premium:
        return false;
    }
  }
}
