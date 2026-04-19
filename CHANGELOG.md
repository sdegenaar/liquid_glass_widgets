# 0.7.15

### Bug Fixes

- **FIX**: `lib/theme/glass_theme_settings.dart` was accidentally omitted from version control in 0.7.14. All consumers of `GlassThemeSettings` received a compile error (`type 'GlassThemeSettings' is not a subtype`). This release commits the missing file. No API change — `GlassThemeSettings` was already exported from `liquid_glass_widgets.dart`.
- **FIX**: `GlassPerformanceMonitor._emitWarning` — division-by-zero crash when `rasterBudget` was sub-millisecond (< 1 ms). Protected with a `max(1, ...)` guard.

### Refactor (zero breaking changes)

- **REFACTOR**: Consolidated 18 quality-resolution chains (`widgetQuality ?? inherited?.quality ?? themeData.qualityFor(context) ?? GlassQuality.standard`) into a single canonical helper: `GlassThemeHelpers.resolveQuality(context, widgetQuality: ..., fallback: ...)`. Surface widgets (`GlassAppBar`, `GlassToolbar`, `GlassBottomBar`, `GlassSearchableBottomBar`, `GlassSideBar`) pass `fallback: GlassQuality.premium` to preserve their documented defaults. All other widgets default to `GlassQuality.standard`.
- **REFACTOR**: Extracted `_buildIconShadows` from `BottomBarTabItem` to a `@visibleForTesting` top-level function `buildIconShadows(...)` in `bottom_bar_internal.dart`. No behaviour change — enables isolated unit testing of the shadow-outline geometry.
- **CLEANUP**: `dart fix --apply` removed 36 stale unused/unnecessary imports across 28 files produced by the quality-chain refactor.

### Test Coverage

- **TEST**: Reached **90%+ effective test coverage** (90.15% — excluding `src/renderer` GPU/shader layer where headless simulation is impossible). Total: **949 tests**, all passing.
- **TEST**: New `test/theme/glass_theme_helpers_test.dart` — 5 widget tests covering all 4 priority levels of `GlassThemeHelpers.resolveQuality()`.
- **TEST**: New `test/widgets/surfaces/build_icon_shadows_test.dart` — 6 unit tests covering `buildIconShadows()`: null thickness, active-icon suppression, shadow count, 45° offset math, and color propagation.
- **TEST**: Added `test/theme/`, `test/renderer/`, `test/types/`, `test/constants/`, `test/utils/`, and `test/widgets/` test suites (committed for the first time — these were written during the 0.7.13–0.7.14 coverage push but never staged).

# 0.7.14

### Bug Fixes


