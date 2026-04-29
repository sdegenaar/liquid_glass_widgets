# 0.9.1

## 🐛 Fix — Adaptive quality system calibration

Three coordinated improvements to `GlassAdaptiveScope` / `GlassQualityAdapter` that
prevent modern flagship devices from being incorrectly demoted to `standard` quality
during app startup.

### 1. Startup-skip window (`skipInitialFrames = 60`)

Phase 2 now discards the **first 60 frames** (≈ 1 second at 60 Hz) before collecting
warmup data. Those frames capture shader compilation, the first route transition, and
provider/localisation initialisation — all artificially inflated and unrepresentative of
steady-state glass rendering. Discarding them means the warmup benchmark reflects actual
glass workload, not cold-start overhead.

The constant is tunable for testing: `GlassQualityAdapter.skipInitialFrames = 0`.

### 2. Raised premium threshold: 12 ms → 16 ms

The old threshold of 12 ms (75 % of a 60 fps frame budget) was too tight.
The new threshold is **16 ms — one full 60 fps frame budget** — which has a cleaner
semantic meaning: "can the device render a premium glass frame within the 60 fps
budget at P75? Yes → premium."

| P75 raster time | Before | After |
|---|---|---|
| < 12 ms | premium | — |
| **< 16 ms** | standard | **premium** |
| 16–20 ms | standard | standard |
| > 20 ms | minimal | minimal |

### 3. `allowStepUp` defaults to `true`

Previously `allowStepUp` defaulted to `false`, meaning a Phase 2 decision could never
be corrected at runtime. If Phase 2 still makes a conservative call (e.g. on a device
under thermal load at startup), Phase 3 can now self-correct after 10 consecutive
under-budget windows (≈ 20 seconds) + an 8-second cooldown.

The step-up is deliberately slow and invisible to users. Set `allowStepUp: false`
explicitly if you need to lock quality for the session.

### Zero breaking changes (adaptive fix)

All three changes are additive or alter defaults in a user-beneficial direction.
Explicit constructor overrides (`allowStepUp: false`, `skipInitialFrames`, custom
threshold via `targetFrameMs`) continue to take precedence.

---

## 🐛 Fix — `GlassSwitch` drag interaction

`GlassSwitch` now supports tap and horizontal drag simultaneously without either
interaction interfering with the other.

**What was fixed:**

- **Tap animation restored** — registering both `onTap` and `onHorizontalDrag*`
  on the same `GestureDetector` caused Flutter's gesture arena to drop one
  interaction after the first touch. Taps now use `onTapDown` / `onTapUp` so
  they share the gesture stream cleanly with drags.
- **Slow drag no longer cancels** — Flutter fires `onTapCancel` before
  confirming a horizontal drag, which was deflating the "liquid bloom" pill
  prematurely. `_onDragStart` now stops any in-progress deflation and restores
  the plump state immediately.
- **Animation resets between interactions** — the thickness animation controller
  was left at `1.0` after its first cycle and silently skipped the bloom on
  subsequent taps. It now resets to `0.0` before each new forward pass.

**Gesture behaviour unchanged from the user's perspective:** tap = full liquid
jump animation; drag = thumb tracks finger with symmetric pill stretch; flick =
velocity-based snap.

### Zero breaking changes

No API changes. All existing `GlassSwitch` usages continue to work without
modification.

---

## 🐛 Fix — `interactionGlowColor` now reads from `GlassThemeData`

`GlassBottomBar` and `GlassSearchableBottomBar` (including its `collapsedLogoBuilder`
state and `SearchPill`) previously used a hardcoded white glow (`0x33FFFFFF`) when
no explicit `interactionGlowColor` was set, silently ignoring any `GlassThemeData`
override on the ancestor tree.

**Resolution order is now:**

```
interactionGlowColor param → GlassThemeData.glowColorsFor(context).primary → internal fallback
```

This means setting the primary glow color in `GlassThemeData` now takes effect
on the press-interaction highlight across both bar variants, including the collapsed
logo pill, without requiring any code changes at the call site.

### Affected widgets

| Widget | Location |
|---|---|
| `GlassBottomBar` | `TabIndicator` interaction glow |
| `GlassSearchableBottomBar` | `SearchableTabIndicator` (normal + collapsed/logo state) |
| `GlassSearchableBottomBar` | `SearchPill` expanded glow |

### Zero breaking changes

