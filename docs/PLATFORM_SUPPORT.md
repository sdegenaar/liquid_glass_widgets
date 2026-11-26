# Platform Support

> Last updated: 2026-11-26 · Tracks `v1.21+` (Flutter `>= 3.41.0`, Dart `>= 3.5.0`)

This document describes the rendering behaviour, shader pipeline, known
limitations, and developer guidance for every platform targeted by
`liquid_glass_widgets`.

---

## Supported Platforms

| Platform | Tier | Active Renderer | `GlassQuality.premium` | `GlassQuality.standard` | `GlassQuality.minimal` | `GlassSurfaceStyle.solid` |
|---|---|---|---|---|---|---|
| **iOS** | ✅ Primary | Impeller → Metal | ✅ Full shader | ✅ Lightweight shader | ✅ BackdropFilter | ✅ Shader-free |
| **Android (Impeller)** | ✅ Primary | Impeller → Vulkan / GLES | ✅ Full shader | ✅ Lightweight shader | ✅ BackdropFilter | ✅ Shader-free |
| **Android (Skia)** | ✅ Supported | Skia → OpenGL ES | ⬇️ Capped to `standard` | ✅ Lightweight shader | ✅ BackdropFilter | ✅ Shader-free |
| **macOS** | ✅ Supported | Impeller → Metal | ✅ Full shader | ✅ Lightweight shader | ✅ BackdropFilter | ✅ Shader-free |
| **Windows** | ⚠️ Partial | Skia/ANGLE → DirectX (Impeller opt-in / Flutter 3.50+ desktop defaults) | ⬇️ Capped to `standard` on Skia & under `GlassAdaptiveScope` | ✅ Lightweight shader | ✅ BackdropFilter | ✅ Shader-free |
| **Linux** | ⚠️ Partial | Skia (Impeller opt-in / Flutter 3.50+ desktop defaults) | ⬇️ Capped to `standard` on Skia & under `GlassAdaptiveScope` | ✅ Lightweight shader | ✅ BackdropFilter | ✅ Shader-free |
| **Web (CanvasKit / Wasm)** | ⚠️ Partial | CanvasKit / SkWasm | ⬇️ Always capped to `standard` | ✅ Lightweight shader | ✅ BackdropFilter | ✅ Shader-free |

> **Tier definitions:**
> - **Primary** — actively calibrated and validated against native iOS 26/27 and Android hardware/simulators.
> - **Supported** — API-complete and validated on real desktop/legacy mobile renderers, including keyboard traversal and focus rings.
> - **Partial** — API-complete with shader CI validation across HLSL/FXC, SPIR-V, and `impellerc`, with platform-specific caps or caveats documented below.

---

## Rendering Tiers & Surface Modes

`liquid_glass_widgets` adapts automatically to the active Flutter rendering
backend (`ui.ImageFilter.isShaderFilterSupported` and `kIsWeb`) and supports
both **iOS 27** (`GlassStyle.ios27`, default) and **iOS 26**
(`GlassStyle.ios26`) optics.

### `GlassQuality.premium` (Impeller)

Full custom GLSL multi-pass pipeline (`liquid_glass_geometry_blended.frag` +
`liquid_glass_render.frag`, plus `lens_content_warp.frag` for native iOS 26/27
tab-bar lens optics via `IndicatorLensOptics`):

- Two-pass GPU render: blended SDF geometry precompute → lighting & refraction
- True per-pixel `refract()` (`GlassLensModel.paraxial` on `ios27`, Snell bevel
  on `ios26`), luminance-weighted `frost`, directional `rimShade` / `rimLight`,
  chromatic dispersion, native lifted tab-bar content-fold + spectral-fringe
  optics (`IndicatorLensOptics`), shader-level touch specular (`uTouchPosition`
  / `uTouchIntensity`), and SDF metaball blending (`LiquidGlassBlendGroup`)
- Shared backdrop reads via `GlassBackdropGroup` across top/bottom bar chrome
  and progressive blur strips (`v1.9.0+`, `v1.20.0+`)
- **Requires Impeller.** Automatically capped to `GlassQuality.standard` when
  `kIsWeb` is `true` or `ui.ImageFilter.isShaderFilterSupported` returns
  `false`