- **FIX**: `GlassSearchableBottomBar` — `extraButton` now fades out smoothly when search activates instead of being visually clipped/shrunk between the collapsing tab pill and the expanding search pill. Layout space is still reserved during the morph (no pills jump), only the visual opacity transitions. Taps on the extra button are also correctly blocked while hidden. Fades in when search closes.
- **FIX**: `GlassSearchableBottomBar` — spring morph animations no longer produce a visible jump when reversing direction. Previously the three spring controllers (`tabW`, `searchLeft`, `searchW`) were each started in separate `addPostFrameCallback` calls, introducing a 1-frame desync at reversal. All three are now started in a single batched callback, so the morph is perfectly synchronized in both directions.
- **FIX**: Indicator fade animation in `GlassBottomBar` / `GlassSearchableBottomBar` — replaced `Opacity` wrapper with `LiquidGlassSettings.visibility` fading. Wrapping a `BackdropFilter` in `Opacity` composites into an offscreen buffer, breaking backdrop sampling and causing the indicator to snap in/out instead of fading. The `visibility` path is a single GPU pass — no offscreen buffer — improving drag animation performance and working uniformly for all `blur` values.
- **FIX**: `GlassBottomBar`, `GlassSearchableBottomBar`, `GlassAppBar`, `GlassToolbar`, and `GlassSideBar` resolved to `GlassQuality.standard` instead of their documented `GlassQuality.premium` default. Fixed by setting `quality: null` in the built-in light/dark variants so each widget's documented default is respected.
- **FIX**: Setting any property in `GlassThemeVariant.settings` silently zeroed out all unset properties (e.g. setting only `thickness: 50` also reset `glassColor` to fully transparent). Fixed by introducing `GlassThemeSettings`: a parallel class with all-nullable fields that merges onto each widget's own defaults. Only the fields you explicitly set are applied; everything else inherits from the widget. `GlassThemeVariant.settings` now accepts `GlassThemeSettings?`.
- **FIX**: `GlassSearchableBottomBar` — multiple layout-math regressions in the morph animation corrected:
  - Reserved layout width now correctly scales to `min(size, searchBarHeight)` during search, eliminating the bloated gap when `searchBarHeight < barHeight`.
  - Extra button rendered width now matches the layout reserve (`extraTargetW`), preventing a 14 px overflow into the search pill when `searchBarHeight < barHeight`.
  - Restored `+ widget.spacing` in `targetSearchLeft`; an erroneous `tabToNextGap` variable had suppressed the gap between the tab pill and search pill when no extra button was present.
  - `collapseOnSearchFocus` now exclusively controls visibility/opacity — it no longer affects layout geometry. Toggling it mid-animation no longer triggers the spring or causes the button to jump inside the collapsed tab circle.
- **FIX**: `BottomBarTabItem` — removed a fixed `vertical: 4` padding wrapping the tab column. The padding consumed constraint space before `FittedBox` could scale, causing a 2 px `RenderFlex` overflow when the bar morphed to `searchBarHeight`.

### New

- **NEW**: `GlassThemeSettings` — a partial settings type for use in `GlassThemeVariant`. Accepts the same parameters as `LiquidGlassSettings` but all are nullable. Only non-null fields override the target widget's defaults, enabling precise single-property theme overrides without disturbing others.
- **NEW**: `GlassTabPillAnchor` enum + `GlassSearchableBottomBar.tabPillAnchor` — controls how the tab pill is anchored during the morph animation. `GlassTabPillAnchor.start` (default) preserves existing left-anchor behaviour. `GlassTabPillAnchor.center` makes both edges collapse symmetrically from the pill's centre for a more balanced look. The search pill position adjusts automatically in center mode.
- **NEW**: `GlassSearchBarConfig.showsCancelButton` now defaults to `true`. Tapping the dismiss pill unfocuses the keyboard and collapses search, matching the system-level behaviour seen across iOS apps (Weather, App Store, Apple News). Pass `showsCancelButton: false` to opt out.
- **NEW**: `GlassSearchBarConfig.collapsedTabWidth` is now nullable. When omitted, the collapsed tab pill automatically matches `GlassSearchableBottomBar.searchBarHeight`, ensuring it morphs into a geometric circle with no leftover horizontal margin. Pass an explicit value to override.
- **NEW**: `GlassBottomBarExtraButton.collapseOnSearchFocus` (default `true`) — controls whether the extra button collapses when the search field is focused. When `true`, the button fades out and its layout space spring-animates to zero, giving the search input the full available width (matching native iOS behaviour). When `false`, the button remains fully visible and tappable alongside the search input — useful for contextually relevant actions like a Filter button that applies to search results.
- **EXAMPLE**: `searchable_bar_repro.dart` added to the example app — exercises `GlassSearchableBottomBar` edge cases (extra-button fade, spring desync, bar-height scale, dismiss pill) in isolation. Run standalone: `flutter run -t example/lib/searchable_bar_repro.dart`.

# 0.7.13

### New — `GlassQuality.minimal`

