# Architecture Guide

This document describes the internal architecture of `liquid_glass_widgets` for contributors and future maintainers.

---

## File Layout Convention

```
lib/
├── liquid_glass_widgets.dart     ← Public barrel (only export from here)
├── constants/
│   └── glass_defaults.dart       ← Static const values only — never test directly
├── types/                        ← Public enums and data types
├── theme/                        ← GlassTheme, GlassThemeData, GlassThemeHelpers
├── utils/                        ← Pure utilities (testable in isolation)
│   ├── draggable_indicator_physics.dart
│   └── glass_spring.dart
└── widgets/
    ├── interactive/              ← Leaf widgets (buttons, inputs, toggles)
    ├── shared/                   ← Package-internal shared sub-widgets (NOT exported)
    │   ├── adaptive_glass.dart
    │   ├── animated_glass_indicator.dart
    │   └── ...
    └── surfaces/                 ← Public surface/container widgets
        ├── glass_bottom_bar.dart
        ├── glass_tab_bar.dart
        ├── glass_searchable_bottom_bar.dart
        └── shared/               ← Internal widgets for bar-family surfaces
            ├── bottom_bar_internal.dart
            ├── tab_bar_internal.dart
            ├── searchable_bottom_bar_internal.dart
            └── glass_search_bar_config.dart   ← Shared config type (IS exported)
```

---

## The Internal Widget Extraction Pattern

Every bar-family widget (`GlassBottomBar`, `GlassTabBar`, `GlassSearchableBottomBar`) follows a strict two-file pattern.

### Rule: Public file = API only

The `glass_*.dart` file contains **only**:
- The public `StatefulWidget` class with full dartdoc
- Its `State` class (thin — only wires the public API to the internal widget)
- Public configuration data classes (e.g. `GlassTab`, `GlassBottomBarTab`)

It must **not** contain any stateful sub-widgets with gesture logic.

### Rule: Internal file = all logic

The `shared/*_internal.dart` file contains:
- All stateful sub-widgets (formerly `_PrivateWidget` classes)
- Gesture handlers, spring builders, drag physics
- Rendering helper methods (`_buildSimpleMode`, `_buildHighQualityMode` etc.)
- Pure utility functions annotated `@visibleForTesting`

The internal file is **not exported** from `liquid_glass_widgets.dart`.

### Why this pattern?

1. **Readability**: Public API is immediately clear without scrolling 1,000+ lines
2. **Testability**: Internal classes can be named (non-private) and constructed directly in tests
3. **Circular import prevention**: Config types that need to be imported by both the public widget and the internal widget live in their own `shared/` file (see `glass_search_bar_config.dart`)

### Current file sizes (v0.17.0)

| File | Lines | Internal file | Lines |
|---|---|---|---|
| `glass_bottom_bar.dart` | ~1 140 | `shared/bottom_bar_internal.dart` | ~882 |
| `glass_tab_bar.dart` | ~462 | `shared/tab_bar_internal.dart` | ~920 |
| `glass_searchable_bottom_bar.dart` | ~820 | `shared/searchable_bottom_bar_internal.dart` | ~820 |