- **Default under `GlassStyle.ios27` / `ios26` for:**
  - Persistent navigation chrome (`GlassAppBar`, `GlassTabBar`, `GlassToolbar`,
    `GlassScaffold.bodyOverlays`)
  - Transient overlays (`GlassDialog`, `showGlassConfirmationDialog`,
    `GlassModalSheet`, `GlassMenu`, `GlassPopover`, `GlassContextMenu`)
  - Hero interactive lenses (`GlassSwitch`, `GlassSlider`,
    `GlassSegmentedControl`), which lazy-mount their lens shader only while
    pressed or dragged so resting rows hold zero shader layers
- **Not for scrolling list cards** — use `GlassSurfaceStyle.solid` (preferred,
  matching iOS `.insetGrouped` lists) or `GlassQuality.standard` / `minimal` for
  scrolling body content.

### `GlassQuality.standard` (All Platforms)

Single-pass lightweight fragment shaders (`lightweight_glass.frag` and
`interactive_indicator.frag`):

- Works identically across Impeller, Skia, CanvasKit/Wasm, Windows, and Linux
- Meniscus rim absorption, directional `rimLight`, perimeter hairline contours,
  `GlassBodyMode.adaptive` / `GlassBodyMode.clear`, and optional wallpaper
  refraction via `LiquidGlassScope` / `GlassBackgroundSource`
- Interactive indicator lenses skip backdrop blur in `standard` mode to keep
  frame times flat on Skia and Web
- Recommended default for standalone body glass containers and cross-platform
  apps targeting Web or Skia.

### `GlassQuality.minimal` (Zero Custom Shaders)

Shader-free frosted path (`_FrostedFallback`: `ClipPath` + `BackdropFilter` +
Rec. 709 saturation + specular rim stroke):

- Safe on every renderer with zero custom fragment shader compilation
- Stationary surfaces (bars, cards, resting buttons marked `isStationary: true`)
  keep their `BackdropFilter` blur; animated interactive buttons omit
  `BackdropFilter` during spring motion to avoid compositor flicker
- Pair with `const GlassThemeData.minimal()` (`GlassThemeVariant.minimalLight`
  and `GlassThemeVariant.minimalDark`, `v1.19+` / `v1.20+`) for calibrated
  neutral light/dark tints out of the box.

### `GlassSurfaceStyle.solid` & Nested Vibrancy (`AdaptiveGlass.vibrancy`)

- **`GlassSurfaceStyle.solid`** bypasses `AdaptiveGlass`, `BackdropFilter`, and
  all fragment shaders completely (zero GPU shader cost on every platform). Use
  it on `GlassContainer.card`, `GlassGroupedSection`,
  `GlassReorderableList.grouped`, `GlassDisclosureGroup.standalone`,
  `GlassDatePicker`, `GlassMultiDatePicker`, and `GlassModalSheet` (for an
  always-opaque sheet at every detent); child inputs, pickers, buttons, and
  `GlassToggle.button` inherit `solid` automatically via
  `InheritedGlassSurfaceStyle`.
- **Nested glass vibrancy (`_VibrancyFill`)** activates automatically when a
  grouped glass control is placed inside an enclosing glass surface
  (`InheritedLiquidGlass.avoidsRefraction == true`), matching UIKit's
  `UIVibrancyEffect` with zero second `BackdropFilter` pass and avoiding
  Impeller tile-memory stalls.

### Automatic Quality Negotiation (`GlassAdaptiveScope`)

Enable `LiquidGlassWidgets.wrap(adaptiveQuality: true, ...)` (or mount
`GlassAdaptiveScope` directly) to negotiate a session-wide quality ceiling in
three phases:

1. **Phase 1 — Static probe (synchronous):** Forces `minimal` if
   `ui.ImageFilter.isShaderFilterSupported == false`, and caps `maxQuality` to
   `standard` on Web, Windows, and Linux (see
   [`GlassQualityAdapter`](../lib/utils/glass_quality_adapter.dart)).
2. **Phase 2 — Warm-up benchmark:** Skips initial startup frames, then samples
   real raster frame timings (`P75`):

   | P75 raster time | Quality ceiling selected |
   |---|---|
   | `< 20 ms` | `premium` |
   | `20–28 ms` | `standard` *(or frost-free `premium` first when `frostStep: true`)* |
   | `> 28 ms` | `minimal` |

