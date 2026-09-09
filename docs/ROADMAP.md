# Roadmap: 1.x → 2.0

> Last updated: 2026-09-09 (1.5.0 features & fixes; SwiftUI & Apple HIG parity audit)

This document tracks planned and future work for `liquid_glass_widgets` post-1.0.
The guiding principle remains: **fewer, better widgets that map 1:1 to real iOS 26 components**.

For historical version notes (0.14 → 1.0), see [`CHANGELOG.md`](../CHANGELOG.md).

---

## Current Status (1.4.2 — `main`)

| Criterion | Status | Notes |
|---|---|---|
| No known P0/P1 bugs | ✅ Clear | No open crash reports |
| Dartdoc complete on all public API | ✅ Done | `public_member_api_docs` enforced permanently |
| Test coverage ≥ 90% | ✅ Done | ~92% line coverage (2,969 tests) |
| No `Icons.*` (Material) in `lib/` | ✅ Done | Zero hits — fully `CupertinoIcons` |
| No hardcoded `Colors.*` in `lib/` | ✅ Done | All replaced with `CupertinoColors` or explicit hex `Color` literals |
| `material.dart` imports in `lib/` | ✅ Done | 36 → 0 files |
| Light mode + dark mode | ✅ Done | `GlassTheme.brightnessOf` is the single brightness authority |
| RTL layout verified | ✅ Done | `EdgeInsetsDirectional` / `AlignmentDirectional` audit complete |
| Keyboard / Tab focus / Enter-Space | ✅ Done | `GlassFocusRegion`, focus ring, semantics on all 12 widget families |
| `docs/PLATFORM_SUPPORT.md` | ✅ Done | All platforms, shader tiers, known bugs documented |
| Navigation transition morph | ✅ Done (1.1.0) | `GlassNavigationShell` + `GlassAppBar.pinned` (#221) |
| Scroll-to-minimize | ✅ Done (1.1.0) | `GlassTabBarMinimizeController`, all four behaviour cases (#228) |
| Native gel morph | ✅ Done (1.2.0) | Capsule reshapes natively on push/pop; swell, bounce, glyph blur (#243) |
| Platform view glass passthrough | ✅ Done (1.2.0) | `PlatformViewGlassMode.passthrough` (#247) |
| `GlassBodyMode` adaptive vs clear | ✅ Done (1.4.0) | `Glass.regular` / `Glass.clear` parity (#269) |
| Rec.709 luminance weights | ✅ Done (1.4.2) | All shader + Dart paths corrected from BT.601 |
| Shader-level touch specular | ✅ Done (1.5.0 WIP) | `uTouchPosition`/`uTouchIntensity` uniforms + `_TouchSpecularBridge` |
| Vibrancy fill for nested glass | ✅ Done (1.5.0 WIP) | `AdaptiveGlass.vibrancy()` / `_VibrancyFill`; zero BackdropFilter |
| Collapsed tab native press | ✅ Done (1.5.0 WIP) | Native press growth & lift on collapsed search button (#272) |
| Light-mode golden tests | ✅ Done (1.5.0 WIP) | `goldenTestLight()` + 5 targeted golden files |
| `reduceTransparency` native detection | ⏳ Upstream | Awaiting [Flutter #190318](https://github.com/flutter/flutter/issues/190318); currently approximated via `highContrast` |
| Example app covers all widgets | ⚠️ Partial | Not verified against current widget catalogue |
| Platform testing matrix complete | ⚠️ Partial | iOS + Android confirmed; Web, Windows, macOS need QA |

---

## Active: 1.5.0 (`feat/1.5.0` branch)

### Shader-Level Touch Specular (`uTouchPosition` uniform) ✅ Done

`GlassButton`'s touch-tracking specular sheen (shipped in 1.3.0) is a uniform additive
brightness boost on the Standard path and **absent entirely on the Premium/Impeller path**.
The correct implementation passes the pointer coordinate as a shader uniform, biasing the
specular light direction toward the touch point inside the fragment shader.

Benefits: geometrically bounded by the SDF (no clipper needed), zero GPU cost at rest
(`uTouchIntensity = 0.0` kills the specular term), physically correct highlight that conforms
to capsule/pill corner geometry.

**Shipped:** Two new uniforms (`uTouchPosition vec2`, `uTouchIntensity float`) in
`liquid_glass_final_render.frag` (slots 34–36). Pure 2D specular math (`pow(dot, 8.0)`,
Reinhard compressed). Wired via zero-rebuild `_TouchSpecularBridge` + `ValueNotifier` from
`GlassGlowLayerState`. DPR multiply on Dart side for coordinate alignment.

### Vibrancy Fill Fallback for Nested Glass ✅ Done

When `InheritedLiquidGlass(avoidsRefraction: true)` is set by `GlassContainer`, an inner
`GlassEffect` previously fell through to `GlassQuality.minimal` with no visible surface —
looks like a broken widget.

**Shipped:** `_VibrancyFill` widget in `adaptive_glass.dart`: `ShapeDecoration` tinted fill +
`_SpecularRimPainter` rim, no `BackdropFilter`. `AdaptiveGlass.vibrancy()` static factory.
Alpha ceiling 0.45 (lighter than standalone `_FrostedFallback`). All 2,969 tests pass.

### Native Press Parity for Collapsed Search-Active Tab Indicator ✅ Done

The collapsed left button on `GlassTabBar.searchable` (when `isSearchActive: true`)
now shares the native press growth (`LiquidStretch.nativePressGrowth`), micro-tremor
(`AnchorStretchSettings.nativeTremor`), and surface highlight (`PressAmbientLift`),
matching `GlassButton`, `SearchPill`, and `MinimizableTrailingPill` (PR #272 parity).

### Light-Mode Golden Snapshots ✅ Done

Add golden regression snapshots for key widgets in `Brightness.light` to catch visual
regressions after the Rec.709 luma shift and any future shader calibration work.

**Shipped:** `goldenTestLight()` helper + `LightGoldenTestGroup` / `LightGoldenTestScenario` /
`buildWithLightBackground()` in `test/shared/test_helpers.dart`. Five targeted goldens in
`test/golden/light_mode_widgets_golden_test.dart` — `GlassButton`, `GlassAppBar`,
`GlassTabBar.bottom`, `AdaptiveGlass`/`GlassCard`, `GlassToolbar` — covering
`_InverseShapeClipper`/`_InverseBarClipper` drop-shadow rendering, `ambientBaseLight`
doubling, and Rec.709 adaptive glass strength on light backgrounds.

---

## SwiftUI & Apple HIG Parity (Roadmap to 2.0)

Based on a systematic evaluation of modern SwiftUI and Apple HIG components against `liquid_glass_widgets`, the following gaps and deprecations guide ongoing development for the 2.0 release line. The standard iOS Contacts app benchmark is used as the baseline for system component completeness.

### High-Priority Gaps (Contacts App Benchmark)

Features appearing in standard iOS system flows (e.g. stock Contacts app) prioritized for implementation:

| SwiftUI Feature | Proposed Liquid Glass API | Status | Description |
|---|---|---|---|
| `.swipeActions()` | `GlassListTile.swipeActions` / `GlassSwipeActionScope` | ⬜ Planned | Swipe-to-delete, call, message actions on list items and grouped rows. |
| `DisclosureGroup` | `GlassDisclosureGroup` / `GlassCollapsibleSection` | ⬜ Planned | Collapsible accordion / disclosure section within `GlassGroupedSection`. |
| `EditButton` + `ForEach` | `GlassEditableList` / `GlassListTile.editing` | ⬜ Planned | Edit mode with red delete badges, reorder drag handles, and row insertion. |
| `.contextMenu()` | `GlassContextMenu` | ⬜ Planned | Context menu triggered by long-press / secondary click with haptic surface lift and action stack. |
| `.fullScreenCover()` | `showGlassFullScreenCover` | ⬜ Planned | Dedicated full-viewport modal presentation (distinct from bottom sheets). |
| `DatePicker` / `MultiDatePicker` | `GlassDatePicker` | ⬜ Planned | Liquid glass date/time picker (compact, inline, and wheel/graphical modes). |
| `NavigationStack` + `Link` + `Title` | `GlassNavigationStack` / `GlassNavigationLink` | ⬜ Planned | Declarative typed-route navigation stack. Requires `GlassNavigationLink` as a typed destination link and a `Navigator 2.0`-style route stack manager — meaningfully more than just renaming `GlassNavigationShell`. |

### Medium-Priority Gaps (Standard iOS HIG)

- [ ] **`showGlassConfirmationDialog` (`.confirmationDialog()`)** — modern anchored confirmation popup replacing legacy ActionSheet.
- [ ] **`GlassWheelPicker` (`Picker(.wheel)`)** — iOS-style rotating drum / wheel picker in glass.
- [ ] **`GlassInlinePicker` (`Picker(.inline)`)** — inline embedded picker (e.g. date wheel directly in a form).
- [ ] **`GlassNavigationLinkPicker` (`Picker(.navigationLink)`)** — navigation-link-style drill-down picker, common in Settings-style UIs.
- [ ] **`GlassPalettePicker` (`Picker(.palette)`)** — colour / swatch grid picker; most relevant once `GlassColorWell` lands.
- [ ] **`GlassRadioGroup` (`Picker(.radioGroup)`)** — radio button group selection control.
- [ ] **`GlassPopover` compact variant (`.popover` compact)** — `GlassPopover` currently adapts to a sheet on compact screen sizes. The compact popover variant stays anchored beside the trigger even on iPhone, without falling back to a sheet. This adaptive behaviour needs explicit opt-in support.
- [ ] **`GlassRefreshable` (`.refreshable()`)** — pull-to-refresh control with liquid glass stretch and dynamic blur spinner.
- [ ] **`GlassGauge` (`Gauge`)** — radial, linear, and capacity gauges with specular rim styling.
- [ ] **`GlassRenameButton` (`RenameButton`)** — standard inline edit/rename affordance.
- [ ] **`GlassToggle.button` (`Toggle(.button)`)** — pressed/unpressed glass capsule toggle button.
- [ ] **`GlassOutlineGroup` (`OutlineGroup`)** — hierarchical recursive tree list in glass containers.
- [ ] **`.matchedGeometryEffect()`** — versatile hero morphing API for arbitrary shared-element glass transformations (investigatory).

---

## Post-1.0 Candidates

Ideas under consideration. None committed.

### New Widgets

- [ ] `GlassSplitView` (`NavigationSplitView`) — proper `UISplitViewController` equivalent with adaptive
  columns, swipe-to-collapse, and navigation state. Scoped as Low Priority (non-iPhone / iPad / macOS).
  **Large scope — requires dedicated planning before implementation.**
- [ ] `GlassColorWell` — iOS 26 colour picker pill. Scoped as a trigger widget:
  a tappable glass swatch that opens a `GlassPopover`; colour picker content
  is supplied by the caller.

### Enhancements

- [ ] **Scroll-driven glass materialisation** — app bar surface transitions from
  transparent to frosted on scroll. Closely related to the scroll edge fidelity
  fix above; the two may ship together when `GlassScrollEdgeStyle.blur` lands.
- [ ] **`GlassAppBar` Phase 3 compact search icon** — when `GlassLargeTitle.searchBar`
  and `GlassAppBar.largeTitleController` are in use and `searchBarCollapseProgress == 1.0`,
  show a compact search affordance that re-expands on tap. Blocked by: `GlassAppBar`
  currently implements `ObstructingPreferredSizeWidget` with a fixed `preferredSize`;
  Phase 3 requires dynamic height, touching the layout contract with `CupertinoPageScaffold`.
  Phases 1 + 2 (shipped 0.19.6) deliver 90% of the value; Phase 3 is a polish milestone.
- [ ] **Merge `GlassSheet` into `GlassModalSheet`** — consolidate non-modal and modal sheet
  implementations into a unified sheet controller supporting both persistent/inline and modal
  presentation modes with detents (peek / medium / large).
- [ ] **Drag-to-reorder in `GlassTabBar.bottom()`** — long-press to rearrange tabs,
  matching iOS tab bar customisation.
- [ ] **`GlassNavigationTransition` pinning as default** — the `.pinned` constructor
  is the transition vehicle; once `GlassBarItem` reaches parity with the widget API,
  a major release can make the data-driven API the plain `GlassAppBar`. Remaining
  parity work: text/prominent item styles, `GlassBarItem.spacer()` rendering with
  multi-capsule grouping. The pinned `leading` API and per-item backgrounds
  landed in 1.2.
- [ ] **Unify lone bar-item sizing** (2.0) — a group holding a single item renders
  at the 46pt icon-slot height when its items are
  `GlassBarItemBackground.shared`, and at the 44pt back-button diameter when they
  share with nothing. iOS 26 draws one circular button in both cases, so a lone
  action is 2pt larger than the back button beside it. Collapsing them to 44pt is
  a behaviour change to every shipped one-action pinned bar, so it waits for a
  major. The shape already agrees — at 44pt the capsule's 22pt radius clamps to
  exactly half the box — so this is a metrics change, not a rendering one.

### Platform Edge Cases

- [ ] **CanvasKit Web circular clipping** — `LiquidOval` relies on
  `ClipRRect(borderRadius: 9999)` to work around an iOS PlatformView compositing
  bug (Flutter #177551). On Web (CanvasKit) this massive radius breaks path clipping.
  Needs `ClipOval` / `BoxShape.circle` on Web, or an upstream engine fix.
- [ ] **`platformViewBackdrop` quality cliff** — when `platformViewBackdrop: true`,
  rendering is capped at `_FrostedFallback` regardless of requested quality tier.
  The `platformViewBackdrop` dartdoc explains this, but the long-term fix is upstream:
  make `RepaintBoundary`/`ImageFilter` capture include hybrid-composed PlatformViews.

### Accessibility

- [ ] **`reduceTransparency` native detection** — Awaiting upstream Flutter engine support
  ([Flutter #190318](https://github.com/flutter/flutter/issues/190318)). When Flutter exposes
  `AccessibilityFeatures.reduceTransparency` (or `MediaQuery.reduceTransparencyOf`),
  `liquid_glass_widgets` will adapt immediately. Until then, `GlassAccessibilityScope`
  approximates it via `MediaQuery.highContrastOf(context)` (documented in README) to keep
  the package 100% pure Dart with zero external dependencies.

### Documentation and pub.dev

- [ ] **Widget catalogue page** — README or docs/ page with screenshots of every
  widget in both quality modes.
- [ ] **Screenshots** — 3–5 screenshots in `pubspec.yaml` for the pub.dev listing.
- [ ] **Analysis score** — ensure 160/160 pub points.
- [ ] **Dedicated documentation site** (GitHub Pages or similar).
- [ ] **Figma/Sketch component library** matching the widget catalogue.
- [ ] **VS Code / IntelliJ snippet pack** for common widget patterns.

### Ecosystem

- [ ] `GlassFilterBar` — horizontal scrollable chip row (the `GlassTabBar(isScrollable: true)`
  successor). Variable-width items, momentum physics, tap-only selection, no safe-area
  handling. The `isScrollable` flag on `GlassTabBar` is a deprecation candidate.

---

## Semver Commitment (from 1.0.0)

- **Patch** (1.0.x / 1.1.x): Bug fixes only.
- **Minor** (1.x.0): New widgets, new parameters, non-breaking additions.
- **Major** (2.0.0): Breaking changes (widget removal, parameter rename, behaviour change).

### Deprecations & Consolidations Scheduled for 2.0.0

The following symbols and patterns are scheduled for removal or consolidation in 2.0.0:

- `GlassBottomBar`, `GlassSearchableBottomBar`, `GlassBottomBarTab` — replaced by `GlassTabBar` (shipped 1.0).
- `GlassTabBar(isScrollable: true)` — superseded by `GlassFilterBar`.
- `GlassToast` — non-standard iOS pattern; not part of native Apple HIG (which uses dynamic island, banners, or alerts).
- `showGlassActionSheet` — legacy ActionSheet pattern; superseded by modern `showGlassConfirmationDialog`.
- `GlassChip` — redundant; capsule-style `GlassButton` fulfills this use case.
- `GlassContainer` / `GlassCard` consolidation — **decision: `GlassCard` becomes `GlassContainer.card(...)` named constructor** (opinionated preset with standard corner radius, shadow, and padding), mirroring how `GlassTabBar.bottom()` / `.inline()` / `.searchable()` work. The standalone `GlassCard` class is deprecated; `GlassContainer` is the single surface primitive.
- `GlassSheet` — merged into `GlassModalSheet` for unified sheet mechanics.

Behaviour changes scheduled for 2.0.0:

- `GlassAppBar.pinned` becomes the plain `GlassAppBar`, demoting the widget-based
  `leading`/`actions` constructor to a legacy mode.
- A pinned group holding a single item renders at 44pt on both sides, matching the
  back button and iOS 26, rather than 46pt when its items are
  `GlassBarItemBackground.shared`.