Explicit `interactionGlowColor` parameters continue to win with highest priority.
This only changes what happens when the parameter is left `null`.

---

## ✨ Feature — `glowBlurRadius`, `glowSpreadRadius`, `glowOpacity` on `GlassGlowColors`

Three new appearance fields on `GlassGlowColors` give fine-grained control over the
shape of the directional press-glow across all glass widgets:

| Field | Type | Default | Effect |
|---|---|---|---|
| `glowBlurRadius` | `double` | `4.0` | Gaussian blur sigma via `MaskFilter.blur` — softens the glow edge into a natural liquid-glass halo |
| `glowSpreadRadius` | `double` | `0` | Extra circle radius as a fraction of the layer's shortest side |
| `glowOpacity` | `double` | `1` | Master opacity multiplier (0–1) applied on top of the glow color's own alpha |

### Usage

Set them globally via `GlassThemeData` to affect all glass widgets at once:

```dart
GlassTheme(
  data: GlassThemeData(
    light: GlassThemeVariant(
      glowColors: GlassGlowColors(
        primary: Color(0x55FFFFFF),
        glowBlurRadius: 8,       // soft, diffuse halo
        glowSpreadRadius: 0.15,  // bleeds 15 % beyond touch radius
        glowOpacity: 0.75,       // 75 % of the color's own alpha
      ),
    ),
  ),
  child: ...,
)
```

Or override per-widget via `GlassButton.glowBlurRadius` / `glowSpreadRadius` /
`glowOpacity` — widget-level values take precedence over the theme.

### Defaults preserve existing visual behaviour

`glowSpreadRadius` and `glowOpacity` default to `0` and `1` respectively,
preserving previous rendering. `glowBlurRadius` defaults to **`4.0`** —
a soft, natural halo that better fits the liquid-glass aesthetic.
`MaskFilter.blur` is guarded at zero so there is no GPU cost when the value
is left at `0`. Set `glowBlurRadius: 0` explicitly for a hard-edge disc.

### Affected widgets

All widgets that render `GlassGlow` consume these fields, including:
`GlassButton`, `GlassBottomBar`, `GlassSearchableBottomBar`
(both the tab pill and the search pill), `GlassSlider`, `GlassSwitch`.

### Zero breaking changes

Existing code that does not set these fields continues to render identically.
`copyWith`, `==`, and `hashCode` all include the three new fields.

---



# 0.9.0

## ✨ New — `tabWidth` on `GlassBottomBar`

**`tabWidth` is now available on both `GlassBottomBar` and `GlassSearchableBottomBar`.**
Both bar variants share identical compact-sizing semantics and the same default.

### API

```dart
GlassBottomBar(
  // Default (no tabWidth): expand — pill fills available space.
  // tabWidth: 88.0 → iOS 26 compact sizing
  tabWidth: 88.0,
  ...
)
```

| `tabWidth` | Behaviour | 2 tabs | 3 tabs | 4 tabs |
|---|---|---|---|---|
| `null` *(default)* | Expand — fills available space | fills bar | fills bar | fills bar |
| `88.0` | Compact — iOS 26 style | 176 px | 264 px | 352 px |

The pill is automatically **clamped** so it never overflows its container,
regardless of how many tabs are present or how narrow the screen is.

### Zero breaking changes

`tabWidth` defaults to `null` (expand) on both `GlassBottomBar` and
`GlassSearchableBottomBar`. Existing code that does not pass `tabWidth`
continues to behave exactly as before — the tab pill fills the bar.
Pass `tabWidth: 88.0` to opt-in to iOS 26 compact sizing.

### Shared infrastructure (internal)

- **`bar_layout_utils.dart`** — new pure-Dart file containing
  `resolveTabPillWidth`. Both `GlassBottomBar` and
  `SearchableBottomBarController` delegate to this single function, eliminating
  two separate inline implementations of the same arithmetic.
- **`kBottomBarGlassDefaults`** — the 9-field `LiquidGlassSettings` constant
  that was previously copy-pasted into both bar state classes is now defined
  once in `bottom_bar_internal.dart` and referenced from both locations.

### Production hardening

- **Extra button pinned to trailing edge in `GlassBottomBar`.**
  Previously the extra button sat immediately adjacent to the tab pill when
  using compact `tabWidth` sizing, leaving empty space to its right. It is now
  always pinned to the far-right edge (using `Expanded` + `Align(centerRight)`)
  to match the searchable bar's layout. The `maxTabW` arithmetic is unchanged;
  only the Row structure changed. Works correctly in both compact and expand modes.
