/// How a card-like surface is rendered.
///
/// Used by `GlassContainer.card`, `GlassGroupedSection`,
/// `GlassReorderableList.grouped`, `GlassDatePicker` and
/// `GlassMultiDatePicker` via their `surfaceStyle` parameter.
enum GlassSurfaceStyle {
  /// A liquid glass surface (blur, refraction, rim light).
  ///
  /// This is the default in 1.x. Glass is best reserved for chrome that floats
  /// above content (bars, sheets, menus, controls). iOS itself renders cards
  /// inside **scrolling list content** (inset-grouped lists) as flat, opaque
  /// surfaces, so prefer [solid] when you want that native look.
  glass,

  /// A flat, opaque fill with no blur, rim light, refraction or shadow.
  ///
  /// Matches the inset-grouped list cards used by iOS Settings-style screens:
  /// white in light mode and `#1C1C1E` in dark mode, with a continuous
  /// (superellipse) corner. The brightness is resolved the same way as the
  /// rest of the package (`GlassTheme` override, then a pinned
  /// `CupertinoTheme`, then the Material theme, then the platform).
  ///
  /// This path does not sample the backdrop and does not use any shader, so
  /// the surface renders identically on every platform and rendering backend,
  /// and per-widget glass `settings`, `quality` and `useOwnLayer` have no
  /// effect on it (a debug-mode message is printed if you pass them).
  ///
  /// Limitation: the fill is always `#1C1C1E` in dark mode. iOS switches to a
  /// lighter "elevated" grouped background (`#2C2C2E`) for cards shown inside
  /// sheets and covers; that variant is not implemented. Pass a custom
  /// widget (for example a `DecoratedBox`) if you need it.
  solid,
}