3. **Phase 3 — Runtime hysteresis:** Degrades when `P95 > 1.5× targetFrameMs`
   for 2 consecutive windows; recovers (when `allowStepUp: true`) after 10
   consecutive windows below `0.6× targetFrameMs` with an 8-second cooldown.
   Supports `frostStep: true` (drops iOS 27 `frost` before stepping down from
   `premium` to `standard`) and `GlassAdaptiveScope.holdMeasurement()` to pause
   sampling during heavy app work (`v1.20.0+`).

See [`ADAPTIVE_QUALITY.md`](./ADAPTIVE_QUALITY.md) for threshold calibration,
cold-start persistence, and `GlassAdaptiveScopeConfig` examples.

---

## iOS

**Renderer:** Impeller → SPIRV-Cross → MSL → Metal

- Primary reference platform for both `GlassStyle.ios27` and `GlassStyle.ios26`.
- All quality tiers, `GlassBackdropGroup` shared backdrops, `LiquidGlassBlendGroup`
  teardrop morphs, display-bezel superellipse page transitions
  (`GlassPageTransitionClip` / `GlassPageTransitionsBuilder`), and iPhone Duo
  vertical chrome (`GlassVerticalBar`) are fully supported.
- **Native `reduceTransparency` detection:** Currently approximated via
  `MediaQuery.highContrastOf(context)` inside `GlassAccessibilityScope` while
  awaiting upstream [Flutter #190318](https://github.com/flutter/flutter/issues/190318).
- **`ClipRRect(borderRadius: 9999)` PlatformView forwarding:** Flutter
  PR [#177551](https://github.com/flutter/flutter/pull/177551) (included in
  Flutter `3.41+`) forwards `ClipRRect` clips to the iOS PlatformView mutator
  stack. `LiquidOval` uses a large rounded-rect radius on native platforms to
  benefit from this forwarding; arbitrary `ClipPath` shapes over PlatformViews
  still require `platformViewBackdrop: true` or `PlatformViewGlassMode.passthrough`.

---

## Android

**Renderer:** Impeller → SPIRV-Cross → GLSL ES → Vulkan / OpenGL ES (default),
or Skia → OpenGL ES (`--no-enable-impeller`)

### Impeller (Default)

- All three quality tiers work. `LiquidGlassWidgets.initialize()` preloads all
  six shaders asynchronously before `runApp()` to avoid first-frame stalls.
- Under `GlassAdaptiveScope`, Android devices default to conservative warm-up
  seeding (`standard` until Phase 2 finishes) unless `initialQuality` is set,
  protecting GLES-only devices from cold-start jank while promoting capable
  Vulkan devices to `premium`.

### Skia (Legacy)

- `ui.ImageFilter.isShaderFilterSupported` returns `false`; any `premium`
  request silently caps to `GlassQuality.standard` at render time.
- `standard`, `minimal`, and `GlassSurfaceStyle.solid` all work normally.

**Runtime renderer check:**

```dart
import 'dart:ui' as ui;

final bool impellerAvailable = ui.ImageFilter.isShaderFilterSupported;
```

---

## macOS

**Renderer:** Impeller → SPIRV-Cross → MSL → Metal

- Uses the same Impeller/Metal shader pipeline as iOS; all three quality tiers
  and `GlassBackdropGroup` / `LiquidGlassBlendGroup` work out of the box.
- Most Apple Silicon and discrete-GPU Macs comfortably sustain
  `GlassQuality.premium` under `GlassAdaptiveScope`.
- Full keyboard traversal (`Tab`, `Space`, `Enter`, `Escape`), single-node
  VoiceOver semantics (`GlassFocusRegion`), mouse hover highlights, and
  macOS-appropriate checked radio menu semantics (`GlassMenuItem.semanticsChecked`)
  are supported across the widget library.

---

## Windows

**Renderer:**
- **Flutter `3.41–3.49`:** Skia → ANGLE → DirectX by default (Impeller opt-in
  via `--enable-impeller`).
- **Flutter `3.50+`:** Desktop Impeller rollout (ANGLE/DirectX or Vulkan).

### Runtime Behaviour in `liquid_glass_widgets`

- **Skia:** `ui.ImageFilter.isShaderFilterSupported` is `false`, so `AdaptiveGlass`
  caps `GlassQuality.premium` to `GlassQuality.standard`.
- **Impeller on Windows (`--enable-impeller` / Flutter 3.50+ desktop defaults):**
  - `AdaptiveGlass` checks `ui.ImageFilter.isShaderFilterSupported`, so explicit
    `GlassQuality.premium` surfaces can execute when Impeller is active.
  - By default, `LiquidGlassWidgets.initialize(warmUpMode: GlassWarmUpMode.auto)`
    skips preloading the multi-pass premium shaders on Windows, and
    `GlassAdaptiveScope` (`GlassQualityAdapter._staticProbe()`) caps quality to
    `GlassQuality.standard` to prevent runtime GLSL/ANGLE compilation stalls on
    the raster thread. Pass `warmUpMode: GlassWarmUpMode.always` if you
    explicitly opt into desktop Impeller `premium` without `GlassAdaptiveScope`.
- **Drop shadows:** `AdaptiveGlass` detects `TargetPlatform.windows` and uses
  the inverse-clipped `DecoratedBox` `BoxShadow` fallback instead of the GPU
  cutout shadow on own-layer surfaces to avoid OpenGL/ANGLE `saveLayer`
  artifacts.

---

## Linux

**Renderer:**
- **Flutter `3.41–3.49`:** Skia by default (Impeller opt-in via
  `--enable-impeller`).
- **Flutter `3.50+`:** Desktop Impeller rollout (OpenGL ES / Vulkan).

### Runtime Behaviour in `liquid_glass_widgets`

- Mirrors Windows for quality negotiation:
  - Under Skia, `ui.ImageFilter.isShaderFilterSupported` is `false` and
    `premium` silently caps to `standard`.
  - Under Impeller (`--enable-impeller` / Flutter 3.50+ desktop defaults),
    `AdaptiveGlass` supports `premium` when requested directly, while
    `GlassAdaptiveScope` static-caps to `standard` and `GlassWarmUpMode.auto`
    skips multi-pass premium preload by default to avoid driver-dependent GLSL
    compilation hitches.
- `standard`, `minimal`, and `GlassSurfaceStyle.solid` work across both
  renderers with no known Linux-specific bugs.

---

## Web (CanvasKit & WebAssembly / SkWasm)

**Renderer:** CanvasKit (Skia Wasm) or SkWasm (`flutter build web --wasm`)

### Quality Limits & Shader Lifecycle

- `GlassQuality.premium` is **always capped to `GlassQuality.standard`** via
  `kIsWeb` in `AdaptiveGlass`, `GlassEffect`, and `GlassAdaptiveScope` (and
  `LiquidGlassWidgets.initialize()` skips multi-pass premium preload on Web).
- `LightweightLiquidGlass` allocates per-widget `FragmentShader` instances on
  Web (`kIsWeb`) rather than sharing a mutable global shader instance.
- **Flutter `3.50+` Wasm builds (`flutter build web --wasm`):** All six
  fragment shaders enforce single-exit `void main()` (`v1.17.4`,
  `flutter/flutter#190809`) so `impellerc` compiles cleanly with zero warnings.
- **Drop shadows:** `AdaptiveGlass` routes `kIsWeb` to the inverse-clipped
  `DecoratedBox` `BoxShadow` fallback (the GPU cutout path is native-only).

### Known Limitation: `LiquidOval` Circular Clipping (CanvasKit)

**Status:** Active (tracked in [`ROADMAP.md`](./ROADMAP.md#platform-edge-cases)).

`LiquidOval` uses `BorderRadius.circular(9999)` (`GlassDefaults.capsuleRadius`)
to preserve iOS PlatformView `ClipRRect` forwarding (Flutter #177551). On
CanvasKit Web, that oversized radius can break path clipping on `GlassGlow` and
`DecoratedBox` shadows.

**Workaround on Web:** Use `LiquidRoundedSuperellipse` / `LiquidRoundedRectangle`
with an explicit finite `borderRadius` (e.g. half the widget's height) or
`GlassQuality.minimal` where circular clip artifacts appear.

---

## Flutter 3.50+ & `cupertino_ui` Compatibility

`liquid_glass_widgets` `1.x` supports **Flutter `>= 3.41.0`** while staying
ready for **Flutter `3.50+`**:

- **Shaders:** Validated against `impellerc` across Metal, OpenGL ES, Vulkan,
  and SkSL targets with zero warnings (including the Flutter 3.50 / Windows FXC
  single-exit `main()` requirement from `flutter/flutter#190809`).
- **Apps migrating to standalone `package:cupertino_ui` on Flutter `3.50+`:**
  Add Flutter's compatibility bridge to your `CupertinoApp` so `CupertinoTheme`
  and `CupertinoLocalizations` propagate into `1.x` SDK-Cupertino packages:

  ```dart
  CupertinoApp(
    builder: (context, child) => CupertinoUiCompatibilityBridge(child: child!),
    home: const MyHomePage(),
  )
  ```

- **Full `cupertino_ui` migration** (raising the SDK floor to Flutter
  `>= 3.50.0`) is scheduled for **`2.0.0`** (see
  [`ROADMAP.md`](./ROADMAP.md#sdk-dependency--behaviour-changes-scheduled-for-200)).

---

## Shader Compatibility Rules (Impeller, SkSL, HLSL/FXC, ANGLE)

All six shaders in `shaders/` (`lightweight_glass.frag`,
`interactive_indicator.frag`, `liquid_glass_geometry_blended.frag`,
`liquid_glass_render.frag`, `lens_content_warp.frag`, and
`progressive_blur.frag`) must compile cleanly on
**Impeller** (Metal / Vulkan / GLES), **SkSL / SPIR-V**, **Windows HLSL/FXC**,
and **Web ANGLE**. Respect these seven rules whenever editing any `.frag` or
`.glsl` file:

1. **Single-exit `void main()` alongside `sampler2D`** (`flutter/flutter#190809`)
   — never place early or multiple `return;` statements inside `void main()` in
   a fragment shader that samples a `sampler2D`. Assign `fragColor` through
   structured `if`/`else` branches and exit once at the end of `main()`.
   Enforced statically by `scripts/validate_shaders.sh` and
   [`test/shaders/single_return_main_test.dart`](../test/shaders/single_return_main_test.dart).
2. **No dynamic array indexing** — uniform array indices must be compile-time
   constant literals (e.g. `uShapeData[]` via `SDF_SHAPE_N(BASE)`).
3. **Static compile-time loop bounds** — all `for` loops must use `const int`
   bounds or unrolled steps.
4. **No unguarded `dFdx` / `dFdy` / `fwidth`** — unavailable on some SPIR-V
   targets; guard Metal-only usage with `#ifdef IMPELLER_TARGET_METAL`.
5. **No `min(int, int)`** — use ternary expressions (`a < b ? a : b`).
6. **No non-constant global initialisers** — unpack uniforms inside `main()`.
7. **No array parameters passed by value** — access global uniform arrays
   directly inside helper functions.

**Validate locally before opening a PR:**

```bash
bash scripts/validate_shaders.sh
flutter test test/shaders/
```

`scripts/validate_shaders.sh` runs the zero-dependency HLSL/FXC single-exit
check, `glslangValidator --target-env vulkan1.0` (when installed), and Flutter's
own `impellerc` across runtime stages (failing on any `[WARNING]` or error).

---

## PlatformViews (Maps, WebViews, Camera, Video)

Hybrid-composed `PlatformView`s (e.g. `google_maps_flutter`, `webview_flutter`,
`camera`, `video_player`) are excluded from Flutter's `RepaintBoundary` /
shader backdrop capture. `liquid_glass_widgets` provides **two** ways to render
glass cleanly over a PlatformView:

### Option 1: Live Blur Fallback (`platformViewBackdrop: true`)

Available on `AdaptiveGlass`, `AdaptiveLiquidGlassLayer`, `GlassContainer`,
`GlassButton`, `GlassIconButton`, `GlassToggle.button`, `GlassButtonGroup`,
`GlassTabBar`, `GlassNavigationShell`, `GlassModalSheet`, `GlassPopover`,
`GlassMenu`, and `showGlassConfirmationDialog`:

- Routes the widget to `_FrostedFallback` (a live `BackdropFilter`), which
  re-samples the composited scene including the PlatformView underneath.
- **Trade-off ("quality cliff"):** Silently caps `GlassQuality.premium` to
  `GlassQuality.minimal` (no shader refraction) and keeps the `BackdropFilter`
  active during interaction/drags, adding one live `BackdropFilter` pass per
  widget. Set `platformViewBackdrop: true` **only** when a PlatformView is
  actually behind the control:

  ```dart
  GlassTabBar.bottom(
    platformViewBackdrop: currentPageHasMapView,
    ...
  )
  ```

### Option 2: Premium Passthrough (`PlatformViewGlassMode.passthrough`, `v1.2.0+`)

Configured via `LiquidGlassSettings(platformViewMode: PlatformViewGlassMode.passthrough)`:

- Keeps the `GlassQuality.premium` shader rim, Fresnel, and lighting active
  while letting coverage follow what was actually sampled — clear where the
  backdrop texture was empty (so the PlatformView shows through instead of solid
  black or `platformViewFallbackColor`), and opaque where Flutter widgets exist.
- Best for floating pills/chrome over maps or video where you want sharp
  transparent pass-through with a crisp refractive edge and no live
  `BackdropFilter` cost.
- Contrast with the default `PlatformViewGlassMode.fallbackColor` (which fills
  unsampled pixels with `LiquidGlassSettings.platformViewFallbackColor`).

---

## Renderer Feature Matrix

| Feature | Impeller (iOS / macOS / Android) | Skia / CanvasKit / Windows Skia |
|---|---|---|
| Per-pixel `refract()` (`paraxial` & Snell) | ✅ `premium` | ❌ Capped to `standard` |
| Luminance-weighted iOS 27 `frost` | ✅ `premium` | ❌ Capped to `standard` |
| Chromatic dispersion & SDF metaball blend | ✅ `premium` | ❌ Capped to `standard` |
| `GlassBackdropGroup` shared backdrop reads | ✅ `premium` | ❌ N/A |
| `ProgressiveBlur` shader | ✅ Custom two-pass blur | ⬇️ Graceful single-pass / fallback |
| Lightweight shader (`lightweight_glass.frag`) | ✅ `standard` | ✅ `standard` |
| `BackdropFilter` fallback (`GlassQuality.minimal`) | ✅ `minimal` | ✅ `minimal` |
| `GlassSurfaceStyle.solid` (zero shader) | ✅ All modes | ✅ All modes |
| `GlassGlow` touch specular | ✅ Widget + shader (`uTouchPosition`) | ⚠️ Shader-based (`glowIntensity`) |
| Drop shadow (light mode) | GPU cutout (native) / inverse-clipped `BoxShadow` (Windows) | Inverse-clipped `BoxShadow` |
| `LiquidOval` clipping | ✅ `ClipRRect` PlatformView forwarding | ⚠️ CanvasKit Web `circular(9999)` clip bug |

---

## Validation Status

| Platform | Environment | Impeller | Skia / Web | Notes |
|---|---|---|---|---|
| **iOS** | iOS 26 & iOS 27 Simulator + physical iPhones | ✅ Validated | N/A | Primary calibration baseline (`v1.21+`) |
| **Android** | Impeller (Vulkan / GLES) & Skia fallback | ✅ Validated | ✅ Validated | Conservative `GlassAdaptiveScope` warm-up |
| **macOS** | Apple Silicon (Impeller Metal) | ✅ Validated | — | Full keyboard, focus ring & VoiceOver support |
| **Web** | Chrome (CanvasKit & Wasm) | N/A | ✅ Shader CI + `standard`/`minimal` | Single-exit Wasm shaders verified (`v1.17.4+`); `LiquidOval` clip caveat |
| **Windows** | Skia/ANGLE & `impellerc` HLSL/FXC CI | ⚠️ Static-capped to `standard` in `GlassAdaptiveScope` | ✅ Shader CI + `standard`/`minimal` | Single-exit HLSL/FXC verified (`v1.17.4+`) |
| **Linux** | Skia & `impellerc` SPIR-V CI | ⚠️ Static-capped to `standard` in `GlassAdaptiveScope` | ✅ Shader CI + `standard`/`minimal` | No Linux-specific rendering bugs tracked |

---

## Filing Platform-Specific Issues

When reporting a platform-specific bug, please include:

- `flutter --version` and `flutter doctor -v`
- Target OS, device/GPU (e.g. *"Windows 11, AMD Radeon RX 6700"*, *"Pixel 8, Android 16"*)
- Active renderer (`Impeller` vs. `Skia`, `--enable-impeller` / `--no-enable-impeller`, `--wasm`)
- Active `GlassStyle`, `GlassQuality`, and whether `GlassAdaptiveScope` is enabled
- A minimal reproduction snippet

Issues: [github.com/sdegenaar/liquid_glass_widgets/issues](https://github.com/sdegenaar/liquid_glass_widgets/issues)