- `resolveTabPillWidth` guards against negative `maxAvailable` values
  (`math.max(0.0, maxAvailable)` before the `clamp`) to prevent a `RangeError`
  in unusual layout constraint environments.
- Both constructors now assert `tabWidth == null || tabWidth > 0` — passing a
  negative value previously produced a zero-width pill silently.
- Golden regression sentinel added for `tabWidth: null` (expand mode), so a
  layout regression in legacy behaviour is caught by the pixel-test suite.


### Example

`example/lib/tab_width_demo.dart` — covers both `GlassBottomBar`
and `GlassSearchableBottomBar` via a **Bar variant** chip, with live metrics
showing the computed pill width in real time.

---

# 0.8.4


## CI & Tooling

- **CI: Multi-platform test matrix.** The CI pipeline now runs the full test suite
  on `ubuntu-latest`, `macos-latest`, and `windows-latest` across both `stable`
  and `beta` Flutter channels. Previously only `macos-latest / stable` was tested,
  which silently allowed the three Windows shader regressions shipped in 0.7.9–0.7.12.
  Fail-fast is disabled so all platform failures are visible in a single run.

- **CI: Windows shader validation gate.** `glslangValidator` (the same SPIR-V
  compiler core Flutter uses on Windows) now runs in CI on every push and PR via
  the `shader-validation` job. Any shader that would produce a
  _"index expression must be constant"_ or _"loop bounds must be compile-time
  constants"_ error is caught before it reaches `main`. Previously this check only
  ran locally via `bash scripts/validate_shaders.sh` on macOS.

- **CI: pub.dev publish dry-run gate.** A dedicated `pub-check` job runs
  `dart pub publish --dry-run` on every push and PR. Catches missing dartdoc
  comments, `pubspec.yaml` issues, platform declaration gaps, and score regressions
  before they land in a release.

- **CI: Coverage threshold guard (≥ 90 % effective).** The pipeline now fails if
  effective line coverage drops below 90 % on the stable channel. _Effective_
  coverage is computed after stripping `lib/src/renderer/*` — 16 GPU
  `CustomPainter` / `RenderObject` files that cannot execute in a headless VM (no
  GPU rasterizer; documented as untestable in `ARCHITECTURE.md`). Current effective
  coverage is **91.8 %** (4 146 / 4 514 lines). A `.codecov.yml` config now mirrors
  this exclusion so the pub.dev / GitHub badge agrees with the CI gate rather than
  showing the raw ~81 % figure that included the untestable renderer paths.

- **CI: Run concurrency cancel.** Added `concurrency` group so redundant
  in-progress runs on the same branch are cancelled automatically, saving CI
  minutes on rapid-push workflows.

- **Tooling: `scripts/validate_shaders.sh` cross-platform update.** The shader
  validation script now resolves `glslangValidator` / `glslangValidator.exe`
  automatically, works on Windows (Git for Windows bash), and prints correct
  install instructions for macOS (`brew`), Ubuntu (`apt-get`), and Windows
  (`choco` / `winget`). Path resolution is now robust regardless of which
  directory the script is called from.

## GlassAdaptiveScope Diagnostics *(experimental)*

- **`GlassAdaptiveDiagnostic` — rich quality change event.** A new immutable
  data class is emitted whenever `GlassAdaptiveScope` changes quality tier.
  It carries the full context of *why* the change happened: `from`/`to` quality,
  `reason` (`warmupComplete`, `thermalDegradation`, `thermalRecovery`,
  `restoredFromCache`, `staticProbe`), `phase`, and the P75/P95 raster timing
  that triggered the decision.

- **`GlassAdaptiveScope.onDiagnostic`** — a new optional callback that receives
  a `GlassAdaptiveDiagnostic` alongside the existing `onQualityChanged`. The old
  callback is unchanged — this is purely additive.

- **`GlassAdaptiveScope.debugLogDiagnostics: true`** — zero-wiring diagnostic
  mode. Add this flag to print a structured console block on every quality change
  in debug builds (no-op in profile/release). Designed to lower the barrier for
  community threshold calibration reports:

  ```
  ┌─ 📊 GlassAdaptiveScope ─────────────────────────────────────────
  │  Change  : premium → standard
  │  Reason  : warmupComplete
  │  Phase   : runtime
  │  P75     : 14.2 ms
  │  Frames  : 10
  │
  │  📬 Post to: github.com/sdegenaar/liquid_glass_widgets/discussions
  └──────────────────────────────────────────────────────────
  ```

