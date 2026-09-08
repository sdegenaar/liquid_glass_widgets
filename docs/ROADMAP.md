# Roadmap: 1.x → 2.0

> Last updated: 2026-09-08 (reflecting 1.4.2 state; `feat/1.5.0` branch active)

This document tracks planned and future work for `liquid_glass_widgets` post-1.0.
The guiding principle remains: **fewer, better widgets that map 1:1 to real iOS 26 components**.

For historical version notes (0.14 → 1.0), see [`CHANGELOG.md`](../CHANGELOG.md).

---

## Current Status (1.4.2 — `main`)

| Criterion | Status | Notes |
|---|---|---|
| No known P0/P1 bugs | ✅ Clear | No open crash reports |
| Dartdoc complete on all public API | ✅ Done | `public_member_api_docs` enforced permanently |
| Test coverage ≥ 90% | ✅ Done | ~92% line coverage (2,932 tests) |
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
| Light-mode golden tests | ⬜ Planned (1.5.0) | In `feat/1.5.0` |
| `reduceTransparency` native detection | ⬜ Planned (1.5.0) | Method channel; currently approximated via `highContrast` |
| Example app covers all widgets | ⚠️ Partial | Not verified against current widget catalogue |
| Platform testing matrix complete | ⚠️ Partial | iOS + Android confirmed; Web, Windows, macOS need QA |

---

## Active: 1.5.0 (`feat/1.5.0` branch)

### Shader-Level Touch Specular (`uTouchPosition` uniform)

`GlassButton`'s touch-tracking specular sheen (shipped in 1.3.0) is a uniform additive
brightness boost on the Standard path and **absent entirely on the Premium/Impeller path**.
The correct implementation passes the pointer coordinate as a shader uniform, biasing the
specular light direction toward the touch point inside the fragment shader.

Benefits: geometrically bounded by the SDF (no clipper needed), zero GPU cost at rest
(`uTouchActive = 0.0` kills the specular term), physically correct highlight that conforms
to capsule/pill corner geometry. See [ROADMAP.md L109-L144] for the full GLSL sketch.

**Scope:** New uniforms in `liquid_glass_final_render.frag`, pointer-event → shader UV
mapping per `GlassGlowLayer`, Skia path retains existing additive brightness fallback.

### Vibrancy Fill Fallback for Nested Glass

When `InheritedLiquidGlass(avoidsRefraction: true)` is set by `GlassContainer`, an inner
`GlassEffect` silently falls through to `GlassQuality.minimal` with no visible surface —
looks like a broken widget. The correct fix renders a translucent tinted fill with rim and
specular preserved but the refraction lens dropped, approximating iOS 26 vibrancy layer
behaviour. The debug-assert stopgap is skipped in favour of shipping the correct fix.

### `reduceTransparency` Native Detection

`GlassAccessibilityScope` currently approximates Reduce Transparency via
`MediaQuery.highContrastOf(context)` (Increase Contrast on iOS — a different toggle).
A small method channel reading `UIAccessibility.isReduceTransparencyEnabled` gives exact
detection.

### Light-Mode Golden Snapshots

Add golden regression snapshots for key widgets in `Brightness.light` to catch visual
regressions after the Rec.709 luma shift and any future shader calibration work.

---

## Post-1.0 Candidates

Ideas under consideration. None committed.

### New Widgets

- [ ] `GlassSplitView` — proper `UISplitViewController` equivalent with adaptive
  columns, swipe-to-collapse, and navigation state. **Large scope — requires
  dedicated planning before implementation.**
- [ ] `GlassColorWell` — iOS 26 colour picker pill. Scoped as a trigger widget:
  a tappable glass swatch that opens a `GlassPopover`; colour picker content
  is supplied by the caller.

### Enhancements

- [ ] **Scroll-driven glass materialisation** — app bar surface transitions from
  transparent to frosted on scroll. Closely related to the scroll edge fidelity
  fix above; the two may ship together when `GlassScrollEdgeStyle.blur` lands.
