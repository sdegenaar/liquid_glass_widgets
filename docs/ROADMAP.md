# Roadmap: 0.15.0 → 1.0.0

> Last updated: 2026-06-19

This document tracks the planned work to get `liquid_glass_widgets` from the
current 0.14.x series to a stable 1.0.0 release. The guiding principle is:
**fewer, better widgets that map 1:1 to real iOS 26 components** — nothing
half-baked, nothing Material-flavoured.

---

## 0.14.x — Stabilisation ✅

0.14.0–0.14.2 shipped, settled, and patch-released. 0.14.2 completed the
initial Material artifact purge (InkWell → GestureDetector, Material icons →
Cupertino). **Done.**

---

## 0.15.0 — API Cleanup (Breaking) ✅

A focused breaking release that removes Material-leaning and thin-wrapper
widgets before the API surface gets cemented at 1.0.

### Widgets to Delete

| Widget | Reason |
|---|---|
| `GlassWizard` | Material vertical stepper concept. Apple uses navigation stacks or horizontal pagers for multi-step flows — not numbered circles connected by lines. |
| `GlassSideBar` | Simplified drawer / navigation rail. A real iPadOS sidebar is `UISplitViewController` with adaptive column widths, swipe-to-collapse, and deep navigation state. This widget is a static `Column` in a `SizedBox(width: 280)` — shipping it implies iPad-readiness it doesn't have. |
| `GlassSnackBar` | Literally documented as "Alias for GlassToast to match Material Design naming." Remove the alias, keep `GlassToast`. |
| `GlassPanel` | Thin convenience wrapper — identical to `GlassContainer` except `padding: 24` instead of `16` and `borderRadius: 20` instead of `12`. Not worth the API surface. Users can pass those two values to `GlassCard` or `GlassContainer`. |

### Deprecations

| Symbol | Notes |
|---|---|
| `GlassBackdropScope` | Deprecated in 0.14.0 (now a no-op). Kept as deprecated until 1.0.0 per the published deprecation timeline. Will be deleted in 1.0.0. |

### Exports & Tests

- Remove deleted widgets from `liquid_glass_widgets.dart` barrel exports.
- Delete associated test files and golden image files.
- Update example app to remove any demos referencing deleted widgets.
- Update README widget catalogue.

### What Stays (and Why)

Every remaining widget should map to a recognisable iOS 26 component:

| Widget | iOS 26 Equivalent | Notes |
|---|---|---|
| **Structural** | | |
| `GlassPage` | Full-screen glass page root | ✅ Solid |
| `GlassScaffold` | `CupertinoPageScaffold` + glass | ✅ New in 0.14, solid |
| `GlassAppBar` | `UINavigationBar` (transparent) | ✅ Name is Flutter-discoverable, implementation is iOS 26 |
| `GlassTabBar` | `UITabBarController` (unified) | ✅ One widget: `.bottom()`, `.searchable()`, default inline |
| `GlassSegmentedControl` | `UISegmentedControl` | ✅ `GlassSegmentedControl.scrollable()` covers filter chips |
| `GlassBottomBar` | `@Deprecated` → `GlassTabBar.bottom()` | Thin shim, removed in 2.0 |
| `GlassSearchableBottomBar` | `@Deprecated` → `GlassTabBar.searchable()` | Thin shim, removed in 2.0 |
| `GlassToolbar` | `UIToolbar` | ✅ Solid |
| **Containers** | | |
| `GlassContainer` | Base glass surface | ✅ Core primitive |
| `GlassCard` | Grouped inset card | ✅ `GlassContainer` with card defaults |
| `GlassListTile` | `UICollectionViewListCell` | ✅ Name is Flutter-discoverable |
| `GlassDivider` | `UITableView` separator | ✅ Solid |
| `GlassStepper` | `UIStepper` (−/+ control) | ✅ Direct 1:1 iOS mapping |
| **Interactive** | | |
| `GlassButton` | Various button styles | ✅ Core, heavily tested |
| `GlassIconButton` | `UIBarButtonItem` | ✅ Solid |
| `GlassSegmentedControl` | `UISegmentedControl` | ✅ Direct mapping |
| `GlassSwitch` | `UISwitch` | ✅ Direct mapping |
| `GlassSlider` | `UISlider` | ✅ Direct mapping |
| `GlassChip` | Filter pill / tag | ✅ Common in iOS apps (Photos tags, App Store) |
| `GlassBadge` | Notification badge | ✅ Direct mapping (`UITabBarItem.badgeValue`) |
| `GlassButtonGroup` | Grouped button bar | ✅ iOS toolbar button groups |
| `GlassPullDownButton` | `UIMenu` pull-down | ✅ Direct iOS 16+ mapping |
| `GlassPageControl` | `UIPageControl` | ✅ Direct mapping — dot indicators for paged content |
| **Input** | | |
| `GlassTextField` | `UITextField` | ✅ Solid, community-tested |
| `GlassTextArea` | Multi-line `UITextView` | ✅ Solid |
| `GlassSearchBar` | `UISearchBar` | ✅ Solid |
| `GlassPasswordField` | Secure `UITextField` | ✅ Convenience, solid |
| `GlassFormField` | Label + error text wrapper | ✅ Simple utility, no glass — just layout |
| `GlassPicker` | `UIPickerView` | ✅ Direct mapping |
| **Feedback** | | |
| `GlassProgressIndicator` | `UIProgressView` / `UIActivityIndicatorView` | ✅ Direct mapping |
| **Overlays** | | |
| `GlassDialog` | `UIAlertController` (.alert) | ✅ Solid |
| `GlassActionSheet` | `UIAlertController` (.actionSheet) | ✅ Direct mapping |
| `GlassSheet` | `UISheetPresentationController` | ✅ Solid |
| `GlassModalSheet` | Modal sheet variant | ✅ Solid, documented guide |
| `GlassMenu` | `UIMenu` / context menu | ✅ Solid, liquid morph engine |
| `GlassMenuItem` / `GlassMenuDivider` / `GlassMenuLabel` | Menu item types | ✅ Support widgets for `GlassMenu` |
| `GlassToast` | Notification pill / HUD | ✅ Widely understood cross-platform term |
| **Shared / Infra** | | |
| `AdaptiveGlass` | Quality-adaptive glass renderer | ✅ Core infra |
| `AdaptiveLiquidGlassLayer` | Layer wrapper | ✅ Core infra |
| `GlassIsolationScope` | Z-order isolation | ✅ Core infra |
| `GlassAccessibilityScope` | Accessibility config | ✅ Core infra |
| `GlassAdaptiveScope` | Device capability adaptation | ✅ Core infra |
| `GlassMotionScope` | Reduce-motion support | ✅ Core infra |
| `GlassScrollEdgeEffect` | iOS 26 `.scrollEdgeEffectStyle(.soft)` | ✅ Core infra |
| `LiquidGlassScope` | Refraction/background source config | ✅ Core infra |

---

## 0.18.0 — `GlassTabBar` Unification (All-in-One)

The defining architectural change before 1.0. Ships everything in one release:

### What Ships

1. **Internal `pill_internal.dart` merge** — `bottom_bar_internal.dart` +
   `tab_bar_internal.dart` merged into one engine with a `placement` flag.
   Prerequisite for everything else.

2. **Expanded `GlassTab`** — gains `activeIcon`, `glowColor` fields from
   `GlassBottomBarTab`. `GlassBottomBarTab` becomes `@Deprecated` typedef.

3. **`GlassTabBar` named constructors** — `.bottom()` (current `GlassBottomBar`
   behaviour) and `.searchable()` (current `GlassSearchableBottomBar`). Default
   constructor retains current inline tab bar behaviour.

4. **Deprecation shims** — `GlassBottomBar` and `GlassSearchableBottomBar`
   become zero-logic `StatelessWidget` wrappers forwarding to
   `GlassTabBar.bottom()` / `.searchable()`. Kept through 1.x, removed in 2.0.

5. **`GlassSegmentedControl.scrollable()`** — handles scrollable horizontal chip rows.
   Promoted from `GlassTabBar(isScrollable: true)`. That flag is deprecated.

6. ~~**Always-visible resting glass**~~ — *Omitted: Native iOS 26 uses a flat translucent pill at rest to save GPU cycles, blooming into glass only during interactions. Our existing implementation using `indicatorColor` already handles this correctly. Forcing the Impeller glass shader to run permanently at rest was deemed a performance waste and a deviation from native behaviour.*

### Breaking Changes