- **`GlassQualityChangeReason` enum** — exported publicly so analytics pipelines
  can filter on specific event types (e.g. only log `warmupComplete` and skip
  `restoredFromCache` noise).

- **Adapter diagnostic tracking** — `GlassQualityAdapter` now records
  `lastP75Ms`, `lastP95Ms`, `lastFramesMeasured`, and `lastChangeReason` before
  every quality decision so the scope can snapshot them synchronously before the
  async `addPostFrameCallback` gap.

## Bug Fixes

- **FIX: Refraction inverted on Android (Pixel 7, Mali GPU, OpenGL ES emulator).** On all
  devices where Impeller uses the OpenGL ES backend, the liquid glass refraction effect
  appeared to bend inward rather than outward — content beneath the glass lens distorted
  toward the centre instead of away from it. The glass bottom bar, segmented control
  indicator, and all premium-quality glass surfaces were affected.

  **Root cause:** OpenGL ES stores render-to-texture outputs with a bottom-left Y origin
  (Y increases upward), whereas Flutter's widget coordinate system uses Y-down. The shaders
  already flip `screenUV.y` and `geometryUV.y` with `1.0 − y` to compensate when _sampling_
  textures. However, the `displacement` vector (in `liquid_glass_final_render.frag`) and
  `edgeOffsetLogical` (in `interactive_indicator.frag`) were computed in Flutter's Y-down
  space and added directly to the Y-up UV without correcting the Y component. A positive Y
  displacement (outward at the bottom edge) therefore moved the sample _toward_ the centre
  in UV space — the exact opposite of the intended direction.

  **Fix:** Under `#ifdef IMPELLER_TARGET_OPENGLES`, negate the Y component of the
  displacement/offset vector before applying it to the sampled UV. This re-aligns the
  Y-down displacement with the Y-up UV coordinate space.

  The Metal (iOS/macOS) and Vulkan (Samsung S22 / Adreno / AMD Xclipse) code paths are
  unchanged — the fix is gated entirely by `IMPELLER_TARGET_OPENGLES` and verified against
  both a Pixel 7 API 35 emulator and a physical Samsung Galaxy S22.

---




# 0.8.3

## Performance & Bug Fixes


- **`GlassBottomBar` / `GlassSearchableBottomBar` — glass lens now correctly refracts active tab icons.** Previously the selected icon layer was rendered *above* the `AnimatedGlassIndicator` in a separate compositor layer, making it invisible to the `BackdropFilter`. The glass pill swept over a blank canvas, producing a flat, unrefracted active icon. Both the selected and unselected icon layers are now combined into a single `RepaintBoundary` placed *behind* the glass lens, so all icon colours are physically sampled and warped by the chromatic aberration as the pill moves — matching iOS 26 behaviour.

- **Performance improvement.** The fix eliminates 5–9 redundant GPU compositor layers per bar render frame: the per-tab `RepaintBoundary` nodes on both the selected and unselected icon rows have been removed in favour of a single shared compositor texture for the entire icon canvas. Fewer texture uploads, one `BackdropFilter` sample — net improvement at 120 Hz.

---

# 0.8.2


## Bug Fixes

- **`GlassQuality.premium` no longer crashes outside a `LiquidGlassLayer`.** Previously caused an opaque `Null check operator` crash. Now throws a descriptive `AssertionError` in debug builds and falls back gracefully (renders child without glass) in release. Fix: add `useOwnLayer: true` to any standalone `GlassButton` using `premium` quality.