> **v1.0 note:** `bottom_bar_internal.dart` and `tab_bar_internal.dart` are
> targeted for merger into a single `pill_internal.dart`. See the
> [v1.0 Roadmap](#v10-roadmap--pill-widget-unification) section.

---

## Import Rules

```
liquid_glass_widgets.dart
  └── exports glass_*.dart (public widgets)
  └── exports glass_search_bar_config.dart (shared config — IS public)
  └── does NOT export *_internal.dart files

glass_bottom_bar.dart
  └── imports shared/bottom_bar_internal.dart
  └── JellyClipper defined here (imported by bottom_bar_internal via `show`)

shared/bottom_bar_internal.dart
  └── imports glass_bottom_bar.dart show GlassBottomBarTab, GlassBottomBarExtraButton, JellyClipper
  └── imports shared/glass_search_bar_config.dart (NOT glass_searchable_bottom_bar.dart)
```

**Critical rule**: Never import a public widget file from its own internal file for anything other than its public data types via an explicit `show` clause. That is how the circular dependency was introduced in the first place and resolved in v0.7.16.

---

## Test Coverage Ceiling

**Effective coverage (renderer excluded): ~91.8 %** — 4 146 / 4 514 lines\
**Raw Codecov badge: ~81 %** — 4 496 / 5 553 lines (includes untestable GPU renderer)

The Codecov badge shows the raw number because that is what `lcov.info` contains.
The gap between 81 % and 91.8 % is accounted for entirely by `lib/src/renderer/`
(16 files, ~1 039 lines) — GPU `CustomPainter`, `RenderObject`, and shader-loading
paths that require a real GPU rasterizer and cannot be exercised in a headless VM.

The CI threshold gate strips `lib/src/renderer/*` before checking the 90 % floor,
so the gate measures effective coverage and will not false-fire on the renderer.

The remaining ~8.2 % (effective) should not be pursued:

| Category | Examples | Why untestable |
|---|---|---|
| GPU renderer paths | `paint()` in `CustomPainter` subclasses, shader uniform setters | Requires real GPU rasterizer — headless VM has no rasterizer |
| Web-only branches | `kIsWeb` blocks, `_captureBackgroundAsync` | Test VM is not a web runtime |
| Impeller warmup | `preWarm()` in `GlassEffect` | Shader loading fails silently in headless |
| Private constructors | `GlassDefaults._()`, singletons | Intentionally uncallable |
| Error catch branches | `toImageSync` catch | Only fires on real hardware failure |

**Do not** add workarounds (mocks of `kIsWeb`, fake GPU contexts) to push coverage
past this ceiling — the complexity is not worth it and the tests would not
represent real behaviour.

---

## Bug Fixes Reference (v0.7.16)

### Memory Leak — `GlassSearchableBottomBar`
When `controller` was replaced at runtime, `didUpdateWidget` attached a new listener without removing the old one. Pattern to follow everywhere a `ChangeNotifier` is used:

```dart
@override
void didUpdateWidget(covariant MyWidget oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.controller != widget.controller) {
    oldWidget.controller.removeListener(_onControllerChanged); // ← always remove first
    widget.controller.addListener(_onControllerChanged);
  }
}

@override
void dispose() {
  widget.controller.removeListener(_onControllerChanged);
  super.dispose();
}
```

### NaN/Infinity Guard — `DraggableIndicatorPhysics`
A zero-size `RenderBox` (during cold widget tree build) caused division-by-zero in velocity calculation, producing `NaN` velocities that broke spring snapping. Guard pattern:

```dart
final box = context.findRenderObject() as RenderBox?;
if (box == null || !box.hasSize || box.size.width == 0) return; // ← guard
final velocityX = details.velocity.pixelsPerSecond.dx / box.size.width;
```

---

## Quality System

Widgets resolve rendering quality in this priority order:

1. Explicit `quality:` parameter on the widget
2. `InheritedLiquidGlass` widget quality from an ancestor `LiquidGlassScope`
3. `GlassThemeData.qualityFor(context)` from `GlassTheme`
4. `GlassQuality.standard` (universal fallback)

Surface widgets (`GlassBottomBar`, `GlassAppBar`, `GlassToolbar`, `GlassSideBar`) use `GlassQuality.premium` as their documented default. All other widgets default to `GlassQuality.standard`.

Always resolve via:
```dart
final effectiveQuality = GlassThemeHelpers.resolveQuality(
  context,
  widgetQuality: widget.quality,
  // fallback: GlassQuality.premium  ← only for surface widgets
);
```

### Premium vs. Standard Rendering Physics

There is a fundamental mathematical difference in how visual properties are rendered across quality levels:

*   **Premium (Impeller / 3D Ray-Marched SDF):** 
    Uses a 3D ray-marched signed-distance field. `thickness` extrudes real 3D geometry towards the user, and `lightIntensity` calculates a physical specular reflection bouncing off that bevel.
*   **Standard / Minimal (Skia/Web / 2D Fragment Shader):** 
    Uses a 2D fragment shader or pure Canvas operations. Because there is no 3D geometry, `thickness` is faked via a 2D inner rim/stroke, and `lightIntensity` drives a 2D linear gradient over that rim.

**Tuning Tradeoff:** Because the physics models are entirely different, passing identical high values (e.g., `thickness: 15.0`, `lightIntensity: 1.5`) will look beautifully refractive and deep in Premium, but can look overpowering, thick, and overly bright (like a bold painted stroke) when the device falls back to Standard or Minimal. When designing for the package, it is often best to tune the baseline settings for Standard, or accept that Standard is meant to be a flatter, "frosted macOS" aesthetic while Premium provides the heavy "refractive iOS" look.

**Automatic Normalization (shipped — `AdaptiveGlass`):** To solve the tuning tradeoff without requiring developers to maintain two sets of values, `AdaptiveGlass` automatically intercepts `LiquidGlassSettings` before handing off to the 2D lightweight pipeline. When `!canUsePremiumShader` is true, the following scaling is applied:

```dart
final normalizedSettings = baseSettings.copyWith(
  thickness:
      (baseSettings.effectiveThickness * 0.4).clamp(0.0, double.infinity),
  lightIntensity:
      (baseSettings.effectiveLightIntensity * 0.6).clamp(0.0, 10.0),
);
```

This ensures that when an app tuned for Premium drops to Standard/Skia/Web, the stroke boldness and gradient brightness remain perceptually consistent without looking overpowering. Developers do **not** need to manually tune separate values for each quality tier.

---

## Production Performance (Android / Impeller / Mali GPU)

Production crash data (Play Console: 0.23% crash rate, 0.5% ANR rate) revealed
three distinct failure modes on **Mali GPU devices running Flutter's Impeller
engine (Vulkan backend)**. All three are rooted in Flutter engine bugs in
Impeller's Vulkan texture lifecycle management, but our package's GPU workload
(BackdropFilter layers, custom fragment shaders, `toImageSync` rasterization)
is the trigger that exposes them on low-end hardware.

### Known Failure Modes

| # | Failure | Root Cause | Our Mitigation |
|---|---------|-----------|----------------|
| 1 | Use-after-free in `DoRasterizeToImage` | `Picture.toImage()` callback destroys GPU textures on the platform thread after Mali GL context mutex is destroyed | Dimension guards + try-catch on `toImageSync` in geometry rasterization |
| 2 | Use-after-free during `Isolate::Shutdown` | `DlRuntimeEffectColorSource` (our shader) retained by `BackdropFilterLayer` finalized after Vulkan context teardown | Eager filter clearing in layer disposal, null-guarding in render object dispose |
| 3 | ANR: main thread blocked on `SurfaceChanged` | Raster thread overwhelmed by BackdropFilter + shader workload on low-end Mali | Faster quality degradation (2 windows instead of 3), lower warmup thresholds |

### Recommendations for Production Android Apps

1. **Use `adaptiveQuality: true`** — This is the single highest-impact
   configuration for production Android apps. The quality adapter automatically
   steps down to `minimal` (BackdropFilter-only, zero shader cost) on devices
   that cannot sustain the full glass effect, preventing crashes entirely.

2. **Set `initialQuality: GlassQuality.standard`** for apps targeting budget
   Android devices — this avoids the warmup benchmark window entirely and
   starts at a safe rendering tier.

3. **Persist quality across launches** — Use `initialQuality` with a storage
   mechanism (e.g. `SharedPreferences`) to restore the quality level from the
   previous session, eliminating warmup jank on repeat launches.

### Defensive Patterns Applied

- **Geometry rasterization**: Both `render()` and `renderAsync()` in
  `UnrenderedGeometryCache` guard against zero/negative dimensions and wrap
  `toImageSync` in try-catch to gracefully handle Mali GPU driver failures.

- **Render object lifecycle**: `LiquidGlassRenderObject.paint()` checks
  `attached` before any GPU operations. `dispose()` nulls `_settings` to break
  reference chains to the render shader's GPU resources.

- **Layer disposal**: `RenderLiquidGlassLayer.dispose()` eagerly clears
  `BackdropFilterLayer.filter` references before nulling layer handles, breaking
  the `DlRuntimeEffectColorSource → TextureVK → Vulkan mutex` retention chain.

- **Widget image lifecycle**: Both `GlassEffect` and `LightweightLiquidGlass`
  null `_backgroundImage` before disposing shaders in `dispose()`, and
  `_captureBackgroundSync` checks `mounted` after image creation.

---

## v1.0 Roadmap — `GlassTabBar` Unification

### Background

The `indicator_parity_demo.dart` in the example app was built to prove that all
four "pill" widgets render identically. The fact that a parity demo was needed
**is itself the architectural signal**: these four widgets share one physics
engine (`AnimatedGlassIndicator` + `DraggableIndicatorPhysics`) and differ only
in placement, chrome, and default sizing. In v0.17.0 the `indicatorPinchStrength`
parameter became the visible proof — one parameter controls the same physical
behaviour across all four widgets simultaneously.

In v0.18.0 we make this explicit in the public API.

---

### What iOS 26 Actually Has

Apple unified all floating glass navigation under one class in iOS 26:
`UITabBarController` (UIKit) / `TabView` (SwiftUI). It handles bottom nav,
in-page sub-nav, search tab morph, scroll-to-minimize, and sidebar (iPad)
through configuration — not through separate classes.

Key SwiftUI API surface:
```swift
TabView {
    Tab("Home", systemImage: "house") { HomeView() }
    Tab(role: .search) { SearchView().searchable(text: $text) }
}
.tabBarMinimizeBehavior(.onScrollDown)
.tabViewBottomAccessory { MiniPlayer() }
```

There is **no scrollable tab bar** in UIKit/SwiftUI. What looks like one in
Photos or App Store is a completely separate `ScrollView` of filter chips with
tap-only selection — no drag-to-navigate physics, no jelly indicator.

Our separate public widgets (`GlassBottomBar`, `GlassTabBar`,
`GlassSearchableBottomBar`) don't reflect Apple's architecture. They reflect
Flutter's `BottomNavigationBar` / `TabBar` split, which was the practical
starting point but is not the right long-term shape for a library claiming
iOS 26 fidelity.

---

### The Three-Category Model

#### 1. `GlassTabBar` — THE unified navigation tab bar

One widget with named constructors that handles all `UITabBarController`-
equivalent use cases:

```dart
// Default — inline tab bar (44px, no safe area, embedded in content)
GlassTabBar(
  tabs: [GlassTab(label: 'Timeline'), GlassTab(label: 'Mentions')],
  selectedIndex: i,
  onTabSelected: (i) => ...,
)

// Bottom — floating pill at screen bottom (64px, safe area, extraButton)
GlassTabBar.bottom(
  tabs: [GlassTab(label: 'Home', icon: Icon(...), activeIcon: Icon(...))],
  selectedIndex: i,
  onTabSelected: (i) => ...,
  extraButton: GlassTabBarExtraButton(...),
)

// Searchable — bottom bar + morphing search pill
GlassTabBar.searchable(
  tabs: [...],
  selectedIndex: i,
  onTabSelected: (i) => ...,
  searchConfig: GlassSearchBarConfig(...),
  isSearchActive: _searching,
)
```

The named constructor controls:
- Safe area handling (`.bottom()` and `.searchable()` only)
- Default height (64 px bottom, 44 px inline)
- Whether `extraButton` is accepted (`.bottom()` and `.searchable()` only)
- Whether `adaptiveBrightness` is wired (`.bottom()` and `.searchable()` only)
- Default quality level (`premium` for bottom, `standard` for inline)
- Search pill morph engine (`.searchable()` only)

**Unified tab type — `GlassTab`:**

The existing `GlassTab` class is expanded with optional fields from
`GlassBottomBarTab`. `GlassBottomBarTab` becomes a deprecated typedef.

```dart
class GlassTab {
  final Widget? icon;
  final Widget? activeIcon;     // from GlassBottomBarTab
  final String? label;
  final Color? glowColor;       // from GlassBottomBarTab
  final String? semanticLabel;
}
```

#### 2. `GlassFilterBar` — Scrollable horizontal chip row (new widget)

A **genuinely different component** that maps to Apple's scrollable
category/topic filter pattern (App Store, Apple News, Photos). This is NOT
`UITabBarController` — it is a horizontal `ScrollView` of selectable pill chips.

Key differences from the navigation tab bar:
- Scrolls horizontally with momentum
- Items can be variable width (text-driven)
- Selection is tap-only (no drag-to-navigate physics)
- No safe-area handling
- Suitable for 5–∞ items

The implementation is based on the community-contributed `GlassTabBar.isScrollable`
feature — that work is the foundation of `GlassFilterBar` and is preserved and
promoted to a proper first-class widget, not discarded.

#### 3. `GlassSegmentedControl` — stays unchanged

Maps directly to `UISegmentedControl`. The name is correct, the scope is
correct (2–4 segments, tap-only, no scrolling), and no iOS 26 precedent
exists for changing it. Leave it alone.

---

### Migration Path (no breaking changes)

| Today | v0.18.0 | Notes |
|---|---|---|
| `GlassBottomBar` | `@Deprecated` → `GlassTabBar.bottom()` | Thin shim, same behaviour |
| `GlassTabBar` (non-scrollable) | Stays as default constructor | Direct evolution |
| `GlassSearchableBottomBar` | `@Deprecated` → `GlassTabBar.searchable()` | Thin shim |
| `GlassTabBar(isScrollable: true)` | `@Deprecated` → `GlassFilterBar` | Scrollable logic extracted |
| `GlassBottomBarTab` | `@Deprecated` typedef → `GlassTab` | Same fields, shorter name |
| `GlassSegmentedControl` | **Unchanged** | Correct name, correct scope |

Deprecated widgets are kept as zero-logic shims through the 1.x series.
No user code breaks on upgrade. Shims are removed in 2.0.0.

### Important: `extraButton` is NOT Apple's `tabViewBottomAccessory`

Apple's `tabViewBottomAccessory` is a persistent widget (mini player, Now
Playing bar) that sits **above** the tab bar and animates with it. Our
`extraButton` sits **inside** the tab bar pill row as a trailing action button.
These are different features — do NOT rename `extraButton` to `accessory`.