- **FEAT**: `GlassQuality.minimal` — third quality tier: a crisp frosted glass surface with
  zero custom fragment shader execution on any platform. Uses `BackdropFilter` blur
  + Rec. 709 saturation matrix + a light-angle specular rim stroke. No refraction
  warping or chromatic aberration — a deliberately flat, clean aesthetic that looks
  excellent on any background and never adds GPU shader cost.

  Two distinct use cases:

  **Device fallback** — for hardware where even [standard] is too heavy:
  very old Android devices with limited shader driver support, or any device where
  `ImageFilter.isShaderFilterSupported` returns `false`.

  **GPU budget management** — for shader-dense screens: use [minimal] for background
  panels, list cards, and decorative containers while keeping [standard] or [premium]
  on the focal element. A screen with 15 glass list cards running [minimal] fires
  zero shader invocations during scroll — only `BackdropFilter` compositing.

  ```dart
  AdaptiveGlass(
    quality: GlassQuality.minimal,
    child: child,
  )
  ```

- **FEAT**: `GlassThemeVariant.minimal` — static preset that applies `.minimal` quality globally via
  `GlassThemeData`:

  ```dart
  GlassTheme(
    data: GlassThemeData(
      light: GlassThemeVariant.minimal,
      dark:  GlassThemeVariant.minimal,
    ),
    child: child,
  )
  ```

### New — `GlassPerformanceMonitor`

- **FEAT**: Debug/profile-only performance monitor that watches raster frame durations while
  `GlassQuality.premium` surfaces are active. When frames exceed the GPU budget
  for 60 consecutive frames, a single `FlutterError` is emitted with actionable guidance
  (specific widget parameters, device compatibility notes, and alternative quality tiers).

  **Zero production overhead** — the monitor never registers a callback in release builds.
  Enabled by default in debug/profile builds via `LiquidGlassWidgets.initialize()`:

  ```dart
  // Default: auto-enabled in debug/profile, zero-cost in release
  await LiquidGlassWidgets.initialize();

  // Opt out:
  await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);

  // Custom thresholds (advanced):
  GlassPerformanceMonitor.rasterBudget = const Duration(microseconds: 8333); // 120 fps
  GlassPerformanceMonitor.sustainedFrameThreshold = 120; // 2 seconds at 60 fps
  ```

  The monitor correctly attributes slowdowns to premium glass by counting active
  `GlassQuality.premium` surfaces. It stays silent when no premium widgets are mounted,
  avoiding false positives from other parts of the app.

---

# 0.7.12

### Bug Fixes

- **FIX**: Interactive blend-group stretch asymmetry — `LiquidStretch` now expands geometry symmetrically from the widget centre, fixing the left-leans-in / right-resists imbalance during touch-drag on button groups.

- **FIX**: Erroneous highlight bias — removed a legacy shader hack that skewed surface normals horizontally. Normals are now derived accurately from the SDF gradient, eliminating optical hotspots that made straight groups look crooked.

- **PERF**: Zero-jitter animation bounds — geometry texture mapping is now strictly bound to the physical size it was rasterised for, stopping frame-lag wobble when buttons change scale during interactive drags.

- **FIX**: Theme quality cascade — audited 15+ widgets (`GlassBottomBar`, `GlassSwitch`, `GlassTextField`, and others) that were silently overriding the global `GlassThemeVariant` quality setting with `GlassQuality.premium`. All widgets now correctly inherit and respect the global quality profile, protecting frame rate and thermal limits on older devices (e.g. iPhone 12 and below).

- **FIX**: Zero-thickness blur — setting `thickness: 0` no longer makes the glass fully transparent. Backdrop blur now renders correctly on glass surfaces regardless of geometric thickness, restoring backward-compatible behaviour.

- **FEAT**: `GlassSearchBarConfig.focusNode` — optional `FocusNode` for `GlassSearchBarConfig`. When provided, the caller has full programmatic focus control (`requestFocus()`, `unfocus()`, `addListener()`) independent of `autoFocusOnExpand`. The widget adopts the caller-provided node without disposing it (caller owns lifecycle), matching Flutter's own `TextField.focusNode` contract.

