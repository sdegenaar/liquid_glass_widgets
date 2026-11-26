/// How a card-like, recessed input, button, or sheet surface is rendered.
///
/// Used by `GlassContainer.card`, `GlassGroupedSection`,
/// `GlassReorderableList.grouped`, `GlassDisclosureGroup.standalone`,
/// `GlassDatePicker`, `GlassMultiDatePicker`, `GlassTextField`,
/// `GlassSearchBar`, `GlassTextArea`, `GlassPasswordField`, `GlassPicker`,
/// `GlassChip`, `GlassButton` (and `GlassButton.custom`), `GlassIconButton`,
/// and `GlassModalSheet` (and `GlassModalSheetScaffold` and
/// `GlassModalSheet.show`) via their `surfaceStyle` parameter.
enum GlassSurfaceStyle {
  /// A liquid glass surface (blur, refraction, rim light).
  ///
  /// This is the default in 1.x. Glass is best reserved for chrome that floats
  /// above content (bars, sheets, menus, controls). iOS itself renders cards,
  /// form inputs, chips, and in-content buttons inside **scrolling list
  /// content** (inset-grouped lists) as flat surfaces, so prefer [solid] when
  /// you want that native look.
  ///
  /// On a `GlassModalSheet`, glass becomes opaque toward the large detent.
  glass,

  /// A flat fill with no blur, rim light, refraction, or shadow.
  ///
  /// - **Cards & sections** (`GlassContainer.card`, `GlassGroupedSection`,
  ///   `GlassReorderableList.grouped`, `GlassDisclosureGroup.standalone`,
  ///   `GlassDatePicker`, `GlassMultiDatePicker`): renders `#FFFFFF` in light
  ///   mode, `#1C1C1E` in dark mode, and `#2C2C2E` inside elevated modal sheets
  ///   or full-screen covers, with a 26pt continuous (superellipse) corner.
  /// - **Inputs, pickers & chips** (`GlassTextField`, `GlassSearchBar`,
  ///   `GlassTextArea`, `GlassPasswordField`, `GlassPicker`, `GlassChip`):
  ///   renders an iOS `tertiarySystemFill` recessed well (`#1E767680` in light
  ///   mode, `#3D767680` in dark mode), and auto-inherits [solid] when placed
  ///   inside a solid card or section via `InheritedGlassSurfaceStyle` unless
  ///   overridden.
  /// - **Buttons** (`GlassButton`, `GlassButton.custom`, `GlassIconButton`):
  ///   maps `GlassButtonStyle.filled` (SwiftUI `.bordered`) to an iOS
  ///   `tertiarySystemFill` well (`#1E767680` light / `#3D767680` dark, or
  ///   `color`), `GlassButtonStyle.prominent` (SwiftUI `.borderedProminent`) to
  ///   `CupertinoTheme.of(context).primaryColor` (or `color` / `tintColor`)
  ///   with contrast-aware foreground, and `GlassButtonStyle.transparent`
  ///   (SwiftUI `.borderless`) to no resting box (unless `color` is set),
  ///   auto-inheriting [solid] inside a solid card or section via
  ///   `InheritedGlassSurfaceStyle` unless overridden.
  /// - **Sheets** (`GlassModalSheet`): opaque at every detent, in the sheet's
  ///   `expandedColor` or `expandedDarkColor` (by default `#F2F2F7` in light
  ///   mode, white in `GlassStyle.classic`, `#1C1C1E` in dark mode). The sheet
  ///   publishes [solid] to its content through `InheritedGlassSurfaceStyle`,
  ///   and its `settings` still reach the glass controls inside it. The sheet
  ///   keeps the light-mode drop shadow that a glass sheet has.
  ///
  /// On the cards, inputs, chips and buttons above, this path does not sample
  /// the backdrop and does not use any shader, so the surface renders
  /// identically on every platform and rendering backend, and per-widget glass
  /// `settings`, `quality`, and `useOwnLayer` have no effect on it (a
  /// debug-mode message is printed if you pass them).
  solid,
}
