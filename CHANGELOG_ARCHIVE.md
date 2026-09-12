# 0.10.3

Big thanks to [@yukinoaruu](https://github.com/yukinoaruu) for [PR #47](https://github.com/sdegenaar/liquid_glass_widgets/pull/47) — a comprehensive interaction engine upgrade for `GlassMenu` that brings it more in line with iOS 26 context menu behaviour. 🙏

## ✨ Features

### Heterogeneous menu items — `GlassMenuDivider` and `GlassMenuLabel`

Menus now accept any `Widget`, enabling iOS 26-style section grouping:

```dart
GlassMenu(items: [
  const GlassMenuLabel(title: 'Actions'),    // renders as 'ACTIONS'
  GlassMenuItem(title: 'Save', onTap: () {}),
  const GlassMenuDivider(),
  GlassMenuItem(title: 'Delete', isDestructive: true, onTap: () {}),
])
```

`GlassMenuLabel` exposes a `height` parameter (default `30.0`) so custom font sizes don't drift the selection-pill position.

### `GlassMenuItem` — rich content

Six new parameters: `subtitle`, `enabled`, `titleStyle`, `subtitleStyle`, `iconColor`, `iconSize`.

### Scroll-aware selection pill

A sliding highlight follows the pointer and disappears automatically when the user starts scrolling (10 px drag-slop guard + `ScrollNotification` listener).

### Elastic stretch and scroll-safe glow

`GlassMenu` now wraps in `LiquidStretch` for spring physics on drag. `glowOnTapOnly: true` (the new default) suppresses the glass glare after a drag, preventing a stuck-glow artefact during list scrolling. Full parameter surface: `interactionScale`, `stretch`, `stretchResistance`, `stretchAxis`, `allowPositiveX/NegativeX/Y`.

### New primitives on `GlassGlow` and `GlassContainer`

`GlassGlow.enabled`, `GlassGlow.glowOnTapOnly`, and `GlassContainer.glowIntensity` are now available for custom integrations.

## 🐛 Fixes

- **GlassMenu — double `BackdropFilter`** · Removed an extra blur layer above `GlassContainer` that doubled the blur sigma and created an over-frosted ring.
- **GlassMenu — DETACHED compositing layers** · Removed the outer `RepaintBoundary` wrapping `_buildMorphingContainer`. When `GlassContainer(useOwnLayer: true)` installs a `BackdropFilter` layer it forces compositing on the entire subtree; a `RepaintBoundary` above it fought the compositor for `OffsetLayer` ownership, leaving descendant `RepaintBoundary` nodes (i.e. each `GlassMenuItem`'s glass layer) DETACHED from the scene. `GlassGlow` and `GlassContainer` already own their compositing layers — no extra boundary is needed. Separately, `Opacity` widgets at `>= 1.0` are now skipped entirely so no gratuitous `OpacityLayer` is inserted when compositing is already being forced by a `BackdropFilter` descendant.
- **GlassMenu — layout overflow during open animation** · `GlassContainer(height: currentHeight)` propagated tight height constraints through its entire subtree during the morph. When menu items became visible (previously at `value > 0.65`), the container was only ~114 px tall while 3 items needed 132 px, causing the `Column` inside `Positioned.fill` to overflow by 18 px. Fixed by deferring content rendering until `value ≥ 0.85`, exactly when `currentHeight` becomes `null` and the container sizes naturally — no tight-constraint cascade possible.
- **GlassMenu — interaction glow bleeds onto background** · `GlassGlow` previously wrapped `GlassContainer` from the outside. `_RenderGlassGlowLayer.paint()` called `canvas.drawCircle()` over the full overlay canvas with no shape boundary, causing the radial gradient to paint beyond the menu's glass shape onto the background. Fixed by moving `GlassGlow` inside `GlassContainer`'s `clipBehavior: Clip.antiAlias` subtree — matching the architecture used by `GlassButton`.
- **GlassMenuItem — `AnimatedScale` layout overflow on press** · `AnimatedScale` (backed by `RenderTransform`) retains the pre-scale layout size during a 0.98-scale press animation, causing a spurious overflow against the menu's bounded `Positioned.fill`. Fixed by wrapping `AnimatedScale` in `SizedBox(height: effectiveHeight)` to isolate the transform's layout footprint.
- **GlassMenu — selection pill layout exception** · `AnimatedPositioned` is now inside a bounded `SizedBox(height: totalH) → Stack`, preventing a debug-mode layout exception and an out-of-bounds pill position when scrolled.
- **GlassMenu — `RangeError` on item removal** · `didUpdateWidget` clears `_hoveredIndex` when `items.length` shrinks while the menu is open.
- **GlassMenu — `GlassMenuItem` state flicker** · Wrapped items cached; only rebuilt when `widget.items` changes, preventing pressed/hover resets during the 60 fps spring ticker.
- **GlassGlow — permanently muted glow** · `didUpdateWidget` resets `_glowSuppressed` when `glowOnTapOnly` is toggled off.
- **GlassMenuItem — desktop hover state leak** · `dispose()` clears `_isHovered`.
- **Impeller — extreme-stretch glyph-bounds crash** · Scale determinant clamped before reaching the shader.
- **Android — negative safe-area assertion** · `sysBottom > 25` guard added.

## ⚠️ Semi-Breaking

`GlassMenu.items` changed from `List<GlassMenuItem>` to `List<Widget>`. Existing code compiles unchanged — only typed `List<GlassMenuItem>` variable declarations need widening.

## 🧪 Tests — 1,648 passing

---

# 0.10.2


## Fixes

- **GlassTabBar (scrollable) — indicator clipping** · Migrated the selected-tab indicator to an overlay architecture outside `SingleChildScrollView`, eliminating clip artifacts during scrolling and preserving the full iOS 26 glass bloom expansion.
- **GlassTabBar (scrollable) — tap fires on scroll** · `onTabSelected` no longer fires when the user scrolls the tab bar; selection is now only triggered on confirmed taps.
- **GlassTabBar (scrollable) — bloom activates on scroll** · The pressed indicator bloom no longer activates when scrolling the tab bar content.
- **GlassTabBar (scrollable) — indicator pulsates on transition** · Fixed a threshold bug that caused the bloom to flicker during tab-switch animations.
- **GlassTabBar (scrollable) — scroll into view** · Tapping or programmatically selecting a partially-visible tab now smoothly scrolls it fully into view.
- **GlassAdaptiveScope — Android false-negative quality downgrade** · Mid-range Android devices with Impeller/Vulkan can report inflated warmup P75 values (17–18 ms) due to GPU clock-scaling and JIT shader cache warm-up — not actual slowness. The previous `premium` threshold of `< 16 ms` (the raw 60-fps frame budget) was too strict and incorrectly demoted capable hardware to `standard` or `minimal`. Thanks @hank205 for the detailed diagnostic log. 🙏
- **GlassModalSheet / `.show()` / `GlassModalSheetScaffold` — `dragIndicatorWidth`** · The drag handle pill width was previously hardcoded at 36 (iOS native). A new `dragIndicatorWidth` parameter lets you customise it — e.g. `64` for sheets where a more prominent handle better suits the layout. Defaults to `36`, no breaking change. Thanks @jfhair (#46). 🙏

## Changes

- **`GlassQualityAdapter` / `GlassAdaptiveScopeConfig` / `GlassAdaptiveScope` — configurable warmup thresholds** · Two new parameters let you tune (and help us calibrate) the Phase 2 warmup classification thresholds:
  - `warmupPremiumThresholdMs` — P75 below this → `premium`. Default raised from `16.0` to **`20.0`** to account for Android GPU warm-up inflation. *(Calibration status: 1 device report — please share yours!)*
  - `warmupStandardThresholdMs` — P75 at or below this (and above premium) → `standard`. Default **`28.0`**. *(Calibration status: provisional — no real-device data for this band yet.)*
  - `skipInitialFrames` raised from **60 → 90** (≈1.5 s at 60 Hz) to give Android more time for GPU clocks and shader caches to settle before the benchmark begins.

> **Phase 3 hysteresis remains the safety net.** If a device cannot sustain its warmup-assigned quality, it steps down automatically within ~6 seconds — the new thresholds only affect the initial classification, not runtime correction.

> ⚠ **Community calibration needed** — especially for `warmupStandardThresholdMs`. If your device produces a warmup P75 in the 20–28 ms range, please enable `debugLogDiagnostics: true` and post your P75 + device model to the [Threshold Calibration Discussion](https://github.com/sdegenaar/liquid_glass_widgets/discussions).

# 0.10.1

Big thanks to @yukinoaruu (#43) and @jfhair (#44, #45) for three excellent contributions this release. 🙏

## Fixes

- **GlassModalSheet — child State preservation** · Removed `GlobalObjectKey` from the internal `Focus` bridge. The key was changing every rebuild, quietly tearing down child `State` (scroll positions, controllers, etc.) on each expand/collapse. (#44)
- **GlassModalSheet — `onStateChanged` skipped on slow drag** · Introduced `_settledState` to track the last published state separately from the in-flight animation target. Side-effects (haptics, callbacks, scroll-to-top) now fire reliably after a drag that crosses a snap threshold mid-gesture. (#45)
- **GlassModalSheet — ghosting and jitter** · Fixed visual artefacts during sheet transitions. (#43)
- **GlassModalSheet — element subtree stability** · `LiquidStretch` now always returns a consistent widget type regardless of `interactionScale`/`stretch` values, preventing a full subtree teardown on the frame the sheet reaches full expansion.
- **LightweightLiquidGlass — null-shader passthrough** · The widget tree shape is now stable while the fragment shader loads asynchronously; a tinted passthrough is painted instead of switching widget types.

# 0.10.0

## ⚠️ Breaking — Pre-v1 API Cleanup

### `LiquidGlassWidgets.wrap()` — `child` is now a required named parameter

Before:
```dart
LiquidGlassWidgets.wrap(const MyApp(), adaptiveQuality: true)
```
After:
```dart
LiquidGlassWidgets.wrap(child: const MyApp(), adaptiveQuality: true)
```
This aligns with Flutter widget conventions where `child` is always named.

### `GlassModalSheetScaffold` — parameter renames

| Old | New | Reason |
|-----|-----|--------|
| `background:` | `body:` | Matches Flutter `Scaffold.body` — it's the primary content, not a visual property |
| `sheetChild:` | `sheet:` | Cleaner, matches Flutter naming patterns |

Before:
```dart
GlassModalSheetScaffold(
  background: MyMapWidget(),
  sheetChild: MySheetContent(),
)
```
After:
```dart
GlassModalSheetScaffold(
  body: MyMapWidget(),
  sheet: MySheetContent(),
)
```

### `GlassQualityAdapter.skipStaticProbeForTesting` — `@visibleForTesting` annotated

The static field is now annotated `@visibleForTesting`. Production code referencing it
will receive an analyzer hint. Usage in test files is unchanged.

## 🐛 Fix — Android glass fallback on capable devices

`GlassQualityAdapter` was applying the static probe result (`GlassQuality.minimal`) without
respecting `minQuality`. On some Android devices `ImageFilter.isShaderFilterSupported`
returns a false negative, causing the glass shader to be skipped even though the hardware
supports it — the only workaround being `adaptiveQuality: false`.

`minQuality` is now honoured as a true floor even when the static probe fires:

```dart
// Prevents fallback on Android devices with a false-negative static probe
LiquidGlassWidgets.wrap(
  child: const MyApp(),
  adaptiveQuality: true,
  adaptiveConfig: const GlassAdaptiveScopeConfig(
    minQuality: GlassQuality.standard,
  ),
)
```

## ✨ New — Community contributions

### `GlassSearchBarConfig.searchIcon` — custom search icon (PR #41)

Thanks to [@jfhair](https://github.com/jfhair) for [PR #41](https://github.com/sdegenaar/liquid_glass_widgets/pull/41).

The search pill now accepts a fully custom `Widget` in place of the default `CupertinoIcons.search` glyph:

```dart
GlassSearchBarConfig(
  onSearchToggle: (active) { … },
  searchIcon: const Icon(CupertinoIcons.sparkles, color: Colors.white),
)
```

When `searchIcon` is `null` (default) the behaviour is unchanged.

### `indicatorExpansion` — tunable jelly-stretch on bottom bars (PR #40)

Thanks to [@jfhair](https://github.com/jfhair) for [PR #40](https://github.com/sdegenaar/liquid_glass_widgets/pull/40).

Both `GlassBottomBar` and `GlassSearchableBottomBar` now expose `indicatorExpansion`
to control how far the active-tab pill stretches during a drag gesture:

```dart
GlassBottomBar(
  tabs: myTabs,
  selectedIndex: _index,
  onTabSelected: _onTab,
  indicatorExpansion: 8,   // default 14; lower = tighter morph
)
```

### `GlassModalSheet` — two-phase organic interpolation (PR #39)

Thanks to [@yukinoaruu](https://github.com/yukinoaruu) for [PR #39](https://github.com/sdegenaar/liquid_glass_widgets/pull/39).

The sheet's corner-radius animation now uses a two-phase curve that separates the
rapid initial expansion from the final settle, eliminating the snapping artifacts
that were visible at the `half → full` transition on some devices.

The fix also corrects `resolveAdaptiveRadius` to use **logical screen height**
(`MediaQuery.size.height`) instead of `viewPadding.top` as the primary Pro Max
detector, preventing false-positive 54 dp radii on some non-Pro-Max iPhones with
unusually high status-bar padding.

### Asymmetric top/bottom corner radii in premium pipeline (PR #42)

Thanks to [@jfhair](https://github.com/jfhair) for [PR #42](https://github.com/sdegenaar/liquid_glass_widgets/pull/42).

`LiquidVerticalRoundedSuperellipse` now feeds independent top/bottom corner radii
into the premium SDF shader via a 7-float-per-shape stride, enabling sheets that
hug the device chassis curve at the bottom while keeping a tighter radius at the
top — matching the Apple Music / Apple Maps card style:

```dart
LiquidGlass(
  shape: const LiquidVerticalRoundedSuperellipse(
    topRadius: 20,
    bottomRadius: 54, // tracks iPhone 15 Pro Max chassis
  ),
  child: myContent,
)
```

> **Shader note**: all shaders continue to pass `glslangValidator` SPIR-V
> validation. The new stride-7 path is gated on `type == 3` in `sdf.glsl`
> and leaves the existing stride-6 path untouched.

---

# 0.9.6

## 🐛 Fix — `GlassModalSheet` interaction glow in full state

Thanks to [@yukinoaruu](https://github.com/yukinoaruu) for [PR #38](https://github.com/sdegenaar/liquid_glass_widgets/pull/38).

- **Haptic & glow suppression in full state:** `HapticFeedback.selectionClick()` and
  `_saturationController.forward()` were firing on every touch when the sheet was in
  `SheetState.full` — where the glass surface is fully opaque and neither effect is visible.
  Both are now gated on `!isFull`, eliminating spurious haptic feedback and redundant
  animation ticks.
- **Background glass hides when content glass is active:** Added an `Opacity(0.0)` on the
  background `AdaptiveGlass` layer when `expandProgress > 0.98` and `maintainContentGlass`
  is enabled. Prevents "glass on glass" shader conflicts in Premium mode at full expansion.
- **Interaction glow threshold tightened:** `GlassGlow` pulse guard lowered from
  `expandProgress < 0.98` to `< 0.9` to match the existing saturation gate — consistent
  behaviour across all glow signals.
- **`GlassModalSheet` geometry defaults refined:** `topBorderRadius` defaults to `56`
  (was `null`), `horizontalMargin` to `5.0` (was `8.0`), `bottomMargin` to `6.0`
  (was `8.0`) for tighter, more native-feeling geometry.
- **`InteractionNotification` exported:** `InteractionNotification` is now part of the
  public API surface, enabling consumers to dispatch Smart Silence events from their own
  widgets.
- **Corner radius tuning:** `GlassThemeHelpers.resolveAdaptiveRadius` values updated to
  54 / 46 / 46 (Pro Max / Pro / Notch) for a more conservative, closer-to-system look.

## 🧪 Tests — Coverage improvements (1,573 tests)

Extended branch coverage across five previously under-tested subsystems.
Full test count grew from 1,491 → 1,573 (+82 tests).

---

# 0.9.5

## ✨ Feature — Asymmetric corner radii & floating peek geometry for `GlassModalSheet`

Thanks to [@yukinoaruu](https://github.com/yukinoaruu) for [PR #37](https://github.com/sdegenaar/liquid_glass_widgets/pull/37).

- **Shader fix:** `lightweight_glass.frag` now supports per-quadrant corner radii via a new `uData6` uniform (slots 24–27). A sentinel of `uCornerRadius = -1.0` enables asymmetric mode; all existing symmetric shapes fall through unchanged.
- **Clip gap fix:** `ClipPath` geometry on the Skia/Web path is now aligned to `RoundedRectangleBorder` (circular arc) to match the shader SDF — eliminates the sub-pixel transparent notch at sheet corners.
- **Peek geometry:** Five new optional params on `GlassModalSheet` / `GlassModalSheetScaffold` — `peekWidth`, `peekHorizontalMargin`, `peekBottomMargin`, `peekTopBorderRadius`, `peekBottomRadius` — for Apple Maps-style floating pill peek states.
- **Cleanup:** `forceSpecularRim` removed from `AdaptiveGlass`, `GlassSheet`, `GlassModalSheet`, and `GlassModalSheetScaffold`. The shader renders the specular rim natively; no migration needed.

## 🐛 Fix — `GlassSearchableBottomBar` dismiss pill focus & keyboard restoration

The dismiss (×) pill was calling `FocusScope.of(context).unfocus()` which left the `FocusNode` in a "previously focused" state. This caused Flutter to restore the keyboard on back-navigation, and made the first post-dismiss tap get swallowed by focus routing.

**Fixed by:**
- Replacing `FocusScope.unfocus()` with `FocusManager.instance.primaryFocus?.unfocus()` in the DismissPill, fully clearing focus state.
- The × button now **only dismisses the keyboard** — it does not collapse the search state. This matches the real Apple Music / Apple News behaviour where the search bar remains visible (unfocused/ready) after tapping ×. The caller explicitly collapses search by tapping the home pill or switching tabs.
- `onCancelTap` fires first (before the unfocus) so callers can react (clear results, analytics, etc.) before focus is released.

A new `onCancelTap: VoidCallback?` on `GlassSearchBarConfig` gives callers a hook into the × tap.

## ✨ Demo — Apple Music mini-player refinements

High-fidelity improvements to the Apple Music demo to match the real Apple Music app:

- **Play pill visibility:** The floating play pill now stays visible when the search bar is in the "search ready" state (keyboard dismissed). It only hides when the keyboard is actively up (`_searchFieldFocused`), matching real Apple Music behaviour.
- **Dynamic icon colour:** `collapsedLogoBuilder` now shows the selected (red) icon in scroll-collapse mini mode and the unselected (white) icon when search is active, via a static `_kTabs` field so tab definitions aren't duplicated.
- **Play pill positioning:** `aboveBarBottom` is now responsive to the bar's current height — switching to `collapsedNavBarH` when search is active so the pill doesn't drop excessively when the bar shrinks.
- **Play pill animates on search from mini mode:** When search is activated from the scroll-collapsed mini state, the play pill animates from the mini gap position back to its full-width position above the expanded search bar, matching real Apple Music.
- **Home pill restores full bar from any state:** Tapping the home pill now always calls `_dismissMiniMode()` when in mini mode — whether arriving from scroll-collapse or from search — scrolling to top and restoring the full 3-tab bar.
- **Library default preserved:** `collapsedLogoBuilder` in the library remains `unselectedIconColor` — the Apple Music colour logic is isolated to the demo's `GlassSearchBarConfig`.
- **Multi-tab scroll fix:** `_dismissMiniMode` now uses `_activeScrollController` (per active tab) instead of hardcoding the home tab's controller, fixing a bug where tapping Radio/Library in mini mode would leave the bar stuck.

---

# 0.9.4


## ✨ Feature — `GlassSearchableBottomBar` programmatic interaction callbacks

Addresses two community-requested quality-of-life gaps for `GlassSearchableBottomBar`.

### 1. `onBarTap` — tap-to-restore after scroll-to-hide

A new `onBarTap: VoidCallback?` parameter on `GlassSearchableBottomBar` fires whenever the user taps anywhere on the bar. The callback is wired through a **translucent** `GestureDetector` wrapper, so all internal handlers (tab selection, search toggle, indicator drag) continue to work normally — there is zero interference.

Primary use-case is restoring the bar after a scroll-to-hide animation that is managed in the caller's code:

```dart
GlassSearchableBottomBar(
  onBarTap: () => setState(() => _barVisible = true),
  ...
)
```

When `onBarTap` is `null` (the default) no extra widget is inserted into the tree — zero overhead.

### 2. `onSearchFieldTap` — detect taps on the active search field

A new `onSearchFieldTap: VoidCallback?` parameter on `GlassSearchBarConfig`, passed directly to `TextField.onTap`. Fires on every tap of the expanded search field body, including re-focus taps after the keyboard was dismissed.

Useful for navigating to a dedicated search screen, showing a suggestion overlay, or logging an analytics event without needing to own the `FocusNode`:

```dart
GlassSearchBarConfig(
  onSearchToggle: ...,
  onSearchFieldTap: () {
    showSuggestions();
    analytics.log('search_field_tapped');
  },
)
```

Zero breaking changes. Both parameters are optional with `null` defaults.

---

# 0.9.3

## ✨ Feature — `GlassModalSheet` system & rendering performance refinement

Big thanks to [@yukinoaruu](https://github.com/yukinoaruu) for [PR #33](https://github.com/sdegenaar/liquid_glass_widgets/pull/33) — a comprehensive and beautifully engineered contribution that brings a whole new class of interactive modal sheet to the library.

### 1. `GlassModalSheet` system

A new, comprehensive modal sheet implementation supporting three interactive states: `peek`, `half`, and `full`.

- **Physics-Driven Transitions:** Spring physics for fluid, organic state changes.
- **Asymmetric Geometry:** Morphs from a rounded floating pill to a sharp-bottomed full-screen container using the new `LiquidVerticalRoundedSuperellipse`.
- **Isolated Mechanics:** Logic separated into a robust state machine (`glass_modal_sheet_state.dart`) and physics handler (`glass_modal_sheet_mechanics.dart`) — a clean architectural blueprint for future complex components.

### 2. Device-Aware Adaptive Radius

An intelligent radius resolution algorithm that infers the ideal corner curvature from the device's physical safe area — Dynamic Island vs. Notch vs. Android Home Bar — automatically matching glass curvature to device hardware without manual updates.

### 3. Advanced Visual Feedback — Pulse System

A global pulse synchronisation system in the rendering layer allows `GlassModalSheet` to trigger coordinated saturation and lighting pulses during high-velocity interactions, giving the glass surface a "living", organic feel.

### 4. Smart Silence — `suppressInteractionOnChildren`

`InteractionNotification` support prevents the "double-reacting" artifact where both a button **and** the sheet scale simultaneously on a single tap. Child buttons/switches can seamlessly suppress the parent sheet's scaling and glow effects when tapped.

### 5. New shapes & `LiquidStretch` constraints

- **`LiquidVerticalRoundedSuperellipse`**: Enables asymmetric corner radii (top-rounded, bottom-flat) essential for the modal sheet's full-screen morphing animation.
- **Axis constraints**: `allowPositive` / `allowNegative` pivot support prevents the sheet from "collapsing" downward when dragged — it only stretches upward as a tactile response.

### Documentation & Testing

- `docs/assets/GLASS_MODAL_SHEETS_GUIDE.md` — comprehensive developer guide covering the full parameter surface and state behaviours.
- `test/widgets/overlays/glass_modal_sheet_test.dart` — 679 lines of rigorous unit and widget tests covering state transitions, gesture arena logic, and physics edge cases.

Zero breaking changes. `GlassModalSheet` is additive — all existing `GlassSheet` usages are unaffected.

---

## 🐛 Fix — Selected icon colour washed out by glass indicator

A huge shoutout and thanks to [@jfhair](https://github.com/jfhair) for spotting this issue and putting together [PR #29](https://github.com/sdegenaar/liquid_glass_widgets/pull/29) — it was a fantastic catch, and you had exactly the right instinct on the fix!

The active-tab icon was visually muted ("dull") at rest because the `AnimatedGlassIndicator` glass lens was painting *over* the icon layer. Simply moving the indicator behind the icons restores vibrancy but kills the refraction effect — the glass shader needs icons beneath it to warp them as the pill moves.

The fix uses a split-pass sandwich: the pill's solid background renders *below* the icons (full vibrancy at rest), while the glass shader renders *above* them (refraction preserved during animation). Both `GlassBottomBar` and `GlassSearchableBottomBar` are updated. Zero breaking changes.

---

## 🐛 Fix — `GlassSheet` specular rim artifact & washed-out inner elements

Inspired by [@yukinoaruu](https://github.com/yukinoaruu)'s work in PR #33, who introduced the `forceSpecularRim` flag and first surfaced this class of visual fidelity issue with the lightweight glass renderer.

### The problem & fix

On the Skia/Web (lightweight) rendering path, a `refractiveIndex` of `0.7` on a large `GlassSheet` produced a hard, visible border around the sheet — a bright "line" that looked like an artifact rather than a premium glass surface. 

Lowering it globally to fix the sheets caused components **inside** the sheet to lose their specular highlights and become washed out.

We've introduced semantic preset separation via two distinct `RecommendedGlassSettings` presets to solve this:
- **`RecommendedGlassSettings.overlay`** (`refractiveIndex: 0.7`): For cards, buttons, and small interactive widgets.
- **`RecommendedGlassSettings.sheet`** (`refractiveIndex: 0.15`): For large bottom sheets and modal overlays.

All `GlassSheet.show()` calls in the demo app now use the `sheet` preset, while every `GlassButton.custom` and `GlassCard` **inside** a sheet explicitly passes `settings: RecommendedGlassSettings.overlay`. The package-level default for `GlassSheet` (`glass_sheet_defaults.dart`) has also been updated to use `refractiveIndex: 0.15` for a better out-of-the-box experience.

Zero breaking changes.

---

# 0.9.2


## 🐛 Fix — `GlassSwitch` initial-state bloom anchor & polish

- **First-click bloom anchored correctly.** A switch initialised with `value: true`
  now anchors the bloom to the right edge on the very first tap, matching all
  subsequent interactions. Previously `_isMovingForward` was hardcoded to `true`
  at construction regardless of `widget.value`.

- **`_justEndedDrag` race condition eliminated.** The flag is now consumed
  atomically inside `didUpdateWidget` rather than being reset one frame later via
  `addPostFrameCallback`, preventing a rare double-bloom after a drag toggle.

- **Floating-point guard hardened.** Animation controller resets now use `>= 0.99`
  instead of `== 1.0`, making the bloom sequence robust against sub-epsilon drift
  during rapid consecutive toggles.

- **Dead code removed** (`glassOverlay` no-op widget).

- **Haptic feedback added.** `GlassSwitch` now emits `HapticFeedback.lightImpact()`
  on tap-toggle, when the thumb crosses the 50 % midpoint during a drag, and on
  drag-release snap (when the midpoint was never crossed, e.g. a fast flick).
  Opt out with `enableHaptics: false`.

- **3 new regression tests** added; `GlassSwitch` test count now 24.

Zero breaking changes.

---

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
  textures. However, the `displacement` vector (in `liquid_glass_render.frag`) and
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


# 0.7.x — 0.1.0

Early access and preview releases. See [GitHub Releases](https://github.com/sdegenaar/liquid_glass_widgets/releases) for full details.