- **FEAT**: `GlassSearchBar.focusNode` — same `FocusNode` support added to the standalone `GlassSearchBar` for consistency. `GlassTextField` already had this.

- **FIX**: `ExtraButtonPosition` — new enum on `GlassBottomBarExtraButton`. Set `.position = ExtraButtonPosition.afterSearch` to pin the extra button to the **right** of the search pill. Spring geometry calculations reserve space correctly to prevent `RenderFlex` overflows during expand/collapse. Default is `ExtraButtonPosition.beforeSearch` — fully backwards-compatible.

- **FIX**: Windows / SkSL shader compilation — eliminated all dynamic array index expressions from `sdf.glsl`. The previous `getShapeSDFFromArray(int index)` computed offsets at runtime, which SkSL/glslang on Windows rejects with *"index expression must be constant"*. Replaced with literal-indexed `sdf0()`…`sdf15()` helpers and a fully-unrolled `sceneSDF` for 1–16 shapes. `MAX_SHAPES` stays 16; no API or visual change.

- **TOOLING**: `scripts/validate_shaders.sh` — macOS script that validates all shaders against Windows/SkSL compiler rules using `glslangValidator`. Run `bash scripts/validate_shaders.sh` before releasing. Requires `brew install glslang` (one-time).

---

# 0.7.11

### Bug Fixes

- **FIX**: Windows/Android build failure — three shader compilation errors on the SPIR-V/glslang path: loop bounds must be compile-time constants; `dFdx`/`dFdy` on a scalar `float` is rejected by glslang (geometry shader now uses `#ifdef IMPELLER_TARGET_METAL` to keep hardware derivatives on iOS/macOS and fall back to ±0.5 px finite differences on Vulkan/OpenGL ES); global non-constant initialisers at file scope in `liquid_glass_final_render.frag` moved into `main()`.

- **FIX**: Blend-group asymmetry — the liquid-glass merge neck between grouped buttons leaned toward the left button. Fixed with a bidirectional smooth-union pass (L→R + R→L, averaged 50/50) that cancels the directional bias exactly.

---

# 0.7.10

### Bug Fixes

- **FIX**: Windows build (`flutter build windows`) — two shader issues fatal on SkSL/glslang but silently accepted on Metal: `no match for min(int, int)` (replaced with a ternary) and global non-constant initialisers (moved into `main()`). No visual change on any platform.

---

# 0.7.9

### Bug Fixes

- **FIX**: Windows build failure — `uShapeData[MAX_SHAPES * 6]` was passed as a by-value function parameter, which glslang rejects. Fixed by accessing it as a global uniform. No visual change.

### Tweaks

- **TWEAK**: `GlassSearchableBottomBar` iOS 26 Apple News parity — animated inline `×` clear button replaces microphone when text is present; simplified hit-testing layout replaces `Overlay` layers; guaranteed GPU liquid-glass merging between the search and dismiss pills in a single shader pass.

---

# 0.7.8

### Tweaks

- **TWEAK**: `GlassThemeVariant.light` now defaults to a cool-tinted `glassColor` (`Color(0x32D2DCF0)`), stronger `refractiveIndex`, and boosted `ambientStrength` to ensure premium specular rendering and visible refraction on flat white backgrounds.

### Examples

- **Apple News demo** — replaced `Image.network` calls with pre-sized bundled assets (`example/assets/news_images/`) to fix Impeller GPU command-buffer overflow on iOS 26 physical devices.
- **Apple News demo** — `collapsedLogoBuilder` now mirrors the active tab icon instead of a static badge.

---

# 0.7.7

### Refactor

- **Internal**: Removed `GlassIndicatorTapMixin` and migrated `GlassTabBar` and `GlassSegmentedControl` fully to raw `Listener` pointer events, matching `GlassBottomBar`'s robust drag-cancel and press-and-hold handling. No API change.

---

# 0.7.6

### Bug Fixes