- **`GlassBottomBar` / `GlassSearchableBottomBar` — repeat-tap on active tab now fires `onTabSelected` ([#22](https://github.com/sdegenaar/liquid_glass_widgets/issues/22)).** Previously the `index != widget.tabIndex` guard silently suppressed callbacks when the user tapped the already-selected tab, making it impossible to implement scroll-to-top or refresh-on-retap patterns. The guard has been removed; `onTabSelected` is now always called once per gesture lifecycle regardless of whether the tab index changes.

- **`GlassBottomBar` / `GlassSearchableBottomBar` — drag-end snaps to correct tab ([#23](https://github.com/sdegenaar/liquid_glass_widgets/pull/23)).** A coordinate-space mismatch in `_onDragEnd` caused the indicator to snap to the wrong tab: dragging to the centre of a 5-tab bar landed on tab 3 instead of tab 2. The fix corrects the inversion formula to `i = round(relX × (n − 1))`, which is the exact inverse of the alignment space `computeAlignment(i, n) = −1 + 2i/(n−1)`.

- **`GlassBottomBar` / `GlassSearchableBottomBar` — `onTabSelected` no longer fires twice per tap.** `BottomBarTabItem` had its own `onTap: () => onTabSelected(i)` callback that fired independently of the outer `TabIndicator`'s `onTapDown` handler, causing every tap to call `onTabSelected` twice. The item-level callback is now `null`; the outer indicator is the single source of truth for all selection events.

  > **Credit:** These interaction fixes were identified and originally patched by [@qinshah](https://github.com/qinshah) in [PR #23](https://github.com/sdegenaar/liquid_glass_widgets/pull/23). The implementation was refactored to preserve the existing jelly physics, desktop tap support, and fling-based navigation that the PR removed, and extended to cover `GlassSearchableBottomBar` with shared logic via the new internal `TabDragGestureMixin`.

## API

- **`GlassSearchBarConfig.expandWhenActive`** *(new)*. Controls whether the search pill expands when `isSearchActive` is `true`. Default `true` — no change needed for standard usage. Set to `false` for advanced layouts (e.g. Apple Music Play Pill pattern) where the search pill should remain compact while `isSearchActive` drives a non-search transition independently.

## Examples

- **`apple_music_demo`** — added as a reference for the Play Pill pattern: a floating `GlassButton` (`useOwnLayer: true`, `GlassQuality.premium`) that animates between a full-screen player and a mini-mode docked pill using `AnimatedPositioned` + `AnimatedOpacity`, synchronized with `GlassSearchableBottomBar`'s spring morph via `expandWhenActive`.

---


# 0.8.1

## New Features

### `GlassInteractionBehavior` — precise, orthogonal control of press interactions

A new first-class enum that independently controls the two dimensions of press
feedback on `GlassBottomBar`, `GlassSearchableBottomBar`, and `GlassTextField`
(as well as its derivative inputs):

| Value | Glow | Scale |
|---|---|---|
| `none` | ✗ | ✗ |
| `glowOnly` | ✓ | ✗ |
| `scaleOnly` | ✗ | ✓ |
| `full` *(default)* | ✓ | ✓ |

The *glow* is the iOS 26-style directional light spotlight that follows the
touch position across the glass surface. The *scale* is the spring-physics
size pulse on press.

```dart
// Glow only — light follows your finger, no bounce:
GlassBottomBar(
  interactionBehavior: GlassInteractionBehavior.glowOnly,
  ...
)

// Scale only — spring bounce, no glow:
GlassSearchableBottomBar(
  interactionBehavior: GlassInteractionBehavior.scaleOnly,
  pressScale: 1.06,
  ...
)

// Disable both for a completely static bar:
GlassBottomBar(
  interactionBehavior: GlassInteractionBehavior.none,
  ...
)
```

**Zero overhead when disabled.** When `interactionBehavior` suppresses glow (`none`
or `scaleOnly`), the `GlassGlow` sensor widget is removed from the tree entirely —
saving 3 widget allocations and 3 `RenderBox` nodes per tab indicator per frame.
Scale is resolved at build time to a scalar `1.0` with no animation controller
overhang.

### New parameters on `GlassBottomBar`, `GlassSearchableBottomBar`, and `GlassTextField`

`GlassTextField` now shares the same `interactionBehavior` API as the bar-family
widgets. The *scale* dimension maps onto the subtle press-bounce animation
(field squishes slightly when pressed down); the *glow* dimension is the directional
spotlight that tracks touch position across the glass surface.

`GlassPasswordField` and `GlassTextArea` delegate to `GlassTextField` and inherit
the new parameter automatically.

| Parameter | Widget(s) | Type | Default |
|---|---|---|---|
| `interactionBehavior` | All three | `GlassInteractionBehavior` | `.full` |
| `pressScale` | Bar widgets / Inputs | `double` | `1.04` (bars) / `1.03` (inputs) |
| `interactionGlowColor` | Bar widgets | `Color?` | `null` (theme default) |
| `glowColor` | `GlassTextField` | `Color?` | `null` (~12% white) |
| `interactionGlowRadius` | Bar widgets | `double` | `1.5` |
| `glowRadius` | `GlassTextField` | `double` | `1.5` |

All defaults preserve existing `0.8.0` visual behaviour — **no migration required**.

#### Migration from `enableGlow` / `enableFocusAnimation`

`GlassTextField.enableGlow` and `GlassTextField.enableFocusAnimation` have been
replaced by `interactionBehavior`. The mapping is direct:

```dart
// Before (0.8.0):
GlassTextField(enableGlow: false, enableFocusAnimation: false)

// After (0.8.1):
GlassTextField(interactionBehavior: GlassInteractionBehavior.none)

// Before: glow only
GlassTextField(enableGlow: true, enableFocusAnimation: false)
// After:
GlassTextField(interactionBehavior: GlassInteractionBehavior.glowOnly)
```


## Bug Fixes

- **FIX**: `SearchPill` was silently ignoring `interactionBehavior`. The `interactionGlowColor`
  parameter was never passed to the `SearchPill` constructor, so the search pill always rendered
  with a visible glow regardless of the bar's `interactionBehavior` setting. The glow was
  hardcoded to `Color(0x1FFFFFFF)` even when `behavior = none`.

- **FIX**: `SearchPillState` had no glow short-circuit on the expanded pill path. Added
  `_wrapWithGlow` helper (matching the pattern already in `TabIndicatorState` and
  `SearchableTabIndicatorState`) to skip `GlassGlow` allocation when glow is suppressed.

---

# 0.8.0

## New Features

### `GlassAdaptiveScope` *(experimental)* — automatic runtime quality adaptation

A new scope widget that automatically adjusts `GlassQuality` for its subtree
based on real raster performance observed from `SchedulerBinding` frame timings.
Handles the three device scenarios that are impossible to test on a developer
device:

- **Broken / slow shader drivers** (e.g. Pixel 4a, Galaxy A22 class): detected
  synchronously at startup via `ImageFilter.isShaderFilterSupported` and capped
  immediately to `minimal`.
- **Warm-up jank** ("wrong quality at startup"): resolved by a ~180-frame
  benchmark that measures real P75 raster durations and sets the initial quality
  tier before the user notices.
- **Thermal throttling** ("fine at launch, janky after 10 minutes"): detected
  and corrected by a continuous runtime hysteresis engine.

**Three-phase adaptation:**

| Phase | Trigger | Action |
|---|---|---|
| Phase 1 — Static probe | Mount | Forces `minimal` on unsupported hardware; caps at `standard` on web |
| Phase 2 — Warm-up | First ~180 frames (~3 s at 60 fps) | Sets initial quality from real P75 raster durations |
| Phase 3 — Runtime hysteresis | Ongoing | Degrades after 3 bad windows; recovers after 10 good windows (8 s cooldown) |

The scope acts as a **quality ceiling** — widgets with an explicit `quality:`
parameter are unaffected. The ceiling is enforced by
`GlassThemeHelpers.resolveQuality`, which reads `GlassAdaptiveScopeData` from
the nearest ancestor scope.

```dart
// Per-screen control:
GlassAdaptiveScope(
  child: Scaffold(...),
)

// Advanced — conservative start for fragmented Android market:
GlassAdaptiveScope(
  initialQuality: GlassQuality.standard, // earn your way up to premium
  allowStepUp: true,
  onQualityChanged: (from, to) => analytics.log('glass_quality_changed'),
  child: child,
)
```

> **Experimental in 0.8.0.** `GlassAdaptiveScope` and `GlassAdaptiveScopeConfig` are
> annotated `@experimental`. The three-phase adaptation logic is architecturally sound
> and fully tested, but the Phase 2 timing thresholds (P75 < 12 ms → premium,
> 12–20 ms → standard, > 20 ms → minimal) have been validated by reasoning, not yet
> by broad real-device data across the Android fragmentation landscape.
>
> **How to enable it:** `LiquidGlassWidgets.wrap(myApp, adaptiveQuality: true)`
> (opt-in, default `false`).
>
> **If you observe unexpected behaviour** — quality too low on a mid-range device,
> or stuck at `standard` on a flagship — please file an issue with your device model
> and raster timings from Flutter DevTools. Your data will be used to tune the
> thresholds for a future release.

### `GlassAdaptiveScopeConfig` *(experimental)* — portable configuration value object

Bundles all `GlassAdaptiveScope` parameters into a single `const`-constructible,
equality-comparable value object. Used by `LiquidGlassWidgets.wrap()` and useful
for passing scope configuration through APIs that cannot accept widget parameters
directly.

```dart
const config = GlassAdaptiveScopeConfig(
  initialQuality: GlassQuality.standard,
  allowStepUp: true,
  targetFrameMs: 8, // 120 Hz ProMotion
);
```

## API Refactor — `initialize()` and `wrap()` separation

The responsibilities of `initialize()` and `wrap()` have been clarified and
made consistent with the broader Flutter ecosystem (cf. `easy_localization`,
`MaterialApp`):

| Method | Responsibility |
|---|---|
| `initialize()` | Async platform / engine setup only (shader prewarming, Impeller pipeline, debug monitor) |
| `wrap()` | Widget-tree composition and all behavioral configuration |

### `wrap()` — new parameters

```dart
runApp(LiquidGlassWidgets.wrap(
  const MyApp(),
  respectSystemAccessibility: false, // moved from initialize()
  adaptiveQuality: true,             // new — inserts GlassAdaptiveScope
  adaptiveConfig: GlassAdaptiveScopeConfig(
    initialQuality: GlassQuality.standard,
    allowStepUp: true,
  ),
));
```

### Scope nesting order inserted by `wrap()`

`GlassAdaptiveScope` → `GlassBackdropScope` → `child`

## Breaking Changes

### `initialize(respectSystemAccessibility:)` removed

`respectSystemAccessibility` has moved from `initialize()` to `wrap()`.

**Migration** (one-line change):

```dart
// Before (0.7.x):
await LiquidGlassWidgets.initialize(respectSystemAccessibility: false);
runApp(LiquidGlassWidgets.wrap(const MyApp()));

// After (0.8.0):
await LiquidGlassWidgets.initialize();
runApp(LiquidGlassWidgets.wrap(const MyApp(), respectSystemAccessibility: false));
```

The `LiquidGlassWidgets.respectSystemAccessibility` getter and setter remain
available as an escape hatch for tests and advanced runtime overrides. In
production code, set it through `wrap()`.

## Bug Fixes

### Glass invisible on white / light backgrounds (transparency regression)

- **FIX**: Standalone glass widgets (`GlassButton`, `GlassContainer`, `GlassTextField`,
  `GlassCard`, and all widgets that delegate to them) rendered with zero opacity on
  light backgrounds when no explicit `settings:` were provided. Root cause: these
  widgets fell through to `InheritedLiquidGlass.ofOrDefault()`, which returns
  `LiquidGlassSettings()` — a default with `glassColor: Color(0x00FFFFFF)` (alpha = 0).
  The lightweight shader computes `body tint = glassColor.alpha × 0.15`, so
  `0 × 0.15 = 0` — the glass body was literally transparent regardless of `thickness`
  or `blur`.

  **Fix**: Replaced all `InheritedLiquidGlass.ofOrDefault()` call sites with the new
  `GlassThemeHelpers.resolveSettings()`, which traverses the full 5-level priority chain:

  1. Widget-level `settings:` parameter (explicit wins)
  2. `InheritedLiquidGlass` — nearest parent `AdaptiveLiquidGlassLayer`
  3. `LiquidGlassWidgets.globalSettings` — app-level override
  4. `GlassThemeData` — brightness-aware theme variant (light / dark)
  5. `LiquidGlassSettings()` — absolute last resort

  Standalone widgets now correctly resolve to the theme's `glassColor` and are
  always visible out of the box.

### Light theme defaults rebalanced

- **TWEAK**: `GlassThemeVariant.light` updated for an icy-frosted aesthetic that
  reads clearly on white backgrounds:

  | Property | Before | After |
  |---|---|---|
  | `blur` | 10.0 | 6.0 |
  | `glassColor` | `0x73FFFFFF` (45% neutral white) | `0x4AD2DCF0` (~29% cool blue-white) |
  | `chromaticAberration` | 0.1 | 0.3 |
  | `thickness` | 16.0 | 20.0 |
  | `lightIntensity` | 1.0 | 1.2 |

  The cool blue-white tint (`D2DCF0`) matches the icy tone of iOS 26 frosted glass.
  Blur 6 gives visible background diffusion without obscuring content.

## API

### `GlassBackdropScope` now exported from the main barrel

- **FIX**: `GlassBackdropScope` was missing from `liquid_glass_widgets.dart`. Consumers
  had to use the internal path
  `package:liquid_glass_widgets/widgets/shared/glass_backdrop_scope.dart`, which is
  fragile and undocumented. It is now a first-class public export.

  **Migration** — update any direct internal imports:
  ```dart
  // Before (workaround, fragile):
  import 'package:liquid_glass_widgets/widgets/shared/glass_backdrop_scope.dart';

  // After (correct):
  import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
  ```

- **CHORE**: add CI and Codecov badges.

# 0.7.16

### Bug Fixes

- **FIX**: `GlassSearchableBottomBar` — memory leak when `controller` was swapped at runtime. The old controller's listener was never removed before attaching to the new controller. Now correctly removed in `didUpdateWidget`.
- **FIX**: `DraggableIndicatorPhysics` — velocity NaN/Infinity guard. A zero-size render box (e.g. during widget tree warm-up) could produce `Infinity` or `NaN` for `velocityX`, which propagated into the spring physics and caused erratic snapping. Now clamped to 0 when the box has no size.

### Refactor (zero breaking changes)

- **REFACTOR**: Extracted `GlassSearchBarConfig` from `glass_searchable_bottom_bar.dart` into a dedicated file `lib/widgets/surfaces/shared/glass_search_bar_config.dart`. Resolves a circular import between the public widget and its internal sub-widgets. `GlassSearchBarConfig` is re-exported from the barrel file — no consumer-facing API change.
- **REFACTOR**: Extracted `_TabIndicator` / `_TabIndicatorState` from `glass_bottom_bar.dart` into `shared/bottom_bar_internal.dart` as `TabIndicator` / `TabIndicatorState` (package-internal, not exported). Follows the same pattern used for `GlassSearchableBottomBar`. `glass_bottom_bar.dart` reduced from **1,406 → ~895 lines**.
- **REFACTOR**: Extracted `_TabBarContent`, `_TabBarContentState`, and `_TabItem` from `glass_tab_bar.dart` into `shared/tab_bar_internal.dart`. `glass_tab_bar.dart` reduced from **728 → ~310 lines**. Architecture is now consistent across all bar-family widgets.

### Test Coverage

- **TEST**: Reached **91.85% effective coverage** (up from 89.6% in 0.7.15 — excluding GPU/shader renderer paths that are physically untestable in a headless VM). Total: **1,031 tests**, all passing, 0 analyzer warnings.
- **TEST**: New `test/widgets/surfaces/glass_bottom_bar_drag_test.dart` — 7 regression tests covering `_onDragEnd` physics snapping, `_onDragCancel` (mid-drag and no-drag), slow drags, fast flings, and full-bar sweeps. These paths are the highest-risk regressions in navigation UX.

# 0.7.15


### Bug Fixes

- **FIX**: `lib/theme/glass_theme_settings.dart` was accidentally omitted from version control in 0.7.14. All consumers of `GlassThemeSettings` received a compile error (`type 'GlassThemeSettings' is not a subtype`). This release commits the missing file. No API change — `GlassThemeSettings` was already exported from `liquid_glass_widgets.dart`.
- **FIX**: `GlassPerformanceMonitor._emitWarning` — division-by-zero crash when `rasterBudget` was sub-millisecond (< 1 ms). Protected with a `max(1, ...)` guard.

### Refactor (zero breaking changes)

- **REFACTOR**: Consolidated 18 quality-resolution chains (`widgetQuality ?? inherited?.quality ?? themeData.qualityFor(context) ?? GlassQuality.standard`) into a single canonical helper: `GlassThemeHelpers.resolveQuality(context, widgetQuality: ..., fallback: ...)`. Surface widgets (`GlassAppBar`, `GlassToolbar`, `GlassBottomBar`, `GlassSearchableBottomBar`, `GlassSideBar`) pass `fallback: GlassQuality.premium` to preserve their documented defaults. All other widgets default to `GlassQuality.standard`.
- **REFACTOR**: Extracted `_buildIconShadows` from `BottomBarTabItem` to a `@visibleForTesting` top-level function `buildIconShadows(...)` in `bottom_bar_internal.dart`. No behaviour change — enables isolated unit testing of the shadow-outline geometry.

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
