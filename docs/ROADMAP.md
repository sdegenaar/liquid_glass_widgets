# Roadmap: 1.x → 2.0

> Last updated: 2026-10-08 (v1.11.0 stable; Active v1.12.0: SwiftUI & Apple HIG Parity Gaps)

This document tracks planned and future work for `liquid_glass_widgets` post-1.0.
The guiding principle remains: **fewer, better widgets that map 1:1 to real iOS components**.

For historical version notes, see [`CHANGELOG.md`](../CHANGELOG.md).

---

## Current Status (1.11.0 — `main`)

| Criterion | Status | Notes |
|---|---|---|
| No known P0/P1 bugs | ✅ Clear | No open crash reports |
| Dartdoc complete on all public API | ✅ Done | `public_member_api_docs` enforced permanently |
| Test coverage ≥ 90% | ✅ Done | ~92% line coverage (3,000+ tests) |
| No `Icons.*` (Material) in `lib/` | ✅ Done | Zero hits — fully `CupertinoIcons` |
| No hardcoded `Colors.*` in `lib/` | ✅ Done | All replaced with `CupertinoColors` or explicit hex `Color` literals |
| `material.dart` imports in `lib/` | ✅ Done | Zero files |
| Light mode + dark mode | ✅ Done | `GlassTheme.brightnessOf` is the single brightness authority |
| RTL layout verified | ✅ Done | `EdgeInsetsDirectional` / `AlignmentDirectional` audit complete; RTL tab bar & menu gestures verified |
| Keyboard / Tab focus / Enter-Space | ✅ Done | Single-node semantics; `GlassFocusRegion`, focus ring, semantics across all widget families |
| `docs/PLATFORM_SUPPORT.md` | ✅ Done | All platforms, shader tiers, known bugs documented |
| Navigation transition morph | ✅ Done (1.1.0) | `GlassNavigationShell` + `GlassAppBar.pinned` (#221) |
| Scroll-to-minimize | ✅ Done (1.1.0) | `GlassTabBarMinimizeController`, all four behaviour cases (#228) |
| Native gel morph | ✅ Done (1.2.0) | Capsule reshapes natively on push/pop; swell, bounce, glyph blur (#243) |
| Platform view glass passthrough | ✅ Done (1.2.0) | `PlatformViewGlassMode.passthrough` (#247) |
| `GlassBodyMode` adaptive vs clear | ✅ Done (1.4.0) | `Glass.regular` / `Glass.clear` parity (#269) |
| Rec.709 luminance weights | ✅ Done (1.4.2) | All shader + Dart paths corrected from BT.601 |
| Shader-level touch specular | ✅ Done (1.5.0) | `uTouchPosition`/`uTouchIntensity` uniforms + `_TouchSpecularBridge` |
| Vibrancy fill for nested glass | ✅ Done (1.5.0) | `AdaptiveGlass.vibrancy()` / `_VibrancyFill`; zero BackdropFilter |
| Continuous swipe & glide-to-select | ✅ Done (1.7.0/1.10.0) | `GlassMenu` and `GlassPullDownButton` slide selection & external glide |
| iOS 27 material shaders | ✅ Done (1.8.0) | `LiquidGlassSettings.ios27Light`/`ios27Dark` (frost, rimShade, rimLight, paraxial lens) |
| Impeller shared backdrops | ✅ Done (1.9.0) | `GlassBackdropGroup` (shared backdrop reads, cutting GPU time 23.6 → 9.3ms) |
| iPhone Duo vertical bar strip | ✅ Done (1.9.0/1.11.0) | `GlassVerticalBar`, display occlusion cutouts, lens tracking, and popovers |
| Layered submenus | ✅ Done (1.11.0) | `GlassMenuItem.submenu` with native card recession and liquid droplet morph |
| Upstream migration PRs | ✅ Done | PR #1 ([#13162](https://github.com/flutter/packages/pull/13162)) and PR #2 ([#13163](https://github.com/flutter/packages/pull/13163)) staged in `flutter/packages` |
| `reduceTransparency` native detection | ⏳ Upstream | Awaiting [Flutter #190318](https://github.com/flutter/flutter/issues/190318); currently approximated via `highContrast` |

---

## Active: 1.12.0 (`feat/swipe-actions` branch)

Addressing the **High-Priority SwiftUI / Apple HIG feature gaps** from Google's upstream gap analysis (Tong Mu / `@dkwingsmt`, benchmarked against the stock iOS Contacts app):

### GlassSwipeActions (`.swipeActions()`) ✅ Complete

Swipe gestures on list tiles and containers with authentic iOS spring physics, revealed platter, and full-swipe execution.
- **Data Model:** `GlassSwipeAction` with icon, optional label, callback, background tint, destructive style, and flex.
- **Container Widget:** `GlassSwipeActions` wrapping any tile/child with horizontal pan gesture recognition (velocity-based, disambiguated with vertical scrolling via `dx.abs() > dy.abs() * 1.5`).
- **Platter Aesthetic:** `GlassSwipeActionStyle.tintedGlass` (iOS 26/27 liquid glass with specular rim and surface gradient) & `GlassSwipeActionStyle.solidVibrancy`.
- **Mechanics:** Underdamped spring return, rubber-band damping beyond action width, full-swipe threshold at 65% with haptic tick and automatic execution on release.
- **Mutual Exclusivity:** `GlassSwipeActionScope` ensuring only one row can be open at a time; auto-closes on scroll.
- **First-Class Integration:** `GlassListTile(leadingSwipeActions: [...], trailingSwipeActions: [...], onDismissed: ...)`.

### GlassDisclosureGroup (`DisclosureGroup`) ✅ Complete

Collapsible accordion / disclosure section within `GlassGroupedSection` and standalone containers.
- Spring-animated expansion/collapse of child rows with `SizeTransition(curve: Curves.easeInOutCubic)`.
- Smooth rotating chevron ($\frac{\pi}{2}$ radians) matching native iOS timing.
- Composable directly within `GlassGroupedSection` with smart divider indentation (56px with leading, 16px without).
- Programmatic control via `isExpanded` prop or `GlobalKey<GlassDisclosureGroupState>`.
- Standalone mode with `GlassDisclosureGroup.standalone`.

### GlassEditScope & GlassReorderableList (`EditMode` / `EditButton` / `ForEach`) ✅ Complete

Comprehensive list editing, item deletion, selection, and reordering parity.
- **Ambient State:** `GlassEditScope` with `GlassEditMode` (`inactive`, `active`, `transient`) and `GlassEditController` (`isEditing`, `toggle()`, `startEditing()`, `stopEditing()`).
- **Interactive Control:** `GlassEditButton` and `GlassEditButton.explicit` with animated crossfade between "Edit" and bold "Done", selection haptics, and ambient controller coordination.
- **Reorderable List:** `GlassReorderableList` and `GlassReorderableList.grouped` with authentic iOS lift elevation proxy (1.025x scale, elevated specular shadow, selection haptic tick). Modern `onReorderItem` and legacy `onReorder` compatibility.
- **Row-Level Editing:** `GlassListTile` editing features:
  - Circular red minus delete badge (`CupertinoIcons.minus_circle_fill`) with 90° rotation into an inline slide-in "Delete" confirmation pill.
  - Circular green plus insertion badge (`CupertinoIcons.plus_circle_fill`).
  - Selection checkmark state (`canSelect`, `isSelected`, `onSelectedChanged`).
  - 3-bar reorder drag handle (`CupertinoIcons.bars`) with immediate touch drag initiation via `ReorderableDragStartListener`.
  - Automatic suppression of swipe gestures during active edit mode to prevent gesture conflicts.

---

## SwiftUI & Apple HIG Parity (Roadmap to 2.0)

Based on a systematic evaluation of modern SwiftUI and Apple HIG components against `liquid_glass_widgets` (Google / Flutter team gap analysis), the following gaps and deprecations guide ongoing development for the 2.0 release line. The standard iOS Contacts app benchmark is used as the baseline for system component completeness.

### High-Priority Gaps (Contacts App Benchmark)

Features appearing in standard iOS system flows (e.g. stock Contacts app) prioritized for implementation:

| SwiftUI Feature | Proposed Liquid Glass API | Status | Description |
|---|---|---|---|
| `.swipeActions()` | `GlassSwipeActions` / `GlassListTile.swipeActions` | ✅ Complete | Swipe-to-delete, call, message actions on list items and grouped rows (1.12.0). |
| `DisclosureGroup` | `GlassDisclosureGroup` / `GlassCollapsibleSection` | ✅ Complete | Collapsible accordion / disclosure section within `GlassGroupedSection` (1.12.0). |
| `EditButton` + `ForEach` | `GlassEditScope` / `GlassEditButton` / `GlassReorderableList` / `GlassListTile.editing` | ✅ Complete | Full edit mode with ambient scope, delete confirmation badges, reorder handles, and grouped lists (1.12.0). |
| `.contextMenu()` | `GlassContextMenu` / `GlassContextMenuAction` | ✅ Complete | Long-press / secondary click with 0.96× compression, haptic surface lift, progressive backdrop blur, elevated specular platter, glide selection, and preview builder (1.12.0). |
| `.fullScreenCover()` | `showGlassFullScreenCover` / `GlassFullScreenCover` | ✅ Complete | Full-viewport modal presentation with spring slide-up, interactive swipe-to-dismiss, elastic resistance, and liquid glass navigation bar (1.12.0). |
| `DatePicker` / `MultiDatePicker` | `GlassDatePicker` / `GlassMultiDatePicker` | ✅ Complete | Liquid glass date/time picker with compact pill, inline graphical month calendar, 3D wheel, multi-date selection, and modal sheet (1.12.0). |
| `NavigationStack` + `Link` + `Title` | `GlassNavigationStack` / `GlassNavigationLink` | ✅ Complete | Declarative typed-route navigation stack with `GlassNavigationPath`, typed destination mapping, chevron link rows, and `.navigationTitle` semantics (1.12.0). |

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
  parity work: text/prominent item styles. The pinned `leading` API and
  per-item backgrounds landed in 1.2, and `GlassBarItem.spacer()` has since.
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
- `GlassContainer` / `GlassCard` consolidation — **decision: `GlassCard` becomes `GlassContainer.card(...)` named constructor** (opinionated preset with standard corner radius, shadow, and padding), mirroring how `GlassTabBar.bottom()` / `.inline()` / `.searchable()` work. The standalone `GlassCard` class is deprecated; `GlassContainer` is the single surface primitive. *Status: `GlassContainer.card` (with `surfaceStyle`) shipped and `GlassCard` is `@Deprecated` in 1.x; 2.0.0 removes `GlassCard`.*
- `GlassSheet` — merged into `GlassModalSheet` for unified sheet mechanics.

Behaviour changes scheduled for 2.0.0:

- `GlassAppBar.pinned` becomes the plain `GlassAppBar`, demoting the widget-based
  `leading`/`actions` constructor to a legacy mode.
- A pinned group holding a single item renders at 44pt on both sides, matching the
  back button and iOS 26, rather than 46pt when its items are
  `GlassBarItemBackground.shared`.
- `GlassGroupedSection`, `GlassReorderableList.grouped`, `GlassDatePicker`, `GlassMultiDatePicker` and `GlassContainer.card` change their default `surfaceStyle` from `GlassSurfaceStyle.glass` to `GlassSurfaceStyle.solid` (flat opaque `#FFFFFF` / `#1C1C1E` cards with 26pt corners, matching native inset-grouped lists). 1.x keeps `glass` as the default (no silent visual change) and 2.0 flips it. `GlassContainer` itself stays glass-first. Pass `surfaceStyle: GlassSurfaceStyle.glass` to keep the old look.