- **FIX**: `LiquidGlassBlendGroup` asymmetry — left buttons attracted their neighbours more strongly than right buttons in groups of 3+. Fixed with a bidirectional smooth-union pass (L→R + R→L, averaged 50/50). Two-shape groups are mathematically identical to before.

- **FIX**: `GlassButtonGroup` — glass effect could bleed as a dark rectangle on Impeller with `GlassQuality.premium` and `useOwnLayer: true`. A `ClipRRect(antiAlias)` now hard-clips the bleed at the superellipse boundary without forcing a quality downgrade.

---

# 0.7.5

### Bug Fixes

- **FIX**: `GlassBottomBar` / `GlassSearchableBottomBar` — added `HitTestBehavior.opaque` to the root `GestureDetector` so the full bar height reliably consumes pointer events on simulator and desktop.

- **FIX**: `GlassSearchableBottomBar` — keyboard no longer flickers on physical devices; focus is requested after the expansion animation completes.

- **FIX**: `GlassSearchableBottomBar` — dead zone at expanded search pill edges resolved; the full glass surface now claims taps and routes them to the search field.

### New — `GlassSearchBarConfig` parameters

Seven new parameters (all backwards-compatible):

| Parameter | Type | Default | Description |
|---|---|---|---|
| `autoFocusOnExpand` | `bool` | `false` | Keyboard opens automatically on expand. |
| `trailingBuilder` | `WidgetBuilder?` | `null` | Replaces the mic icon with any custom widget. |
| `textInputAction` | `TextInputAction?` | `null` | Keyboard action key (`search`, `done`, `go`, …). |
| `keyboardType` | `TextInputType?` | `null` | Keyboard layout (`url`, `emailAddress`, …). |
| `autocorrect` | `bool` | `true` | Disable for codes, usernames, etc. |
| `enableSuggestions` | `bool` | `true` | Controls QuickType bar on iOS. |
| `onTapOutside` | `TapRegionCallback?` | `null` | Called when user taps outside the field. |

---

# 0.7.4

### New Components

- **`GlassSearchableBottomBar`** — `GlassBottomBar` with a morphing search pill that shares the same `AdaptiveLiquidGlassLayer` as the tab pill, producing iOS 26 liquid-merge blending. When `isSearchActive` is `true` the tab pill collapses and the search pill expands via spring animation. Configured via `GlassSearchBarConfig`.

### Examples

- **Apple News demo** (`example/lib/apple_news/apple_news_demo.dart`) — iOS 26 Apple News replica showcasing `GlassSearchableBottomBar`.

### Visual Fixes

- **FIX**: Default glow color on press changed from iOS system blue to a brightness-adaptive neutral white (~35% light / ~22% dark), matching iOS 26 glass press behaviour.

---

# 0.7.3

### Performance

- **PERF**: Deleted unused `rotate2d()` from `render.glsl` — it was compiled into every shader binary but never called.
- **PERF**: Eliminated a redundant `normalize()` in `interactive_indicator.frag` by reusing an already-computed length.
- **PERF**: Removed a no-op `canvas.save()`/`canvas.restore()` pair in `GlassGlow` paint.

### Bug Fixes

- **FIX**: `GlassGlow` tracking — glow gradient is now correctly recreated each frame when `glowOffset` changes, fixing the spotlight freezing at its initial position.
- **FIX**: Glow on Skia/Web — `LightweightLiquidGlass` now wraps in `GlassGlowLayer`, giving the Skia path the same light-follows-touch behaviour as Impeller.
- **FIX**: Glow on first touch — spotlight now appears immediately at the tap position instead of sliding in from the widget's top-left corner.
- **FIX**: Glow tracking inside button groups — converted from widget-local to global coordinates so the spotlight correctly follows touches regardless of nesting depth.
- **FIX**: Glow radius on wide buttons — switched from `shortestSide` to `√(width × height)` so the spotlight scales proportionally to the button area.

---

# 0.7.2

### Performance & Polish