- **Visual:** All resting-state goldens regenerate (glass pill now visible at rest)
- **Semantic:** `indicatorColor` changes from solid-pill fill to glass tint
- **Deprecations:** `GlassBottomBar`, `GlassSearchableBottomBar`,
  `GlassBottomBarTab`, `GlassTabBar(isScrollable: true)` — all still work, IDE warnings only

### Migration

```dart
// BEFORE
GlassBottomBar(tabs: [...], ...)           → GlassTabBar.bottom(tabs: [...], ...)
GlassSearchableBottomBar(tabs: [...], ...) → GlassTabBar.searchable(tabs: [...], ...)
GlassBottomBarTab(label: 'Home', icon: ...)→ GlassTab(label: 'Home', icon: ...)
GlassTabBar(isScrollable: true, ...)       → GlassSegmentedControl.scrollable(segments: [...], ...)
```

---

## 0.18.x → 0.19.x — Hardening

Focus areas to address before 1.0. These are not all confirmed — they will be
refined based on 0.18.x feedback and community requests.

### Material Artifact Purge (continued from 0.14.2)

0.14.2 replaced `InkWell` → iOS-style opacity highlight and swapped Material
icons to Cupertino equivalents in `GlassListTile`, `GlassActionSheet`, and
`GlassStepper`. Remaining items:

- [ ] **Hardcoded colour audit** — Multiple widgets hardcode colours instead of
  resolving from theme:
  - `GlassSwitch` defaults `activeColor` to `Colors.green` (iOS uses system
    green, which is theme-aware)
  - `GlassFormField` uses `Colors.redAccent.shade100` for errors (iOS uses
    system red)
  - `GlassDialog` uses `Colors.red` for destructive actions
  - `GlassMenuDivider` uses hardcoded `Color(0xFFEF5350)` for destructive items
  - All should resolve from `GlassThemeData.glowColors` or
    `CupertinoColors.systemRed` / `.systemGreen`

### Light Mode / Theming Gap ✅ Resolved (infrastructure complete)

The library is no longer broken in light mode. A comprehensive content colour
audit across 0.15.0 and 0.15.1 replaced all hardcoded `Colors.white` /
`Colors.black` with brightness-aware `CupertinoColors` / `CupertinoTheme`
resolution. Light-mode drop shadows, frosted-white standard glass, and
brightness-aware `GlassSearchBar` / `GlassTextField` defaults were all shipped.