The `tabViewBottomAccessory` equivalent in our library is the
`GlassScaffold.bodyOverlays` pattern used by the Apple Music and Podcasts
example apps, where a `GlassButton.custom` play pill is positioned via
`AnimatedPositioned` above the tab bar.

---

### Internal Work Required

#### Step 1 — Merge the duplicated internal files

`tab_bar_internal.dart` (~920 lines) and `bottom_bar_internal.dart` (~880 lines)
are parallel implementations of the same physics, gesture, and indicator engine.
Every bug must currently be fixed twice, and every feature (like `pinchStrength`)
must be added twice.

**Target:** One `pill_internal.dart` with a `placement` flag. The two current
files become thin wrappers that forward to it.

This is the **prerequisite** for the unified `GlassTabBar`.

#### Step 2 — Expand `GlassTab` + add named constructors to `GlassTabBar`

Expand `GlassTab` with `activeIcon`, `glowColor` fields. Add `.bottom()` and
`.searchable()` named constructors to `GlassTabBar`. The default constructor
retains current inline behaviour.

#### Step 3 — Deprecation shims

`GlassBottomBar` becomes a zero-logic `StatelessWidget` that builds
`GlassTabBar.bottom(...)`, forwarding all parameters. Same for
`GlassSearchableBottomBar` → `GlassTabBar.searchable(...)`.