- **PERF**: Lightweight shader (`lightweight_glass.frag`) — reduced ALU instruction count ~10–15 ops per fragment; restored the `normalZ` Fresnel ramp to `sqrt(1 − dot(n,n))`.
- **PERF**: Impeller final render shader — eliminated `length()`/`normalize()` from anisotropic specular; made `getHeight()` fully branchless; collapsed four `step()` multiplications into one.
- **PERF**: Dart side — cached light direction trig in `LiquidGlassRenderObject` (only recomputed when `lightAngle` changes); changed `GlassGroupLink.shapeEntries` from `List` to `Iterable` to eliminate per-frame heap allocation.
- **FIX**: Adjusted `GlassBottomBar`, `GlassTabBar`, and `GlassSegmentedControl` spring from 500ms `bouncySpring` to 350ms `snappySpring`, matching iOS 26 segment-indicator physics.

---

# 0.7.1

### Bug Fixes

- **FIX**: `GlassBottomBar`, `GlassTabBar`, `GlassSegmentedControl` — rapid taps no longer prematurely snap the indicator, killing spring physics. Removed pixel-snapping from `onHorizontalDragDown` so taps correctly use spatial distance for the iOS 26 jump animation.

---

# 0.7.0

### New Components

- **`GlassDivider`** — iOS 26-style hairline separator, horizontal and vertical. Theme-adaptive opacity (dark: 20% white / light: 10% black).
- **`GlassListTile`** — iOS 26 Settings-style row with leading icon, title, subtitle, trailing widget, and automatic grouped dividers. Use inside a zero-padding `GlassCard`. Convenience constants: `GlassListTile.chevron`, `GlassListTile.infoButton`.
- **`GlassStepper`** — iOS 26 `UIStepper` equivalent. Compact `−`/`+` glass pill with auto-repeat on hold, `min`/`max` clamping, `wraps` cycling, fractional `step`, and haptic feedback.
- **`GlassWizard` + `GlassWizardStep`** — multi-step flow with numbered indicators, checkmarks, and expandable step content.

### Accessibility

- **`GlassAccessibilityScope`** — reads platform Reduce Motion and Reduce Transparency preferences and propagates them to all glass widgets in its subtree:
  - **Reduce Motion**: spring animations snap instantly.
  - **Reduce Transparency**: replaces the full glass shader pipeline with a plain `BackdropFilter(blur)` + frosted container.
- Semantics updated across all remaining widgets to match iOS `UIAccessibility` conventions.

### Performance

- **PERF**: `GlassSpecularSharpness` enum — replaces `pow(lightCatch, exponent)` (two transcendentals per fragment) with a pure squaring chain in `lightweight_glass.frag`. Zero transcendentals. Default: `.medium`.
- **PERF**: `pow(x, 1.5)` → `x·√x` in Impeller edge lighting — `sqrt()` is a single hardware SFU instruction.
- **PERF**: Anisotropic specular and Fresnel rim brightening ported from the Impeller path to `lightweight_glass.frag`, closing the largest visual gap between rendering paths.
- **PERF**: Content-adaptive glass strength — intensity auto-adjusts based on backdrop luminance on Impeller, or `MediaQuery.platformBrightness` on Skia/Web.

### Developer Experience

- **`GlassRefractionSource`** — renamed from `LiquidGlassBackground` to better reflect its role. `LiquidGlassBackground` remains as a deprecated `typedef` (removed in 1.0.0).
- **Synchronous background capture** — rebuilt using `boundary.toImageSync()` on native (zero CPU↔GPU readback) and async `toImage()` on web.

---

# 0.6.1

### Visual Quality