**Resources:**
- [iOS 26 Liquid Glass: Comprehensive Reference](https://medium.com/@madebyluddy/overview-37b3685227aa)
  — Material variants (`.regular`/`.clear`), hierarchy rules ("glass cannot
  sample glass"), accessibility modes, specular highlights, and adaptive shadow
  principles. Key validation against our implementation:
  - ✅ Lensing (not just blur) — our `LiquidGlassRenderer` does true refraction
  - ✅ 135° upper-left key light — both theme variants use `lightAngle: 2.356`
  - ✅ Glass isolation — `GlassIsolationScope` prevents glass-sampling-glass
  - ✅ Navigation-layer-only — all widgets map to iOS navigation-tier components
  - ✅ Adaptive shadows — `GlassShadow` constants with inverse-clipped rendering
  - ✅ Light-mode content colours — all widgets resolve from `CupertinoTheme`
- Apple HIG: Liquid Glass guidelines (WWDC 2025 sessions)

**0.15.0 fixed:**
- `GlassMenuItem`, `GlassMenuDivider`, `GlassMenuLabel` — colours from `CupertinoTheme`
- `GlassDialog`, `GlassActionSheet` — brightness-aware backgrounds and text
- `GlassPage` — safe under pure `CupertinoApp` (no `Theme.of` guard)
- `glassSettings` → `settings` rename across 8 widgets
- Example app migrated from `MaterialApp` to `CupertinoApp`

**0.15.1 fixed:**
- `GlassTextField`, `GlassSearchBar` — default text/icon/glow colours brightness-aware
- `GlassFormField` — label/helper text from `CupertinoColors.label` / `.secondaryLabel`
- `GlassPicker` — value text and chevron from `CupertinoColors.label`
- `GlassPasswordField` — icons from `CupertinoColors.secondaryLabel`
- `GlassToast` — background and text resolve from brightness
- `GlassChip` — text and icons visible in light mode
- Light-mode drop shadows (inverse-clipped, `GlassShadow` constants)
- Standard quality glass renders as clean frosted white in light mode

**Content colour audit completed across 0.15.0–0.15.1:**
- [x] `GlassTextField` — text/icon/glow colours now brightness-aware
- [x] `GlassToolbar` — title and divider colours from `CupertinoTheme`
- [x] `GlassAppBar` — title text from `CupertinoTheme` (no hardcoded colours)
- [x] `GlassStepper` — labels from `CupertinoTheme`, dividers brightness-aware
- [x] `GlassToast` — background and text resolve from brightness
- [x] `GlassProgressIndicator` — no hardcoded `Colors.white`/`Colors.black`

**0.18.6 fixed:**
- Centralised brightness authority — `GlassTheme.brightnessOf(context)` is now
  the single mandatory call site for all brightness decisions in the library.
- Four-level cascade: `GlassThemeData.brightness` override → explicit Cupertino
  pin → `MaterialApp` `ThemeMode` (the root fix) → OS/device fallback.
- New `GlassThemeData.brightness` field for per-glass-subtree overrides.
- All 26 widget files migrated from ad-hoc `CupertinoTheme` / `MediaQuery`
  brightness lookups to `GlassTheme.brightnessOf`.
- Canonical regression: `GlassBottomTabBar` shadow disappearing when device is
  in Dark Mode but app is pinned to `ThemeMode.light` — fully fixed.
- 39 new tests covering the full cascade including the regression scenario.

**Remaining:**
- [ ] **Light-mode golden tests** — add golden snapshots for key widgets in
  `Brightness.light` to catch regressions.

### Platform Edge Cases / Engine Bugs

- [ ] **CanvasKit Web circular clipping** — `LiquidOval` relies on `ClipRRect(borderRadius: 9999)` inside `_ShapeClip` to work around an iOS PlatformView compositing bug (Flutter #177551). However, on Web (CanvasKit), this massive radius breaks path clipping, causing the interaction `GlassGlow` to spill out as a giant square and destroying the CSS/SVG drop-shadow extraction on `DecoratedBox`. 
  - **Proposed fix:** We need a way to branch and use `ClipOval` / `BoxShape.circle` strictly for Web/CanvasKit, or wait for an upstream engine fix for `ClipRRect(9999)` bounds calculation on Web.

### RTL / Internationalisation

Only `GlassTextField` and the shared renderer reference `TextDirection`. No
widget-level RTL testing exists.

- [ ] **RTL layout audit** — verify all widgets using `Row`, `Positioned`,
  `EdgeInsets.only(left:)` work correctly in RTL locales. Replace
  directional padding with `EdgeInsetsDirectional` where appropriate.
- [ ] **RTL golden tests** — at minimum for `GlassListTile`, `GlassAppBar`,
  `GlassTabBar.bottom()`, and `GlassTabBar.searchable()`.

### Quality & Reliability

- [ ] **Test coverage push** — target 90%+ line coverage on all remaining
  public widgets. Currently at ~2219 tests; identify gaps.
- [ ] **Golden test audit** — ensure every widget has at least one golden for
  both Standard and Premium quality modes.
- [ ] **Accessibility audit** — verify every interactive widget has correct
  `Semantics`, focus traversal, and VoiceOver/TalkBack support.
- [ ] **Performance profiling** — document frame budgets for common layouts
  (list of 50 cards, bottom bar + body, modal sheet stack).
- [ ] **Brightness enforcement lint / CI check** — a grep-based CI script (or
  eventually a `custom_lint_builder` rule) that fails the build if any widget
  calls `MediaQuery.platformBrightnessOf` or `CupertinoTheme.of(context).brightness`
  directly, enforcing that all brightness decisions go through
  `GlassTheme.brightnessOf`. The three intentional exceptions in `glass_page.dart`
  and `glass_scaffold.dart` (OS status-bar icon colour) are whitelisted.

### API Polish

- [ ] **Consistent parameter naming** — audit all widgets for naming
  inconsistencies (e.g. `glassSettings` vs `settings`, `useOwnLayer` patterns).
- [ ] **Deprecation sweep** — ensure any deprecated API from 0.12–0.14 is
  either removed or has a clear migration path documented.
- [ ] **Public API freeze** — document the complete public API surface and
  commit to it. No new widget classes after this point, only refinements.

### Documentation

- [ ] **Widget catalogue page** — README or docs/ page with screenshots of
  every widget in both quality modes.
- [ ] **Migration guide** — 0.14 → 0.15 migration guide covering all deleted
  widgets and what to use instead.
- [ ] **Architecture doc update** — update ARCHITECTURE.md for any structural
  changes since it was last written.

### pub.dev Readiness

- [ ] **Screenshots** — add 3–5 screenshots to `pubspec.yaml` for the pub.dev
  listing (bottom bar, glass cards, menu morph, dialog, search bar).
- [ ] **Funding metadata** — add `funding:` to pubspec if applicable.
- [ ] **Analysis score** — ensure 160/160 pub points (no warnings, full
  dartdoc coverage, all platforms declared).

---

## 1.0.0 — Stable Release

### Entry Criteria

All of the following must be true before tagging 1.0.0:

- [ ] No known P0/P1 bugs.
- [ ] All public API documentation is complete (dartdoc on every public class,
  method, and parameter).
- [ ] Test coverage ≥ 90% on public API surface.
- [ ] Example app demonstrates every widget with working code.
- [ ] No Material `InkWell`, `Icons.*`, or hardcoded `Colors.*` in widget
  implementations (doc examples may still reference them for familiarity).
- [ ] Light mode and dark mode both produce acceptable visuals for all widgets.
  *(0.18.6: brightness resolution infrastructure is now solid — all widgets honour
  `ThemeMode`. Remaining gap: golden coverage in `Brightness.light`.)*
- [ ] RTL layout verified for all widgets that lay out children horizontally.
- [ ] Tested on: iOS (Impeller), Android (Impeller), Android (Skia), Web,
  macOS, Windows.
- [ ] **Platform limitation docs** — a `docs/PLATFORM_SUPPORT.md` documenting
  known limitations per platform (e.g. web shader fallbacks, Skia vs Impeller
  quality differences, Windows SkSL compatibility rules).
- [ ] **Keyboard & focus support** — all interactive widgets support Tab
  focus traversal and Enter/Space activation for macOS/iPadOS keyboard use.
- [ ] No deprecated symbols from pre-0.15 remain (0.18.0 deprecation shims stay through 1.x).
- [ ] CHANGELOG documents every breaking change from the 0.x series with
  migration instructions.
- [ ] README widget table is accurate and complete.

### Semver Commitment

From 1.0.0 onward:
- **Patch** (1.0.x): Bug fixes only.
- **Minor** (1.x.0): New widgets, new parameters, non-breaking additions.
- **Major** (2.0.0): Breaking changes (widget removal, parameter rename, behaviour change).

---

## Future (Post-1.0)

Ideas for consideration after stable. None of these are committed.

### New Widgets
- [ ] `GlassSplitView` — proper `UISplitViewController` equivalent with
  adaptive columns, swipe-to-collapse, and navigation state. This is the widget
  `GlassSideBar` wanted to be but wasn't ready for.
- [ ] `GlassDatePicker` / `GlassTimePicker` — iOS date/time picker wheels with
  glass treatment.
- [ ] `GlassColorWell` — iOS 26 colour picker pill.
- [ ] `GlassNavigationTransition` — coordinated glass morphing during
  `CupertinoPageRoute` push/pop transitions.

### Enhancements
- [ ] **Scroll-to-minimize** (`GlassBarMinimizeBehavior.onScrollDown`) — tab bar
  shrinks on scroll-down, re-expands on scroll-up. Matches iOS 26
  `tabBarMinimizeBehavior`. High priority post-1.0.
- [ ] **Tab bar bottom accessory** — persistent widget (mini player) above
  the tab bar that animates with minimize. Matches iOS 26 `tabViewBottomAccessory`.
  Currently achieved via `GlassScaffold.bodyOverlays` manually.
- [ ] Scroll-driven glass materialisation — app bar surface that transitions
  from transparent to glass on scroll (the feature removed from `GlassAppBar`
  in 0.14.0, done properly as a standalone widget or `GlassScaffold` feature).
- [ ] `GlassToast` queue management — show multiple toasts sequentially
  instead of overlapping.
- [ ] Drag-to-reorder support in `GlassTabBar.bottom()` — long-press to rearrange
  tabs, matching iOS tab bar customisation.
- [ ] `GlassSheet` snap points — configurable detent heights (peek / half /
  full) matching `UISheetPresentationController.Detent`.

### Ecosystem
- [ ] Dedicated documentation site (GitHub Pages or similar).
- [ ] Figma/Sketch component library matching the widget catalogue.
- [ ] VS Code / IntelliJ snippet pack for common widget patterns.