#### Step 4 — `GlassFilterBar` widget

New widget. Takes the `isScrollable` logic from `tab_bar_internal.dart` as its
starting point. Add momentum physics, variable item widths. Deprecate
`GlassTabBar(isScrollable: true)` with a message pointing to `GlassFilterBar`.

#### Step 5 — Always-visible resting glass + `indicatorColor` rework

Spring target changes from `0.0` → `restingThickness` (default `0.35`).
`indicatorColor` is remapped from solid-pill fill → glass tint. See the
"v0.18.0 — Always-Visible Glass Pill" section below for full details.

---

### Why the Pinch Work (v0.17.0) Matters for This Plan

The `indicatorPinchStrength` feature shipped in v0.17.0 is the architectural
proof that the four pill widgets share one engine. Before the pinch feature,
someone could argue they merely looked similar. After v0.17.0, a **single
parameter controls the same physical behaviour across all four simultaneously**.

That is the v0.18.0 story:
> "In v0.17.0 we proved they're the same engine. In v0.18.0 we made it one widget."

---

## v0.18.0 Roadmap — Always-Visible Glass Pill + `indicatorColor` Rework

### Background

Discovered during v0.17.0 pinch work: native iOS 26 tab bars show the glass pill
**permanently** at the selected tab at rest — it is never hidden. Our current
implementation hides the glass entirely at rest (`thickness → 0`, `fade = 0`) and
substitutes a solid `indicatorColor` pill as a placeholder. This produces two
problems:

1. **Visual regression at rest.** The selected icon/label appears less vivid at rest
   than when active, because the glass effect (whitening, specular, refraction) that
   normally makes the content pop is absent.
2. **Wrong mental model.** The solid `indicatorColor` pill teaches developers to think
   about the resting indicator as a solid shape, when in reality it should be the same
   glass pill at a lower visibility.

### Reference — Native iOS 26 Behaviour

In Photos, Settings, and all first-party iOS 26 apps with `UITabBarController`:

- **Resting state:** glass pill always visible at ~35 % opacity — subtle frosted
  rounded-rectangle sitting behind the selected icon. No colour change to the icon.
- **Press / drag state:** pill expands with jelly physics, full glass opacity, pinch
  UV distortion active.
- The resting pill is the pressed pill at lower `visibility`. There is no "solid
  placeholder" — it is one continuous glass object.

### The Fix

#### 1. Spring rests at `restingThickness` (~0.35) instead of 0.0

```dart
// CURRENT — glass disappears at rest
value: (tabIsDown || moving) ? 1.0 : 0.0

// PROPOSED — glass stays at low visibility at rest
value: (tabIsDown || moving) ? 1.0 : restingThickness   // default 0.35
```

At `thickness = 0.35`:
- `fade = 0.35` → `visibility = 0.35` → subtle semi-transparent frosted pill ✓
- `backgroundOpacity = (1 − 0.35/0.15).clamp(0,1) = 0` → solid pill invisible ✓