- **FIX**: True surface normal storage in geometry texture — the geometry pass now stores the SDF-gradient-derived surface normal instead of the refraction displacement vector. The render shader decodes and recomputes displacement via `refract()`. Specular highlights on blended glass shapes (e.g. two overlapping pills) now correctly follow true surface curvature rather than the refraction direction. Single-shape surfaces are visually identical to 0.6.0.
- **FIX**: Anisotropic specular highlights (Impeller) — specular lobe stretched 20% along the surface tangent, producing the horizontal oval highlight that matches iOS 26.
- **FIX**: Fresnel edge luminosity ramp (Impeller) — gentle brightness ramp at grazing angles matching iOS 26's centre-to-edge luminosity gradient.
- **FIX**: Luminosity-preserving glass tint in lightweight shader — replaced additive tint with the same `applyGlassColor()` model as the Impeller path: achromatic glass lifts toward white, chromatic glass shifts hue while preserving luminance.

### Performance

- **PERF**: Branchless `smoothUnion` — eliminated a conditional branch that caused warp divergence when glass shapes transition between merged and separate.
- **PERF**: `if/else if` dispatch in shape SDF — GPU now short-circuits after the first type match; default changed to `0.0` for a clearly visible failure mode.
- **PERF**: Single texture fetch when chromatic aberration is disabled — `interactive_indicator.frag` previously sampled the background three times unconditionally; 66% fewer texture reads in the common case.
- **PERF**: Flat-interior early-exit in final render shader — pixels where `normalXY ≈ 0` skip `refract()` and all texture samples, replaced with a single background sample. Lossless.

---

# 0.6.0

### Breaking Changes

- **`LiquidGlassLayer.useBackdropGroup` removed.** Glass layers now automatically detect a `BackdropGroup` ancestor. Remove `useBackdropGroup: true` from any `LiquidGlassLayer(...)` calls.

### New Features

- **`LiquidGlassWidgets.wrap()`** — wraps your app in a `GlassBackdropScope` in one line:
  ```dart
  runApp(LiquidGlassWidgets.wrap(const MyApp()));
  ```
- **`GlassMotionScope`** — drives glass specular angle from any `Stream<double>` (e.g. device gyroscope). No new dependencies required.

### Performance

- **PERF**: `GlassBackdropScope` auto-activation — glass layers automatically share a single GPU backdrop capture when a scope ancestor is present.
- **PERF**: Local-space geometry rasterization — geometry texture cached until pill size or shape changes, eliminating per-frame rebuilds during animation.
- **PERF**: Shader UV bounds check — discards fragments where geometry UV falls outside `[0, 1]`, preventing the thin "protruding line" artifact during jelly-physics expansion.

### Visual

- **FIX**: Refraction UV — uses `uSize` uniform (always valid on first frame) instead of `textureSize()` which returns `(0,0)` on the first frame in Impeller.
- **FIX**: `precision highp float` in final render shader (was `mediump`, risking colour banding on mobile).
- **FIX**: iOS 26 glass tint model — preserves backdrop luminance while shifting chroma. Replaces Photoshop Overlay mode.
- **FIX**: Leading-dot rim artifact — `x / (1 + x)` soft-clamping on highlight intensity prevents bright corner artifact during drag.
- **FIX**: Impeller indicator clipping — jelly physics animations no longer clip at the static bounding box (`clipExpansion` parameter added).
- **FIX**: Web & WASM — removed `dart:io` imports from shader resolution logic.

### Dependencies

- **Removed `motor` dependency** — replaced with self-contained `glass_spring.dart`. Zero third-party runtime dependencies beyond the Flutter SDK.

---

# 0.5.0

### Breaking Changes

**`LiquidGlass` removed from the public API.**
It was inadvertently exposed and silently renders nothing on Skia/Web. Use `AdaptiveGlass` instead:

```dart
// Before
LiquidGlass(settings: LiquidGlassSettings(...), child: ...)

// After
AdaptiveGlass(settings: LiquidGlassSettings(...), child: ...)
```

`LiquidGlassLayer`, `LiquidGlassBlendGroup`, `LiquidGlassSettings`, `LiquidShape`, `GlassGlow`, and `debugPaintLiquidGlassGeometry` remain public.

### New Features

