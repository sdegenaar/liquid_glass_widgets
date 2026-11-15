# Roadmap: 1.x → 2.0

> Last updated: 2026-11-14 (v1.17.4 stable)

This document tracks planned and future work for `liquid_glass_widgets` post-1.0.
The guiding principle remains: **fewer, better widgets that map 1:1 to real iOS components**.

For historical version notes, see [`CHANGELOG.md`](../CHANGELOG.md).

---

## Current Status (1.17.4)

| Criterion | Status | Notes |
|---|---|---|
| No known P0/P1 bugs | ✅ Clear | No open crash reports |
| Dartdoc complete on all public API | ✅ Done | `public_member_api_docs` enforced permanently |
| Test coverage ≥ 90% | ✅ Done | ~92% line coverage (3,960+ tests) |
| No `Icons.*` (Material) in `lib/` | ✅ Done | Zero hits — fully `CupertinoIcons` |
| No hardcoded `Colors.*` in `lib/` | ✅ Done | All replaced with `CupertinoColors` or explicit hex `Color` literals |
| `material.dart` imports in `lib/` | ✅ Done | Zero files (`cupertino_ui` migration staged on `feat/flutter-3.50-migration` for 2.0) |
| Light mode + dark mode | ✅ Done | `GlassTheme.brightnessOf` is the single brightness authority |
| RTL layout verified | ✅ Done | `EdgeInsetsDirectional` / `AlignmentDirectional` audit complete; RTL tab bar & menu gestures verified |
| Keyboard / Tab focus / Enter-Space | ✅ Done | Single-node semantics; `GlassFocusRegion`, focus ring, semantics across all widget families |
| `docs/PLATFORM_SUPPORT.md` | 🔄 Refresh | Needs refresh from `0.25.x` baseline for Flutter 3.50 desktop Impeller defaults |
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
| `GlassStepper` & popover blur ramp | ✅ Done (1.13.0) | Native two-button stepper capsule and `GlassPopover.blurRamp` |
| Liquid droplet morph & `GlassMaterialize` | ✅ Done (1.14.0) | `morphFrom` / `morphFromRect` on sheets, dialogs, action sheets & popovers; blur-to-sharp materialize |
| Contacts app HIG benchmark | ✅ Done (1.15.0) | `GlassSwipeActions`, `GlassDisclosureGroup`, `GlassEditScope` / `GlassReorderableList`, `GlassContextMenu`, `GlassFullScreenCover`, `GlassDatePicker`, `GlassNavigationStack` |
| `GlassSurfaceStyle.solid` cards & wells | ✅ Done (1.15.0–1.17.2) | Shader-free inset-grouped cards (`GlassContainer.card`, `GlassGroupedSection`, `GlassDisclosureGroup.standalone`) and automatic `InheritedGlassSurfaceStyle` `tertiarySystemFill` wells across all inputs, `GlassPicker`, and `GlassChip` (only container default flip awaits 2.0) |
| `GlassStyle` presets & iOS 26/27 alignment | ✅ Done (1.17.0) | `GlassStyle.ios27` (default), `GlassStyle.ios26`, and `GlassStyle.classic` across platters, tab bars, interactive lenses, menus, sheets, and 320 pt alerts |
| Bezel page clipping & Flutter 3.50 shaders | ✅ Done (1.17.1–1.17.4) | `GlassPageTransitionClip` superellipse transition clipping (#451) and single-exit `main()` HLSL/ANGLE/`impellerc` validation (#190809) |
| Upstream migration PRs | ✅ Done | PR #1 ([#13162](https://github.com/flutter/packages/pull/13162)) and PR #2 ([#13163](https://github.com/flutter/packages/pull/13163)) staged in `flutter/packages` |
| `reduceTransparency` native detection | ⏳ Upstream | Awaiting [Flutter #190318](https://github.com/flutter/flutter/issues/190318); currently approximated via `highContrast` |

---

## SwiftUI & Apple HIG Parity (Roadmap to 2.0)

Based on a systematic evaluation of modern SwiftUI and Apple HIG components against `liquid_glass_widgets` (Google / Flutter team gap analysis), the following gaps and deprecations guide ongoing development for the 2.0 release line. The standard iOS Contacts app benchmark is used as the baseline for system component completeness.

### High-Priority Gaps (Contacts App Benchmark)

Features appearing in standard iOS system flows (e.g. stock Contacts app) prioritized for implementation:

| SwiftUI Feature | Proposed Liquid Glass API | Status | Description |
|---|---|---|---|
| `.swipeActions()` | `GlassSwipeActions` / `GlassListTile.swipeActions` | ✅ Complete (1.15.0) | Swipe-to-delete, call, message actions on list items and grouped rows. |
| `DisclosureGroup` | `GlassDisclosureGroup` | ✅ Complete (1.15.0) | Collapsible accordion / disclosure section within `GlassGroupedSection` and `.standalone`. |
| `EditButton` + `ForEach` | `GlassEditScope` / `GlassEditButton` / `GlassReorderableList` / `GlassListTile.editing` | ✅ Complete (1.15.0) | Full edit mode with ambient scope, delete confirmation badges, reorder handles, and grouped lists. |
| `.contextMenu()` | `GlassContextMenu` / `GlassContextMenuAction` | ✅ Complete (1.15.0) | Long-press / secondary click with row lift, progressive backdrop blur, elevated platter, glide selection, and preview builder. |
| `.fullScreenCover()` | `showGlassFullScreenCover` / `GlassFullScreenCover` | ✅ Complete (1.15.0) | Full-viewport modal presentation with spring slide-up, interactive swipe-to-dismiss, elastic resistance, and `GlassFullScreenCoverBar`. |
| `DatePicker` / `MultiDatePicker` | `GlassDatePicker` / `GlassMultiDatePicker` | ✅ Complete (1.15.0) | Liquid glass date/time picker with compact pill, inline graphical month calendar, 3D wheel, multi-date selection, and modal sheet. |
| `NavigationStack` + `Link` + `Title` | `GlassNavigationStack` / `GlassNavigationLink` | ✅ Complete (1.15.0) | Declarative typed-route navigation stack with `GlassNavigationPath`, typed destination mapping, chevron link rows, and `.navigationTitle` semantics. |

### Medium-Priority Gaps (1:1 SwiftUI & Apple HIG iOS 26/27)

- [ ] **`showGlassConfirmationDialog` (`.confirmationDialog()`)** — modern iOS 26/27 confirmation dialog superseding legacy `showGlassActionSheet`. Anchors and morphs as a floating Liquid Glass popover platter directly from its source trigger (omitting the Cancel button when anchored, since outside tap dismisses), falling back to the centered 320 pt platter with Cancel (`1.17.0`) when unanchored.
- [ ] **`GlassToggle.button` (`Toggle(.button)`)** — pressed/unpressed Liquid Glass capsule toggle button. Native SwiftUI primitive superseding Material-style `GlassChip` and horizontal filter strips.
- [ ] **`GlassWheelPicker` (`Picker(.wheel)`)** — iOS-style rotating drum / wheel picker in glass.
- [ ] **`GlassInlinePicker` (`Picker(.inline)`)** — inline embedded picker (e.g. wheel or checkmark rows directly inside a form section).
- [ ] **`GlassNavigationLinkPicker` (`Picker(.navigationLink)`)** — navigation-link-style drill-down picker, common in Settings-style UIs. *(Note: `Picker(.menu)` is already covered by `GlassPullDownButton` + `GlassMenuItem.semanticsSelected`.)*
- [ ] **`GlassPalettePicker` (`Picker(.palette)`)** — horizontal swatch/icon row inside `GlassMenu` (in SwiftUI on iOS, `.palette` only renders as a palette inside a `Menu` and falls back to segmented elsewhere); pairs naturally with `GlassColorWell`.
- [ ] **`GlassPopover` compact adaptation (`.presentationCompactAdaptation(.popover)`)** — explicit opt-in keeping `GlassPopover` anchored beside its trigger on compact iPhone widths without adapting to a sheet.
- [ ] **`GlassRefreshable` (`.refreshable()`)** — pull-to-refresh control matching `UIRefreshControl` / SwiftUI `.refreshable()`.
- [ ] **`GlassGauge` (`Gauge`)** — radial, linear, and capacity gauges (`.accessoryCircular`, `.linearCapacity`, etc.).
- [ ] **`GlassOutlineGroup` (`OutlineGroup`)** — hierarchical recursive tree wrapper built atop `GlassDisclosureGroup`.
- [ ] **`GlassRenameButton` (`RenameButton`)** — low-priority convenience action for triggering inline title rename focus.
- [ ] **`.matchedGeometryEffect()`** — versatile hero morphing API for arbitrary shared-element glass transformations (investigatory).

*(Excluded as non-iOS: `Picker(.radioGroup)` is macOS-only in SwiftUI and not part of iOS/iPadOS HIG; Material-style `Chip` and standalone `FilterBar` classes have no UIKit/SwiftUI equivalent and are composed in SwiftUI via horizontal `ScrollView` + `Toggle(.button)` / `Button`.)*

---

## Post-1.0 Candidates

Ideas under consideration. None committed.

### New Widgets

- [ ] `GlassSplitView` (`NavigationSplitView`) — proper `UISplitViewController` equivalent with adaptive
  columns, swipe-to-collapse, and navigation state (iPadOS, macOS, and iPhone Duo inner display). Scoped as Low Priority.
  **Large scope — requires dedicated planning before implementation.**
- [ ] `GlassColorWell` (`ColorPicker` / `UIColorWell`) — iOS 26/27 colour picker pill. Scoped as a trigger widget:
  a tappable glass swatch that opens a `GlassPopover`; colour picker content
  is supplied by the caller.

### Enhancements

- [ ] **Continued iOS 26 / iOS 27 optical & interaction refinement** — iterative tuning passes building on the `1.17.0` foundational `GlassStyle.ios27` / `GlassStyle.ios26` alignment across dynamic transitions, edge-case backdrops, and remaining interactive controls.
- [ ] **Scroll-driven glass materialisation** — app bar surface transitions from
  transparent to frosted on scroll (`GlassScrollEdgeStyle.blur` itself already shipped in `GlassScrollEdgeEffect`).
- [ ] **`GlassAppBar` Phase 3 compact search icon** — when `GlassLargeTitle.searchBar`
  and `GlassAppBar.largeTitleController` are in use and `searchBarCollapseProgress == 1.0`,
  show a compact search affordance that re-expands on tap. Blocked by: `GlassAppBar`
  currently implements `ObstructingPreferredSizeWidget` with a fixed `preferredSize`;
  Phase 3 requires dynamic height, touching the layout contract with `CupertinoPageScaffold`.
  Phases 1 + 2 (shipped 0.19.6) deliver 90% of the value; Phase 3 is a polish milestone.
- [ ] **Deprecate `GlassSheet` in favour of `GlassModalSheet`** — `GlassModalSheet` already implements both modal (`GlassSheetMode.dismissible`) and Maps-style persistent (`GlassSheetMode.persistent` + `GlassModalSheetScaffold` hit-through background interaction, matching SwiftUI `.sheet()` + `.presentationBackgroundInteraction(.enabled)`) presentation with detents. Only marking `GlassSheet` `@Deprecated` in `1.18.x` ahead of removal in `2.0.0` remains.
- [ ] **iPadOS floating tab bar customisation (`TabViewCustomization`)** — tab reordering for regular-width / iPadOS floating tab bars and sidebars (compact iPhone bottom tab bars reserve long-press drag for the lifted magnifying indicator lens).
- [ ] **`GlassNavigationTransition` pinning as default** — the `.pinned` constructor
  is the transition vehicle; once `GlassBarItem` reaches parity with the widget API,
  a major release can make the data-driven API the plain `GlassAppBar`. Remaining
  parity work: text and `.prominent` item styles (`UIBarButtonItem.Style.prominent` / `ToolbarItem(placement: .confirmationAction)` / `.buttonStyle(.glassProminent)`). The pinned `leading` API and
  per-item backgrounds landed in 1.2, and `GlassBarItem.spacer()` landed in 1.10.
- [ ] **Unify lone bar-item sizing** (2.0) — a group holding a single item renders
  at the 46pt icon-slot height when its items are
  `GlassBarItemBackground.shared`, and at the 44pt back-button diameter when they
  share with nothing. iOS 26/27 draws one circular button in both cases, so a lone
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
  approximates it via `MediaQuery.highContrastOf(context)` (documented in README) to preserve
  zero third-party runtime dependencies and consistent cross-platform engine behaviour without expanding native plugin channels.

### Documentation and pub.dev

- [ ] **Refresh `docs/PLATFORM_SUPPORT.md`** — update from `0.25.x` baseline for `1.17+` and Flutter 3.50 desktop Impeller defaults.
- [ ] **Migration guide (`docs/MIGRATION_1.x_TO_2.0.md`)** — step-by-step upgrade guide covering `cupertino_ui` / Flutter 3.50+, `GlassSurfaceStyle.solid` default flips, 44pt lone bar items, and retired `1.x` symbols.
- [ ] **Widget catalogue page** — README or docs/ page with screenshots of every
  widget in both quality modes.
- [ ] **Screenshots** — 3–5 screenshots in `pubspec.yaml` for the pub.dev listing.
- [ ] **Analysis score** — ensure 160/160 pub points.
- [ ] **Dedicated documentation site** (GitHub Pages or similar).
- [ ] **Live web demo of the example app** — GitHub Pages build, clearly labelled as a standard-quality preview (web has no Impeller, so no premium refraction). Community PRs welcome.
- [ ] **Figma/Sketch component library** matching the widget catalogue.
- [ ] **VS Code / IntelliJ snippet pack** for common widget patterns.

---

## Semver Commitment (from 1.0.0)

- **Patch** (1.0.x / 1.1.x): Bug fixes only.
- **Minor** (1.x.0): New widgets, new parameters, non-breaking additions.
- **Major** (2.0.0): Breaking changes (widget removal, parameter rename, behaviour change, SDK floor bump).

### Pre-2.0 Bridge Checklist (Final `1.x` Minor Before `2.0.0`)

Before cutting `2.0.0`, ship a bridge `1.x` minor so every retiring API has its 1:1 Apple replacement and `@Deprecated` analyzer guidance in place:

- [ ] Ship **`GlassBarItem` text / `.prominent`** item styles (unblocks `GlassAppBar.pinned` becoming default `GlassAppBar`).
- [ ] Ship **`GlassToggle.button`** (native SwiftUI replacement before deprecating `GlassChip` and `GlassTabBar(isScrollable: true)`).
- [ ] Ship **`showGlassConfirmationDialog`** with source-anchor popover support (native iOS 26/27 replacement before deprecating `showGlassActionSheet`).
- [ ] Add `@Deprecated('... Will be removed in 2.0.0.')` annotations across `GlassSheet`, `GlassToast`, `GlassChip`, `showGlassActionSheet`, `GlassTabBar(isScrollable: true)`, and `GlassStyle.classic` (+ `classic*` theme/settings presets). (`GlassCard` and `GlassNavBarRegistration.presentSheet` are already `@Deprecated` in `1.x`.)

### Deprecations & Consolidations Scheduled for 2.0.0

The following symbols and patterns are scheduled for removal or consolidation in 2.0.0:

- `GlassCard` — **already `@Deprecated` in 1.x** in favour of `GlassContainer.card(...)`; `2.0.0` removes the standalone `GlassCard` class (`GlassContainer` is the single surface primitive).
- `GlassNavBarRegistration.presentSheet` — **already `@Deprecated` in 1.x** (hoisted sheet items present directly out of the hoisted capsule); removed in `2.0.0`.
- `GlassSheet` — superseded by `GlassModalSheet` (`GlassSheetMode.dismissible` / `GlassSheetMode.persistent` + `GlassModalSheetScaffold`), matching SwiftUI's single `.sheet()` API.
- `showGlassActionSheet` — legacy ActionSheet API; superseded by source-anchored `showGlassConfirmationDialog` (`.confirmationDialog()`).
- `GlassChip` — Material-ism with no UIKit/SwiftUI counterpart; superseded by `GlassToggle.button` (`Toggle(.button)`) and capsule-style `GlassButton`. *(Note: `GlassChip` already inherits `InheritedGlassSurfaceStyle` as of `1.17.2` for `1.x` apps until removal.)*
- `GlassTabBar(isScrollable: true)` — native `UITabBar` / `TabView` is never horizontally scrollable; superseded by composing `GlassToggle.button` / capsule `GlassButton` in a horizontal `ScrollView`.
- `GlassToast` — non-standard Android/Material pattern; not part of native Apple HIG (which uses Dynamic Island, banners, or alerts).
- `GlassStyle.classic`, `GlassThemeData.classic()`, `GlassThemeVariant.classicLight` / `classicDark`, `GlassThemeSettings.classicLight` / `classicDark`, and `LiquidGlassSettings.classic*` — introduced in 1.17.0 as a 1-line migration bridge for the pre-calibration `1.x` look when `GlassThemeData()` flipped to `GlassStyle.ios27` by default. Scheduled for deprecation and removal in 2.0.0 so `GlassStyle` only represents Apple OS eras (`ios26`, `ios27`, etc.).

### SDK, Dependency & Behaviour Changes Scheduled for 2.0.0

- **Flutter `>=3.50.0` & standalone `cupertino_ui` migration** — unpark `feat/flutter-3.50-migration` to migrate all 71 `package:flutter/cupertino.dart` imports (deprecated in Flutter 3.50) to standalone `cupertino_ui` alongside raising the minimum Flutter SDK constraint.
- **`GlassAppBar.pinned` becomes the plain `GlassAppBar`**, demoting the widget-based `leading`/`actions` constructor to a legacy mode.
- **Lone pinned bar items render at `44pt`** on both sides, matching the back button and iOS 26/27, rather than `46pt` when `GlassBarItemBackground.shared` is used.
- **`GlassSurfaceStyle.solid` becomes the default for cards, grouped lists, and date pickers** — `GlassContainer.card`, `GlassGroupedSection`, `GlassReorderableList.grouped`, `GlassDisclosureGroup.standalone`, `GlassDatePicker`, and `GlassMultiDatePicker` flip their default `surfaceStyle` from `GlassSurfaceStyle.glass` to `GlassSurfaceStyle.solid` (flat opaque `#FFFFFF` / `#1C1C1E` cards with 26pt continuous corners, matching native `.insetGrouped` lists). **Automatic child inheritance is already implemented (`1.16.0` / `1.17.2`):** because `GlassTextField`, `GlassTextField.search`, `GlassSearchBar`, `GlassTextArea`, `GlassPasswordField`, `GlassPicker`, and `GlassChip` already default to `surfaceStyle: null` and read `InheritedGlassSurfaceStyle`, flipping those enclosing containers in `2.0.0` automatically switches every nested input/picker well to `GlassSurfaceStyle.solid` (`tertiarySystemFill`), while standalone floating inputs on a page canvas remain `glass`. `GlassContainer()` itself stays glass-first; pass `surfaceStyle: GlassSurfaceStyle.glass` on cards/sections to keep the glass look.