The glass pill IS the resting indicator. The solid `backgroundIndicator` pill is
only ever visible during the brief 0 → 0.15 ramp at app startup or initial tab set.

#### 2. Pinch threshold recalibrated for new spring range

The `stablePinchFade` formula (shipped in v0.17.0) must be recalibrated so pinch is
**zero at resting thickness** and reaches full strength only during active drag/press:

```dart
// Pinch activates only above the resting threshold — no UV distortion at rest
final pinchActivation = ((fade - restingThickness) / (1.0 - restingThickness))
    .clamp(0.0, 1.0);
final stablePinchFade = 1.0 - (1.0 - pinchActivation) * (1.0 - pinchActivation);
```

At `fade = 0.35` (rest): `pinchActivation = 0` → no pinch ✓  
At `fade = 1.0` (drag): `pinchActivation = 1` → full pinch ✓

#### 3. `indicatorColor` repurposed as glass tint (Option A)

`indicatorColor` currently fills the solid background pill. In the new model that
pill is effectively gone at rest. Instead `indicatorColor` is mapped to the
`glassColor` of the indicator's `LiquidGlassSettings`, tinting the frosted glass
at rest with the supplied colour at a calibrated alpha (~15 %):

```dart
// Existing solid-pill path (REMOVED for resting state)
// indicatorColor → DecoratedBox fill colour

// New glass-tint path
final effectiveGlassColor = indicatorColor != null
    ? indicatorColor!.withValues(alpha: 0.15)
    : defaultGlassTint;   // white @ 8 % dark mode, black @ 6 % light mode
```

This means:
- `indicatorColor: null` (default) → neutral system-adaptive frosted tint — matches
  native iOS 26 exactly.
- `indicatorColor: Colors.purple` → subtle purple-tinted frosted glass resting pill.
- Existing code that passes `indicatorColor` continues to work visually — the colour
  is expressed through the glass tint rather than a solid box.

#### 4. `restingThickness` as a new public parameter

```dart
/// Minimum glass visibility at rest. Controls how visible the glass pill is
/// when no interaction is occurring.
///
/// - `0.35` (default) — native iOS 26 feel: subtle frosted pill always present.
/// - `0.0` — legacy behaviour: glass fully hidden at rest (solid indicatorColor
///   pill replaces it). Useful for pre-iOS 26 aesthetic targets.
/// - `0.5` — more prominent resting pill for dark backgrounds.
final double restingThickness;
```

Setting `restingThickness: 0.0` restores the legacy solid-pill resting behaviour,
providing a migration path for users who preferred it.

### Files to Change

| File | Change |
|---|---|
| `shared/pill_internal.dart` | Spring value target, `restingThickness` param (post-merge) |
| `shared/animated_glass_indicator.dart` | Pinch threshold, `restingThickness`-aware backgroundOpacity |
| `glass_tab_bar.dart` | Expose `restingThickness` on all constructors, remap `indicatorColor` → glass tint |
| `glass_segmented_control.dart` | Same (segmented uses a fixed spring so impact is minimal) |
| `glass_bottom_bar.dart` | Deprecation shim — forwards to `GlassTabBar.bottom()` |
| `glass_searchable_bottom_bar.dart` | Deprecation shim — forwards to `GlassTabBar.searchable()` |
| `test/golden/**` | All pill widget goldens will change — full regeneration required |

### Why This Is Post-0.17.0

- Visual breaking change — all resting-state goldens regenerate.
- `indicatorColor` semantic change requires a careful migration note in CHANGELOG.
- The pinch formula (v0.17.0) needs re-calibration — the two changes must ship
  together so the maths is self-consistent.
- Scope touches all four pill widgets simultaneously — warrants its own PR and
  dedicated review cycle.

---


1. All changes go through `mcp_dart-mcp-server_analyze_files` — must return `No errors`
2. Full test suite must pass: `mcp_dart-mcp-server_run_tests`
3. Update `CHANGELOG.md` with the new version entry before tagging
4. Bump `version:` in `pubspec.yaml`
5. Commit, `git tag v<version>`, push both
6. `dart pub publish`

The maintainer (sdegenaar) handles all git operations manually.