- [ ] **Shader-Level Touch Specular (`uTouchPosition` uniform, target 1.4.0)** —
  `GlassButton`'s touch-tracking specular sheen (shipped in 1.3.0) is implemented
  as a 2D `Canvas.drawCircle` painted with `BlendMode.plus` and clipped by
  `ShapeBorderClipper`. This is a good approximation but not physically correct:
  the specular term should be computed *inside* the fragment shader as a bias on
  the SDF surface normal, not as an additive overlay on top.

  The correct implementation passes the pointer coordinate to the glass fragment
  shader as a new uniform:
  ```glsl
  uniform vec2  uTouchPosition; // Layer-local logical px; (-1,-1) when inactive
  uniform float uTouchActive;   // 0.0 at rest → 1.0 while finger down (spring)

  // Bias the specular light direction toward the touch point
  vec2  touchOff = (uTouchPosition / uLayerSize) * 2.0 - 1.0;
  vec3  biasedLight = normalize(uLightDir + vec3(touchOff * 0.4, 0.0));
  float spec = pow(max(dot(surfaceNormal, biasedLight), 0.0), shininess)
             * uTouchActive;
  ```
  Benefits over the 1.3.0 overlay approach:
  - Geometrically impossible to escape the glass SDF boundary (no clipper needed).
  - Zero GPU cost at rest (`uTouchActive = 0.0` kills the `spec` term entirely).
  - Physically correct: the specular is part of the glass reflection, not painted
    over it.
  - Enables a clean, deprecation-friendly API: `glowRadius`/`glowBlurRadius`/
    `glowSpreadRadius` can be removed in a 2.0 breaking change, replaced by the
    declarative `interactionBehavior` enum analogous to SwiftUI's `.interactive()`.
  - **Natural geometry adaptation across aspect ratios:** Because the SDF surface
    normal inherently reflects the widget's exact shape and corner radii, the specular
    highlight naturally conforms to capsule/pill geometries (concentrating on curved
    caps while moderating across flat label spans), eliminating the need for
    shape-specific radius tuning between circular and pill buttons.

  **Scope:** Requires the vendored `liquid_glass_renderer` shaders to accept two new
  uniforms, pointer-event → shader UV coordinate mapping per `GlassGlowLayer`, and
  Skia/Web fallback (the existing `GlassGlow` overlay can remain the Skia path).
- [ ] **`GlassAppBar` Phase 3 compact search icon** — when `GlassLargeTitle.searchBar`
  and `GlassAppBar.largeTitleController` are in use and `searchBarCollapseProgress == 1.0`,
  show a compact search affordance that re-expands on tap. Blocked by: `GlassAppBar`
  currently implements `ObstructingPreferredSizeWidget` with a fixed `preferredSize`;
  Phase 3 requires dynamic height, touching the layout contract with `CupertinoPageScaffold`.
  Phases 1 + 2 (shipped 0.19.6) deliver 90% of the value; Phase 3 is a polish milestone.
- [ ] **`GlassToast` queue management** — show multiple toasts sequentially instead
  of overlapping.
- [ ] **Drag-to-reorder in `GlassTabBar.bottom()`** — long-press to rearrange tabs,
  matching iOS tab bar customisation.
- [ ] **`GlassSheet` snap points** — configurable detent heights (peek / half / full)
  matching `UISheetPresentationController.Detent`.
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

- [ ] **`reduceTransparency` native detection** — `GlassAccessibilityScope` currently
  approximates Reduce Transparency via `MediaQuery.highContrastOf(context)`, which maps
  to **Increase Contrast** on iOS — a different toggle. A small method channel reading
  `UIAccessibility.isReduceTransparencyEnabled` would give exact detection. Until then,
  the README notes the approximation.
- [ ] **Light-mode golden tests** — add golden snapshots for key widgets in
  `Brightness.light` to catch regressions.

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

Deprecated symbols from the 1.x series (`GlassBottomBar`, `GlassSearchableBottomBar`,
`GlassBottomBarTab`, `GlassTabBar(isScrollable: true)`) are scheduled for removal in 2.0.0.

Behaviour changes scheduled for 2.0.0:

- `GlassAppBar.pinned` becomes the plain `GlassAppBar`, demoting the widget-based
  `leading`/`actions` constructor to a legacy mode.
- A pinned group holding a single item renders at 44pt on both sides, matching the
  back button and iOS 26, rather than 46pt when its items are
  `GlassBarItemBackground.shared`.