- **`GlassBackdropScope`** — halves GPU blur capture cost when multiple glass surfaces are on screen simultaneously. Wrap your `MaterialApp` or `Scaffold` to activate:

```dart
GlassBackdropScope(
  child: MaterialApp(
    home: Scaffold(
      appBar: GlassAppBar(...),
      bottomNavigationBar: GlassBottomBar(...),
    ),
  ),
)
```

### Renderer

The renderer from `liquid_glass_renderer` (whynotmake.it, MIT) is now vendored directly, giving full control over the rendering pipeline with no user-facing API changes.

---

# 0.4.1

### Bug Fixes

- **FIX**: `GlassBottomBar` and other surfaces now correctly respond to dynamic `glassSettings` changes on `GlassQuality.standard` — `AdaptiveGlass` in grouped mode now inherits settings from `InheritedLiquidGlass` instead of using empty defaults.
- **FIX**: Luminance-aware ambient floor for white glass on `GlassQuality.standard` — high-opacity white glass no longer renders as dark grey.

### New

- **FEAT**: `GlassBottomBar.iconLabelSpacing` — configurable vertical gap between tab icon and label (default: `4.0`). Thanks @baneizalfe (#11).

### Breaking Changes

**Library-wide `IconData` → `Widget` API migration.** All icon parameters now accept any `Widget`:

```dart
// Before
GlassButton(icon: CupertinoIcons.heart, onTap: () {})

// After
GlassButton(icon: Icon(CupertinoIcons.heart), onTap: () {})
// Or any custom widget:
GlassButton(icon: SvgPicture.asset('assets/heart.svg'), onTap: () {})
```

`GlassBottomBarTab.selectedIcon` renamed to `activeIcon` to match Flutter's `BottomNavigationBarItem` convention.

---

# 0.4.0

### New Components

- **`GlassMenu` / `GlassMenuItem` / `GlassPullDownButton`** — iOS 26 morphing context menu with spring physics and position-aware expansion.
- **`GlassButtonGroup`** — joined-style container for related actions (e.g. Bold/Italic/Underline toolbar).
- **`GlassFormField`** / **`GlassPasswordField`** / **`GlassTextArea`** / **`GlassPicker`** — full iOS 26 input suite.
- **`GlassSideBar`** — vertical navigation surface with header, footer, and scrollable items.
- **`GlassToolbar`** — standard iOS-style action toolbar.
- **`GlassTabBar`** — horizontal tab navigation bar with animated indicator and scrollable mode for 5+ tabs.
- **`GlassProgressIndicator`** — circular and linear variants (indeterminate and determinate), iOS 26 specs.
- **`GlassToast` / `GlassSnackBar`** — 5 notification types, 3 positions, auto-dismiss, swipe-to-dismiss.
- **`GlassBadge`** — count and dot status badges, 4 positions.
- **`GlassActionSheet`** — iOS-style bottom-anchored action list.

### Performance

- **Universal Platform Support** — `AdaptiveGlass` and `AdaptiveLiquidGlassLayer` introduced. All 26 widgets deliver consistent glass quality on Web, Skia, and Impeller.
- **Batch-blur optimisation** — glass containers share a single `BackdropFilter` (was: one per widget). ~5× faster in common multi-widget layouts.
- **Impeller pipeline warm-up** — shaders pre-compile at startup to eliminate first-frame jank.

### Theme System

- **`GlassTheme` / `GlassThemeData` / `GlassThemeVariant`** — global styling and quality inheritance across all widgets. Set once, inherited everywhere.

---

# 0.3.0 — 0.1.0

Early access and preview releases establishing the core widget library, initial glass rendering pipeline (`LiquidGlass`, `LiquidGlassLayer`, `LiquidGlassBlendGroup`), and foundational components (`GlassBottomBar`, `GlassButton`, `GlassSwitch`, `GlassCard`, `GlassSearchBar`, `GlassSlider`, `GlassChip`, `GlassSegmentedControl`, `GlassSheet`, `GlassDialog`, `GlassIconButton`).
