# 1.4.0

## Features

- **`GlassBodyMode` (`adaptive` vs `clear`) — exact design token color fidelity (#269):**
  Introduced `GlassBodyMode` enum and `bodyMode` property on `LiquidGlassSettings` (defaulting to `GlassBodyMode.adaptive`), achieving 1:1 parity with Apple iOS 26 Liquid Glass `Glass.regular` vs `Glass.clear`.
  - `GlassBodyMode.adaptive` (default): Employs iOS 26 dynamic luminosity normalization, ambient tint modulation, and brightness compensation based on underlying backdrop luminance.
  - `GlassBodyMode.clear`: Bypasses luminosity normalization, white-point lift, and content-adaptive modulation. Directly composites the designer's exact hex color and alpha from `glassColor` over the refracted scene while preserving all 3D optical properties (specular rim reflections, Fresnel edge glow, meniscus edge absorption, and surface refraction).
  - Perfectly resolves color fidelity when `blur: 0` is combined with custom tinted glass surfaces.
  - Fully integrated across all shader tiers (Impeller `liquid_glass_final_render.frag`, standard `lightweight_glass.frag`, and Skia `_FrostedFallback`).

- **Decoupled track background quality in `GlassTabBar`:**
  Added `backgroundQuality: GlassQuality?` across `GlassTabBar.bottom`, `GlassTabBar.inline`, `GlassTabBar.searchable`, and `GlassTabBar.minimizable`.
  - Directly matches UIKit's `UITabBarAppearance.backgroundEffect` decoupling from the active selection capsule.
  - Allows tab bar containers to render with lightweight frosted glass (e.g., `backgroundQuality: GlassQuality.minimal` or `.standard`) while the moving selection pill retains full liquid refraction (`quality: GlassQuality.premium`).
  - Defaults to `null`, which seamlessly inherits from `quality` without any visual regression.

- **`GlassTabBarTrailingButton.menu` and `GlassTabBarExtraButton.menu` — native pull-down menus from tab bars (#275):** Both the trailing pill on `GlassTabBar.minimizable` and the extra action button on `GlassTabBar.bottom` and `GlassTabBar.searchable` now support an optional `GlassMenu` pull-down, using the same `.menu` named-constructor pattern established by `GlassButtonGroupItem.menu` and `GlassBarItem.menu`.

  ```dart
  // Minimizable trailing pill → opens a menu on tap
  GlassTabBarTrailingButton.menu(
    icon: const Icon(CupertinoIcons.ellipsis_circle),
    label: 'More',
    menuItems: [
      GlassMenuItem(label: 'Edit', onTap: _edit),
      GlassMenuItem(label: 'Share', onTap: _share),
    ],
  )

  // Bottom-bar extra button → opens a menu on tap
  GlassTabBarExtraButton.menu(
    icon: const Icon(CupertinoIcons.plus),
    label: 'New',
    menuItems: [
      GlassMenuItem(label: 'New Note', onTap: _newNote),
      GlassMenuDivider(),
      GlassMenuItem(label: 'Import', onTap: _import),
    ],
  )
  ```

  - **Liquid spring origin:** The menu expansion spring originates from the button's actual render coordinates — identical behaviour to `GlassBarItem.menu` and `UIBarButtonItem(image:menu:)` in SwiftUI.
  - **Auto-upward expansion:** `autoAdjustToScreen: true` is always applied, so menus anchored inside a bottom bar always expand upward, matching the iOS 26 Liquid Glass `UIMenu` behaviour on toolbar items.
  - **`enabled` toggle:** Setting `enabled: false` on either constructor dims the button and suppresses the menu — consistent with the existing tap-callback variant.
  - **Accessibility:** Both triggers are wrapped in a `Semantics` node using the required `label` so screen readers announce the control correctly.
  - **API surface:**
    - `GlassTabBarTrailingButton` gains: `menuItems`, `menuAlignment`, `menuWidth`, `label`, `enabled`.
    - `GlassTabBarExtraButton` gains: `menuItems`, `menuAlignment`, `menuWidth`. The `label` and `enabled` fields were already present.
    - The `isMenu` getter on both classes returns true when the menu variant is active.
  - **No scope creep:** Direct pass-through of arbitrary widget trees to the trigger position is explicitly deferred; use `GlassMenu.triggerBuilder` directly for fully custom triggers.

  Thanks to [@JoetineY](https://github.com/JoetineY) for the feature request (#275).

## Bug Fixes

- **Color configuration is uncertain when blur=0 (#269):** When developers configured custom tint colors with `blur: 0`, the surface previously suffered from unexpected luminance and saturation drift because the shader applied adaptive ambient and light calculations intended for blurred glass. Developers can now set `bodyMode: GlassBodyMode.clear` on `LiquidGlassSettings` to bypass adaptive tinting and composite the exact designer hex color while maintaining specular highlights, Fresnel sheen, and 3D meniscus edge refraction.

Thanks to [@JoetineY](https://github.com/JoetineY) for the bug report (#269).

- **Minimized bar keeps the selected tab's icon colour (#279):** On `GlassTabBar.minimizable`, the minimized pill drew the selected tab's icon in `unselectedIconColor`, so a custom `selectedIconColor` dropped out on minimize and returned on expand. The pill now uses `selectedIconColor`, as the native bar does — the tab is still selected, only the bar has shrunk. `GlassTabBar.searchable` is unchanged: its collapsed pill shows the tab search was opened from, which is no longer the selected one.

Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix (#280).

- **`GlassScrollEdgeStyle.blur` stays on its own route (#278):** The progressive blur is a backdrop filter, and left unclipped a backdrop filter frosts everything beneath it up to the nearest ancestor clip — under a Cupertino pop that included the route being revealed, which showed the outgoing screen's top and bottom bands until the transition settled. The shader path lost its `ClipRect` when the region moved to paint time in 0.30.1; it is back, so a `ProgressiveBlur` now frosts nothing outside its own rectangle wherever it sits.

Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix and on-device integration tests (#281).

- **`GlassAppBar` title alignment (#282):** Left-aligned titles (`centerTitle: false`) no longer add an unintended 8 px start gap when no leading widget is present, correctly aligning with content padding.

Thanks to [@Vincen-dev](https://github.com/Vincen-dev) for the bug report and reproduction test (#282).

- **Menu and popover dismiss instantly on route navigation (#274):** When an item or action navigates to another page, `GlassMenu` and `GlassPopover` dismiss immediately instead of playing the close spring across the destination route transition.

Thanks to [@Vincen-dev](https://github.com/Vincen-dev) for the bug report (#274).

---

# 1.3.0

## Bug Fixes

- **`GlassButton` presses like a native button (behaviour change) (#267):** Measured at 120 fps, the press now grows by ~17 pt on a snappy spring (`interactionScale: null`), drags stretch no more than ~5 %, and the surface combines ambient lift (`ambientBaseLight: 0.3`) with a subtle shape-clipped specular sheen (`glowRadius: null`, resolving to a wide 1.6 radius with soft sigma-16 blur). The highlight is clipped strictly to `shape` via `ShapeBorderClipper`, staying bounded within the button geometry and sweeping across grouped buttons without creating a pointy hotspot. `LiquidStretch` declares its scale through `LiquidGlassSelfScaleScope` so the release undershoot no longer freezes refraction.

  > **Migration:** Pass `glowRadius: 0.0` to disable the directional sheen (pure ambient lift). Pass `interactionScale: 1.05`, `ambientBaseLight: 0.08`, or use `GlassInteractionSettings` theme-wide to customize.

- **Search circle and trailing pill press like native buttons (#272, #276):** The collapsed pills now use `GlassButton`'s ~17 pt growth, tremor stretch, and ambient lift, staying round through inflation. The expanded search field follows a lengthwise drag (≈7 pt saturation) and gives a couple of points of vertical stretch, measured against Photos. `pressScale` and `ambientBaseLight` are both nullable — null means the native behaviour, a number is a fixed override.

Thanks to [@JakeThomson](https://github.com/JakeThomson) for the native press implementation, `LiquidOval` corner fix, and axis-constrained expanded field stretch (#276).

- **Transform tracking crash on route pop fixed (#268):** `GeometryTransformTrackingLayer.addToScene` now checks `renderObject.attached` and wraps `getTransformTo(null)` in a try-catch, preventing the `StateError` that occurred while render objects were detaching during page transitions.

Thanks to [@kdbhalala](https://github.com/kdbhalala) for the fix (#268).

## Performance

- **O(N) Quickselect for frame timing percentiles (#268):** The Phase 3 P95 hysteresis check now uses in-place Quickselect (Hoare partition, midpoint pivot) instead of a full sort, eliminating per-evaluation heap allocations on the frame callback path.

Thanks to [@kdbhalala](https://github.com/kdbhalala) for the optimisation (#268).

- **Zero-allocation glow paint path (`_RenderGlassGlowLayer`):** Eliminates per-frame `Path` allocations during gesture spring animations. `_RenderGlassGlowLayer` now follows the Flutter engine's `RenderCustomClip` pattern: clip paths are cached keyed on `size`, `shouldReclip` prevents re-clipping on value-equal rebuilds, and `canvas.translate` replaces `.shift()`. Drops native path heap churn from up to 240 allocations/s on 120 Hz ProMotion displays to zero steady-state allocations during drags.

## Internal

- **`THIRD_PARTY_NOTICES` added (#273):** The pub.dev archive now includes full MIT copyright notices for the vendored `liquid_glass_renderer` and adapted `motor` spring utilities. README updated to link to the notices file.

---


# 1.2.3

## Bug Fixes

- **Inline bottom accessory reaches the trailing edge without a trailing button (#264):** On `GlassTabBar.minimizable`, a minimized bar with a bottom accessory and no trailing button left a dead gap on the trailing edge — the accessory geometry reserved space for the trailing pill regardless of whether one was present. The accessory now extends flush to the horizontal padding when no trailing button is configured, and still clears the pill when one is.

Thanks to [@eomgerm](https://github.com/eomgerm) for the fix (#265).

## Internal

- **`MinimizableTrailingPill` — dedicated stateless pill for the trailing slot:** The trailing-button pill was previously synthesised by re-using `GlassSearchBarConfig` with a dummy search config, creating a double-source-of-truth between `_buildMinimizable` and the layout engine. It is now a dedicated `MinimizableTrailingPill` widget sharing the same `LayoutBuilder`/oval-detection morph pattern as `SearchPill` — identical pill physics, single authoritative gate. A debug-mode assert now fires if `searchConfig` and `trailingButton` are both non-null; these are mutually exclusive rendering slots.

---

# 1.2.2

## New Features

- **Scrollable segmented control — selection stability and picker behaviors (#263):** The pill no longer slides in from the track edge on mount or blinks out on list changes (`VelocitySpringBuilder.teleportEpoch`). `GlassSegment.id` keeps surviving cells mounted across list changes. New opt-in picker behaviors: `SegmentSelectionAlignment.center`, `SegmentDragBehavior.scroll`, `regridDuration` (anchored re-grid morph, default `Duration.zero`), and an externally injectable `scrollController`.

Thanks to [@jfhair](https://github.com/jfhair) for the full implementation, tests, and example demo (#263).

---

# 1.2.1

## Bug Fixes

- **Quality recovery is reachable again (#261):** Glass quality demoted by a transient cost spike (a map, large images, a native view) now recovers after a sustained run of under-budget frames. Previously, frames landing in the neutral band between the upgrade and downgrade thresholds reset the recovery counter, making recovery essentially unreachable in practice.

- **Tab indicator settles back when host declines selection (#255):** Dragging or tapping to a new tab when the host declines the selection (action tab, navigation guard, failed route push) previously left the indicator parked on the wrong tab. It now springs back to the host's current tab on the next frame across all gesture paths.

- **Sheet ↔ content scroll handover (#258):** A multi-detent `GlassModalSheet` now grows and then scrolls its content on one unbroken drag, and reverses the same way. Content on a `ScrollController` of its own is now observed too — no call-site changes required.

- **`GlassNavigationShell` pinning no longer gated on blur quality (#262):** Pinning is chrome geometry, not a shader effect — it costs no render pass of its own. The `minimal` quality gate that previously switched pinning off has been removed. `GlassQualityAdapter` steps down to `minimal` automatically under frame pressure, so pinning was silently disabling itself in debug builds and on low-end devices that need it most.

Thanks to [@Nixxx19](https://github.com/Nixxx19) for the quality recovery, tab indicator, and pinning gate fixes (#255, #261, #262).

Thanks to [@JakeThomson](https://github.com/JakeThomson) for the sheet ↔ content scroll handover (#258).

---

# 1.2.0

## New Features

- **Native gel morph for pinned clusters:** A cluster present on both routes now reshapes the way the iOS 26 bar does instead of gliding between widths. Its width and item positions ride the package's bouncy spring profile for the full length of the route transition, settling in the same breath the page lands; the spring's overshoot is deliberately not walked in width — it is expressed as a whole-shell squeeze instead, layered on a gel pulse that inflates the shell early — height, radius and glyphs together, as real geometry through the glass renderer. Glyphs no longer plainly cross-fade: an outgoing glyph smears away under heavy blur while the shell reshapes beneath it, and an incoming one arrives soft and sharpens last. A pop plays the same forward choreography toward the other cluster rather than the push in reverse. The morph stays a pure function of the route clock; timing and blur constants live together in `GlassNavPinnedMetrics`, and the choreography is locked down by a frame-by-frame trace test. (Clusters only one route has materialize instead — see below.)
- **Header Actions Morph demo:** New pattern in the example app's Navigation Patterns page — a repository-style drill-down where each destination carries a different trailing cluster (contract to one, identifier-matched hold, widen to three), so every capsule morph can be exercised and scrubbed in isolation.
- **Progressive Blur Scroll Edge Style (`GlassScrollEdgeStyle.blur`):** Introduces a hardware-accelerated GPU progressive Gaussian frost option via `ProgressiveBlur`, applying an `ImageFilter.shader` pass with ease-in quadratic falloff (`falloff: 1.2`) directly over live scrolling content. Default remains `GlassScrollEdgeStyle.soft` (the diffused gradient fade matching iOS 26's `.scrollEdgeEffectStyle(.soft)`). Developers can opt into `.blur` for richer frosting over custom dynamic gradients, video backdrops, or media grids.
- **Configurable `maxSigma` & Signed Fade Extents:** Exposes `maxSigma` (default 18.0) for `GlassScrollEdgeStyle.blur`, alongside signed `topEdgeFadeExtent` and `bottomEdgeFadeExtent` (default 20.0) on `GlassScaffold` and `GlassScrollEdgeEffect` for granular transition zone control (including negative extents for tight floating-bar insets).
- **Materialize entrance & exit transitions (`GlassMaterialize`):** Glass items now appear and disappear the way iOS 26 does, mirroring SwiftUI's `glassEffectTransition(.materialize)`: the glass fades up as it settles inward from slightly oversized, and its content sharpens only after the shape has resolved — reversed on the way out, where the content blurs away first and leaves the shell briefly empty before it dissolves. `GlassMaterialize` is the implicit `visible:`-driven form (the `AnimatedOpacity` idiom); `GlassMaterializeTransition` is the explicit `Animation`-driven form (the `FadeTransition` idiom), and doubles as an `AnimatedSwitcher.transitionBuilder` via `GlassMaterializeTransition.switcherBuilder`. Works on any glass surface at any quality tier: rather than fading a layer — which pops, because a backdrop pass renders fully or not at all — the effect drives the glass shader's own visibility uniforms, where the refraction warp lerps to identity and the render pass drops out entirely at zero.
- **Pinned navigation chrome materializes (behaviour change):** A pinned back button or actions capsule that only one of the two routes has no longer switches on or off at the transition midpoint — it materializes or dematerializes over a window straddling it. The phase is a pure function of route progress, so a pop plays the windows in reverse with the exit still leading the entrance in both directions. An interactive back-swipe does *not* scrub them: the page and title track the finger, but the chrome holds still until the gesture commits and then plays its transition over the travel that remains, so a swipe you abandon never half-dissolves anything. A capsule present on *both* routes is unaffected: it still morphs in place with one persistent glass shell. Opt out with `GlassNavigationShell.effectTransition: GlassEffectTransition.identity`, which restores the 1.1.0 behaviour exactly; **Reduce Motion selects it automatically**, and the standalone widgets likewise fall back to a plain cross-dissolve with no scale or blur.
- **Materialize Playground Demo:** Added `example/lib/demos/materialize_demo.dart` — a single glass button, a multi-item capsule, and an `AnimatedSwitcher` swapping glass chips, each toggleable, over a busy backdrop with a live Reduce Motion switch.
- **`GlassPinnedBarChrome` — pin a bar that isn't a `GlassAppBar`:** The registration handshake behind `GlassAppBar.pinned` is now public, so an app whose bars are its own widgets — a Material `AppBar` with a bespoke backdrop, a collapsing large-title sliver — can join a `GlassNavigationShell` without reimplementing it. Items are declared once as data; the builder receives `chrome.leading` and `chrome.actions`, which hold the real glass buttons until the shell has both accepted the registration and had a frame to render its copy, and same-sized unpainted placeholders after — so the bar never builds a second copy and nothing shifts at the hand-over. `GlassAppBar.pinned` now builds its own slots the same way, so there is one implementation rather than two. An `enabled` flag keeps a nested navigator's roots out of the shell, which ranks routes within a single `Navigator`. New **Custom Bar Pinning** pattern in the nav-patterns demo pins a plain Material `AppBar`.
- **Pinned leading items (`GlassAppBar.pinned(leading:)`):** The pinned bar's leading slot is no longer limited to its own automatic back button, so a screen with a Cancel, a close button or a profile photo can pin its chrome instead of falling back whole. `leading` takes the same `GlassBarItem` vocabulary as `actions` and inherits the whole morph — width interpolation, `id` matching, icon cross-fade, taps swallowed mid-transition — because the cluster render object now anchors to whichever edge it is pinned to rather than always the trailing one. A non-empty `leading` **replaces** the back button, matching `UINavigationItem.leftBarButtonItems` and Flutter's own `AppBar.leading`; `leadingItemsSupplementBackButton: true` shows both, mirroring `UINavigationItem.leftItemsSupplementBackButton`. A lone back button renders exactly as before.
- **`GlassBarItemBackground` — per-item glass:** Collapses the two booleans iOS 26 added to `UIBarButtonItem` into their three distinct results: `shared` (the default — `sharesBackground`, items form one capsule), `separate` (`sharesBackground: NO` — its own shell, which at a lone icon's size is the circular button iOS 26 draws for a single bar item) and `none` (`hidesSharedBackground` — no glass at all, for content that carries its own shape, such as a profile photo). A cluster now renders one shell per group rather than always one capsule.
- **Leading Items demo:** The nav-patterns showcase gains a pattern walking the four leading configurations — a bare avatar, the implied back button, a leading that replaces it, and one beside it — plus the lone circular shell growing into a two-item capsule.
- **Scroll Edge Playground Demo:** Added a comprehensive interactive showcase in the example app (`example/lib/demos/scroll_edge_style_demo.dart`) featuring live style switching (`soft`, `hard`, `blur`), real-time extent/sigma sliders, top/bottom toggles, and floating `GlassAppBar` & `GlassTabBar.bottom` integration with solid content cards.
- **Bottom accessory follows the bar (behaviour change) (#226):** on
  `GlassTabBar.minimizable`, a `bottomAccessory` with no explicit
  `bottomAccessoryPlacement` now resolves to
  `GlassTabBarAccessoryPlacement.inline` while the bar is minimized, matching
  how iOS 26 animates a `tabViewBottomAccessory` down into the minimized bar.
  Previously it stayed `expanded` unless `inline` was passed explicitly.

  **This changes what `GlassTabBarAccessoryPlacementScope.of(context)` returns**
  for affected callers — an accessory that switches on it will render its
  compact variant on scroll where it previously did not, with no code change on
  your side — and shrinks `preferredSize` by
  `bottomAccessorySpacing + bottomAccessoryHeight` while minimized. Affects only
  bars that have an accessory, pass no explicit placement, and reach the
  minimized state. Pass `GlassTabBarAccessoryPlacement.expanded` to keep the
  previous behaviour.

  `GlassTabBar.searchable` is deliberately unchanged. Auto-collapsing on search
  was removed in 0.x because it hid the mini-player behind the search capsule,
  and that decision stands — a search field expanding is not the bar minimizing.

## API

- **`PlatformViewGlassMode.passthrough` — glass over platform views (#247):** New enum value on `LiquidGlassSettings`. Instead of resolving to black where the backdrop capture held nothing (over a map, camera, video, or WebView), coverage follows what was actually sampled so the live view shows through. Default is `PlatformViewGlassMode.fallbackColor` — no behaviour change for existing callers. `GlassTabBar` gains a matching `passthroughOverPlatformView` flag that lifts selected-tab content above the glass to avoid the doubled-label the refracted icon layer would otherwise cause.

- **`GlassChip.platformViewBackdrop` (#250):** `GlassButton` already exposed this parameter; `GlassChip` now surfaces and forwards it, closing the gap for chips rendered over platform views. Default is `false`, no change for existing callers.

- **`GlassNavPinnedMetrics` is now exported from the package barrel:** The geometry the pinned shell redraws hoisted chrome at — 44pt back circle, 46pt action slots, 44pt toolbar band, 8pt edge inset. A bar that is not a `GlassAppBar` had no supported way to reach it and had to hardcode the numbers, which drift the first time the package retunes them. The `show` clause exposes the metrics only; `GlassNavPinnedHost` and the cluster render objects stay internal. Documented under [Glass Navigation Transition](docs/GLASS_NAVIGATION_TRANSITION.md#if-your-bar-is-not-a-glassappbar).

## Bug Fixes

- **`GlassNavPinnedMetrics.crossFadeStart`/`crossFadeEnd` changed meaning:** These are now fractions of the morph window (`morphStart`..`morphEnd`) rather than raw route progress; `glyphSharpenStart`/`glyphSharpenEnd` follow the same convention. Read them through `GlassNavPinnedMetrics.morphProgressAt` to align custom chrome.
- **Matched icons no longer spuriously cross-fade:** Icons were compared by reference rather than value, so two identical `Icon(Icons.x)` literals on different routes cross-faded with themselves on every push. Icons are now compared by value (glyph, size, colour, key).
- **`GlassTabBarMinimizeController` drivable without a `ScrollController`:** `handleSample` is no longer `@visibleForTesting`, and a new `handleNotification(ScrollNotification)` method drives the bar directly from a `NotificationListener`. Leave `GlassTabBar.minimizable`'s `scrollController` unset when using this path.
- **`blur: 0` no longer downgrades any tier to `_FrostedFallback` (#253):** A `blur: 0` surface now keeps its rim, Fresnel, and specular — the shader's own guard already handles the zero-blur pass cleanly. **Visual change at standard:** surfaces that previously resolved to `_FrostedFallback` now render the lightweight shader. Use `GlassQuality.minimal` explicitly if frost fallback was intentional.
- **Presented routes now cover the pinned chrome (#259):** A dialog, action sheet, `GlassModalSheet`, or `fullscreenDialog` previously left the pinned glass back button and actions capsule painted above the presentation at full brightness. The shell now hands the chrome back to the presented route so it dims with everything else.

Thanks to [@JakeThomson](https://github.com/JakeThomson) for the materialize transitions, pinned navigation chrome, leading API and per-item glass backgrounds, scroll-to-minimize controller improvements, bottom accessory inline behaviour, metrics export, and the presented-route chrome fix (#240, #238, #236, #239, #233, #234, #259).

Thanks to [@marco242424](https://github.com/marco242424) for the native gel morph (#243).

Thanks to [@Nixxx19](https://github.com/Nixxx19) for the platform-view glass passthrough mode, `GlassChip` backdrop parameter, and the blur tier-downgrade fix (#247, #250, #253).

---

# 1.1.0

## New Features

- **GlassNavigationTransition — pinned navigation-bar chrome:** New `GlassNavigationShell` hosts the glass back button and trailing actions capsule *above* the `Navigator`, reproducing the iOS 26 navigation bar: page content and title slide during push/pop (including the interactive back-swipe, scrubbed proportionally) while the glass chrome stays pinned and morphs in place. Screens opt in with the `GlassAppBar.pinned` constructor, declaring actions as data (`GlassBarItem.icon` / `GlassBarItem.custom`); items sharing an `id` are treated as the same item across routes, mirroring `UIBarButtonItem.identifier`. Custom widgets are measured at intrinsic width, exactly as UIKit measures a `customView`. Works with any Pages-API router (go_router, auto_route, beamer) — the shell only reads `ModalRoute` animations. Without a shell, or where the effect cannot render, the same data renders in-route as today's glass capsule.
- **`GlassBarItem.menu` — pull-down menus in a pinned bar:** The `UIBarButtonItem.menu` analogue, and the iOS 26 overflow button. The whole capsule morphs into the pull-down, matching `GlassButtonGroupItem.menu`. Menus cannot be opened mid-transition, and one already open is dismissed when navigation starts — the pinned capsule outlives the route that owns it, so nothing else would. Falls back to `GlassButtonGroupItem.menu` in-route wherever pinning does.
- **GlassAppBar single-line titles:** The inline title no longer wraps to a second line when wide actions squeeze it; it truncates with an ellipsis, matching iOS.
- **`GlassModalSheet` swipe-dismissals morph back from the release point (#223):** Dragging a morphed sheet away used to skip the morph and slide the sheet off. Below the lowest detent the sheet now shrinks about the grabbed point as it follows the finger — the interactive zoom-dismissal measured off iOS 26 — and the release hands that exact frame to the closing morph. Sideways, the card chases the finger through a tracking spring, pinning at the screen edge. A release short of the dismiss threshold springs back. Sheets shown without `morphFrom` keep their plain slide-away unchanged.
- **Scroll-to-minimize for `GlassTabBar.minimizable` (#228):** A new `GlassTabBarMinimizeController` drives the minimize from scrolling — the Flutter equivalent of SwiftUI's `.tabBarMinimizeBehavior(_:)`. `GlassBarMinimizeBehavior` mirrors Apple's enum case for case. The trigger is accumulated distance, not a per-frame delta — fixing the 1.0.0 ProMotion 120 Hz reliability issue.

## Bug Fixes

- **Spring reversals no longer stall (#228):** `SearchableBottomBarController.makeSpring` now carries in-flight velocity through retargets; reversing mid-morph no longer reads as a stall followed by a restart. Also benefits `GlassTabBar.searchable`.
- **Shared `ScrollController` crash fixed (#228):** The searchable and minimizable placements reading `ScrollController.position` now safely guard when multiple scroll views share one controller during transitions.
- **Premium glass shape no longer stranded during swipe-dismiss (#229):** `RenderLiquidGlassLayer` froze shader UVs under any uniform scale-down, which was correct for the CupertinoSheet push-back but wrong for a swiped `GlassModalSheet` whose backdrop holds still. A new internal `LiquidGlassSelfScaleScope` lets the sheet declare which arrangement it is; the push-back path is unchanged.

## Improvements

- **`GlassNavActionSlot.crossFades` — documented widget-equality behaviour:** Cross-fade detection uses reference equality; `const` icon widgets share an instance across routes and never trigger a spurious cross-fade. Documented in the API dartdocs and the navigation guide.
- **Multiple `GlassBarItem.menu` in one cluster — debug warning:** Using more than one menu item in a single cluster silently treated the extras as plain icons. A debug-mode `debugPrint` now surfaces this so developers see the constraint immediately rather than wondering why a second menu does not open.
- **`GlassModalSheet` fling velocity carried into the closing morph (#227):** A fast swipe no longer stalls at the release point — the closing droplet now starts at the speed the fling was running at rather than from rest.

## Documentation

- **`GlassModalSheet.peekSize` docs:** Clarified that `peekSize` accepts both absolute pixels (`> 1.0`) and a screen-height fraction (`≤ 1.0`), consistent with `halfSize` and `fullSize`.
- **New guide:** `docs/GLASS_NAVIGATION_TRANSITION.md` — setup (including `.router`), matching rules, a behaviour table, a direction section, and known limitations.
- **`ROADMAP.md`** — `GlassNavigationTransition` checked off; the "pinning becomes the default" trajectory and parity work recorded.

Thanks to [@JakeThomson](https://github.com/JakeThomson) for the navigation transition, modal sheet, tab bar scroll-to-minimize, and premium renderer fix improvements (#221, #223, #227, #228, #230).

---

# 1.0.0

## Major Milestone: General Availability

This release marks the **1.0.0 General Availability** of `liquid_glass_widgets`, delivering a stable, unified API surface, zero third-party dependencies, and production-grade iOS 26-style liquid glass with hardware-adaptive quality tiers (Metal, Vulkan, Skia, and shader-free fallbacks) across all supported Flutter platforms.

### New Features

- **`GlassTabBar.minimizable()` — SwiftUI `tabBarMinimizeBehavior` parity (#217):** A new named constructor that collapses the tab bar to a single selected-tab circle without requiring a search bar. `minimized` replaces `isSearchActive`, `onMinimizedTabTap` handles the restore tap, `minimizedBarHeight` shrinks both pills while minimized, and an optional `GlassTabBarTrailingButton` fills the trailing slot — exactly modelling `Tab(role: .search)` priority-visibility behaviour. Scroll-driven minimize is caller-controlled, matching the SwiftUI `.onScrollDown` pattern.
- **`GlassSearchBarConfig.showPill` (#217):** A new boolean on `GlassSearchBarConfig` (default `true`) that removes the search pill entirely and returns its width to the tab pill. Hiding is done by unmounting the pill and spring-scaling it at its slot — `Opacity` and zero-width leave a glass remnant fused to the tab pill on the shared blend layer; only absence can hide a grouped glass surface.

Thanks to [@JakeThomson](https://github.com/JakeThomson) for the contribution (#217).

- **`GlassModalSheet` morphs from a trigger button (#219):** `show()` gains `morphFrom` — the `GlassMorphAnchor` from a new `GlassMorphTrigger` wrapper — presenting the sheet with the iOS 26 liquid morph instead of the slide-up: the trigger empties, a glass droplet detaches and inflates as it travels, and lands as the sheet. Makes the sheet the second consumer of the Liquid Morph Engine after `GlassMenu`. `morphSpeed` tunes the spring.
- **`GlassMorphTrigger` / `GlassMorphAnchor` (#219):** The wrapper owns the trigger's key and opacity so the trigger can empty itself for the morph and take the closing bounce on its own ticker. `morphFromRect` remains for triggers that can't be wrapped, blooming from a point. The morph degrades gracefully to the slide presentation on Skia/web, `GlassQuality.minimal`, and `platformViewBackdrop`.

Thanks to [@JakeThomson](https://github.com/JakeThomson) for the contribution (#219).

### Breaking Changes & API Unification

- **Unified Navigation Surface (`GlassTabBar`)**:
  - Consolidated bottom navigation into `GlassTabBar` via named constructors: `GlassTabBar.bottom()`, `GlassTabBar.searchable()`, and `GlassTabBar.inline()`.
  - Removed legacy transitional shims `GlassBottomBar` and `GlassSearchableBottomBar`.
  - Tab items are now canonically represented by `GlassTab` across all tab bars.
  - Tab bar collapse types `GlassTabBarCollapseConfig` and `GlassTabBarCollapseDirection` have been **removed**. The collapse-to-extra-button pattern is not an iOS 26 design primitive and was unreliable on 120 Hz ProMotion displays. Use `GlassTabBar.minimizable` instead — it directly mirrors SwiftUI's `tabBarMinimizeBehavior(.onScrollDown)` with spring physics.
- **Modal Sheet Simplification**:
  - Removed deprecated `enablePeek` parameter from `GlassModalSheet`, `GlassModalSheet.show()`, and `GlassModalSheetScaffold`. Sizing and peeking behavior is now governed cleanly and declaratively by `detents` and `mode`.
- **Initialization & Setup Cleanup**:
  - Removed deprecated `respectsAccessibility` from `LiquidGlassWidgets.initialize()`. System accessibility preferences (Reduce Motion, Reduce Transparency) are now automatically detected and respected out of the box.
  - Removed deprecated `warmUpImpellerPipeline` from `LiquidGlassWidgets.initialize()`. Shader bytecode preloading is handled asynchronously and safely during app bootstrap.
- **Shader Quality & Scope Purge**:
  - Removed deprecated `usesBackdropFilter` getter from `GlassQuality`.
  - Removed deprecated `LiquidGlassScope.stack`, `GlassRefractionSource`, and `LiquidGlassBackground` in favor of `GlassPage` and `GlassBackgroundSource`.
  - Removed deprecated `GlassBackdropScope` stub.

### Documentation & Tooling

- Added comprehensive [Migration Guide](docs/MIGRATION_0.x_TO_1.0.md) detailing step-by-step code upgrades for 0.x projects.
- Updated documentation and all example demo screens for 1.0.0 APIs.

---

# 0.30.2

## Bug Fixes

- **GlassPullDownButton / GlassMenu crash in minimal quality (#214):** Fixed a crash when quality falls back to `GlassQuality.minimal`. `LiquidGlassBlendGroup` is now skipped when no `LiquidGlassLayer` is present in the tree. Same fix applied to `GlassPopover`.

---

# 0.30.1

## Bug Fixes

- **Dark mode collapsed tab pill icon (#208):** Fixed an issue where the collapsed tab pill icon in `GlassTabBar.searchable` rendered opaque black in dark mode instead of white when `unselectedIconColor` was unset.
- **ProgressiveBlur region origin (#210, credit: @jfhair):** Fixed `ProgressiveBlur` rendering black or losing its gradient when not positioned at the top-left of the backdrop layer (modal sheets, inset containers, scroll edges). The shader region origin is now resolved at paint time, keeping the gradient correct through drags and animated transitions.
- **GlassScrollEdgeEffect stale background on route resume (#212):** Fixed stale background texture and ghosting shadows when returning from routes where the theme or background changed. Background capture is now deferred until the route resumes, and in-flight capture requests are coalesced.

---

# 0.30.0

## Bug Fixes

- **Windows Impeller startup hang (#204):** `LiquidGlassWidgets.initialize()` no longer submits blocking GPU draw calls to the raster thread prior to `runApp()`. On Flutter 3.47+ Windows Impeller (ANGLE / `OpenGLESSDF`), runtime GLSL driver compilation previously locked the raster thread during OS surface initialization, preventing the native window from presenting. The app window now displays immediately on Frame 1 on all Windows and desktop configurations.
- **Android GLES ANR (#187 follow-up):** Removed the synchronous pre-`runApp` offscreen warm-up draw. All Android devices launch with zero splash-screen delay, and GLES devices are safely protected from runtime driver compile lockups.

## Architecture & Performance

- **Non-blocking shader preloading with full Vulkan/Metal parity:** `LiquidGlassWidgets.initialize()` now preloads shader bytecode asynchronously into memory via fast I/O on Android (Vulkan and GLES), iOS, and macOS, eliminating first-frame placeholder flashes while ensuring zero GPU raster stalls before `runApp()`.
- **Zero GPU work before `runApp()`:** Removed all `toImageSync` calls from `preWarm()`. Internal 1×1 sampler dummy textures are now allocated lazily on first paint in the widget tree.
- **`GlassWarmUpMode` configuration:** Added `warmUpMode` (`GlassWarmUpMode.auto`, `.always`, `.never`) to `LiquidGlassWidgets.initialize()`. Default `.auto` preloads all shaders for Android, iOS, and macOS, while skipping unused premium shaders on statically-capped desktop/web backends. Deprecated `warmUpImpellerPipeline`.
- **Windows & Linux adaptive defaults:** `GlassAdaptiveScope` static probe defaults Windows and Linux to `GlassQuality.standard` (`lightweight_glass.frag` with real iOS 26 squircle geometry, dual specular highlights, meniscus absorption, and blur) for guaranteed 60/120fps performance without driver compile delays.
- **GLES shape compile optimization:** `shaders/sdf.glsl` now caps shape evaluation at 8 shapes on OpenGL ES / ANGLE backends via `#ifdef LGR_OPENGLES_CAP_SHAPES` (`shaders/gles_compat.glsl`), reducing the inlined AST size for runtime JIT drivers while leaving Metal (iOS/macOS) and Vulkan (Android) on the full 16-shape unrolled AOT path with zero changes.

---

# 0.29.8

## Maintenance & Upstream Compatibility

- **Pure Flutter SDK dependencies:** Removed all third-party and external dependencies across runtime and dev environments (`equatable`, `flutter_shaders`, `logging`, `meta`, `alchemist`, and `mocktail`). Golden tests now use Flutter's native `matchesGoldenFile`. Package depends purely on `flutter: sdk: flutter`.
- **Optimized value equality:** Replaced `Equatable` with native `operator ==` and `Object.hashAll` across shapes and settings, eliminating heap allocations during hot animation loops.
- **Internalized shader loading & uniform binding:** Shaders load directly via `dart:ui.FragmentProgram` with cached isolate pipelines and zero-overhead uniform setters.

---

# 0.29.7

## Performance

- **Progressive blur: 50% fewer texture reads.** Gaussian tap count halved with identical ±3σ coverage; GPU memory bandwidth for the blur pass is halved with no perceptible quality change.
- **Gaussian weight loop: `exp()` eliminated.** Per-tap exponential replaced with a two-scalar IIR recurrence — saves 24 GPU instructions per blur pass with mathematically identical output.
- **PlatformView fallback: skipped when unused.** The background composite is now gated on a uniform flag; no GPU cost when there is no PlatformView beneath the glass.

## Visual

- **`edgeAbsorption` parameter added** (`LiquidGlassSettings`, `GlassThemeSettings`, default `0.0`): Physical rim darkening — the glass absorbs more light at the thickest edge. Default `0.0` matches iOS 26's crisp luminous glass. Increase (`0.10–0.20`) for physical-depth or iOS 27-style recipes.
- **Hemisphere lens profile:** Replaced polynomial falloff with a physical circular arc across all shaders — interiors stay crystal clear while absorption steepens at the bevel.
- **Light-modulated absorption:** Absorption is scaled by light direction for realistic 3D rim separation without washing out specular highlights.
- **Cross-platform `fresnelStrength` parity:** `fresnelStrength` now controls grazing-angle rim highlights identically across all rendering engines (Skia, Web, Windows, Android, and Impeller).
- **Edge-concentrated chromatic aberration:** Prismatic dispersion is now strictly zero in flat glass interiors, concentrated only at the rim — consistent across all rendering paths.

## Example App & Tooling

- **Meniscus & Blur Lab (`MeniscusAndBlurDemoPage`):** Interactive calibration workbench for live testing of `edgeAbsorption`, `fresnelStrength`, thickness, blur, and progressive blur performance.

## Bug Fixes

- **`GlassTabBarExtraButton` loses backdrop blur in minimal quality (#203):** Added `isStationary` flag to `GlassButton` (default `false`). Setting `isStationary: true` on `GlassTabBarExtraButton` retains its `BackdropFilter` blur in `GlassQuality.minimal`.

---


# 0.29.6

## Bug Fixes

- **Impeller GLES sampling UV double-flip on Flutter 3.46+ (#202):** Flutter 3.46 absorbed the OpenGL ES render-to-texture Y-axis inversion inside the engine backend, but six shader sites still compensated for the old convention — actively mirroring every backdrop sample on 3.46+. A new `shaders/gles_compat.glsl` header gates the flip on `IMPELLER_OPENGLES_UNFLIPPED_DEPRECATED`, the migration macro introduced by the Flutter engine team for exactly this transition. The fix is correct across all Flutter versions from the existing `>=3.41.0` minimum; the `pubspec.yaml` constraint does not move. A new source-level regression guard in `test/shaders/gles_flip_guard_test.dart` prevents the pattern from re-appearing.

Thanks to [@TIANLI0](https://github.com/TIANLI0) for the contribution (#202).

---

# 0.29.5

## Bug Fixes

- **`GlassAppBar` title not centred when `leading` is set (#198):** Toolbar layout rewritten using a `CustomMultiChildLayout` delegate, matching the approach used by Flutter's own `CupertinoNavigationBar`. The title is now centred on the full bar width regardless of leading/trailing widget sizes, and is constrained to never overlap either button group. `centerTitle: false` correctly left-aligns the title after the leading widget in both LTR and RTL locales.

---

# 0.29.4

## Bug Fixes

- **`GlassModalSheet` stale `_currentState` (#197):** A drag ending at its origin state left `_currentState` holding the predicted mid-drag target. `_currentState` is now reconciled on every snap unconditionally, preventing the sheet from appearing stuck after a short drag.
- **`GlassModalSheet` overscroll axis guard (#197):** `_onScrollNotification` now ignores notifications whose `metrics.axis` is not `Axis.vertical`, preventing horizontal descendant lists (carousels, date strips) from hijacking the sheet gesture.
- **`GlassModalSheet` one-shot axis lock (#197):** Gesture axis is decided once on the first movement past the threshold and held until the touch lifts, preventing a sideways swipe from later grabbing the sheet mid-gesture.

Thanks to [@jfhair](https://github.com/jfhair) for the contribution (#197).

---

# 0.29.3

## Bug Fixes

- **Premium glass lens detaches during `CupertinoSheet` drag (#192):** The refracted lens drifted away from its pill while an interactive `CupertinoSheet` drag scaled the background. Fixed by snapshotting the layer's unscaled screen-space coordinates on every paint frame and freezing them the moment a uniform ancestor scale-down is detected, keeping UV mapping locked to the captured texture for the duration of the drag.
- **`GlassAppBar` title typography (#194):** The title widget is now wrapped in `DefaultTextStyle` using `CupertinoTheme`'s `navTitleTextStyle`, matching native `CupertinoNavigationBar` behaviour. A plain `Text` widget now automatically picks up correct Cupertino typography (weight, size, ellipsis) without manual styling. Also adds `Semantics(header: true)` for VoiceOver/TalkBack navigation.

---

# 0.29.2

## Universal DPR (Device Pixel Ratio) Normalization

The Liquid Glass rendering engine now achieves 1:1 mathematical parity across all display densities (e.g., macOS 2.0x, iOS 3.0x, and various Android fractional densities like 2.75x or 3.5x). Previously, running shaders in physical pixels caused inconsistent refraction scaling on high-density screens.

- **Geometry Curvature:** `effectiveThickness` is scaled by DPR, guaranteeing identical refraction depth across devices.
- **Surface Normals:** SDF tap spacing is scaled by DPR, ensuring edge highlights and Fresnel rims maintain exact proportional widths.
- **Lighting Clamps:** The physical thickness floor is scaled by DPR, preventing lighting anomalies across different hardware.

## Bug Fixes

- **Indicator Pill:** Removed chromatic aberration (`0.15` → `0.0`) from the default animated pill to eliminate the rainbow rim artifact, while preserving true lens distortion.
- **Pinch Shader:** Fixed a mathematical bug (L6 norm with an 8th-root extraction) in the squircle distance field. Replaced with an exact **L4 norm**, producing naturally soft, Apple-like corners during drag animations and saving one GPU instruction per fragment.
- **Brightness Cascade (#124):** Hardened the brightness resolution cascade by evaluating `brightnessResolver` before `CupertinoTheme.of`. This acts as a defensive backstop for older Flutter versions or edge cases where the `MaterialBasedCupertinoThemeData` bridge fails to propagate `ThemeMode` correctly.
- **Accessibility / Semantics (#189):** Restored VoiceOver/TalkBack tap-to-dismiss behavior. The `GlassModalSheet` drag indicator now exposes a `Semantics.onTap` action that correctly triggers sheet dismissal, matching Material's handle behavior.
- **Customization (#190):** `GlassModalSheet`'s `dragIndicatorColor` is now honored. It was previously accepted by the API but dropped internally in favor of hard-coded defaults.
- **Android Quality (Best Foot Forward):** `GlassAdaptiveScope` now seeds at `maxQuality` (premium) on Android from the very first frame. Previously, Android cold-started at `standard` and promoted to premium only after the 3-second Phase 2 benchmark. The ANR safety net (shader pre-compilation in `LiquidGlassWidgets.initialize()`) makes this safe; Phase 2 continues to demote genuinely slow/budget devices.


---

# 0.29.1

## Fixes

**`GlassSegmentedControl` — duplicate unlabeled semantics node (#188)**
Each segment emitted two tappable nodes (one unlabeled), breaking VoiceOver/TalkBack. Fixed by adding `excludeFromSemantics: true` to the internal `GestureDetector`; semantics are fully handled by `GlassFocusRegion`.

**`GlassTabBar` shadow lost in Dark OS + Light app (#124)**
Shadow disappeared when the device was in Dark Mode but `ThemeMode.light` was set. Introduced a zero-material IoC bridge: pass `brightnessResolver: Theme.maybeBrightnessOf` to `LiquidGlassWidgets.wrap()` so the package correctly honours `ThemeMode` without importing `flutter/material.dart`.

> **Migration** — MaterialApp users must add this one line to fix #124:
> ```dart
> runApp(LiquidGlassWidgets.wrap(
>   child: const MyApp(),
>   brightnessResolver: Theme.maybeBrightnessOf,
> ));
> ```
> `CupertinoApp` users: no change required.

**Dead `flutter/material.dart` import removed from `tab_bar_bottom_internal.dart`**
Leftover from pre-0.26.0, never cleaned up. `lib/` is now 100% zero-material for `cupertino_ui` compatibility.

---



Eliminates production ANRs on Android devices running Impeller GLES (devices without
Vulkan support, including many MediaTek and budget Qualcomm Snapdragon SoCs).

### Root cause

On Android GLES, `glCompileShader` + `glLinkProgram` executes synchronously on the
Flutter raster thread at first use (100–800 ms on mid-range hardware). When this
coincides with `FlutterJNI.nativeSurfaceChanged` during surface setup, Android's
watchdog declares an ANR. The previous warm-up implementation instantiated a
`LiquidGlassLayer` widget outside the widget tree — an unmounted widget is never
rasterized, so no GPU work occurred. The warm-up was a no-op.

### Fix

- **True GPU warm-up (`liquid_glass_setup.dart`):** `_warmUpImpellerPipeline()` now
  draws both premium glass shaders to a 1×1 off-screen surface using
  `Picture.toImage()` and awaits rasterization. This forces GLES pipeline compilation
  on the raster thread while `initialize()` is still running — before `runApp` — so
  compilation completes behind the native splash screen and cannot race with surface
  setup.

- **Android-only execution:** The warm-up is guarded by
  `defaultTargetPlatform == TargetPlatform.android`. iOS and macOS use precompiled
  Metal shaders and skip this step entirely, preserving their zero startup overhead.

- **Reuses cached programs:** The warm-up now calls `MultiShaderBuilder.cachedProgram()`
  to retrieve the `FragmentProgram` objects already loaded by `precacheShaders()` in
  step 1 of `initialize()`. No duplicate GPU objects are created.

- **`warmUpImpellerPipeline` parameter:** `LiquidGlassWidgets.initialize()` accepts a
  new `warmUpImpellerPipeline: bool` parameter (default `true`). On non-Android
  platforms the parameter is a no-op. Pass `false` only if you are managing Android
  shader warm-up yourself.

- **Conservative Android quality seeding (`glass_adaptive_scope.dart`):** Fixed a
  code-comment mismatch in `_GlassAdaptiveScopeState.initState`. The file header
  documented seeding at `GlassQuality.standard`; the code seeded at `maxQuality`
  (premium). On Android, `initState` now correctly seeds at `GlassQuality.standard`
  so Phase 2 benchmarks the device from a stable baseline. iOS and macOS continue to
  seed at `maxQuality` for an immediate premium experience.

### No action required

Existing call sites (`await LiquidGlassWidgets.initialize()`) are unchanged and
benefit from the fix automatically. The `adaptiveQuality: true` path also benefits
from the corrected `initState` seeding on Android.

### Documentation

- README Platform Support table now distinguishes Android Vulkan from Android GLES
  and links to a new Android GLES mitigation section.

---

# 0.29.0


## 🎵 iOS 26 `tabViewBottomAccessory` Support

Added `bottomAccessory` / `bottomAccessoryHeight` / `bottomAccessoryEnabled` / `bottomAccessorySpacing` / `bottomAccessoryPlacement` to both `GlassTabBar.bottom` and `GlassTabBar.searchable` — mirroring Apple's `tabViewBottomAccessory` modifier.

- **Expanded mode** — accessory floats directly above the nav bar pill with a configurable spacing gap (default `6.0px`, calibrated to match Apple's native spacing).
- **Inline mode** (`searchable` only) — set `bottomAccessoryPlacement: GlassTabBarAccessoryPlacement.inline` to have the accessory slide horizontally into the gap between the collapsed tab indicator and search capsule, with a simultaneous width squish, matching the iOS 26 `.inline` placement.
- **Two independent animation timelines** — `accessoryT` drives the inline↔expanded morph (height, left, right) while `searchT` tracks the tab-pill→search-capsule height change so the accessory follows the bar downward during the search activation, maintaining a consistent visual overlap gap throughout.
- **Safe defaults** — `bottomAccessoryPlacement` defaults to `.expanded`. The accessory never collapses inline automatically; developers must explicitly opt into `.inline` placement, mirroring the iOS 26 model where placement intent is declared at the call site.
- **Pixel-accurate scaffold insets** — `preferredSize` is always in sync with the layout engine so `GlassScaffold`'s edge fade reserves the exact correct amount of space in both expanded and inline states.
- **`GlassTabBarAccessoryPlacement` enum** — `expanded` and `inline` values, readable inside the accessory widget itself via `GlassTabBarAccessoryPlacementScope.of(context)` to adapt the accessory's own layout between the full row and compact strip.
- **Apple Music and Apple Podcasts demos** fully showcase the feature — including the expanded/inline transition and the search-active behaviour.

### Upgrading from `bodyOverlays`

Previously, the recommended pattern for a floating mini-player was to place it in `GlassScaffold.bodyOverlays` and manually manage its position using `AnimatedPositioned` with scroll-offset math. That approach still works and `bodyOverlays` remains available for other use cases (e.g. floating action overlays, toast banners).

For a bottom accessory that is architecturally part of the tab bar — which is exactly what iOS 26 `tabViewBottomAccessory` models — the `bottomAccessory` API is the correct replacement:

```dart
// Before (bodyOverlays workaround)
GlassScaffold(
  bodyOverlays: [
    AnimatedPositioned(
      bottom: _isMiniMode ? barH : barH + accessoryH + spacing,
      left: 0, right: 0,
      child: MiniPlayer(),
    ),
  ],
)

// After (iOS 26-aligned)
GlassTabBar.searchable(
  bottomAccessory: MiniPlayer(),
  bottomAccessoryHeight: 50.0,
  bottomAccessoryPlacement: _isMiniMode && !_isSearching
      ? GlassTabBarAccessoryPlacement.inline
      : GlassTabBarAccessoryPlacement.expanded,
)
```

The new API removes all manual position arithmetic, keeps the `GlassScaffold` edge fade pixel-accurate, and persists the accessory automatically across tab switches.

---

# 0.28.1

## 📚 Internal Refactor — API Documentation

- **100% Dartdoc coverage** — every public member is documented. `public_member_api_docs` is now permanently enabled in `analysis_options.yaml`; future undocumented public API additions will fail `dart analyze`.
- **Internal layout engines moved to `lib/src/`** — 9 internal implementation files relocated per Dart convention so `dart doc` and pub.dev omit them from the generated API reference. No public API changes. 2517 tests passing.

---

# 0.28.0

## 🌐 Full RTL (Right-to-Left) Support

Completed the Right-to-Left (RTL) layout audit. All directional padding and
alignment primitives now use `EdgeInsetsDirectional` / `AlignmentDirectional`
so widgets mirror correctly in RTL locales (Arabic, Hebrew, Persian, etc.)
without any API changes for existing callers.

### Widgets Updated

- **`GlassGroupedSection`** — header and footer labels now use
  `EdgeInsetsDirectional.only(start: 16, end: 16)`. Under RTL the text aligns
  to the correct physical edge.
- **`GlassDivider`** — horizontal divider `indent` / `endIndent` now use
  `EdgeInsetsDirectional.only(start: indent, end: endIndent)`. The leading
  indent is always on the logical leading side regardless of text direction.
  Vertical divider `top` / `bottom` are unchanged (not directional).
- **`GlassAppBar`** — non-centered title now uses
  `AlignmentDirectional.centerStart` + `EdgeInsetsDirectional.only(start: 8)`
  so the title anchors to the leading edge in both LTR and RTL.
- **`GlassSearchBar`** — cancel button gap uses
  `EdgeInsetsDirectional.only(start: 10)` so the gap appears between the
  search field and the cancel button in both directions.
- **`GlassDialog`** — horizontal two-button layout gap uses
  `EdgeInsetsDirectional.only(start: 8)` so buttons remain correctly spaced
  in RTL.
- **`GlassLargeTitle`** — two improvements:
  - `padding` and `searchBarPadding` defaults changed from `EdgeInsets.*` to
    `EdgeInsetsDirectional.*` — the field types were already `EdgeInsetsGeometry`,
    so this is a zero-breaking-change improvement. Callers who pass custom
    asymmetric directional padding (e.g. `EdgeInsetsDirectional.only(start: 32)`)
    now get correct physical mirroring in RTL.
  - `Transform.scale` alignment changed from `Alignment.bottomLeft` to
    `AlignmentDirectional.bottomStart` — under RTL, the rubber-band overscroll
    stretch now scales from the correct logical leading edge rather than always
    pinning to the physical left.
- **`GlassProgressIndicator.linear`** — custom canvas drawing now explicitly
  respects `Directionality`. In RTL locales, both the determinate fill and
  indeterminate moving bar correctly animate from the physical right (logical start)
  to the left.
- **`GlassSlider`** — drag logic and active track drawing now invert cleanly under
  RTL. Dragging left increases the value, and the track anchors to the physical right.

### Bug Fixes & Accessibility

- **`GlassTabBar.bottom`** — Resolved an edge-case visual bug in RTL mode where the animated glass pill would jump to the mirror-image tab when selecting an end tab. Fixed by enforcing `Alignment(x, y)` physical coordinates instead of `AlignmentDirectional` within the physics engine bounds.
- **`GlassSegmentedControl` & `GlassTabBar`** — Unselected segments now correctly emit a "not selected" accessibility state (resolves [#184](https://github.com/sdegenaar/liquid_glass_widgets/issues/184)). Thanks to @Xodus-CO for the detailed report!



---

# 0.27.0


## ♿ Accessibility & Keyboard Navigation

Every interactive widget now supports full keyboard traversal, Space/Enter activation, and VoiceOver/TalkBack semantics.
### Focus & Keyboard

- **`GlassFocusRegion`** — new shared widget that is the single source of truth for all focus behaviour. Two modes:
  - *Interactive* — wraps `FocusableActionDetector`, registers `ActivateIntent` (Space/Enter), lifts hover/focus state to parent via `ValueNotifier`, and paints the iOS 26-style outset focus ring.
  - *Observe* (`.observe()`) — for widgets that own their own `FocusNode` (e.g. `GlassTextField`). Listens passively and paints the ring; no duplicate traversal or intent handling.
- **iOS 26 focus ring** — 3 px outset, 2 px wide, rounded to the widget's shape. Implemented as `GlassFocusRingPainter` (pure `CustomPainter`; zero cost for touch users via `ValueListenableBuilder`).
- **`GlassStepper` keyboard fix** — Space/Enter triggers a single-shot activation; the pointer-only long-press repeat timer is no longer erroneously started by keyboard input.
- All 12 interactive widget families wired: `GlassButton`, `GlassSwitch`, `GlassSlider`, `GlassSegmentedControl`, `GlassListTile`, `GlassMenuItem`, `GlassActionSheet`, `GlassButtonGroup`, `GlassTextField`, `GlassSearchBar`, `GlassStepper`, `GlassChip`.

### Semantics

- Semantic roles (`isButton`, `isSlider`, `isSelected`, `toggled`, `value`) set on every widget matching Material and Cupertino SDK conventions.
- Destructive and disabled states propagate correctly to the semantic tree.
- **`GlassBadge` — `semanticLabel` and `semanticCount` overrides** — resolves two user-reported limitations:
  - `semanticLabel` (optional `String?`) fully replaces the VoiceOver/TalkBack announcement; enables non-notification domains ("5 downloads", "Online", etc.).
  - `semanticCount` (optional `int?`) overrides only the spoken *number* while leaving the visual cap (`99+`) unchanged; allows "2500 notifications" to be announced when the badge visually shows "99+".
  - Both constructors (`GlassBadge` and `GlassBadge.dot`) support `semanticLabel`; `semanticCount` is only applicable to count badges.
  - Fully backwards-compatible — existing callers with no overrides get identical defaults.
- **`GlassPageControl` — `semanticLabel` param** — the capsule now announces `'Page N of M'` to VoiceOver/TalkBack by default (1-indexed). A `semanticLabel` override lets callers substitute domain-specific wording (e.g. `'Slide 3 of 5'`). Non-interactive controls (no `onPageChanged`) omit the tap hint automatically.
- **`GlassPasswordField` — toggle button semantics** — the show/hide password suffix icon is now wrapped in `Semantics(label: 'Show password' / 'Hide password', button: true)`. Previously the `GestureDetector` was invisible to screen readers; VoiceOver now correctly announces the button and its toggled state.
- **`GlassProgressIndicator` — `semanticLabel` param** — the hardcoded `'Progress'` label is now an overridable default. Callers can pass `semanticLabel: 'Download progress'` (or any domain string) to both `.circular()` and `.linear()` constructors. Backwards-compatible.
- **`GlassPullDownButton` — `semanticLabel` param** — icon-only pull-down buttons previously announced an empty string. A new `semanticLabel` param (e.g. `'More options'`) is used as the `GlassButton.label` in the icon-only code path. Visible-label variants are unaffected.

### Layout & Architecture

- **`GlassInteractionStateMixin`** — internal `State` mixin (modelled on `SingleTickerProviderStateMixin`) providing `isPressed`, `isFocused`, `isHovered` `ValueNotifier`s and their `Listenable.merge` combinations. Replaces ~76 lines of identical boilerplate across `GlassListTile`, `GlassMenuItem`, `_ActionSheetButton`, and `_GlassGroupItemWidget`. No public API change.
- All container-item widgets migrated to `ValueNotifier` + `ListenableBuilder` — only the `AnimatedContainer` highlight layer rebuilds on interaction; the surrounding subtree is stable.

# 0.26.1

## 🐛 Bug Fixes

- **`GlassAdaptiveScope` quality oscillation after `reset()`** — when
  `allowStepUp: false`, a `reset()`-triggered warm-up could silently promote
  quality back up (e.g. `standard → premium`). Warm-up now respects the flag
  and can only confirm or lower the current quality, never raise it. Thanks to
  [@jingluoguo](https://github.com/jingluoguo) for the contribution (#180).

# 0.26.0

## 💥 Breaking Changes

- **`GlassScaffold.floatingActionButton` removed** — iOS does not use Floating
  Action Buttons. `floatingActionButton` is removed entirely; this package is
  pre-v1 and that is the window to get the API right.

  **Migration:**

  ```dart
  // Before
  GlassScaffold(
    floatingActionButton: FloatingActionButton(onPressed: _add, child: Icon(Icons.add)),
    body: ...,
  )

  // After — glass-treated, iOS-idiomatic
  GlassScaffold(
    bodyOverlays: [
      Positioned(
        bottom: 24, right: 24,
        child: GlassButton(
          onTap: _add,
          child: const Icon(CupertinoIcons.add, color: CupertinoColors.white),
        ),
      ),
    ],
    body: ...,
  )
  ```

  `bodyOverlays` is above the body and below the bars. `GlassButton` applies
  the correct liquid glass treatment.

## ♻️ Refactoring — Material Decoupling (`material.dart` 36 → 0)

`GlassScaffold` now uses `CupertinoPageScaffold` internally. `GlassPage` no
longer injects a Material `Theme` shim. All `Colors.*` constants replaced with
`CupertinoColors` or explicit hex literals. **No visual changes.**

`glass_brightness.dart` was completely rewritten to drop its dependency on
`Theme.maybeBrightnessOf`. It now reads `CupertinoTheme.of(context).brightness`,
which natively inherits from the Material `ThemeMode` when used inside a
`MaterialApp` (thanks to Flutter's automatic `MaterialBasedCupertinoThemeData`
injection).

With this final swap, **`liquid_glass_widgets` now has zero imports of
`package:flutter/material.dart` in its `lib/` directory.** It is fully
decoupled and ready for the `cupertino_ui` package split. The example's
Apple replica demos (`apple_music`, `apple_podcasts`, `apple_messages`,
`apple_news`, `apple_lockscreen`) run with zero Material imports as well,
proving the library works purely within a Cupertino-only context.

## 🐛 Bug Fixes

- **`LightweightLiquidGlass` incorrect brightness in `GlassTheme` override
  contexts** — was calling `Theme.of(context).brightness` instead of the
  canonical `GlassTheme.brightnessOf(context)`. Could produce wrong brightness
  when `GlassTheme` set a different mode than the ambient Material theme. Fixed.

# 0.25.1

## 🐛 Bug Fixes

- **`GlassMenu` mispositioned inside nested `Navigator`s** — `OverlayPortal`
  now targets the root `Overlay` (via `OverlayChildLocation.rootOverlay`),
  matching the screen-global coordinates captured by `localToGlobal`. Previously
  the menu drifted by the offset of the nearest nested `Overlay` from the screen
  edge (e.g. a side-rail in a `StatefulShellRoute` layout). Thanks to
  [@sinanhaci](https://github.com/sinanhaci) for the contribution (#179).

# 0.25.0

## ✨ New Features

- **Optional sheet detents** — `GlassModalSheet` (and `.show()`) gained a
  `detents` set (`Set<GlassSheetDetent>`, mirroring UIKit's sheet detents) plus
  a `dismissible` flag, to compose which stops a sheet offers:
  - `{GlassSheetDetent.medium}` → a **half-only glass** sheet that never morphs
    to the opaque full state (its content still scrolls at the half detent).
  - `{GlassSheetDetent.large}` → a **full-only opaque** sheet that opens
    straight to full.
  - `{GlassSheetDetent.medium, GlassSheetDetent.large}` → the default two-stop
    sheet.
  - `{GlassSheetDetent.small, ...}` → adds the maps-style **peek floor**
    underneath, so one mechanism now describes every resting stop.
  - `dismissible: false` → the sheet rubber-bands at its lowest detent instead
    of swiping away (the Apple Pay / Sign in with Apple pattern).

  The set must be non-empty (asserted). Style the small detent with the
  existing `peek*` params (`peekSettings`, `peekWidth`, …), which stay
  top-level: a `Set` whose members carried per-instance payload would need
  equality that ignores that payload, or `detents.contains(small)` breaks and
  two differently-configured smalls could sit in one set.

## ⚠️ Deprecations

- **`GlassModalSheet.enablePeek`** → use `GlassSheetDetent.small` in `detents`.
  Peek is now a detent like medium and large. `enablePeek` is still honoured
  and takes precedence over the set when set explicitly, so existing code keeps
  working unchanged; it will be removed in a future release.
  `GlassSheetMode.persistent` keeps its peek floor with or without the detent —
  a persistent sheet is defined by resting rather than dismissing.

## 🐛 Bug Fixes

- **`GlassModalSheetController` reattachment** — the controller no longer
  detaches when its `GlassModalSheet` is swapped under a stable controller
  (e.g. a `ValueKey` change): the replacement's `initState` runs before the
  outgoing widget's `dispose`, so the detach is now guarded to only clear the
  attachment it still owns. Previously this left the controller inert and the
  sheet un-openable.
- **Half-only content scrolling** — a sheet's inner scroll view now enables at
  the sheet's *topmost* detent rather than hardcoding the `full` state, so a
  half-only sheet scrolls its content correctly.

Thanks to [@jfhair](https://github.com/jfhair) for the contribution (#178).

# 0.24.4

## 🐛 Bug Fixes

- **`GlassBottomBar` collapse trajectory fixed** — when `GlassBottomBarCollapseConfig` with `direction: towardsExtraButton` was set, the collapsed tab pill stopped short of the extra button, leaving a visible gap between the two circles. The pill now travels to the exact horizontal centre of the extra button on both left and right placements, and the extra button correctly overlays the pill at the end of the animation. Thanks to [@jingluoguo](https://github.com/jingluoguo) for the contribution (#176).

## ✨ Improvements

- **`GlassBottomBarCollapseConfig` default `animationDuration` bumped from 220 ms → 280 ms** — the collapse animation carries semantic meaning (the tab pill merges into the action button) and the extra 60 ms is enough for the eye to track the trajectory without feeling sluggish. Override it any time via the config:

  ```dart
  collapseConfig: GlassBottomBarCollapseConfig(
    animationDuration: Duration(milliseconds: 220), // snappier
  ),
  ```

# 0.24.3


## 🐛 Bug Fixes

- **Transparent scaffold during navigation fixed** — `GlassScaffold` was unconditionally setting the inner `Scaffold.backgroundColor` to `Colors.transparent`, even when no `background` widget was provided. This caused the previous route to bleed through the incoming screen during `MaterialPageRoute` slide transitions, making the new page appear transparent. Fixed by only forcing the scaffold transparent when `GlassScaffold` actually has a background widget or `backgroundColor` to render — matching the existing `GlassPage` behaviour. Screens without an explicit background now inherit the theme's opaque `scaffoldBackgroundColor`, producing correct, opaque transitions (issue #177).

# 0.24.2

## 🐛 Bug Fixes

- **Android cold-launch crash fixed** — On Android, Flutter's warm-up frame can produce zero-width or unbounded (`Infinity`) layout constraints before the window fully resolves. `RenderLiquidGlassGeometry._buildGeometryPicture` would attempt to scale and `ceil()` those non-finite bounds, throwing `UnsupportedError: Infinity or NaN toInt`. Fixed by guarding against empty or non-finite bounds and returning a safe empty `Picture` for the one affected frame. A matching guard was added in `LiquidGlassRenderObject.paint` to prevent the same non-finite values propagating into `toImageSync`.
- **Compositing bits race condition fixed (Vulkan/Impeller)** — When `LightweightLiquidGlass` or `LiquidGlassRenderObject` changed settings that affect `alwaysNeedsCompositing`, the compositing bit was not synchronised, causing incorrect layer decisions on the first paint under Vulkan. Fixed by calling `markNeedsCompositingBitsUpdate()` whenever the compositing contract changes.

# 0.24.1


## 🐛 Bug Fixes

- **`GlassButton.custom` border invisible in release builds with `--obfuscate`** — `GlassEffect` and `LightweightLiquidGlass` were using `dynamic` property access and `runtimeType.toString()` heuristics to extract the shape's corner radius for the shader. Both techniques are silently broken by the Dart AOT obfuscator: property names are mangled and class names become single-character tokens. The fallback silently resolved to `0.0`, producing a perfectly square (borderless) shape in release builds. Fixed by adding a typed `effectiveRadius` abstract getter to `LiquidShape` implemented by every concrete shape class — a single virtual dispatch that the compiler can optimise and the obfuscator cannot break.

# 0.24.0


## ⚠️ Breaking Changes

- **`GlassAppBar.preferredSize` constructor parameter removed.** Replace with `toolbarHeight: double` (default `44.0`).

  ```dart
  // Before
  GlassAppBar(preferredSize: Size.fromHeight(52))

  // After
  GlassAppBar(toolbarHeight: 52)
  ```

## 🐛 Bug Fixes

- **`GlassScaffold` dark-mode gradient flash fixed.** When `backgroundColor` is set and the device is in dark mode, the edge-fade gradient around `GlassTabBar` / `GlassBottomBar` could briefly flash dark. The scaffold now always renders with a transparent Material background (preventing theme bleed), and passes the explicit `backgroundColor` to the edge-effect fallback gradient.
- **`GlassBottomBar` default radius inconsistency fixed.** Was `32.0`; now `GlassDefaults.capsuleRadius` — consistent with `GlassTabBar.bottom`.
- **Indicator radius inconsistent across widgets.** All interactive widgets (`GlassSegmentedControl`, `GlassTabBar`, `GlassBottomBar`) now share a unified radius calculation that is guaranteed correct during jelly-bloom expansion.

## ✨ New Features

- **3-tier indicator radius system** — all interactive bar/control widgets now follow iOS 26 defaults out of the box:
  - **Tier 1 (default):** bar and indicator are both a perfect capsule — no configuration needed.
  - **Tier 2:** set `barBorderRadius` to a custom value and the indicator automatically tracks at `barBorderRadius − padding` (concentric nested arcs).
  - **Tier 3:** set `indicatorBorderRadius` explicitly to override everything.
- **`GlassDefaults.capsuleRadius`** — named constant (`9999.0`) for the capsule sentinel:
  ```dart
  GlassBottomBar(barBorderRadius: GlassDefaults.capsuleRadius)
  ```

- **`GlassAppBar.bottom`** — Accepts any `PreferredSizeWidget` (typically a `TabBar`) rendered below the navigation bar title. The scaffold automatically reserves the combined height — no manual sizing needed.

  ```dart
  GlassAppBar(
    title: const Text('Browse'),
    bottom: TabBar(tabs: [...]),
  )
  ```

---

# 0.23.0


## ⚠️ Breaking Changes

- **`AnimatedGlassIndicator.useSuperellipse` removed.** This parameter has been deleted from the constructor. Any call site passing `useSuperellipse: true` or `useSuperellipse: false` will fail to compile.

  **Migration:** simply remove the parameter. The indicator is always a rounded rectangle (capsule) now, which is mathematically correct. Squircle geometry is unstable for dynamic stretching elements.

  ```dart
  // Before (0.22.1)
  AnimatedGlassIndicator(
    useSuperellipse: false,
    ...
  )

  // After (0.23.0) — just remove the parameter
  AnimatedGlassIndicator(
    ...
  )
  ```

---

## ✨ New Features

- **`LiquidGlassSettings.fresnelStrength`** — New parameter (range `0.0`–`1.0`, default `1.0`) that scales the natural Fresnel edge luminosity on the Premium rendering path. At `1.0` the glass behaves as physically lit glass with a rim highlight at grazing angles (existing default). At `0.0` the rim is completely suppressed, producing a pure blur-overlay appearance that matches iOS 26 system UI glass (Messages buttons, notification banners, lock screen controls). Intermediate values interpolate smoothly. Fully backwards compatible — omitting the parameter preserves all existing rendering. Also exposed on `GlassThemeSettings` so it can be set app-wide via `GlassTheme`.

- **`GlassMenuItem.enablePressScale`** — New `bool` parameter (default `true`) that controls the 0.98× scale-down animation on press. Set to `false` on fill-rate-limited devices to eliminate the per-frame GPU cost of animating a `Transform.scale` over the glass layer. Fully backwards compatible.
- **`GlassExtraButtonPlacement`** — Added `GlassExtraButtonPlacement.left` and `right` for non-searchable bottom bars so `GlassTabBarExtraButton` can be placed on either side. Defaults to `right` to preserve existing behavior. Thanks to @jingluoguo (#169).


---

## 🐛 Bug Fixes

- Fixed hard clip at the top of `useOwnLayer: true` buttons during press-scale animation on Impeller.
- **GlassSlider** — Fixed an issue where discrete slider snapping would round the absolute value and shift the snapped range when using a non-zero minimum. Thanks to @huanglizhuo (#168).

---

## ♻️ Refactoring — Pure Geometry & iOS 26 Shape Parity

This release fundamentally solves the long-standing geometry tension between Flutter's path rendering and our GPU shaders. We completely rewrote the squircle math to use pure analytical curves, fixed stretching bugs in tab indicators, and simplified the API.

### 1. Pure Analytic Lamé Squircles
- **Shader Rewrite (`sdf.glsl`)**: We completely removed the old piecewise 45-degree seam approach and the hacky `blend` safety valve. `sdfSquircle` now uses a pure, analytic Lamé curve (`|x|^n + |y|^n = 1`). Squircles now perfectly match Apple's continuous curve geometry with zero flattening on the edges.
- **Graceful Degradation (The Ghost-Glow Fix)**: When a squircle is given a radius that physically cannot fit (e.g. `r = 18` on a `36px` tall button), the shader now dynamically recalculates the exponent `n` based on the clamped available space. As space runs out, `n` smoothly degrades to `2.0`, collapsing into a perfect circle. This mathematically guarantees that the shader's interaction glow always aligns perfectly flush against Flutter's clipping path, eliminating the dark corner gaps.

### 2. Perfect iOS 26 Pills (Capsules)
Apple never uses squircles for pill shapes (like "Edit" buttons or Tab Indicators). They use pure circular-arc capsules. We audited the library to align with this:
- **`GlassChip` & Demo Buttons**: Replaced `LiquidRoundedSuperellipse` with `LiquidRoundedRectangle` for all pill-shaped elements. They now explicitly use `sdfRRectAsym`, ensuring perfect circular ends.
- **`GlassMenu` & `GlassPopover` morph blobs**: Replaced `LiquidOval` with `LiquidRoundedRectangle`. The rounded rect SDF is mathematically stable at all aspect ratios during dynamic morphs.

### 3. AnimatedGlassIndicator API Cleanup
The glass tab indicator previously suffered from a "stretching bug" where it turned squarish during drag expansion because its finite `borderRadius` was outgrown by its expanding height.
- **Removed `useSuperellipse`** *(see Breaking Changes above)*: This parameter was mathematically incorrect for dynamic stretching indicators.
- **Optional `borderRadius` (Default `9999.0`)**: `borderRadius` is no longer required. It defaults to `9999.0`, which offloads the math entirely to the shader's `min(r, shortest)` clamp. This guarantees a perfect capsule at *any* drag size.
- **Segmented Controls**: `GlassSegmentedControl` explicitly passes `borderRadius: containerRadius - 3`, ensuring it retains its correct inset rounded-rectangle geometry rather than defaulting to a capsule.


## 📚 Documentation

- **`shape_debug_demo.dart`** — corrected the Standard-mode description banner from the inaccurate `"_SquircleClipper + lightweight shader (CPU L4/L2 path)"` to the accurate `"ShapeBorderClipper + lightweight blur shader (shape-blind)"`. There is no `_SquircleClipper` class; the lightweight shader is shape-type-blind by design.


---

# 0.22.1


## 🐛 Bug Fixes

- **Tab Bar Semantics** — Fixed multiple accessibility issues in `GlassTabBar` and `GlassBottomBar`:
  - `GlassTab.semanticLabel` is now properly propagated, allowing icon-only tabs to be correctly announced instead of defaulting to `'Tab'`.
  - Fixed an issue where tab labels were announced twice by wrapping the internal `Text` widget in `ExcludeSemantics`.
  - Eliminated duplicate semantic nodes for the active tab by hiding the visual clipping indicator from the accessibility tree, ensuring exactly one node per tab.
  Thanks to @simiwe (#159).

## ♻️ Refactoring

- **Internal Tab Models** — Deprecated `GlassBottomBarTab` is no longer used by the internal layout engines. They now natively accept `GlassTab`, removing the need for mapping closures and `SizedBox.shrink()` sentinels.

---

# 0.22.0

## ✨ New Features

- **`ProgressiveBlur`** — a graduated backdrop blur that is strongest at one
  edge and dissolves to sharp at the opposite edge (the iOS 26 / Signal header
  look). Self-contained — no `LiquidGlassLayer` ancestor required.

  ```dart
  Positioned(
    top: 0, left: 0, right: 0, height: 96,
    child: ProgressiveBlur(maxSigma: 20),
  )
  ```

  - **`maxSigma`** — blur sigma at the strong edge (`0` ⇒ passthrough).
  - **`direction`** — which edge is strongest
    (`topToBottom` / `bottomToTop` / `leftToRight` / `rightToLeft`).
  - **`falloff`** — gradient gamma (default `1.2`).

  Pre-warmed by `LiquidGlassWidgets.initialize()` at no extra startup cost;
  `ProgressiveBlur.preload()` is available for standalone use. Degrades to a
  uniform `BackdropFilter` on Skia / web. See
  [`docs/PROGRESSIVE_BLUR.md`](docs/PROGRESSIVE_BLUR.md).
  Thanks to @Ahmadre (#162).

## ⚡ Performance

- **`GlassPopover` blur ramp** — the backdrop blur now eases in over the opening
  morph instead of rendering at full strength from frame one. Raster avg halved
  (10.1 ms → 5.8 ms), worst-case halved, missed-budget frames 15 → 6 on the
  reference device. See [`docs/POPOVER_BLUR_RAMP.md`](docs/POPOVER_BLUR_RAMP.md).

  Two new backwards-compatible params:
  - **`blurRampDuration`** (default `Duration(milliseconds: 260)`) — set to
    `Duration.zero` to restore the previous always-full-blur behaviour.
  - **`blurRampCurve`** (default `Curves.easeOut`).

  Automatically disabled when "reduce motion" is active. Thanks to @Ahmadre (#161).

## 🐛 Bug Fixes

- **`GlassPopover` drifted off its trigger in nested overlays** — the morph
  portal now targets `OverlayChildLocation.rootOverlay` to match the
  root-relative coordinates it is placed at. Top-level usage is unaffected.
  Thanks to @Ahmadre (#163).

- **Intrinsic-height `GlassPopover` overflowed on live content growth** — the
  popover now re-measures via `SizeChangedLayoutNotifier` when content grows
  while open, instead of clamping to the height frozen at open time.
  Fixed-`popoverHeight` popovers are unchanged. Thanks to @Ahmadre (#163).
---

# 0.21.6

## 🐛 Bug Fixes

- **`GlassTabBar.bottom` / `GlassBottomBar` distorted tap hit regions with >2 tabs** (#157) — Tapping a tab incorrectly routed through `DraggableIndicatorPhysics.getAlignmentFromGlobalPosition`, which applies an indicator-center remap (`±½ tab-width` padding) designed for continuous drag tracking. For discrete taps this shifted the hit boundaries from the correct `25/50/75 %` to `~31.25/50/68.75 %` on a 4-tab bar, making the right ~25 % of tab 2 select tab 3 instead. A new `tabIndexFromGlobalPosition` helper bypasses the drag remap and computes the tab index directly from the raw position fraction. The same incorrect remap was present in the `recoverIfGestureStuck` path (PlatformView gesture recovery) and is fixed there too. The drag path (`onHorizontalDragUpdate` / `onHorizontalDragStart`) is unaffected. Thanks to @bayraktarmdkaraca for the precise root-cause analysis!

---

# 0.21.5

## 🐛 Bug Fixes

- **`GlassTabBar` loses shadow when OS is Dark but app is `ThemeMode.light`** — fixed an issue where glass components incorrectly resolved to `Brightness.dark` when the device OS was in Dark Mode but the `MaterialApp` was explicitly set to `ThemeMode.light`. The brightness cascade in `resolveGlassBrightness` was checking the `CupertinoTheme` before the Material `ThemeMode`; inside a `MaterialApp` the Cupertino theme is implicitly derived from the OS, causing it to return the wrong brightness. The cascade now correctly prioritises `ThemeMode` in `MaterialApp` contexts. Thanks to @minhtritc97 for the detailed report!

---

# 0.21.4

## ✨ New Features

- **Vertical `GlassSegmentedControl`** — fixed controls now accept `direction: Axis.vertical` and an optional `segmentExtent`. Layout, fractional indicator positioning, jelly expansion, drag velocity, snapping, and gesture recognition all follow the vertical axis. The horizontal default and scrollable constructor remain unchanged. Thanks to @F1orian!

## 🐛 Bug Fixes

- **Impeller shadow corruption fixed** — `shadowElevation` on `LiquidGlass` and `GlassButton` rendered as solid black circles on Windows, Web, and certain Android emulators due to two known Flutter engine bugs (`saveLayer` texture corruption on Vulkan and `Path.combine` clipping failures). The package now selectively bypasses the GPU shadow cutout on affected platforms and uses a safe `evenOdd` winding rule for the fallback, producing perfect shadows without engine issues.

## 🧪 Example

- Added an icon-only vertical segmented control to the Interactive page for tap, drag, indicator, and accessibility testing on a physical device.

---

# 0.21.3

## 🐛 Bug Fixes

- **SVG and custom icons restored** — `SizedBox`-wrapped icons (e.g. `SvgPicture`) were silently stripped from the render tree since `0.20.0`. The `SizedBox.shrink()` sentinel detection now checks `width`, `height`, and `child` fields so a caller-supplied `SizedBox` wrapping a real icon is always rendered correctly.
- **Searchable bar pill stays active while dragging** — the glass indicator on `GlassTabBar.searchable` collapsed back to its resting state when the finger passed over the currently selected tab mid-drag. The thickness spring now includes the `tabIsDragging` guard, matching the behaviour already present in `GlassTabBar.bottom`.
- **`JellyClipper` Impeller radius guard** — the clip radius is now clamped to strictly less than half the indicator's shortest side, preventing a malformed `RRect` path that caused content to vanish under Impeller's Metal renderer in certain animation frames.

## 🧹 Example

- **Indicator Parity demo calibrated** — default refraction set to `1.15` (`GlassDefaults.refractiveIndex`) to match all Apple demos; both `GlassTabBar.inline` variants now wire live tuner sliders for expansion and pinch strength.

---

# 0.21.2


## 🐛 Bug Fixes

- **Extra button stretch disabled over platform views** — `GlassTabBarExtraButton` now correctly disables its stretch effect when `platformViewBackdrop: true`, matching the behavior of `GlassTabBar.bottom` and fixing the jittery spring animation.
- **`GlassMenu` item scroll wiggle fixed** — menu items with wrapped text (e.g. `maxLines: 2`) could drift sub-pixel vertically during slide-to-select dragging because `ClampingScrollPhysics` allowed fractional scroll offsets even when no overflow was intended. Non-scrollable menus now use `NeverScrollableScrollPhysics`, locking the content completely in place during drag.
- **`GlassPopover` first-frame height fixed** — the popover was briefly rendered at full-screen height before its content height was known, producing a visible flash and forcing users to wrap content in a `SingleChildScrollView` as a workaround. An invisible `Offstage` measurement pass now runs on Frame 1, letting Flutter's layout engine calculate the exact intrinsic content height before the morph animation starts. The animation launches on Frame 2 with perfect geometry — no mid-flight height correction, no flash, no heuristics.

## ⚡ Performance

- **Removed unnecessary compositing layer in `GlassBottomBar`** — the `RepaintBoundary` wrapping the icon layer in `_buildHighQualityMode` is now only mounted when `platformViewBackdrop: true`, where it is required for the Platform View capture path (bug #99). In the common case (`platformViewBackdrop: false`) the boundary was creating a GPU offscreen texture every frame with no caching benefit, since the `JellyClipper` changes on every animation frame.
- **`GlassPopover` idle trigger optimised** — when the popover is fully closed, the trigger widget now skips unnecessary `Transform`, `Opacity`, and `IgnorePointer` compositing layers. This removes redundant GPU work in the common idle state.

## 🧹 Code Quality

- **Null-safe trigger child access** — replaced a `child!` force-unwrap in `GlassPopoverInternal` with a null-safe `child ?? const SizedBox.shrink()` fallback, preventing a hard crash if `child` is ever omitted in a future refactor.

## 🧪 Example

- **Refraction slider added to Indicator Parity demo tuner** — a "Refraction (n)" slider (range 1.0–2.0, default 1.59 matching `GlassTabBar.bottom`'s internal default) for tuning the `refractiveIndex` on the Premium (Impeller) glass indicator. Standard indicators do not perform background capture so the parameter has no visual effect there.

---

# 0.21.1

## 🐛 Bug Fixes — Standard indicator parity

- **Two-pills misalignment fixed** — at `GlassQuality.standard`, the background rim and glass lens now share the same shape geometry (`ShapeDecoration`) and ride the same jelly `Transform`, eliminating the visible separation mid-morph. Regression reported against `GlassTabBar.inline` / segmented controls.
- **Indicator collapse on drag fixed** — the glass indicator no longer morphs back to the resting pill when dragging over the selected tab. The thickness gate now includes `tabIsDragging` so the indicator stays fully active for the entire gesture duration.
- **Standard rim thickness normalised** — the indicator rim on `GlassQuality.standard` is now proportionally mapped from `indicatorSettings.thickness` (same value as Premium) rather than scaling from the raw glass-depth value, which produced a ~2.8 px border. The result is a fine hairline that gracefully matches the Premium look on Standard-quality devices.

---

# 0.21.0

## ✨ New Features

- **`GlassModalSheet` drag progress** — controller now exposes a `progress` getter and `progressListenable` reporting the live 0–1 drag position between half↔full snap points, so hosts can drive coordinated UI in real time. ([#148](https://github.com/sdegenaar/liquid_glass_widgets/pull/148), [@jfhair](https://github.com/jfhair))
- **`GlassTabBar.inline` spring control** — the `.inline` factory now accepts `springDescription`, matching the other factory constructors. Previously inline tab bars were locked to the shared default spring. ([#149](https://github.com/sdegenaar/liquid_glass_widgets/pull/149), [@jfhair](https://github.com/jfhair))
- **`LiquidGlassSettings.ambientRim`** — tunable full-perimeter rim on the moving indicator pill. Defaults match Apple Music's segmented control (brighter in light mode, off in dark). ([#150](https://github.com/sdegenaar/liquid_glass_widgets/pull/150), [@jfhair](https://github.com/jfhair))
- **`AnimatedGlassIndicator` shadow** — `shadowElevation`/`shadow` in `indicatorSettings` now correctly paints a drop shadow on the glass jelly. Previously these values were silently ignored. ([#151](https://github.com/sdegenaar/liquid_glass_widgets/pull/151), [@jfhair](https://github.com/jfhair))

## 🐛 Bug Fixes — PlatformView gesture stability

- **Tab bar freeze fixed:** Intermittent freeze where the tab indicator stopped
  responding after interacting over an iOS `PlatformView` (e.g. a map or WebView).
  The iOS gesture arena can silently drop terminal callbacks, leaving the recognizer
  wedged. Fixed with proactive cleanup on `PointerDown`, post-frame recovery, and
  a gesture ID guard to prevent rapid-tap state corruption.
- **Hybrid gesture mode on `platformViewBackdrop: true`:** When the tab bar
  floats over a `PlatformView`, the visual indicator now animates to its new
  position instantly on touch-down (matching native iOS responsiveness), while the
  actual tab content swap is deferred safely to touch-up. This prevents the iOS
  UIKit view system from dropping the touch stream mid-gesture due to a mid-frame
  unmount of the `PlatformView`. No impact on any screen where
  `platformViewBackdrop` is `false` — those continue to swap instantly on down.
- **Stretch disabled on `platformViewBackdrop: true`:** Flutter's `BackdropFilter`
  must re-acquire the native pixel buffer every time its bounding box changes.
  Stretch animations resize the glass container, causing a one-frame flicker over
  a `PlatformView`. Stretch is now skipped on all bar elements when
  `platformViewBackdrop` is set; press-scale (`interactionScale`) is unaffected
  because it is a GPU-level transform that leaves the backdrop bounds stable.
  No impact on any other screen or platform.

---

# 0.20.1

## 🐛 Bug Fix — `GlassButton.custom` layout expansion

**Fixes:** `GlassButton.custom` unexpectedly expanding to fill bounded parent constraints (e.g., inside `AppBar` actions) ([#146](https://github.com/sdegenaar/liquid_glass_widgets/issues/146)).

- `GlassButton.custom` `height` now correctly defaults to `null` (matching documented behavior).
- The button now properly shrink-wraps to its content when explicit width/height are not provided.
- **Migration:** No breaking changes. If you were relying on the undocumented `56px` default height, explicitly set `height: 56`.

---

# 0.20.0

## 💥 Breaking — `GlassListTile` divider refactor

`GlassListTile` no longer draws its own divider. The `isLast`, `showDivider`,
and `dividerIndent` parameters have been removed.

**Rationale:** A list tile should be a clean, position-agnostic item. Divider
rendering is a layout concern that belongs to the parent container.

### Migration

**Inside `GlassGroupedSection` — no changes needed.**
`GlassGroupedSection` now automatically injects `GlassDivider`s between tiles
with smart leading-indent detection (56px if the preceding tile has a leading
widget, 16px otherwise). The last tile never gets a trailing divider.

**Standalone column layouts — compose `GlassDivider` explicitly:**

```dart
// Before:
Column(children: [
  GlassListTile(title: Text('A')),                    // showDivider: true (default)
  GlassListTile(title: Text('B'), isLast: true),      // suppresses divider
])

// After (standard Flutter composition pattern):
Column(children: [
  GlassListTile(title: Text('A')),
  GlassDivider(indent: 16),
  GlassListTile(title: Text('B')),
])
```

This aligns with Flutter's own `ListTile` + `Divider` composition model.

---

## ✨ New — `GlassTabBar.inline`

A compact glass tab bar for pinned content-filter sections — sits fixed between
a page header and its scrollable list, not inside the scroll view itself.

> **Performance note:** `GlassQuality.premium` re-runs the full shader pipeline
> whenever the backdrop changes. Placing the bar inside a scroll view invalidates
> the backdrop on every scroll frame. Pin it outside the scrollable region or
> drop to `GlassQuality.standard` if embedding inside a list.

```dart
GlassTabBar.inline(
  tabs: const [
    GlassTab(label: 'For You'),
    GlassTab(label: 'Following'),
    GlassTab(label: 'New'),
  ],
  selectedIndex: _selectedIndex,
  onTabSelected: (i) => setState(() => _selectedIndex = i),
)
```

**Key differences from `GlassTabBar.bottom`:**
- Zero padding — sits flush in its parent container.
- Compact height (40px) with a full stadium shape (`barBorderRadius: 100`, clamped to `height/2`).
- Indicator pill automatically matches the track corner radius (`indicatorBorderRadius` defaults to `barBorderRadius`).
- Indicator expansion `h:12, v:10` — same horizontal weight as `GlassSegmentedControl` and `GlassTabBar.bottom`, +2px vertical to compensate for the shorter bar height giving the glass pill proportional visual mass.
- `indicatorPinchStrength: 0.4` — aligned with all other pill controls.
- Magnification disabled (`1.0x`) — text labels never grow on selection.
- Text-only tabs render with correct vertical centering (no icon slot consuming space).
- `extraButton` not supported (structural navigation feature only).

All standard physics parameters (`indicatorPinchStrength`, `indicatorExpansion`,
`indicatorSettings`, `quality`) are still fully configurable.

See the updated **Indicator Parity** demo (`indicator_parity_demo.dart`) where
`GlassTabBar.inline` now appears alongside the other five pill widgets — including
a text-only variant (40px) and an icon + text variant (52px) — with live tuning sliders.

---

# 0.19.7


## 🐛 Bug Fixes

- **`GlassTabBar.bottom` / `GlassBottomBar`** — fixes RTL support (#143, @naeemeltaief).
  The pill and tap/drag hit-testing now correctly align with the visually reversed tab order
  under RTL. The bottom layout normalises the tab data, selected index and callback for RTL,
  and pins only the two inner tab `Row`s to LTR — leaving `indicatorExpansion`, `tabPadding`
  and all text to resolve against the ambient direction as expected. Consumers no longer
  need to force `Directionality.ltr` and reverse tabs by hand. +2 tests.

- **`AnimatedGlassIndicator`** — restores the resting selection pill inside a `GlassContainer`
  (#144, @jfhair). The background pill was permanently hidden whenever an ancestor set
  `avoidsRefraction`, which is a steady-state layout flag on `GlassContainer` — not a
  transient capture signal. The guard was incorrect and is removed. The pill now renders
  correctly in all contexts. No API change. +1 test.


# 0.19.6

## ✨ New — `GlassLargeTitle` + `GlassLargeTitleController`

First-class iOS 26 large-title + search-bar collapse. Replaces manual
`ScrollController` + `setState` wiring with a single controller and two
widgets.

### Two-phase collapse

- **Phase 1** — large title fades out (`Curves.easeIn`, rubber-band overscroll stretch).
- **Phase 2** — optional inline search bar collapses under the nav bar immediately after.

### New API

- `GlassLargeTitle` — sliver widget. Drop it as the first sliver in any `CustomScrollView`.
  - `searchBar: Widget?` — Phase 2 collapse (e.g. `GlassSearchBar`).
  - `trailing`, `fontSize`, `fontWeight`, `letterSpacing`, `padding`, `searchBarPadding`, `color`.
- `GlassLargeTitleController` — owns the `ScrollController`, exposes `collapseProgress` and `searchBarCollapseProgress`. Self-calibrates to Dynamic Type via `reportMeasuredHeight` / `reportSearchBarHeight`.
- `GlassAppBar.largeTitleController` — new optional param. Bar title cross-fades in as the large title collapses. Non-breaking.

```dart
final _ctrl = GlassLargeTitleController(); // dispose in State.dispose()

// Phase 1 only
GlassLargeTitle(text: 'Chats', controller: _ctrl)

// Phase 1 + 2
GlassLargeTitle(
  text: 'Messages',
  controller: _ctrl,
  searchBar: GlassSearchBar(placeholder: 'Search', onChanged: (_) {}),
)
```

### Demo

- Pattern 2 updated to new API. Pattern 7 (Large Title + Search Bar) added.
- Apple Messages demo migrated from manual `AnimatedOpacity` to `GlassLargeTitle`.

+10 tests. **2,291 total, all passing.**

## ⚡ Performance — `GlassBottomBar` Indicator (Impeller)

- **`GlassBottomBar` indicator** — eliminates the live `BackdropFilterLayer` on Impeller
  premium, replacing it with a deterministic `toImageSync` capture path. Fixes the
  opaque-white indicator rendering on physical iOS (#99) and improves drag performance
  by removing a redundant compositor pass.

## 🔧 `GlassGroupedSection` — Header/Footer styling

- Header and footer text is now styled automatically via `DefaultTextStyle`
  (`CupertinoColors.secondaryLabel`, 13pt) — callers no longer need to style them manually.
- Margin is now applied via `Padding` wrapping the full section rather than on the inner
  `GlassCard`, fixing card-edge clipping when a header or footer is present.
- Import changed to `cupertino.dart` for correct `CupertinoColors` resolution.

## 📝 Dart doc improvements

- `GlassContainer`, `GlassCard`, `GlassGroupedSection`, `GlassSegmentedControl` — added
  **⚠️ Anti-Pattern** sections documenting the glass-in-glass restriction: placing interactive
  glass controls inside a container degrades refraction and clips jelly animations.

# 0.19.5

- **`LiquidGlassSettings`** — adds `platformViewFallbackColor` (#138, @jfhair). Splits
  `backerColor`'s dual role: `backerColor` remains the aesthetic backer pad; the new
  field controls the `uBackgroundFallback` shader uniform (PlatformView fill).
  Fully backwards-compatible — defaults to `null`, falling back to `backerColor`.

- **`GlassModalSheet`** — removes the interior `BoxShadow` that bled through the glass
  as a vignette (#137, @jfhair). Elevation now flows via `LiquidGlassSettings.shadowElevation`.
  Pass `shadowElevation: 0` to disable entirely.

# 0.19.4

## ✨ Enhancements — `GlassButtonGroupItem.menu` & `GlassPullDownButton` improvements

### `GlassButtonGroupItem.menu` — whole-pill liquid glass morph


Adds a new `GlassButtonGroupItem.menu` named constructor that turns any item in a
`GlassButtonGroup.icons` pill into a pull-down menu trigger.

When tapped, the **entire pill morphs** into the menu — the full `GlassButton.custom`
shell becomes the `GlassMenu` trigger, so the whole group shape liquefies and expands
into the menu card. This matches the iOS 26 `GlassEffectContainer` morph pattern where
the source shape, not just the tapped slot, participates in the transition.

```dart
GlassButtonGroup.icons(
  items: [
    GlassButtonGroupItem(icon: Icon(CupertinoIcons.chart_bar), onTap: () {}),
    GlassButtonGroupItem(icon: Icon(CupertinoIcons.clock),     onTap: () {}),
    GlassButtonGroupItem.menu(
      icon: Icon(CupertinoIcons.ellipsis),
      menuItems: [
        GlassMenuItem(title: 'Add to Watchlist', icon: Icon(CupertinoIcons.star), onTap: () {}),
        GlassMenuItem(title: 'Share',            icon: Icon(CupertinoIcons.share), onTap: () {}),
        GlassMenuDivider(),
        GlassMenuItem(title: 'Remove', icon: Icon(CupertinoIcons.trash), isDestructive: true, onTap: () {}),
      ],
      menuAlignment: GlassMenuAlignment.topRight, // optional
      menuWidth: 200,                              // optional, default 200
    ),
  ],
)
```

**Notes:**
- Only the first `GlassButtonGroupItem.menu` in the list is used as the menu trigger; any subsequent menu items are treated as plain tap items.
- Accepts both `GlassMenuItem` and `GlassMenuDivider`, matching `GlassMenu.items` directly.
- Non-menu siblings in the group continue to fire their own `onTap` independently.
- Works with both `Axis.horizontal` and `Axis.vertical` groups.

**Alternatively — group + standalone `GlassPullDownButton`**

For cases where the menu trigger is a separate, visually distinct action from the
group (e.g. a trailing overflow button next to a row of chart controls), compose a
`GlassButtonGroup` alongside a standalone `GlassPullDownButton`. The pull-down
button morphs independently and fully, with no pill residue:

```dart
Row(
  children: [
    GlassButtonGroup.icons(
      items: [
        GlassButtonGroupItem(icon: Icon(CupertinoIcons.chart_bar), onTap: () {}),
        GlassButtonGroupItem(icon: Icon(CupertinoIcons.clock),     onTap: () {}),
      ],
    ),
    SizedBox(width: 8),
    GlassPullDownButton(
      icon: Icon(CupertinoIcons.ellipsis),
      menuAlignment: GlassMenuAlignment.topRight,
      items: [
        GlassMenuItem(title: 'Add to Watchlist', icon: Icon(CupertinoIcons.star), onTap: () {}),
        GlassMenuItem(title: 'Share',            icon: Icon(CupertinoIcons.share), onTap: () {}),
        GlassMenuDivider(),
        GlassMenuItem(title: 'Remove', icon: Icon(CupertinoIcons.trash), isDestructive: true, onTap: () {}),
      ],
    ),
  ],
)
```

| | `.menu` item (shared pill) | group + standalone |
|---|---|---|
| All actions in one pill | ✅ | ❌ |
| Entire pill morphs | ✅ | — |
| Menu button morphs independently | — | ✅ |
| Best for | Overflow within a related set | Separate trailing action |

### `GlassPullDownButton` improvements

- **`items` widened to `List<Widget>`** — now accepts `GlassMenuDivider` alongside `GlassMenuItem`. Source-compatible: existing `List<GlassMenuItem>` code compiles and behaves identically. The `onSelected` callback is applied only to `GlassMenuItem` instances.
- **`menuAlignment` exposed** — new `GlassMenuAlignment?` parameter forwarded to the underlying `GlassMenu`. Defaults to `null` (auto-detect from screen position) — fully backward-compatible.

## 🐛 Bug Fixes — PlatformView Frost Halo & GlassButton Dispose-Race ([#134](https://github.com/sdegenaar/liquid_glass_widgets/pull/134), [#135](https://github.com/sdegenaar/liquid_glass_widgets/pull/135))

Both fixes contributed by [@jfhair](https://github.com/jfhair).

### `LiquidOval` rectangular blur halo over a PlatformView ([#134](https://github.com/sdegenaar/liquid_glass_widgets/pull/134))

**Problem:** Any glass surface with a `LiquidOval` shape (the default for `GlassButton`,
`GlassIconButton`, the collapsed search/dismiss pill, and `GlassBottomBarExtraButton`)
rendered a rectangular blur halo when `platformViewBackdrop: true` routed it through the
`_FrostedFallback` `BackdropFilter` path. The halo matched the widget's bounding box rather
than its circular outline.

**Root cause:** Flutter engine PR #177551 (3.41+) forwards `ClipRRect` clip data to the iOS
PlatformView mutator stack, allowing a descendant `BackdropFilter` to be bounded correctly
over a hybrid-composed view. The same forwarding does NOT apply to `ClipPath` — and
`LiquidOval` (unlike `LiquidRoundedSuperellipse`) was routing through `ClipPath`, leaving
the `BackdropFilter` unclipped.

**Fix:** `_ShapeClip` now accepts a `platformViewBackdrop` flag. When set, any shape whose
border radius can be expressed as a `BorderRadius` (including `LiquidOval` →
`circular(9999)`, `LiquidRoundedRectangle`, and their vertical variants) is routed through
`ClipRRect` instead of `ClipPath`. The clip is then forwarded to the PlatformView mutator
stack and the frost is bounded cleanly to the shape. Off a PlatformView the original
`ClipPath` is used (true ellipse). The flag is threaded through all `_ShapeClip` call sites
in `_FrostedFallback` — the blur body, the content clip, and the specular rim — as well as
the backer dimming pad in `AdaptiveGlass._wrapWithBacker`.

Completes the partial fix shipped in 0.19.3 and fully resolves the rectangular-blur
regression first reported in [#79](https://github.com/sdegenaar/liquid_glass_widgets/issues/79).

### `GlassButton` crash when disposed mid-press ([#135](https://github.com/sdegenaar/liquid_glass_widgets/pull/135))

**Problem:** Tapping a `GlassButton` that is removed by the very tap that activates it
(e.g. a collapsed bar restore button that expands the bar and disposes itself) could throw:

```
AnimationController.reverse() called after AnimationController.dispose()
(assert _ticker != null)
```

A queued `pointerUp` or `pointerCancel` was still dispatched to the now-disposed
`RenderPointerListener`, and the press handler called `_saturationController.reverse()`
after `dispose()`.

**Fix:** All six tap/pointer press handlers in `_GlassButtonState` now guard on `!mounted`
before touching `_saturationController`. A disposed `State` always has `mounted == false`,
so the handler bails safely without touching the controller.

Surfaces frequently in apps that morph or collapse a bar on the tap of a glass control
over a PlatformView (the pattern introduced in #127/#79).

# 0.19.3

## 🐛 Bug Fixes — Search Pill Colors & PlatformView Compositing

- Fixed an issue where the `SearchPill` icon colors (search, mic) would incorrectly render as black when using dark glass (`glassColor: Colors.black26`) over an iOS PlatformView. The root cause was that the color resolution used the OS system brightness (light) instead of the glass brightness (dark), causing `CupertinoDynamicColor.label` to always resolve to its light-mode black variant. The widget now resolves colors through `GlassTheme.brightnessOf()` — the package's single brightness authority — and explicitly passes the resolved color via `IconThemeData` to guarantee white glyphs on dark glass regardless of system brightness.
- Mitigated a Flutter engine clipping bug over PlatformViews by ensuring `LiquidRoundedSuperellipse` and `LiquidOval` correctly clip their bounds using an outer `ClipRRect` when rendering over an iOS PlatformView, preventing blur bleed outside the circular button shape.
- Updated the `google_maps_demo` to correctly demonstrate how to configure `selectedIconColor`, `unselectedIconColor`, and `searchIconColor` for dark glass bottom bars to ensure all tab elements remain visible over the map layer.

# 0.19.2

## 🐛 Bug Fixes — PlatformView Gesture & Rendering

This release resolves a pair of related issues that caused the glass bottom bar
to freeze and render incorrectly when floating over an iOS PlatformView (e.g. a
Mapbox map). All three fixes were contributed by [@jfhair](https://github.com/jfhair)
via detailed PRs that included root-cause analysis, regression tests, and working
reproductions. Many thanks for the exceptional quality of this contribution.

### Gesture freeze over an iOS PlatformView ([#127](https://github.com/sdegenaar/liquid_glass_widgets/pull/127))

**Problem:** `GlassTabBar.searchable` (and `GlassBottomBar`) would freeze when
the draggable indicator was dragged or tapped while the bar floated over an iOS
PlatformView. The freeze was permanent until the widget was rebuilt or disposed.

**Root cause:** iOS reconstructs the platform-view clip chain whenever a clip
layer is added or removed mid-gesture. The engine responds by cancelling the
active touch, which left the bar's `GestureDetector` recognizer wedged — it
never received a terminal callback (`onDragEnd` / `onDragCancel`) and stopped
responding to input. The most frequent trigger was the indicator's `innerBlur`
frost layer unmounting at drag-start (a clip-add/remove cycle).

**Fix — two-part:**
- **Primary fix (PR #127):** The indicator's frost `ClipRRect + BackdropFilter`
  layer now stays _mounted_ across the full drag lifecycle by tracking a
  persistent `bool _frostMounted` flag in `AnimatedGlassIndicator`. This
  eliminates the clip-add/remove cycle that was triggering the iOS clip-chain
  reconstruction.
- **Backstop fix (PR #127):** `TabBarDragGestureMixin` gains a
  `gestureEpoch` counter, a `_gestureActive` liveness flag, and a raw
  `Listener` on the `GestureDetector` subtree. If the raw pointer-up or
  pointer-cancel arrives while `_gestureActive` is still `true` (i.e. the
  terminal callback was silently dropped by the platform-view gesture arena),
  `recoverIfGestureStuck` is called: it selects a fallback tab, bumps
  `gestureEpoch` (forcing the `GestureDetector` to be torn down and
  recreated via `ValueKey`), and clears the stuck state. Covers both the
  tap-without-cancel and drag-start-without-end freeze signatures.

### PlatformView backdrop routing ([#128](https://github.com/sdegenaar/liquid_glass_widgets/pull/128))

**Problem:** Setting `platformViewBackdrop: true` on a bar had no visible effect
for the glass indicator or bar body — the premium/standard Impeller shader paths
read a captured backdrop that excludes hybrid-composed PlatformViews, so the
glass rendered inert (opaque black or clear) over a map.

**Fix:** `AdaptiveGlass` now routes any surface with `platformViewBackdrop: true`
to the frosted fallback (`_FrostedFallback`) regardless of the requested quality
tier. The frosted fallback uses a live `BackdropFilter`, which correctly blurs
hybrid-composed PlatformViews. `_FrostedFallback` also overrides the
`isInteractive` blur-omission that would otherwise skip the blur for interactive
indicator surfaces — over a PlatformView the live blur must always run.

### Premium glass goes black over a PlatformView — `backerColor` fallback ([#129](https://github.com/sdegenaar/liquid_glass_widgets/pull/129))

**Problem:** At `GlassQuality.premium` over a PlatformView, the Impeller shader
sampled a captured backdrop that contained only transparent black where the
PlatformView sat. With no real background pixels to refract, the glass lens
rendered black.

**Fix:** A new `uBackgroundFallback` (vec4) uniform was added to
`liquid_glass_final_render.frag`. The shader composites the fallback colour
over the captured backdrop using a standard `over` blend weighted by the
backdrop's own alpha — where the backdrop is real (alpha ≈ 1) it is left
untouched; where it is transparent black (alpha ≈ 0, i.e. over a PlatformView)
the fallback fills in. `backerColor` from `LiquidGlassSettings` is bound to
this uniform at render time, giving the premium lens a solid colour to refract
instead of transparent black.

### Extra button `platformViewBackdrop` threading (follow-up, this release)

`GlassTabBarExtraButton` previously ignored the bar's `platformViewBackdrop`
flag — the internal `BottomBarExtraBtn` widget was not forwarding it to the
underlying `GlassButton`, so the extra button continued to use the inert shader
path even when the rest of the bar correctly used the frosted fallback.
`platformViewBackdrop` is now threaded through `BottomBarExtraBtn` and both
call sites (`TabBarBottomLayout`, `TabBarSearchableLayout`) to `GlassButton`.

---

# 0.19.1


## 🛡️ Stability Improvements

Addresses production crash and ANR reports seen with v0.19.0 on Flutter 3.44.2
(tracked in flutter/flutter#187140). These are exposure-window mitigations — the
root cause is a Flutter engine issue and requires an engine-level fix.

### Changes

**`GlassEffect` & `LightweightLiquidGlass` — lifecycle-aware Ticker suspension**
Both state classes now implement `WidgetsBindingObserver` and halt background-capture
Tickers during `AppLifecycleState.inactive`, `paused`, and `hidden`. Captures restart
one frame after `resumed`. This reduces GPU texture activity during surface transitions
(rotation, split-screen, keyboard resize) which is the window where engine-level
crashes and ANRs are most likely to occur.

**`GlassEffect` & `LightweightLiquidGlass` — `_isDisposed` guard**
A `_isDisposed` flag prevents Ticker callbacks and async `.then()` continuations
from accessing GPU resources after `dispose()` has completed, guarding against
post-frame-callback / dispose races during rapid navigation.

**`LiquidGlassWidgets.initialize()` — faster startup**
The Impeller pipeline warm-up is no longer `await`ed inside `initialize()`. It now
runs after the first frame via `addPostFrameCallback`, removing a `~16ms` delay from
the startup critical path. Shader disk-loads are still awaited as before.

**Debug log cleanup**
Removed stale `debugPrint` success messages from `GlassEffect` and `LightweightLiquidGlass`
shader pre-warm paths (`✓ Shader precached`, `✓ Created unique shader instance`). These
fired on every debug startup for every app using the package. Failures still surface via
the existing `[LightweightGlass] Pre-warm failed:` error log. The `[LiquidGlass]`
startup bracket (`Initializing...` / `Initialization complete.`) and the
`PerformanceMonitor started` log are retained as actionable developer information.


# 0.19.0


## 💥 Breaking: Pre-v1.0 Public API Cleanup

A pre-release naming audit to establish consistent, idiomatic conventions before v1.0 locks the API.

### Renames

| Old | New | Reason |
|---|---|---|
| `GlassBottomBarExtraButton` | `GlassTabBarExtraButton` | Tracks parent rename `GlassBottomBar` → `GlassTabBar` |
| `GlassGroupItem` | `GlassButtonGroupItem` | Mirrors Flutter's `DropdownMenuItem` pattern |
| `SheetState` | `GlassSheetState` | Prevents collision with Material 3 sheet infrastructure |
| `SheetMode` | `GlassSheetMode` | Same — too generic as a bare name |
| `FillTransition` | `GlassFillTransition` | Too generic as a bare name |
| `ExtraButtonPosition` | `GlassExtraButtonPosition` | Ambiguous without prefix |

> **Migration:** A `@Deprecated` typedef for `GlassBottomBarExtraButton` is provided. All other old names will produce compile errors — migration is mechanical find-and-replace.

### GlassSegment — new concrete class

`GlassSegment` was previously a `typedef` alias for `GlassTab`. It is now a proper class with a focused API for `GlassSegmentedControl`:

```dart
// GlassSegment — for GlassSegmentedControl only
GlassSegment({ Widget? icon, String? label, String? tooltip, String? semanticLabel, bool enabled = true })

// GlassTab — for GlassTabBar.bottom() and GlassTabBar.searchable()
GlassTab({ Widget? icon, Widget? activeIcon, String? label, Color? glowColor, double? thickness })
```

Fields like `activeIcon`, `glowColor`, and `thickness` are navigation-specific and only exist on `GlassTab`. `GlassSegment` adds `tooltip` and `enabled` (with built-in disabled rendering at 38% opacity).

### Barrel hygiene

Internal types (`SheetSnapshot`, `SheetGeometry`, `GesturePhase`, `GestureArena`, `FrozenState`) are no longer accessible from the package barrel. These were implementation details that leaked through `part` file exports.

## ⚡ Performance

- **Shader:** `interactive_indicator.frag` — replaced `pow()` calls with multiply chains; collapsed duplicate rim pass; zero transcendental functions in highlight path.
- **Shader:** `liquid_glass_final_render.frag` — `⁶√x` computed via sqrt cascade (3 SFU vs 2 transcendentals); `sceneSDF` samples reduced from 5 → 4.
- **Dart:** `resolveAdaptiveRadius` scoped to `MediaQuery.viewPaddingOf` + `MediaQuery.sizeOf` — glass widgets no longer rebuild on keyboard or unrelated `MediaQueryData` changes.
- **Dart:** Searchable tab bar and `GlassSegmentedControl` spring animations now use `ListenableBuilder` scoped to the indicator subtree. Verified on-device: zero `State.build()` calls during 120Hz spring animation.

## 🐛 Fix

- **`LiquidGlassWidgets.initialize()`** now pre-warms all four shaders — `liquid_glass_geometry_blended.frag` and `liquid_glass_final_render.frag` were previously lazy-loaded, causing first-frame jank.
- **`GlassSegment.enabled = false` now blocks tap/tapDown** — disabled segments rendered at 38% opacity but still fired `onSegmentSelected` in both fixed-width and scrollable modes. Tap and `onTapDown` handlers now early-return when the target segment is disabled.


---

# 0.18.6

## 🐛 Fix: Glass widgets now honour app `ThemeMode`, not OS dark mode

Resolves a class of UI inconsistency where glass widgets incorrectly read the **device/OS** brightness instead of the **app**'s brightness. The most visible symptom was `GlassBottomTabBar` shadows disappearing when the device was in Dark Mode but the app was pinned to Light Mode via `MaterialApp(themeMode: ThemeMode.light)`.

### Root cause

Every glass widget that needed to decide between light/dark colours or shadow visibility called either `CupertinoTheme.of(context).brightness` or `MediaQuery.platformBrightnessOf(context)` directly. Both of these APIs fall back to the OS/device setting and are blind to `MaterialApp.themeMode`.

### Fix: Centralised brightness cascade

A new `GlassTheme.brightnessOf(context)` authority now governs all brightness decisions in the library. It resolves via a four-level cascade:

1. **`GlassThemeData.brightness`** — new field; an explicit developer override pinned in the `GlassTheme` widget tree (highest priority).
2. **`CupertinoThemeData.brightness`** — explicit Cupertino pin (non-null only; intentional opt-in).
3. **`Theme.maybeBrightnessOf(context)`** — Material `ThemeMode.light`/`.dark`/`.system`, honouring `MaterialApp.themeMode`.
4. **`MediaQuery.platformBrightnessOf(context)`** — OS/device setting (safe fallback).

### Changes

- **New:** `lib/utils/glass_brightness.dart` — `resolveGlassBrightness(context)` utility (package-private).
- **New field:** `GlassThemeData.brightness` — explicit brightness override for fine-grained glass-subtree control. Accepted by both the default and `GlassThemeData.simple()` constructors.
- **New method:** `GlassTheme.brightnessOf(context)` — the single, mandatory brightness authority for the entire library.
- **Fixed:** Shadow suppression in `GlassBottomTabBar`, `GlassSearchableBottomBar`, `AdaptiveLiquidGlassLayer`, and `AdaptiveGlass` (`_FrostedFallback`).
- **Fixed:** Shader `backdropLuma` proxy in `GlassEffect` (controls glass strength in the GPU path).
- **Fixed:** Light/dark colour selection in 20+ widget files across `interactive/`, `containers/`, `input/`, `overlays/`, and `surfaces/` layers.

### Tests

Three new test files cover every level of the cascade:

- `test/utils/glass_brightness_test.dart` — unit tests for `resolveGlassBrightness`.
- `test/theme/glass_theme_brightness_test.dart` — `GlassTheme.brightnessOf` integration tests including the canonical regression scenario.
- `test/theme/glass_theme_data_brightness_test.dart` — `GlassThemeData.brightness` override field, `copyWith`, equality, and backward-compat tests.

---

# 0.18.5

## 🔧 Corrected minimum SDK constraint — Flutter ≥ 3.41.0

- **Fix:** Raised the minimum Flutter constraint to `3.41.0`. The `filterQuality` parameter on `FragmentShader.setImageSampler()` was actually introduced in Flutter 3.41.0 (commit `add442b29c`), not 3.24.0 as previously stated. This prevents users on 3.38.x from failing at compile time.
- **Reverted:** Raised the internal `meta` constraint back to `^1.18.0` since Flutter 3.41.0 guarantees this version is available.

---

# 0.18.4

- **Fix:** Loosened the `meta` dependency constraint to `^1.12.0` (instead of `^1.18.0`) to avoid pub resolution conflicts for users on older Flutter SDKs where `flutter_test` is bound to `meta 1.17.0`.

---

# 0.18.3


## ✨ Per-state label text style on bottom bars — `selectedLabelStyle` / `unselectedLabelStyle`

Adds `selectedLabelStyle` / `unselectedLabelStyle` (`TextStyle?`) to `GlassTabBar.bottom`, `GlassTabBar.searchable`, and the deprecated `GlassBottomBar` / `GlassSearchableBottomBar`.

This complements the `selectedLabelColor` / `unselectedLabelColor` parameters by letting callers set the selected/unselected label's **font family, weight, and letter-spacing per state** — needed to match Apple's tab bar, where the selected label is heavier than a single shared `textStyle` can express.

The per-state style is **merged over** the base label style, so it overrides only the fields it sets and keeps the resolved per-state label color unless the style provides its own. Both default to `null` → existing behavior unchanged.

Also fixes a related precedence bug: an explicit `selectedLabelColor` / `unselectedLabelColor` was silently dropped whenever a `textStyle` was also supplied (the per-state color only fed the fallback style). It now overrides the base color — including a color baked into `textStyle` — while `textStyle`-only callers are unaffected.


## ✨ `innerBlur` — Apple-style rest-blur behind the selected tab

The `innerBlur` parameter on `GlassTabBar.bottom`/`.searchable` (and the deprecated `GlassBottomBar`/`GlassSearchableBottomBar` shims) now renders. It was declared and threaded bar→internal, but never forwarded to the indicator, and `AnimatedGlassIndicator` had no implementation. This wires it through the tab-bar internals and adds the rest-gated `BackdropFilter`.

It paints a backdrop blur behind the **resting** selected pill — the iOS 26 "frost at rest" look — with the sigma scaled by the pill's resting opacity, so the frost is full when settled and fades out as it morphs into the liquid-glass lens during a drag/tap (motion stays crisp).

- `0.0` (default) disables it — no behavior change for existing callers.
- Only the background-painting indicator is affected (reads through a translucent `indicatorColor`).

## ✨ `platformViewBackdrop` on the public glass widgets

Follows up [#94](https://github.com/sdegenaar/liquid_glass_widgets/pull/94) by exposing the premium-over-PlatformView flag on the remaining public widgets — `GlassContainer`, `GlassButton`, `GlassIconButton`, `GlassButtonGroup`, `GlassMenu`, and `GlassModalSheet` — so apps can render premium glass cleanly over an iOS PlatformView (e.g. a Mapbox `MapWidget`) for any control, not just the bottom bar.

Each gets an explicit `platformViewBackdrop` parameter defaulting to `false` (zero overhead / no behavior change for callers that don't need it), forwarded to the underlying `AdaptiveGlass`. For `GlassModalSheet` the flag threads through `GlassModalSheetScaffold` and the sheet state down to the `_SheetLayout`'s glass. Adds widget tests covering the simple-widget forwards.


## 🧹 Removed — `GlassTintBlend` (a no-op since 0.17.0)

`GlassTintBlend` (added in [#107](https://github.com/sdegenaar/liquid_glass_widgets/pull/107)) and the `LiquidGlassSettings.tintBlend` field have been removed.

Since the 0.17.0 shader rewrite, `tintBlend` was never wired into the renderer — it was packed into no uniform, so setting it had no effect: every surface used the automatic chroma-gated blend regardless of the value. We only caught this during real-device tuning, after all the related PRs had already landed.

The automatic behavior is unchanged. `applyGlassColor` still picks luminosity-preserving blending for chromatic tints and flat blending for achromatic tints. Recipes that previously passed `tintBlend: flat` for achromatic (white / grey / near-black) tints render identically, because the chroma gate already resolves those to the flat path.

**Breaking, but inert:** code that passed `LiquidGlassSettings(tintBlend: …)` must drop the argument. No rendered output changes.

## 🔧 SDK constraints bump *(corrected in 0.18.5)*

Raised minimum Flutter to `>=3.24.0` — this was incorrect. The actual minimum is `3.41.0`, corrected in `0.18.5`.

---

# 0.18.2

### Rendering Quality

- **Fix:** Eliminated stair-step aliasing on `AnimatedGlassIndicator` / `GlassEffect` pill edges during press animations.
  Root cause: `FragmentShader.setImageSampler()` defaults to `FilterQuality.none` (Nearest-Neighbor). The 4 % press-scale animation was block-replicating geometry texels into 2×2 stair-step patterns visible as jagged fringe on the pill rim.
  **Resolution:** Pass `filterQuality: FilterQuality.medium` to every `setImageSampler()` call in `liquid_glass_render_object.dart`, `glass_effect.dart`, and `lightweight_liquid_glass.dart`. Zero GPU cost — hardware bilinear filtering happens in a single texel-unit clock cycle.

- **Fix:** Eliminated 2×2 blocky normal artifacts on glass pill edges (all platforms, most visible on iOS/macOS Metal).
  Root cause: Metal's `dFdx`/`dFdy` evaluate in 2×2 pixel quads, so all four neighbours share one gradient vector. At the high-contrast white rim of the pill this produces a coarse stair-step normal map that manifests as jaggy rainbow banding regardless of scale.
  **Resolution:** Replaced hardware derivatives with per-pixel central finite differences in `liquid_glass_geometry_blended.frag` (`dx = sceneSDF(p + 0.5) − sceneSDF(p − 0.5)`). Costs 4 extra SDF evaluations per geometry pixel — negligible on a cached, one-shot geometry pass.

- **Fix:** Restored full rim brightness after the anti-aliasing band was widened.
  Root cause: The previous asymmetric `smoothstep(-smoothing, 0.0, sd)` placed the mathematical pill boundary (`sd = 0`) at the dark end of the alpha ramp (alpha = 0). The rim-lighting peak lives exactly at `sd = 0`, so it was multiplied by zero and rendered invisible.
  **Resolution:** Centred the smoothstep around the boundary — `smoothstep(smoothing * 0.5, -smoothing * 0.5, sd)` — so `sd = 0` maps to alpha = 0.5. This is the canonical SDF anti-aliasing formulation and restores maximum rim brightness with no other visual side-effect.

- **Fix:** Eliminated backdrop texture wrap-around artifacts during `LiquidStretch` scaling and jelly overshoot.
  Root cause: Impeller's default texture sampler wrap mode is `Repeat`. A fragment slightly outside `uGeometrySize` (e.g. during a spring overshoot) produced a `geometryUV` marginally above 1.0; the sampler wrapped it to near-0.0, sampling the opposite edge of the SDF and producing inverted normals and extreme chromatic aliasing.
  **Resolution:** Clamp `geometryUV` to `[0, 1]` before the texture fetch. Clamped-edge pixels have near-zero SDF alpha and are discarded by the existing `geometryData.a < 0.01` early-out — no separate bounds-check branch required.

- **Fix:** Eliminated chromatic wrap artifacts during jelly overshoot in `interactive_indicator.frag`.
  Root cause: When the indicator pill overshoots its `RepaintBoundary` bounds, out-of-bounds `textureBilinear` sample points could trigger the same Repeat-mode wrap in the background texture.
  **Resolution:** Explicitly clamp all four bilinear sample points to `[0, physSize − 1]` before the `texture()` fetch.

- **Fix:** Eliminated jagged/pixelated stair-step artifacts on `AnimatedGlassIndicator` pill edges when `indicatorPinchStrength > 0`.
  Root cause: `BackdropFilterLayer` implicit samplers are bound to `FragmentShader` as Nearest-Neighbor with no Dart API to override it ([Flutter Issue #139887](https://github.com/flutter/flutter/issues/139887)). Continuous sub-pixel UV shifts from the lens pinch and chromatic aberration were snapping to integer texels, producing blocky rainbow fringes on high-contrast backgrounds.
  **Resolution:** Added a `textureBilinear` helper to `liquid_glass_final_render.frag` that performs a standard 4-texel bilinear interpolation in GLSL, restoring perfectly smooth sub-pixel background sampling. The geometry texture (`uGeometryTexture`) is intentionally excluded — its pixel-aligned SDF data must not be softened.

- **Fix:** Eliminated pixelation on the interactive indicator pill (`GlassSegmentedControl`, `GlassEffect`).
  Two compounding causes: (1) the background texture was previously captured at `pixelRatio: 1.0`, so each texel covered a 3×3 block of physical pixels on a 3× Retina display; (2) Impeller's `setImageSampler()` binding defaults to Nearest-Neighbor, snapping continuous UV offsets from edge refraction to these large texels.
  **Resolution:** Background capture now uses the device's full DPR. A `textureBilinear` GLSL helper replaces all raw `texture()` calls in `interactive_indicator.frag`. ~250 KB additional GPU texture memory; sub-0.1 ms additional GPU time per frame — negligible on any modern device.

- **Fix:** Resolved intermittent Metal API Validation abort on iOS (`GlassQuality.premium`) — missing buffer bindings for `uWhiten`, `uWhitenGated`, and `uPinchStrength` ([#121](https://github.com/sdegenaar/liquid_glass_widgets/issues/121)).
  All shader uniforms (slots 0–20) are now written atomically on every paint frame, preventing a stale or zero-initialised `FragmentShader` snapshot from reaching the Metal draw call. Affected: `GlassTabBar.bottom(quality: GlassQuality.premium)` with an animating indicator. No API changes.

### Notes

- **Note (Flutter engine limitation):** The `textureBilinear` workaround in `liquid_glass_final_render.frag` (4-tap bilinear in GLSL) remains necessary for backdrop sampling because Impeller binds the implicit `BackdropFilterLayer` sampler as Nearest-Neighbor with no Dart API to override `FilterQuality`. A Flutter engine feature request to expose sampler filter quality for backdrop layers has been filed at [Flutter Issue #188365](https://github.com/flutter/flutter/issues/188365). Once resolved, the GLSL workaround can be replaced with a single `texture()` call.

### Chore

- **Chore:** Removed unreachable early-out branch in `liquid_glass_final_render.frag` — the `if (any(lessThan(geometryUV, ...)))` check after `clamp(geometryUV, 0.0, 1.0)` could never fire. Replaced with a single consolidated comment explaining how the clamp and the downstream alpha check together handle both the Impeller Repeat-mode and clipExpansion cases.
- **Chore:** Removed dead code from `render.glsl` (`computeY`, `getHeight`, `calculateLighting`, `calculateRefraction`, `renderLiquidGlass`, `debugNormals`) — functions superseded by the inline logic in `liquid_glass_final_render.frag`. Reduces compiled shader binary size.

# 0.18.1

- **Hotfix:** Resolved missing coverage in layout engines and segmented controls.
- **Hotfix:** Fixed package analysis warnings due to unused local variables and unnecessary imports in test files.

# 0.18.0

## 🏗️ Unified Navigation API — iOS 26 Alignment

This release consolidates the widget API to map 1:1 with Apple's iOS 26 control vocabulary. Two v1-era widgets are deprecated (see Migration below), and `GlassTabBar` becomes the single source of truth for all tab-navigation work.

---

### ⚠️ Breaking Change: Android Bottom Bar Padding

`GlassScaffold` now automatically manages the Android system navigation bar padding for `bottomBar`. If you previously added manual `Padding` or `SafeArea` around your bottom bar to prevent it from slipping behind the Android navigation buttons, please remove it to avoid double-padding.

---

### New: `GlassTabBar.bottom()` — iOS 26 UITabBar equivalent

Named constructor for bottom navigation bars. Full liquid glass layer, jelly physics pill indicator, `MaskingQuality` dual-layer icon rendering, and optional `dividerSettings`.

```dart
GlassTabBar.bottom(
  tabs: [
    GlassTab(icon: Icon(Icons.home), label: 'Home'),
    GlassTab(icon: Icon(Icons.search), label: 'Search'),
    GlassTab(icon: Icon(Icons.person), label: 'Profile'),
  ],
  selectedIndex: _selectedIndex,
  onTabSelected: (i) => setState(() => _selectedIndex = i),
)
```

---

### New: `GlassTabBar.searchable()` — UITabBar + morphing search

Named constructor combining bottom navigation with a morphing glass search pill. Identical API to `GlassTabBar.bottom()` with additional `searchBarConfig` and `controller` parameters.

```dart
GlassTabBar.searchable(
  tabs: [...],
  selectedIndex: _selectedIndex,
  onTabSelected: (i) => setState(() => _selectedIndex = i),
  searchBarConfig: GlassSearchBarConfig(hintText: 'Search...'),
  controller: _tabBarController,
)
```

---

### New: `GlassSegmentedControl` — icon support + scrollable mode

#### Icon + label support (fixed mode)

`segments` now accepts `List<GlassTab>` instead of `List<String>`. Each segment can render:
- **Label only** — `GlassTab(label: 'Weekly')`
- **Icon only** — `GlassTab(icon: Icon(Icons.photo))`
- **Icon + label** — `GlassTab(icon: Icon(Icons.photo), label: 'Photos')` (icon above label)

This matches iOS 26 UISegmentedControl which has supported `UIImage` segments since early iOS.

#### Scrollable mode — 100% parity with original `GlassTabBar(isScrollable: true)`

---

### 🚨 Removed: `GlassTabBar()` inline constructor

The default `GlassTabBar()` constructor has been **removed**. `GlassTabBar` is now exclusively used for structural bottom navigation (`GlassTabBar.bottom()` and `GlassTabBar.searchable()`). 

**Migration:**
For all inline tab bars, pill menus, or scrollable tag lists, use `GlassSegmentedControl()` or `GlassSegmentedControl.scrollable()`. They provide 100% feature parity with the old inline `GlassTabBar`.

```diff
- GlassTabBar(
-   tabs: const [
-     GlassTab(label: 'A'),
-     GlassTab(label: 'B'),
-   ],
-   selectedIndex: _selectedIndex,
-   onTabSelected: (i) => setState(() => _selectedIndex = i),
- )
+ GlassSegmentedControl(
+   segments: const [
+     GlassSegment(label: 'A'),
+     GlassSegment(label: 'B'),
+   ],
+   selectedIndex: _selectedIndex,
+   onSegmentSelected: (i) => setState(() => _selectedIndex = i),
+ )
```


New `GlassSegmentedControl.scrollable()` named constructor for category filter tabs (6+ items). Internally uses `ScrollableSegmentContent` — a dedicated widget that owns scrollable pill physics, gesture handling, and 3-layer rendering. Structurally identical to the old inline `GlassTabBar(isScrollable: true)`, now correctly located in the interactive widget family.

```dart
// Fixed (UISegmentedControl — equal width, 2–6 items)
GlassSegmentedControl(
  segments: const [
    GlassSegment(label: 'All'),
    GlassSegment(icon: Icon(Icons.photo), label: 'Photos'),
    GlassSegment(label: 'Videos'),
  ],
  selectedIndex: _selectedIndex,
  onSegmentSelected: (i) => setState(() => _selectedIndex = i),
)

// Scrollable (category filter tabs — natural width, 7+ items)
GlassSegmentedControl.scrollable(
  segments: List.generate(12, (i) => GlassSegment(label: 'Category ${i + 1}')),
  selectedIndex: _selectedIndex,
  onSegmentSelected: (i) => setState(() => _selectedIndex = i),
)
```

---

### Architecture: Dependency inversion

All tab-bar layout logic now lives in dedicated layout files:

| File | Owns |
|---|---|
| `interactive/shared/scrollable_segment_content.dart` | `ScrollableSegmentContent` — scrollable pill + gesture engine (used by `GlassSegmentedControl.scrollable`) |
| `interactive/shared/segmented_control_internal.dart` | `SegmentedControlContent` — fixed-width pill + gesture engine (used by `GlassSegmentedControl`) |
| `surfaces/shared/tab_bar_bottom_layout.dart` | `TabBarBottomLayout` — full glass bottom shell |
| `surfaces/shared/tab_bar_searchable_layout.dart` | `TabBarSearchableLayout` — search morph shell |

`GlassTabBar` dispatches to these shells. `GlassBottomBar` and `GlassSearchableBottomBar` are now zero-logic shims that delegate to the same shells.

---

### Deprecated — removal in v1.0

#### `GlassBottomBar` → `GlassTabBar.bottom()`

```dart
// BEFORE
GlassBottomBar(
  tabs: [GlassBottomBarTab(icon: Icon(Icons.home), label: 'Home')],
  selectedIndex: _selectedIndex,
  onTabSelected: (i) => setState(() => _selectedIndex = i),
)

// AFTER
GlassTabBar.bottom(
  tabs: [GlassTab(icon: Icon(Icons.home), label: 'Home')],
  selectedIndex: _selectedIndex,
  onTabSelected: (i) => setState(() => _selectedIndex = i),
)
```

#### `GlassSearchableBottomBar` → `GlassTabBar.searchable()`

```dart
// BEFORE
GlassSearchableBottomBar(tabs: [...], ...)

// AFTER
GlassTabBar.searchable(tabs: [...], ...)
```

#### `GlassTabBar()` default constructor → `GlassSegmentedControl`

```dart
// BEFORE
GlassTabBar(
  tabs: [GlassTab(label: 'A'), GlassTab(label: 'B')],
  selectedIndex: _selectedIndex,
  onTabSelected: (i) => setState(() => _selectedIndex = i),
)

// AFTER
GlassSegmentedControl(
  segments: [GlassTab(label: 'A'), GlassTab(label: 'B')],
  selectedIndex: _selectedIndex,
  onSegmentSelected: (i) => setState(() => _selectedIndex = i),
)
```

#### `GlassSegmentedControl.segments: List<String>` → `List<GlassTab>`

```dart
// BEFORE
GlassSegmentedControl(segments: ['Daily', 'Weekly', 'Monthly'], ...)

// AFTER
GlassSegmentedControl(
  segments: [
    GlassTab(label: 'Daily'),
    GlassTab(label: 'Weekly'),
    GlassTab(label: 'Monthly'),
  ],
  ...
)
```

---

### iOS 26 control vocabulary — full mapping

| Widget | iOS 26 equivalent | Glass tier |
|---|---|---|
| `GlassSegmentedControl(...)` | `UISegmentedControl` | Light tint + glass pill |
| `GlassSegmentedControl.scrollable(...)` | Scrollable filter tabs | Light tint + glass pill |
| `GlassTabBar.bottom(...)` | `UITabBar` | Full liquid glass |
| `GlassTabBar.searchable(...)` | `UITabBar` + search | Full liquid glass |

---

### New: Configurable label colors and indicator border radius for bottom bars

`GlassTabBar.bottom()`, `GlassTabBar.searchable()`, `GlassBottomBar`, and `GlassSearchableBottomBar` expose three additional styling parameters:

- **`selectedLabelColor`** — tab label colour when selected, independent of `selectedIconColor`
- **`unselectedLabelColor`** — tab label colour when unselected, independent of `unselectedIconColor`
- **`indicatorBorderRadius`** — pill indicator corner radius, independent of `barBorderRadius` (e.g. `100` for a fully round pill on a subtly curved bar)

All three are optional; omitting them preserves existing behaviour exactly.

```dart
GlassTabBar.bottom(
  tabs: [...],
  selectedIndex: _selectedIndex,
  onTabSelected: (i) => setState(() => _selectedIndex = i),
  selectedLabelColor: Colors.blue,
  unselectedLabelColor: Colors.grey,
  indicatorBorderRadius: 100,
)
```

---

# 0.17.1

## 🐛 Fix — `platformViewBackdrop` toggle no longer snaps the selected-tab indicator ([#112](https://github.com/sdegenaar/liquid_glass_widgets/pull/112) by [@jfhair](https://github.com/jfhair))

Toggling `platformViewBackdrop` at runtime (e.g. switching between a map tab and a Flutter-content tab) caused the selected-indicator pill to snap to the new tab instead of sliding. The spring animation controllers inside the indicator subtree were being re-seeded at their already-settled value because the toggle added or removed the `LiquidGlassBlendGroup` wrapper in `AdaptiveLiquidGlassLayer`, changing the child's depth in the element tree and forcing Flutter to discard and re-inflate the whole subtree via `initState`.

**Fix:** `AdaptiveLiquidGlassLayer` is now a `StatefulWidget` that holds a stable `GlobalKey`. The child is always wrapped in a `KeyedSubtree` with that key, so the element identity is preserved across the wrapper toggle — the indicator's `AnimationController`s survive and the morph continues correctly.

No API changes. No breaking changes.

---

# 0.17.0


## 🔬 iOS 26 Concave Lens Pinch — All Four Pill Widgets

The `indicatorPinchStrength` concave lens warp is now unified across all four interactive pill widgets. During a drag the pill edges curve inward (iOS 26 "through a lens" effect). Fully tunable — `0.0` disables it, `1.0` is maximum distortion.

### New parameters

- **`GlassTabBar.indicatorPinchStrength`** (default `0.4`)
- **`GlassTabBar.indicatorExpansion`** (default `EdgeInsets.symmetric(horizontal: 12, vertical: 8)`)
- **`GlassSegmentedControl.indicatorPinchStrength`** (default `0.4`)
- **`GlassSegmentedControl.indicatorExpansion`** (default `EdgeInsets.symmetric(horizontal: 12, vertical: 8)`)
- **`AnimatedGlassIndicator`** exported from the public API — enables `baseIndicatorSettings.copyWith(...)` from app code.

### Changed defaults (`AnimatedGlassIndicator.baseIndicatorSettings`)

- `glassColor`: `alpha: 0.15` → `alpha: 0.0` — glass pill no longer applies a white tint overlay by default.
- `chromaticAberration`: `GlassDefaults.chromaticAberration` → `0.15` — the iridescent rim fringe is now explicitly set for iOS 26 parity.

### Bug fixes

- **`GlassSegmentedControl` refraction** — labels are now refracted through the glass pill at `GlassQuality.premium` (was rendered in wrong z-order).
- **`GlassTabBar` indicator radius** — resting pill now inherits the tab bar's `borderRadius` (was hardcoded `16 px`).
- **`AnimatedGlassIndicator` settings merge** — partial `indicatorSettings` overrides no longer silently reset `chromaticAberration`.
- **Pinch lens jitter at rest** — icon and label content no longer shimmers through the lens when the pill settles. Root cause: the jelly spring's micro-oscillations (±10 % of `thickness`) were directly amplified into the UV warp. Fixed by applying a quadratic ease-out to the pinch multiplier (`1 − (1 − fade)²`), compressing the near-settled oscillation range ≈10×.

### Try it — Indicator Parity demo

The example app includes a live **Indicator Parity** demo (`Demos → Indicator Parity`) with all four pill widgets side-by-side and real-time sliders for `pinchStrength`, `indicatorExpansion`, and `chromaticAberration`. Use it to tune parameters before writing any code.

## 🌑 Apple Dimming Layer — `LiquidGlassSettings.backerColor` ([#111](https://github.com/sdegenaar/liquid_glass_widgets/pull/111) by [@jfhair](https://github.com/jfhair))

New optional `backerColor` on `LiquidGlassSettings` — a shape-matched color pad composited *behind* the glass, giving a control's content contrast over rich or colorful backdrops (video, maps, photography) where the glass tint alone can't. This is Apple's "dimming layer" guidance from the Human Interface Guidelines (Materials section) and the pattern behind SwiftUI's clear `Glass` variant.

```dart
LiquidGlassSettings(
  glassColor: Color(0x20FFFFFF),
  backerColor: Color(0x59000000), // ~35% black — Apple's starting point
)
```

- **`backerColor`** (`Color?`, default `null`) — the color's alpha *is* the dimming opacity. `null` means no backer, so all existing recipes are untouched.
- Rendered at the widget level (like `shadow`) and clipped to the glass shape via `ClipRRect`, so it composites correctly even over a `PlatformView` — maps, video — where a shader-side tint cannot reach.
- Applies in both light and dark mode, and for flat-edge shapes (a bar over a map is a primary use case).
- Skipped on the grouped path (like shadow) — inserting a `Stack` between grouped glass and its shared layer would break metaball morphing.
- `lerp` fades `backerColor` smoothly from transparent when one side is `null`, rather than snapping at the midpoint.

### Migration

All four widgets share the same tuning API:

```dart
indicatorPinchStrength: 0.4,
indicatorExpansion: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
indicatorSettings: AnimatedGlassIndicator.baseIndicatorSettings
    .copyWith(chromaticAberration: 0.15),
```

---

# 0.16.3

## ✨ `GlassTintBlend` — selectable tint blending path ([#107](https://github.com/sdegenaar/liquid_glass_widgets/pull/107) by [@jfhair](https://github.com/jfhair))

New `GlassTintBlend` enum on `LiquidGlassSettings` to explicitly control how `glassColor` blends with the refracted backdrop, instead of relying entirely on the chroma heuristic.

- `GlassTintBlend.auto` — the default. Existing chroma gate, byte-for-byte unchanged behavior.
- `GlassTintBlend.luminosity` — always preserve backdrop luminosity. For near-neutral tints that need to keep the glassy look rather than flattening to a film.
- `GlassTintBlend.flat` — always impose the tint's brightness. For dimming layers, backing scrims, or deliberate frost-film surfaces.

Fully threaded through `LiquidGlassSettings` (`copyWith`, `lerp`, `props`), both the Premium and Standard shader paths, and preserved through `AdaptiveGlass` elevation rebuilds. Frosted fallback renders flat by construction and ignores the setting.

## ✨ `GlassScrollEdgeEffect.bottomFadeInset` ([#109](https://github.com/sdegenaar/liquid_glass_widgets/pull/109) by [@jfhair](https://github.com/jfhair))

New optional `bottomFadeInset` parameter (default `0.0`) that lifts the bottom fade off the widget's true bottom edge by the specified logical pixels. Fixes cases where the scroll viewport extends below the visible area — such as a bottom sheet whose content box overflows past the screen bottom — causing the bottom fade to anchor off-screen and never appear.

**No breaking changes.** All new parameters are optional with safe defaults.

---

# 0.16.2

## 🐛 Bug Fix — `GlassMenu` / `GlassPopover` rebuild on keyboard open/close

`GlassMenu` and `GlassPopover` were rebuilding on every keyboard open/close event,
even when closed. Caused by `MediaQuery.of(context)` in `didChangeDependencies`
subscribing to `viewInsets`. Fixed by switching to scoped accessors
(`disableAnimationsOf`, `maybeSizeOf`, `textScalerOf`). Regression tests added.

## ✨ Content-luminance scroll-edge scrim ([#106](https://github.com/sdegenaar/liquid_glass_widgets/pull/106) by [@jfhair](https://github.com/jfhair))

The continuous companion to the `contentAwareBrightness` discrete lever. Scroll-edge
fades now track content luminance and dissolve toward a dark color as dark content
scrolls under the bars — matching the native App Store early-darkening behaviour.

- `GlassContentAwareScope.register()` gains `onLuminanceChanged` (brightness callback is now optional). Per-rect mean luminance is delivered from the existing single capture; deliveries are gated on >0.005 movement.
- `GlassScrollEdgeEffect.contentAwareFade` — each edge band registers with the scope and lerps toward `darkFadeColor` as content darkens (`luminanceDarkBelow` / `luminanceLightAbove` thresholds, 280 ms ease-out). Inert without a scope.
- `GlassScaffold.contentAwareEdgeFade` — one flag to enable both bars, composing with `contentAwareBrightness`.
- **Latent wrap-order fix (0.16.0):** `GlassScaffold` was wrapping the body in `GlassContentAwareContent` *after* the edge fade, so the fade overlays were inside the sampled region. With the adaptive scrim this is a feedback loop. Wrap order corrected + regression test added.

## 🐛 `GlassModalSheet` handle-drag fixes ([#106](https://github.com/sdegenaar/liquid_glass_widgets/pull/106))

- Handle drag no longer fights the inner scroll. `_handleDragActive` notifier is set on pointer-down (before the inner `Scrollable` can claim slop), disabling inner scroll for the gesture lifetime. Fixes a freeze when dragging the handle over a `PlatformView`.
- `dragIndicatorColor` now actually reaches the drag indicator — it was silently wired into `_SheetLayout` but never forwarded to `_GlassDragIndicator`.

## 🐛 `GlassEffect` — defer capture when boundary is mid-paint ([#106](https://github.com/sdegenaar/liquid_glass_widgets/pull/106))

`toImageSync` called during a dirty repaint boundary spammed `[GlassEffect] toImageSync failed` in debug and dropped the frame's capture. Guarded with `debugNeedsPaint` check (release-safe, same pattern as `GlassScrollEdgeEffect`).

**No breaking changes.** New parameters are all optional with safe defaults — existing code compiles and behaves identically without changes.

---

# 0.16.1


## 🍎 iOS 26 Indicator Defaults — Parity Calibration

Three indicator defaults have been updated across `GlassBottomBar` and
`GlassSearchableBottomBar` to better match the iOS 26 bottom-bar pill
out of the box. No API changes — all parameters remain fully configurable.

### Changed defaults

#### `indicatorPinchStrength` — `1.0` → `0.4`

The previous default of `1.0` applied the maximum concave lens / pinch effect
during drag. iOS 26's actual pinch is more restrained — `0.4` produces the
characteristic "through a lens" look without over-distorting the edges.

**To restore the previous behaviour:**
```dart
GlassBottomBar(
  indicatorPinchStrength: 1.0,
  ...
)
```

#### `indicatorExpansion` — `EdgeInsets.all(8)` → `EdgeInsets.symmetric(horizontal: 12, vertical: 8)`

The indicator pill in iOS 26 bottom bars is slightly wider than it is tall —
a subtle "landing pad" shape that reads as a rounded rectangle rather than a
near-circle. The new default matches this proportion.

**To restore the previous behaviour:**
```dart
GlassBottomBar(
  indicatorExpansion: const EdgeInsets.all(8.0),
  ...
)
```

#### `AnimatedGlassIndicator` chromatic aberration — `0.0` → `0.15`

The indicator's internal `_baseGlassSettings` now sets
`chromaticAberration: 0.15`. Real iOS 26 glass has a faint iridescent
rainbow fringe at the rim. At `0.15` the effect is a whisper — visible
up close, subliminal during normal use.

**To disable the aberration** pass a full `indicatorSettings` override:
```dart
GlassBottomBar(
  indicatorSettings: LiquidGlassSettings(
    chromaticAberration: 0.0,
    // include other fields you need
  ),
  ...
)
```

### Affected widgets

- `GlassBottomBar` — `indicatorPinchStrength` and `indicatorExpansion`
- `GlassSearchableBottomBar` — `indicatorPinchStrength` and `indicatorExpansion`
- All widgets using `AnimatedGlassIndicator` — `chromaticAberration` baseline

`GlassTabBar` and `GlassSegmentedControl` retain their existing expansion
defaults (`EdgeInsets.all(8.0)`) as their geometry is different from a
bottom navigation bar.

---

# 0.16.0

## 🎨 Content-Aware Light/Dark Adaptation

Glass bars now automatically adapt their icon and label colors to match the
content scrolling behind them — light glyphs over dark content, dark glyphs over
light content — with a smooth cross-fade transition. This matches the iOS 26
behaviour where navigation chrome remains legible regardless of what is visible
underneath.

*Core engine contributed by [@jfhair](https://github.com/jfhair) in [PR #103](https://github.com/sdegenaar/liquid_glass_widgets/pull/103).*

### New widgets

- **`GlassContentAwareScope`** — wraps a screen and owns the sampling engine.
  Captures the content boundary at scroll rate (~5 fps), divides each registered
  control's rectangle into voting cells, and delivers per-control brightness
  verdicts via WCAG contrast ratios and dual-threshold hysteresis.
- **`GlassContentAwareContent`** — marks the sampled content region. Installs a
  `RepaintBoundary` that the scope captures. Controls must be **outside** this
  region (e.g. in `Scaffold.bottomNavigationBar` with `extendBody: true`).
- **`GlassContentAwareBrightness`** — per-control consumer that cross-fades
  between the light and dark `GlassThemeVariant` via `GlassThemeVariant.lerp`.
  Supports an external `brightnessOverride` (for PlatformView escape hatches),
  configurable grid dimensions, and per-control flip duration/curve overrides.

### New parameters on existing widgets

- **`GlassBottomBar`** — `adaptiveBrightness`, `brightnessOverride`,
  `onBrightnessChanged`. Set `adaptiveBrightness: true` to opt in.
- **`GlassSearchableBottomBar`** — same three parameters. Both bars
  automatically wrap in `GlassContentAwareBrightness` when enabled.
- **`GlassScaffold`** — `contentAwareBrightness`. When `true`, the scaffold
  automatically wraps the body in `GlassContentAwareContent` and the entire
  layout in `GlassContentAwareScope`. One flag, no manual widget wiring.

### New API surface

- **`GlassThemeVariant.lerp(a, b, t)`** — interpolates settings, glow colors,
  quality, and border radius between two theme variants. Used internally by the
  cross-fade but available to consumers building custom transitions.
- **`GlassThemeSettings.lerp(a, b, t)`** — interpolates all 9 glass setting
  fields (thickness, blur, glassColor, lightAngle, lightIntensity, etc.).
- **`resolveBarLabelColor(context, brightness)`** — shared utility for bars
  to resolve label color from `CupertinoTheme` given an overridden brightness.

### Usage

The recommended path — one flag on `GlassScaffold`, one on the bar:

```dart
GlassScaffold(
  contentAwareBrightness: true,
  bottomBar: GlassBottomBar(
    adaptiveBrightness: true,
    onBrightnessChanged: (b) => /* flip your own icon colors */,
    tabs: [...],
    selectedIndex: _index,
    onTabSelected: (i) => setState(() => _index = i),
  ),
  body: CustomScrollView(...),
)
```

For custom layouts without `GlassScaffold`, use the standalone widgets directly:

```dart
GlassContentAwareScope(
  child: Scaffold(
    extendBody: true,
    body: GlassContentAwareContent(
      child: ListView(...),
    ),
    bottomNavigationBar: GlassBottomBar(
      adaptiveBrightness: true,
      ...
    ),
  ),
)
```

### Bug fix

- **`GlassThemeVariant.==` / `hashCode` missing `borderRadius`** — fixed a
  pre-existing bug where two variants differing only in `borderRadius` compared
  equal. This caused stale radius during content-aware cross-fades where
  intermediate lerped variants would not trigger rebuilds.

### Polish

- **`_sample()` error reporting** — the bare `catch (_)` in the sampling
  pipeline now reports to `FlutterError` inside an assert closure. Errors are
  still suppressed in release builds but surface in debug mode so programming
  mistakes are visible.
- **Removed redundant `setState`** — `_GlassContentAwareBrightnessState._setBrightness`
  no longer calls `setState` since `AnimatedBuilder` already listens to the
  animation controller and rebuilds on every tick.

### Example app

- **Content-Aware Brightness demo** (new) — dedicated showcase with alternating
  light and dark content bands that force visible bar flips during scrolling.
  Available in the Examples tab.

---

# 0.15.7

## 🌙 Adaptive Brightness Fix

Fixed a bug in `LightweightLiquidGlass` where the shader's internal brightness estimation (`backdropLuma`) was incorrectly reading from the OS-level `MediaQuery.platformBrightnessOf(context)` rather than the inherited Flutter `Theme.of(context).brightness`. 

This ensures that glass surfaces now correctly switch to Light Mode parameters (such as the legibility veil) when the app itself overrides the theme to Light Mode, even if the user's physical device remains in Dark Mode.

---

# 0.15.6

## 🌫️ Scroll Edge Fade — Perceptual Gradient Curve

Replaced the 2-stop linear alpha gradient in `GlassScrollEdgeEffect` with a
multi-stop eased curve that matches the perceptual dissolve of iOS 26.

- **5-stop gradient profiles** for both `soft` and `hard` styles — eliminates
  the "denser in the centre" banding and the visible seam at the fade boundary.
- **`hard` style reworked**: steeper hold → sharper drop curve instead of just
  compressing the soft profile. Height multiplier relaxed from 0.33× to 0.5×.
- **Example app**: Nav Patterns demo now fully brightness-aware (adaptive text
  colours, `GlassStatusBarStyle.auto`, adaptive solid-bar colour).

No API changes. No breaking changes.

---

# 0.15.5

## ✨ Whiten Strength — Light-Mode Legibility Veil

Opt-in whitening ("legibility veil") lifts glass toward white for legibility over
busy light backgrounds — modelling iOS 26's light-mode glass.

- **`LiquidGlassSettings.whitenStrength`** (0.0–1.0, default 0.0): lifts the
  finished glass toward white as the last step of the render. A single
  control-wide value with no spatial seams or halo artifacts.
- **`LiquidGlassSettings.whitenGated`** (default `true`): when gated, the lift
  scales by per-pixel luminance so bright content lifts to white while dark
  content (text, icons) stays crisp. Ungated applies the lift uniformly — useful
  for dark-mode frost effects.
- **Consistent across all three quality tiers** from one knob: Premium
  (fragment shader), Standard (tint lerp), and Minimal (frosted fallback) all
  render the same whitenStrength value consistently.
- **`GlassSearchableBottomBar` whiten-at-bottom**: when a `scrollController`
  is provided, the bar animates its whitening toward full white as the page
  nears the scroll bottom — the iOS light-mode behaviour where content crowding
  under a bar gets the strongest legibility lift.

- **Example app**: Buttons & Shadows demo now includes a real-time whiten
  slider with side-by-side comparison cards and scroll-to-bottom boost preview.

*Contributed by [@jfhair](https://github.com/jfhair) in [PR #100](https://github.com/sdegenaar/liquid_glass_widgets/pull/100).*

## 🎬 Scale-with-Morph — Cohesive Overlay Content Reveal

Menu items and popover content now scale in alongside the liquid morph animation
instead of popping in at the tail. The glass container and its content feel like
a single continuous motion.

- **Items enter the tree at 30% morph progress** (down from 94%) and scale from
  0.5× to 1.0× via an `easeOut` curve alongside opacity. Text and icons visually
  grow with the expanding glass container.
- **Applied to both `GlassMenu` and `GlassPopover`** for consistent overlay
  behaviour across the widget family. Content scales in on open and scales
  back out on close — the morph animation is symmetrical in both directions.
- No new API surface. No breaking changes. Purely visual polish.

*`GlassMenu` scale-with-morph contributed by [@F1orian](https://github.com/F1orian) in [PR #97](https://github.com/sdegenaar/liquid_glass_widgets/pull/97).*

---

# 0.15.4

## ⚡ Render Pipeline Performance Pass — FPS & Battery

Internal optimizations targeting the render object `paint()` hot path and background
capture lifecycle. Zero API changes, zero visual changes. All 2,050 tests passing.

## 🎯 Bottom Bar Lateral Sway

- **Subtle lateral sway on fast pill drags** — `GlassBottomBar` and
  `GlassSearchableBottomBar` now respond with a near-subliminal horizontal
  shift when the interactive pill is flicked quickly, matching iOS 26 bottom
  bar physics. Velocity-gated (slow drags produce no movement) and
  spring-animated back to center on release.

### GPU allocation pressure (FPS)

- **Cached `ImageFilter` in `_RenderLightweightGlass`** — the composed
  blur+saturation `ImageFilter` (and its 20-element `ColorFilter.matrix` list) was
  previously reconstructed on every `paint()` frame for every visible glass widget.
  With 5 glass cards at 60 fps, that's ~300 list allocations/second hitting the GC.
  The filter is now cached on the render object and only rebuilt when `blur` or
  `saturation` changes.
- **Cached `ImageFilter` in `_RenderInteractiveIndicator`** — same optimization
  for the interactive indicator shader path (`GlassEffect`). The brightness+blur
  composed filter is now cached and invalidated only when `blurSigma` changes.
- **Cached `ImageFilter.blur` in `RenderLiquidGlassLayer`** — the premium glass
  layer's `BackdropFilterLayer` blur filter was previously recreated on every
  `paintLiquidGlass()` call, even when the blur sigma hadn't changed. During
  jelly/morph animations (60 fps), this creates an `ImageFilter.blur` object per
  frame per premium glass layer. Now cached and reused.
- **Cached `_shapesWithGeometry` list** — the premium glass `paint()` method
  previously allocated a new list on every frame to collect active geometry
  shapes. It now reuses a cleared instance list, eliminating another per-frame
  allocation on the hot path.
- **Cached light angle trigonometry** — both `_RenderLightweightGlass` and
  `_RenderInteractiveIndicator` now cache `cos(lightAngle)` and `-sin(lightAngle)`
  instead of recomputing them on every `_updateShaderUniforms()` call. Matches the
  caching pattern already used by the premium `LiquidGlassRenderObject._cachedLightDir`.
- **Conditional `alwaysNeedsCompositing`** — both `_RenderLightweightGlass` and
  `_RenderInteractiveIndicator` previously returned `true` unconditionally, forcing
  the framework to create a compositing layer even in the fallback path (null shader
  or zero blur). Now returns `true` only when a `BackdropFilterLayer` will actually
  be pushed. Reduces layer tree depth on low-end devices.

### Battery life

- **Background Ticker auto-suspend** — `LightweightLiquidGlass` runs a Ticker to
  capture the background behind each glass widget via `toImageSync`. Previously,
  this ticker ran at 60 fps permanently — even when the background hadn't changed
  for minutes (e.g. a static bottom bar over a static page). After 3 consecutive
  no-change frames (~50 ms), the ticker now self-suspends. It restarts automatically
  when `didUpdateWidget` detects a configuration change. For a bottom bar with 5 tab
  pills, this eliminates 300 unnecessary method calls/second while idle.

### GC pressure on frame timing path

- **Optimised `GlassQualityAdapter._percentile`** — the Phase 3 runtime percentile
  computation previously called `_window.toList()` + `List.from(data)..sort()` every
  120 frames, creating two heap-allocated lists on the frame timing callback path.
  Now reuses a pre-allocated sort buffer (`List<int>.filled`) that is overwritten
  in-place. Eliminates GC pressure from the very code path that monitors for
  GC-induced frame drops.

### Community contribution

- **Collapsed search indicator stretch feedback** — the collapsed indicator in
  `GlassSearchableBottomBar` now wraps in `LiquidStretch`, giving it the same
  press-scale physics as the normal tab indicator.
  *Contributed by [@g3mf0r](https://github.com/g3mf0r) in [PR #96](https://github.com/sdegenaar/liquid_glass_widgets/pull/96).*

### Widget tree rebuild reduction

- **Shared spring listener in `GlassSearchableBottomBar`** — the three morph-
  animation `AnimationController`s (tab width, search left, search width) each
  had their own anonymous `addListener(() => setState(() {}))` callback. During
  a pill morph all three springs tick every frame, producing three independent
  `setState` calls per frame. Now all three share a single named `_onSpringTick`
  callback — Flutter coalesces the dirty mark so only one rebuild fires. Also
  fixes a subtle listener leak: anonymous lambdas can't be matched by
  `removeListener`, but named methods can.

### Consistency fix

- **`GlassEffect.preWarm()` dummy image** — changed from async `await picture.toImage(1, 1)`
  to synchronous `picture.toImageSync(1, 1)`, matching the `LightweightLiquidGlass`
  pattern. Eliminates a 1-frame async initialization delay for a 1×1 transparent
  texture. Added `picture.dispose()` to prevent a minor leak.

---

# 0.15.3

## `platformViewBackdrop` — Premium Glass Over iOS PlatformViews

New opt-in flag that lets glass bars render correctly over native iOS views
(Google Maps, Apple Maps, WebView, MapLibre, video players) while keeping the
premium indicator animations alive. Previously, developers had to downgrade to
`GlassQuality.standard` on iOS — now they can stay on `premium`.

*Contributed by [@jfhair](https://github.com/jfhair) in [PR #94](https://github.com/sdegenaar/liquid_glass_widgets/pull/94).*

### New parameter: `platformViewBackdrop`

- **`GlassBottomBar`** — new `platformViewBackdrop` parameter. When `true`,
  the bar background renders via live `BackdropFilter` (the premium shader's
  `toImageSync` cannot capture a `UIKitView`), while the premium indicator
  refracts the bar's own icon layer instead of the un-capturable backdrop.
- **`GlassSearchableBottomBar`** — same parameter, applied to both the tab
  indicator and the search pill. The collapsed search button automatically
  falls back to `GlassQuality.standard` over a PlatformView.
- **`AdaptiveGlass` / `AdaptiveGlass.grouped()`** — new `platformViewBackdrop`
  parameter that forces the `BackdropFilter` rendering path even at
  `GlassQuality.premium`.
- **`AdaptiveLiquidGlassLayer`** — new `platformViewBackdrop` parameter that
  skips the `LiquidGlassBlendGroup` wrapper when rendering over a PlatformView.

### Usage

```dart
GlassBottomBar(
  quality: GlassQuality.premium,
  platformViewBackdrop: Platform.isIOS, // ← one line fix
  tabs: myTabs,
  selectedIndex: _index,
  onTabSelected: (i) => setState(() => _index = i),
)
```

### Example app

- **Google Maps demo** — updated to use `platformViewBackdrop: Platform.isIOS`
  instead of the old `Platform.isIOS ? GlassQuality.standard : GlassQuality.premium`
  workaround. The bar now stays at `GlassQuality.premium` on all platforms.

---

# 0.15.2

## GPU SDF Shadows — Light Mode Performance & Metaball Support

Replaced the previous inverse-clip shadow system with GPU SDF shadows that render
directly from the merged geometry matte. This is both a performance improvement
and a visual correctness fix — shadows now correctly follow the liquid metaball
shape during morph animations, which was impossible with the old per-element
`ClipPath` approach.

### Light mode shadows

- **GPU SDF shadow pass** — `RenderLiquidGlassLayer.paintGlass` now includes a
  Pass 0 that draws each `BoxShadow` using the geometry matte image. The matte
  is drawn with `ImageFilter.blur` for the shadow spread, tinted via
  `ColorFilter.mode`, and then the interior is punched out with `BlendMode.dstOut`
  so the glass backdrop filter never samples its own shadow. This replaces the
  widget-level `_InversePillClipper` / `_InverseOvalClipper` `ClipPath` approach.
- **Shadows plumbed through the full stack** — `LiquidGlassSettings.effectiveShadow`
  is now resolved at the `AdaptiveGlass` and `AdaptiveLiquidGlassLayer` level and
  passed through `LiquidGlass.withOwnLayer` → `LiquidGlassLayer` → `_RawShapes` →
  `RenderLiquidGlassLayer`. Dark mode and flat-edge shapes (`borderRadius: 0`)
  correctly receive an empty shadow list.
- **Removed old clip-based shadow system** — deleted `_InversePillClipper`,
  `_InverseOvalClipper` from `GlassBottomBar`, and the equivalent clippers from
  `GlassSearchableBottomBar`. Removed `_wrapWithLightModeShadow` from
  `AdaptiveGlass`. This eliminates ~140 lines of widget-level shadow plumbing and
  the associated `ClipPath` compositing cost.
- **Geometry image exposed to subclasses** — `LiquidGlassRenderObject` now
  exposes `geometryImage` and `geometryLocalBounds` as `@protected` getters so
  `RenderLiquidGlassLayer` can access the matte for shadow rendering.

### `GlassMenu` overlay rendering

- **`AdaptiveLiquidGlassLayer` in menu overlay** — the morph overlay now uses
  `AdaptiveLiquidGlassLayer` instead of raw `LiquidGlassLayer`, ensuring correct
  quality resolution and backdrop blur when the menu is rendered in premium mode.

### Example app

- **Buttons & Shadows demo** — locked to Light Mode (`Brightness.light`) to serve
  as the definitive showcase for GPU SDF shadows. Moved from the Demos tab to the
  Examples tab with updated card gradient and subtitle.
- **Apple Messages demo** — menu trigger buttons now use `useOwnLayer: true` to
  correctly enter the GPU SDF shadow pipeline. Menu glass settings are
  brightness-aware (`Colors.white12` dark / `Color(0x99FFFFFF)` light).
- **Surfaces demo** — `_buildDemoBackground()` now accepts `BuildContext` and
  returns a light frosted gradient in Light Mode instead of the hardcoded dark
  navy gradient that caused unreadable text.

### Bug fixes

- Fixed unused import `snap_rect_to_pixels.dart` in `liquid_glass_layer.dart`.
- Fixed unused `isDark` variable in `glass_menu_internal.dart`.
- Removed unnecessary `package:flutter/material.dart` import from
  `adaptive_liquid_glass_layer.dart` (already provided by `cupertino.dart`).
- Fixed duplicate doc comment in `glass_bottom_bar.dart`.
- Fixed release-mode crash in `GlassScrollEdgeEffect._captureBackground` — 
  `RenderRepaintBoundary.toImage()` throws synchronously on `layer!` when called
  before the first paint completes (layer not yet composited). The
  `debugNeedsPaint` guard only runs inside `assert()` and is stripped in release
  builds. Fixed by deferring the initial capture to a post-frame callback and
  wrapping `toImage()` in `try`/`catch` as a safety net. Falls back to the
  solid-colour gradient overlay on failure. _(reported by [@RuslanTsitser](https://github.com/RuslanTsitser) via [#93](https://github.com/sdegenaar/liquid_glass_widgets/pull/93))_
- Updated `GlassBottomBar` golden test reference image.



# 0.15.1

## Full Light & Dark Mode — Complete Adaptive UI Kit

`liquid_glass_widgets` is now a **fully adaptive** iOS 26 UI kit. Every widget
— buttons, menus, search bars, sliders, switches, sheets, toasts, chips, form
fields, and all surface bars — automatically resolves the correct glass color,
rim lighting, shadow, text, and icon values for both **Light** and **Dark**
mode. No manual configuration required.

This release closes the last remaining light-mode rendering gaps and ships a
reference implementation in the Apple Messages demo that matches the
iOS 26 Messages app in both modes. Run the example app to toggle light and dark mode for all demo pages.

### New features

- **Configurable glass shadow** — `LiquidGlassSettings.shadowElevation` scales the light-mode drop shadow (`0.0` = off, `1.0` = default, `2.0` = double). `LiquidGlassSettings.shadow` accepts a custom `List<BoxShadow>` for full control. Both flow through `globalSettings` (theme-level) and per-widget `settings:`.
- **`GlassShadow` constants** — centralised shadow values (`GlassShadow.elevation`, `.contact`, `.defaults`, `.scaled(double)`) exported for custom widget authors.
- **`GlassButtonGroup.icons()`** — introduced a lightweight group constructor for iOS 26 style segmented icon toolbars. Uses a single `GlassButton` parent to drive cohesive group-level stretch/glow interaction, while children are rendered as zero-overhead stateless tap targets.
- **`GlassMenuController`** — imperative controller for `GlassMenu` with `open()`, `close()`, and `isOpen`. Drives the menu programmatically instead of (or in addition to) tapping the trigger — useful for gesture-arena-driven menus. _(contributed by [@F1orian](https://github.com/F1orian))_
- **`GlassMenu.showDismissBarrier`** — when `false`, suppresses the full-screen tap-to-dismiss barrier so an external gesture owner can keep receiving pointer events while the menu is open. Defaults to `true`. _(contributed by [@F1orian](https://github.com/F1orian))_
- **`GlassMenu.morphFromZero`** — when `true`, the menu body lerps from a zero-size point at the trigger center instead of from the trigger's own dimensions, suppressing the spawn blob (Blob A). For invisible or zero-sized triggers. _(contributed by [@F1orian](https://github.com/F1orian))_
- **`GlassMenuController.setFollowOffset(Offset)`** — nudges the open menu to track a moving anchor in real-time. The offset is added to the captured trigger position each frame and reset on the next `open()`. _(contributed by [@F1orian](https://github.com/F1orian))_

### Light & dark mode improvements

- **Complete adaptive rendering** — all widgets now resolve glass color, rim borders, shadows, text, and icon colors from `CupertinoTheme.brightnessOf(context)`. Switching between light and dark mode requires zero widget-level changes.
- **Light-mode rim borders** — removed the heavy dark rim border on glass surfaces in light mode. Dark mode rim lighting remains fully intact and unchanged.
- **Light-mode drop shadows** — added inverse-clipped drop shadows to glass surfaces in light mode (cards, standalone buttons, bottom bars). Shadows render outside the glass boundary so the backdrop filter doesn't blur them. Note: morphing elements like the search pill do not have shadows to prevent animation artifacts.
- **Standard glass white frost** — standard quality glass in light mode now correctly renders as clean frosted white instead of muddy grey.
- **Dynamic color resolution** — improved internal text and icon styling to accurately resolve `CupertinoColors` against the active theme brightness.
- **`GlassSearchBar` and `GlassTextField` default colors now brightness-aware** — default text, icon, and glow colors now resolve dynamically against `CupertinoTheme.brightnessOf(context)` instead of being hardcoded to white. This ensures correct contrast in both light and dark mode.

### Bug fixes

- Fixed missing `} else {` in `lightweight_glass.frag` that caused PATH B (standard widgets) to run inside PATH A.
- Fixed `GlassSheet` sharp corners on macOS by decoupling top and bottom border radius.
- Fixed `GlassMenu` selection pill alignment and hit-test accuracy when system text scaler is active.
- Fixed `GlassChip` resolving with invisible white text and icons in light mode.
- Fixed Apple Podcasts demo incorrectly forcing dark-mode glass colors in light mode.
- Fixed `GlassFormField` label (`Colors.white`) and helper text (`Color(0x99FFFFFF)`) being invisible in light mode — now resolves from `CupertinoColors.label` / `.secondaryLabel`
- Fixed `GlassPicker` value text (`Colors.white`) and chevron icon (`Colors.white70`) being invisible in light mode — now resolves from `CupertinoColors.label` / `.secondaryLabel`.
- Fixed `GlassPasswordField` lock and eye toggle icons (`Colors.white70`) being invisible in light mode — now resolves from `CupertinoColors.secondaryLabel`.
- Fixed `GlassActionSheet` forcing dark card background (`Colors.black @ 0.65`), dividers, and pressed highlights regardless of brightness — now resolves to light frosted glass in light mode.
- Fixed `GlassToast` forcing dark pill (`Colors.black @ 0.7`) and white text regardless of brightness — background and text now resolve from brightness for correct contrast in both modes.
- Removed unnecessary `import 'package:flutter/material.dart'` from `GlassFormField`, `GlassPicker`, `GlassPasswordField`, and `GlassToast`.
- Fixed `GlassMenu` morph size going negative during spring undershoot on small triggers — `currentWidth`/`currentHeight` now clamped to `>= 0` to prevent debug `BoxConstraints` assertion. _(contributed by [@F1orian](https://github.com/F1orian))_
- Fixed `GlassMenu` sub-pixel Impeller crash — body container is replaced with `SizedBox.shrink()` when dimensions fall below 1.0 logical pixel, preventing 0-area matte rasterisation. _(contributed by [@F1orian](https://github.com/F1orian))_
- Fixed `GlassIconButton` bypassing theme quality chain — `quality` now passes `null` through to `GlassButton.custom()` so `GlassThemeHelpers.resolveQuality` can resolve from ancestor layers, theme, then widget default. _(contributed by [@F1orian](https://github.com/F1orian))_

### ⚠️ Breaking — Removed frosted well overlay from `GlassTextField`

`GlassTextField` no longer applies a hidden internal darkening overlay ("frosted well") on top of the glass surface. Previously, a `DecoratedBox` with `Colors.black.withValues(alpha: 0.12)` plus a top-edge gradient was composited inside the glass shape to simulate an iOS 26 recessed input tray. This has been removed entirely.

**Why:** The frosted well fought against user-specified `glassColor`, making text fields appear darker/muddier than buttons with identical settings. It also caused visible nested border artifacts when the overlay's `BorderRadius.circular()` didn't match the glass surface's `LiquidRoundedSuperellipse` shape — especially with `useOwnLayer: true` and `padding: EdgeInsets.zero`.

**Design philosophy:** `GlassTextField` is a hero surface (search bars, compose bars, app bar inputs) — not a form field nested inside glass cards. `glassColor` is now the single source of truth for appearance, consistent with every other glass widget.

**Migration:** If you relied on the frosted well for visual distinction inside a grouped layout, set a slightly darker `glassColor` on the text field explicitly. Most users will see cleaner, more predictable text fields with no action required.

### Example app

- **Input demos** — replaced `GlassCard` wrappers around form fields with flat `CupertinoColors.systemFill` containers. Glass text fields now render as standalone hero surfaces (`useOwnLayer: true`) inside flat-colored form sections, demonstrating the correct pattern. Glass-in-glass nesting is an anti-pattern.
- **Apple Messages demo** — fully adaptive light and dark mode implementation. Light mode uses the iOS system grouped background (`#F2F2F7`), brightness-aware white glass tint, and dynamic layer separation to enable shadows. Dark mode retains liquid blending via the shared `AdaptiveLiquidGlassLayer`. Press interactions use `persistPressOnDrag: true` and an elevated `ambientBaseLight` in light mode so the pressed state remains visible while holding and dragging off the button edge.


# 0.15.0

## ⚠️ Breaking — API Cleanup & Standardisation

Removes Material-leaning widgets and thin wrappers that don't map to real
iOS 26 components. Standardises the public API for v1.0 readiness. This is a
breaking release — users on `^0.14.0` will not auto-upgrade.

### Deleted widgets

| Widget | Migration |
|---|---|
| `GlassPanel` | Replace with `GlassCard(padding: EdgeInsets.all(24))` |
| `GlassWizard` / `GlassWizardStep` | No direct replacement — use `GlassStepper` for sequential steps |
| `GlassSideBar` / `GlassSideBarItem` | No direct replacement — a proper `UISplitViewController`-style sidebar is planned for post-1.0 |
| `GlassSnackBar` | Replace with `GlassToast` (identical API — `GlassSnackBar` was documented as an alias) |

### `glassSettings` → `settings` rename

The `glassSettings` parameter on 8 widgets has been renamed to `settings` for
consistency. The `Glass` prefix on the widget name already identifies the
settings type — `glassSettings` was redundant.

**Affected widgets:** `GlassBottomBar`, `GlassSearchableBottomBar`,
`GlassSegmentedControl`, `GlassButtonGroup`, `GlassMenu`, `GlassPopover`,
`GlassToolbar`, `GlassPicker`.

**Migration:** Find-and-replace `glassSettings:` → `settings:` in your code.

### `GlassSheet.show()` API Cleanup

Removed dead Material parameters from `GlassSheet.show()` that have no effect in the liquid glass rendering pipeline:
- `backgroundColor`
- `elevation`
- `shape`
- `clipBehavior`
- `constraints`

**Migration:** Remove these parameters from your `GlassSheet.show()` calls. Use `settings` to configure the glass visual appearance, and `margin` / `padding` / `borderRadius` to control the layout and shape.

## 🎨 Content Colour Audit — Adaptive Light/Dark Mode

All hardcoded `Colors.white` / `Colors.black` in widget content layers replaced with `CupertinoColors` adaptive equivalents. Widgets now render correctly in both light and dark mode without requiring a `MaterialApp` ancestor.

**Affected widgets:** `GlassDialog`, `GlassActionSheet`, all interactive and surface widgets.

`GlassPage` is now fully safe to use inside a pure `CupertinoApp` — the `Theme.of` guard no longer throws when no Material ancestor is present.

## 🐛 Bug Fixes

### `GlassSheet` sharp corners (All Platforms)

Fixed a bug where `GlassSheet` would render with completely sharp, square corners on all devices (including iOS and Android). The internal `SafeArea` wrapper was consuming the bottom safe area before the adaptive radius calculation could read it, causing it to incorrectly fallback to `0.0` everywhere. `GlassSheet` now decouples its top and bottom border radii, defaulting to `topBorderRadius: 32.0`, and smartly assigning `bottomBorderRadius` to `32.0` when floating (with margin) or `0.0` when docked.

## ✨ New — `GlassButtonStyle.prominent`

A new button style matching iOS 26's `.prominentGlass` / `.glassProminent`
configuration — thicker, more opaque glass for primary call-to-action buttons.

```dart
GlassButton(
  style: GlassButtonStyle.prominent,
  icon: Icon(CupertinoIcons.plus),
  onTap: () {},
)
```

## ✨ New — `GlassGroupedSection`

A convenience wrapper that groups `GlassListTile`s inside a `GlassCard`,
automatically applying `isLast: true` to the final tile to suppress its
bottom divider — the most common source of bugs.

```dart
GlassGroupedSection(
  header: Text('Network'),
  children: [
    GlassListTile(title: Text('Wi-Fi')),
    GlassListTile(title: Text('Bluetooth')),
    GlassListTile(title: Text('VPN')), // isLast applied automatically
  ],
)
```

## ✨ New — `GlassPageControl`

iOS `UIPageControl` equivalent — dot indicators for paged content (carousels,
onboarding, gallery pages). Features animated capsule-shaped active dot with
glass treatment and optional tap-to-navigate.

```dart
GlassPageControl(
  count: 5,
  currentPage: _currentPage,
  onPageChanged: (page) => _pageController.animateToPage(page,
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  ),
)
```

## 📖 README — Glass vs Content design guide

Added a design philosophy section explaining iOS 26's glass hierarchy:
glass for navigation chrome and controls, opaque for content areas.
Repositioned `GlassContainer` as an advanced primitive in the widget catalogue.

### What stays

- **`GlassBackdropScope`** — deprecated no-op stays until 1.0.0 as previously
  committed in the 0.14.0 changelog. Zero cost to keep.
- All other widgets — no changes.

## 🐛 Fix — `GlassMenu` auto-scrolling with large system text

When the user increased system text size, `GlassMenu` would become scrollable
even without `menuHeight` being set. The height calculation now accounts for
`textScaler` so the menu sizes correctly at any accessibility text scale.

## 🐛 Fix — `GlassMenu` selection pill misalignment at large text scale

The sliding selection highlight and hit-test math used the nominal `44px` item
height for positioning, while the actual `GlassMenuItem` widgets grew taller
via `ConstrainedBox` when system text was scaled up. This caused the pill to
drift out of alignment and sometimes produce a "double highlight" effect. All
layout math (`_getItemOffset`, `_calculateIndexFromPosition`, `_isScrollable`)
now uses the `TextScaler`-aware height calculation.

## 🐛 Fix — `GlassMenuItem` / `GlassMenuDivider` / `GlassMenuLabel` Light Mode

These widgets previously hardcoded `Colors.white` for text, icons, and divider
colours, making them invisible on light backgrounds. They now inherit from
`CupertinoTheme.of(context)`:

| Widget | Colour Source |
|---|---|
| `GlassMenuItem` | `theme.textTheme.textStyle.color` → `CupertinoColors.label` |
| `GlassMenuDivider` | `theme.textTheme.tabLabelTextStyle.color` at 15 % opacity |
| `GlassMenuLabel` | `theme.textTheme.tabLabelTextStyle.color` at 45 % opacity |

Custom `iconColor`, `titleStyle`, and `color` parameters still take priority
over the theme default — zero breaking changes.

## 🧹 Core — `CupertinoApp` compatibility

Removed all `Theme.of(context)` dependencies from the core library, replacing them with `CupertinoTheme` and `defaultTargetPlatform`. This ensures glass widgets adapt correctly to dark mode and background colours in pure `CupertinoApp` structures without falling back to Material defaults.

## 🧹 Example app — `CupertinoApp` migration

All 16 standalone demos and the main showcase app have been migrated from
`MaterialApp` to `CupertinoApp`. This is the correct root widget for an iOS 26
glass library — it provides `CupertinoTheme` to the entire widget tree, which
glass widgets depend on for colour resolution.

A `Theme(data: ThemeData.dark(...))` builder is injected below `CupertinoApp`
so that any `Scaffold` widgets in demo pages continue to receive proper Material
theming (background colour, text defaults).

## 🧹 Example app — `GlassMenu` demo controls

Added text-scale slider (1.0×–3.0×) and light/dark theme toggle to the menu
demo. Also added `GlassMenuLabel`, `GlassMenuDivider`, and a destructive
`GlassMenuItem` to the menu items so their theme colour inheritance can be
visually verified.

---

# 0.14.2

## 🧹 Material Artifact Purge

Replaced internal Material primitives with Cupertino-native equivalents for
better iOS 26 fidelity. No public API changes.

- **Tap feedback:** `InkWell` → `GestureDetector` + iOS-style opacity highlight
  in `GlassListTile` and `GlassActionSheet`.
- **Icons:** `Icons.chevron_right`, `Icons.add`, `Icons.remove`, `Icons.info_outline`
  → `CupertinoIcons` equivalents in `GlassListTile` and `GlassStepper`.
- **Colours:** Hardcoded `Colors.green` / `Colors.red` → `CupertinoColors.systemGreen`
  / `CupertinoColors.destructiveRed` across `GlassSwitch`, `GlassBadge`,
  `GlassWizard`, `GlassDialog`, `GlassMenuItem`, and `GlassFormField`.

---

# 0.14.1

## 🐛 Fixed — `GlassScaffold` black background

`GlassScaffold` with no `background:` widget was forcing the inner `Scaffold` to
`Colors.transparent`, rendering black instead of `Theme.scaffoldBackgroundColor`.
Added a `backgroundColor: Color?` parameter; the scaffold now defaults to the
theme colour when no explicit background is provided.

## ✨ Improved — Cancel icon size & customisation

The dismiss `×` button in `GlassSearchableBottomBar` was hardcoded to `size: 16`,
which felt undersized compared to iOS 26. Default bumped to `24`. Both
`GlassSearchBar` and `GlassSearchBarConfig` now expose `cancelIconSize` and
`cancelIcon` so the icon size and glyph are fully overridable.

## ✨ New — `GlassPopover`

A new overlay widget that presents **custom content** in a glass container with
the same liquid morph animation as `GlassMenu`. Use it for tooltips, mini forms,
preview cards, colour pickers, or any content that should appear in a glass
popover — without being limited to a list of menu items.

`GlassPopover` shares `GlassMenu`'s liquid teardrop expansion, spring physics,
auto-positioning, and screen-edge clamping. The `contentBuilder` receives a
`close` callback so popover content can dismiss itself.

```dart
GlassPopover(
  trigger: GlassIconButton(
    icon: Icon(CupertinoIcons.info_circle),
    onPressed: null, // handled by GlassPopover
  ),
  contentBuilder: (context, close) => Padding(
    padding: EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Profile Details',
          style: TextStyle(color: Colors.white, fontSize: 16)),
        SizedBox(height: 12),
        GlassButton(onTap: close, child: Text('Done')),
      ],
    ),
  ),
)
```

**Key parameters:**
- `contentBuilder` — builder for custom popover content, receives a `close` callback
- `trigger` / `triggerBuilder` — the widget that opens the popover on tap
- `popoverWidth` / `popoverHeight` — size control (height defaults to intrinsic)
- `alignment` — manual `GlassMenuAlignment`, or `null` for auto-detect
- `autoAdjustToScreen` — screen-edge clamping (on by default, with 12px padding)
- `barrierDismissible` — whether tapping outside closes the popover (default: true)
- `onOpen` / `onClose` — lifecycle callbacks
- Full `LiquidStretch` and `GlassGlow` support

# 0.14.0

## ⚠️ Breaking — `GlassAppBar` redesigned as pure layout widget

`GlassAppBar` has been fundamentally redesigned from a `StatefulWidget` with its own glass rendering to a lightweight `StatelessWidget` that serves purely as a layout container. This matches iOS 26's actual navigation bar pattern where the bar itself is transparent and glass effects belong on individual interactive elements.

**Removed parameters:**
- `settings` — glass surface settings (the bar no longer renders glass)
- `quality` — glass quality selector
- `useOwnLayer` — layer isolation control
- `scrollController` — scroll-driven glass transition
- `scrollEdgeThreshold` — scroll fade threshold

**New parameter:**
- `buttonSettings: LiquidGlassSettings?` — provides default glass settings to all descendant `GlassButton` widgets via `DefaultButtonSettings` (a new `InheritedWidget`). Individual buttons can still override with their own `settings`.

**Migration:**

```dart
// Before (0.13.x) — scroll-driven glass bar:
GlassAppBar(
  title: Text('Title'),
  scrollController: _ctrl,
  scrollEdgeThreshold: 50.0,
  settings: LiquidGlassSettings(blur: 15),
  quality: GlassQuality.premium,
)

// After (0.14.0) — transparent layout bar:
GlassAppBar(
  title: Text('Title'),
  buttonSettings: LiquidGlassSettings(
    glassColor: Color(0x33FFFFFF),
    thickness: 20,
  ),
)
// Use GlassScaffold.header + headerScrollController for fading headers.
```

Apps that relied on `GlassAppBar.scrollController` for scroll-driven glass should migrate to `GlassScaffold` with its `header` / `headerScrollController` parameters (see below).

## ✨ New — `GlassScaffold` — one-widget page layout

A brand new scaffold that replaces the manual assembly of `GlassPage` + `Scaffold` + `GlassScrollEdgeEffect` + `Stack` with a single widget. Handles z-ordering (bars always above body), edge fading, safe-area padding, and glass layer setup automatically.

### `header` + `headerScrollController` + `headerFadeDistance`

A fixed header widget positioned below the status bar that fades out as the user scrolls — matching the iOS 26 large-title pattern used by Apple Music ("Listen Now"), Apple Podcasts, and similar apps.

```dart
GlassScaffold(
  header: Text('Listen Now', style: largeTitle),
  headerScrollController: _scrollController,
  headerFadeDistance: 60.0,
  body: CustomScrollView(
    controller: _scrollController,
    slivers: [...],
  ),
)
```

The header is wrapped in `IgnorePointer` only when fully faded (opacity == 0), so tappable elements remain interactive at full visibility.

### `bodyOverlays`

Optional list of widgets rendered between the body and the navigation bars in z-order. Designed for floating elements like Apple Music's play-bar pill that need to render above scrollable content but below the bottom bar.

```dart
GlassScaffold(
  bodyOverlays: [
    AnimatedPositioned(
      bottom: isMiniMode ? miniBottom : aboveBarBottom,
      left: 20, right: 20,
      child: PlayBarPill(),
    ),
  ],
  body: scrollContent,
)
```

### `AnnotatedRegion` status bar fix

`GlassScaffold` now wraps the internal `Scaffold` in an `AnnotatedRegion<SystemUiOverlayStyle>` so that the `statusBarStyle` setting correctly overrides `CupertinoPageRoute`'s own region. Previously, pages without a `GlassAppBar` could lose their status bar icon styling when pushed via `CupertinoPageRoute`.

### Improved isolation strategy

`GlassScaffold` now wraps app bar and bottom bar in `GlassIsolationScope(isolated: false, defaultQuality: GlassQuality.premium)` instead of the previous `GlassIsolationScope(isolated: true)`. This means bar buttons join the page-level glass blend group (shared backdrop capture) rather than creating their own layers — saving GPU cost. Stack paint order already guarantees bars render on top of body content.

### Stable `ValueKey`s on stack children

All conditional children (header, app bar, bottom bar) now have explicit `ValueKey`s so Flutter tracks them by identity rather than position. This prevents unmount/remount cycles (and loss of animation state) when toggling the header on and off.

> See `example/lib/demos/nav_bar_patterns_demo.dart` for complete `GlassScaffold` usage patterns.

## ✨ New — `GlassIsolationScope.defaultQuality`

`GlassIsolationScope` gains a `defaultQuality: GlassQuality?` parameter that provides a quality hint for descendants without requiring explicit `quality:` on each widget. This is separate from `isolated` — a scope can be de-isolated (for grouping) while still providing a premium quality default.

`GlassThemeHelpers.resolveQuality` now checks `scopeDefault` and skips inherited page-level quality when a scope provides a `defaultQuality`. This fixes a regression where bar buttons inside `GlassScaffold` would inherit the page's `standard` quality instead of getting the bar's intended `premium`.

## ✨ New — `DefaultButtonSettings` InheritedWidget

A new `InheritedWidget` in `glass_app_bar.dart` that provides default `LiquidGlassSettings` to descendant `GlassButton` widgets. `GlassButton` now checks `DefaultButtonSettings.of(context)` as a fallback between explicit `settings` and inherited layer settings.

## ✨ New — `AdaptiveGlass` interactive auto-promotion

`AdaptiveGlass` now automatically promotes interactive elements (`isInteractive: true`) to their own compositing layer in premium mode. This gives buttons the prominent independent refraction that matches iOS 26's button design, rather than softly blending them into the page blend group. The own-layer wrapper de-isolates children via `GlassIsolationScope(isolated: false)` so nested glass (e.g. tab items inside a bottom bar) groups correctly with the button's layer.

## 🐛 Fix — `GlassBottomBar` extra button z-order

Fixed a compositing z-order issue where the jelly tab indicator would incorrectly render behind the extra trailing button. The internal layout has been restructured from a `Row` to a `Stack` with explicit paint ordering — the extra button is painted first (bottom of z-order), and the tab indicator is painted last (top). This matches the existing pattern in `GlassSearchableBottomBar`.

## 🐛 Fix — `GlassSearchableBottomBar` pill z-order

Fixed the paint order of the search pill and tab pill in `GlassSearchableBottomBar`. The search pill is now painted first (bottom of stack) and the tab pill last (top), so the glass indicator correctly renders on top when it overlaps the search pill during tab transitions.

## 🐛 Fix — `mounted` guards in gesture handlers

Added `if (mounted)` guards before every `setState()` call in `TabDragGestureMixin`, `TabIndicator`, and `SearchableTabIndicator`. Pointer events (`onPointerDown`, `onPointerUp`, `onPointerCancel`) and drag gesture callbacks can fire after the widget has been unmounted during rapid tab switching or page transitions, causing `setState() called on disposed widget` exceptions in debug mode. These guards are zero-cost safety nets.

## 🔄 Changed — Nav bar patterns demo

Removed three `GlassAppBar` demo patterns that used the now-deleted scroll-driven glass API:
- ~~Scroll-Driven Glass~~ (transparent → glass on scroll)
- ~~Static Glass~~ (always-on glass surface)
- ~~Large Title Glass on Scroll~~ (combined collapsing + glass materialisation)

Added a new "Fade Header (No App Bar)" pattern demonstrating the `GlassScaffold.header` fade approach (Apple Music / Podcasts style).

## 🔄 Changed — Example app restructured

### Showcase app uses `GlassScaffold`
The main showcase app (`main.dart`) now uses `GlassScaffold` instead of manually composing `GlassPage` + `Scaffold` + `bottomNavigationBar`. Added a fourth tab ("Examples") and redesigned the Widgets tab with a 2-column card grid.

### Apple demos migrated to `GlassScaffold`
All four Apple demo apps have been migrated from manual `Scaffold` + `Stack` + `GlassScrollEdgeEffect` composition to `GlassScaffold`:

- **Apple Messages** — `GlassScaffold` handles positioning, z-ordering, and edge fading automatically. 8 lines changed.
- **Apple Music** — uses `GlassScaffold.header` for the "Listen Now" fade header, `bodyOverlays` for the floating play pill. Major simplification (294 lines changed).
- **Apple News** — migrated to `GlassScaffold`. Removed unnecessary nested `Stack`. 57 lines changed.
- **Apple Podcasts** — uses `GlassScaffold.bodyOverlays` for the mini-player pill. 372 lines changed.

### Category pages re-indented
All 6 showcase category pages (containers, feedback, input, interactive, overlays, surfaces) have been re-indented for consistency. No functional changes.


## 🐛 Fix — Impeller backdrop visual corruption

Fixed a critical rendering issue where `GlassAppBar` buttons would lose their glass background (rendering as invisible) when multiple `LiquidGlassLayer`s shared a single root `BackdropGroup` (via `GlassBackdropScope`). On Impeller, sharing a `BackdropKey` across multiple `RepaintBoundary` layers caused the engine to bind stale or incorrect backdrop textures.

**Root cause:** The shared `BackdropGroup` architecture assumed that all glass surfaces could safely share a single GPU backdrop capture. On Impeller's tile-based renderer, this created a race between layers trying to use the same `BackdropKey`, causing visual corruption (backgrounds vanishing, ghost artifacts during route transitions).

**Fix:** Each `LiquidGlassLayer` now creates its own isolated `BackdropGroup` → `RepaintBoundary` subtree. This ensures every glass surface captures only its own clipped bounding box — a ~30× reduction in GPU bandwidth compared to the previous full-screen capture, and eliminates cross-layer texture conflicts entirely.

## ⚠️ Deprecated — `GlassBackdropScope`

`GlassBackdropScope` is now a no-op and can be safely removed from your widget tree. Each glass layer manages its own backdrop isolation automatically. `GlassPage` continues to work exactly as before — no migration needed for apps using `GlassPage`.

Apps using `GlassBackdropScope` directly will see a deprecation warning but will compile and run without issues. Remove the widget at your convenience; it will be deleted in 1.0.0.

## 🔄 Changed — `GlassInteractionSettings` is now the canonical interaction API

`GlassInteractionSettings` (introduced in 0.13.0) is now the recommended way to configure all interaction physics app-wide. Pass it via `GlassThemeData.interaction` inside `LiquidGlassWidgets.wrap()`:

```dart
runApp(LiquidGlassWidgets.wrap(
  child: const MyApp(),
  theme: GlassThemeData(
    interaction: GlassInteractionSettings(
      stretch: 0.2,              // subtler drag-following globally
      interactionScale: 1.03,    // less scale-up on press
      resistance: 0.01,          // drag damping factor
      anchorStretch: true,       // iOS 26 rubber-band from anchor
      anchorStretchSettings: AnchorStretchSettings(
        intensity: 0.8,
        squashFactor: 0.15,
      ),
    ),
  ),
));
```

Set `stretch: 0.0` to disable drag-following app-wide while keeping press-scale. Individual widgets can still override any value via their own `stretch:` / `interactionScale:` parameters.

---

# 0.13.0

## ✨ New — Anchor Stretch, Ambient Light, and Interaction Physics

### `AnchorStretchSettings` — fine-tuned stretch feel

A new configuration class for `LiquidStretch` that controls how widgets deform when pressed and dragged. Widgets now stretch *from their anchor point* toward the drag direction — matching iOS 26 button physics where the surface rubber-bands from its resting position rather than free-following the finger.

```dart
GlassButton(
  anchorStretchSettings: AnchorStretchSettings(
    intensity: 0.8,       // more stretchy
    squashFactor: 0.3,    // perpendicular compression
    translationDamping: 0.15, // center-shift toward finger
    bounciness: 0.2,      // elastic snap-back overshoot
  ),
)
```

All parameters have sensible defaults matching iOS 26 behaviour. Most developers won't need to change them.

### `GlassButton.ambientBaseLight` — surface luminosity

A subtle white overlay (default `0.08`) applied during press/drag interactions. Simulates iOS 26 surface luminosity — when the directional glow tracks off-edge, the button still maintains a faint lit appearance rather than going completely dark.

### `GlassButton.persistPressOnDrag`

Controls whether the pressed visual state persists when the user's finger drags outside the button bounds. Defaults to `true`, matching iOS 26 behaviour where buttons stay visually pressed during drag-off and only release on pointer-up. Set to `false` for the traditional behaviour where leaving the hit-test area cancels the press.

### `GlassPage.settings` — page-level glass configuration

`GlassPage` now accepts an optional `settings: LiquidGlassSettings` parameter and internally wraps its child in an `AdaptiveLiquidGlassLayer`. This means all glass widgets inside the page (`GlassAppBar`, `GlassCard`, `GlassButton`, etc.) automatically inherit the page's glass settings — no need to set `useOwnLayer: true` or pass `settings:` to each widget individually.

```dart
GlassPage(
  settings: LiquidGlassSettings(
    glassColor: Color.fromRGBO(28, 28, 30, 0.8),
    thickness: 30,
    blur: 4,
  ),
  child: Scaffold(...),
)
```

When `settings` is null, the layer inherits from `GlassTheme` or uses defaults.

### `GlassScaffold` — comprehensive structural layer

A new structural widget that coordinates interactions between `GlassAppBar`, `GlassBottomBar`, and the page body. It automatically handles edge-to-edge layout, scroll bleeding, and isolates glass rendering layers for maximum performance. This replaces the need to manually compose `AdaptiveLiquidGlassLayer` and `GlassIsolationScope` at the page root.

### `GlassInteractionSettings` Theme

Added a dedicated theme extension to globally configure interaction physics across all glass widgets — stretch, press scale, drag resistance, anchor stretch, and anchor stretch fine-tuning. No more passing interaction parameters to every widget manually.

```dart
GlassThemeData(
  interaction: GlassInteractionSettings(
    stretch: 0.2,              // subtler drag-following globally
    interactionScale: 1.03,    // less scale-up on press
    resistance: 0.01,          // drag damping factor
    anchorStretch: true,       // iOS 26 rubber-band from anchor
    anchorStretchSettings: AnchorStretchSettings(
      intensity: 0.8,
      squashFactor: 0.15,
    ),
  ),
)
```

Set `stretch: 0.0` to disable drag-following app-wide while keeping press-scale. Individual widgets can still override any value.

## 🐛 Fixes & Improvements

### Wide Button Stretch Distortion
Fixed a rendering artifact where very wide `GlassButton`s would exhibit severe shape distortion at the extreme edges during horizontal stretch physics.ts.

### `GlassSearchBarConfig.cursorColor` — cursor follows Flutter theme by default

Thanks to [@jfhair](https://github.com/jfhair) for [PR #71](https://github.com/sdegenaar/liquid_glass_widgets/pull/71). 🙏

`GlassSearchableBottomBar`'s expanded search field now exposes a `cursorColor` knob via `GlassSearchBarConfig`, and the default behaviour aligns with Flutter convention — the cursor follows the standard theme-resolution chain (`Theme.of(context).textSelectionTheme.cursorColor` → `CupertinoTheme.primaryColor` on iOS → `Theme.of(context).colorScheme.primary`) rather than being hard-coupled to `textColor`.

Apps that want the previous behaviour — cursor matching `textColor` — can opt in explicitly:

```dart
GlassSearchBarConfig(
  textColor: Colors.white,
  cursorColor: Colors.white,  // ← previously implicit
)
```

> **⚠ Breaking change.** Apps that set a `textColor` and rely on the cursor implicitly matching it will see their cursor colour change to whatever their `Theme.of(context).colorScheme.primary` is (typically `Colors.blue` if untouched). Two-line migration above.

## 🐛 Fix — Premium stretch edge clipping

Premium-quality `GlassButton` could exhibit jagged rasterization edges during stretch deformation. The Impeller `LiquidGlassLayer` rasterizes at its native resolution, which doesn't perfectly align with the deformed shape boundary during stretch.

Fixed by wrapping the premium glass surface in a vector `ClipPath` at the shape boundary. This renders at screen resolution every frame while preserving full refraction, chromatic aberration, and 3D specular — no quality downgrade needed.

## 🐛 Fix — Mali GPU crash guard

`render_liquid_glass_geometry.dart` now guards against zero and negative dimensions in both `render()` and `renderAsync()`. During jelly animations or rapid layout transitions (modal expansion, tab switching), `matteBounds` can momentarily collapse to zero dimensions — producing an invalid GPU texture request that crashes Mali drivers.

The fix returns a minimal 1×1 fallback cache for zero-dimension frames. Additionally, `matte.toImageSync()` is wrapped in a `try/catch` to handle Mali driver failures gracefully — returning a safe fallback instead of crashing the app. The next paint frame rebuilds the geometry with valid dimensions automatically.

## 🐛 Fix — Searchable bottom bar collapsed shape

The collapsed search button and tab indicator in `GlassSearchableBottomBar` used `LiquidRoundedSuperellipse` even when collapsed to a square. A superellipse with `borderRadius: 32` on a 50×50 square has subtle flat segments between the arcs — invisible at rest but clearly distorted during stretch deformation.

Fixed by switching to `LiquidOval` when constraints are square (within 2px tolerance), which renders a mathematically perfect circle that stretches uniformly. During the collapse animation (when the width is still wider than the height), the superellipse is used to avoid a squashed oval appearance.

## 🎨 Visual — iOS 26 thin glass defaults

The three default theme variants have been standardised to match the thin, refractive glass aesthetic of iOS 26:

| Property | Dark | Light | Minimal |
|----------|------|-------|---------|
| thickness | 40 → **10** | 20 → **12** | 30 → **10** |
| blur | 5 → **4** | 6 → **5** | 12 → **8** |
| lightIntensity | 1.5 → **0.7** | 1.2 → **0.85** | unchanged |
| lightAngle | unset → **135°** | unset → **135°** | unchanged |
| chromaticAberration | unset → **0.01** | 0.3 → **0.02** | unchanged |

> **⚠ Visual change.** Apps using `GlassThemeVariant.dark`, `.light`, or `.minimal` without explicit `LiquidGlassSettings` overrides will see thinner, subtler glass. This is intentional — the previous defaults were heavier than the native iOS 26 aesthetic. If you prefer the heavier look, set explicit `thickness` and `blur` values in your `GlassThemeData`.

## ⚠️ Semi-Breaking — `GlassAppBar` transparent by default

`GlassAppBar` now renders a **transparent** navigation bar by default — no glass surface, no specular rim. This matches iOS 26's actual navigation bar pattern where the glass effect is on individual buttons, not the bar itself.

Previously, `GlassAppBar` always wrapped its content in an `AdaptiveGlass` surface with `LiquidGlassSettings(blur: 15)`. This created a visible glass rectangle behind the title and actions — a Material-style app bar with glass paint, not an iOS 26 navigation bar. A better version of this to come next

To opt in to a glass background (e.g. for scroll-edge transitions), pass explicit `settings`:

```dart
// Before (0.12.x) — glass was always on:
GlassAppBar(title: Text('Title'))

// After (0.13.0) — transparent by default:
GlassAppBar(title: Text('Title'))  // transparent, iOS 26 style

// Opt-in glass background:
GlassAppBar(
  title: Text('Title'),
  settings: LiquidGlassSettings(blur: 15, thickness: 10),
)
```

Additionally, `quality` now defaults to `null` (inherits from ambient scope) instead of `GlassQuality.premium`.

## 🎨 Visual — Specular rim refinement

Standard/minimal quality glass surfaces now render a more refined specular inner-border rim:

- **True inner border** — the specular stroke is now clipped to its inner half via `_ShapeClip`, creating an optically correct glass-edge reflection instead of a center-straddling stroke that bleeds outside the shape boundary.
- **Organic overlay blending** — `BlendMode.overlay` replaces `BlendMode.srcOver`, so the rim reacts to the background colour underneath rather than appearing as a flat white line. Darker backgrounds produce subtler rims; lighter backgrounds produce brighter ones.
- **Flat-edge suppression** — shapes with `borderRadius: 0` (used by `GlassAppBar`, `GlassSideBar`, `GlassToolbar`) no longer render the specular rim. On full-width flat surfaces, the rim looked like a Material divider line rather than an internal glass reflection.

Only affects standard and minimal quality. Premium quality uses Impeller's native `LiquidGlassLayer` which has its own refraction-based edge rendering.

## ⚡ Performance — Quality adapter tuning

- **Faster degradation** — Phase 3 runtime monitoring now triggers a quality step-down after 2 consecutive over-budget windows (previously 3), reducing reaction time from ~6 seconds to ~4 seconds. This means devices that genuinely can't sustain their assigned quality level are protected sooner.
- **Documentation updated** — removed provisional calibration warnings from warmup threshold docs. The 20ms premium / 28ms standard thresholds are now considered validated.

## ⚠️ Semi-Breaking — `LiquidStretch.resistance` default

The default `resistance` value for `LiquidStretch` has changed from `0.08` to `0.01`. This makes all stretch interactions feel more responsive and fluid — closer to the iOS 26 native feel. The previous value was overly dampened.

All widgets using `LiquidStretch` without explicitly setting `resistance` (including `GlassButton`, `GlassCard`, `GlassContainer`, `GlassMenu`) will feel stretchier. To restore the previous behaviour:

```dart
LiquidStretch(
  resistance: 0.08, // previous default
  child: ...,
)
```

## 🧪 Tests — 1898 passing (+124 new)

- New `GlassButton` tests: `persistPressOnDrag` true/false behaviour, default values, cancel paths.
- New `GlassSearchBarConfig.cursorColor` tests: default null, explicit value, independence from `textColor`.
- Updated `glass_quality_adapter` tests for `degradeWindowCount: 2`.
- Updated stretch tests for new `resistance` default.
- Updated `GlassAppBar` defaults test for transparent-by-default change.
- Updated golden tests for specular rim flat-edge suppression.

## 📦 Example app

- **Keypad lock screen demo** — new full-screen demo showcasing `GlassButton` in a PIN-entry layout.
- **Restructured showcase pages** — all category pages (containers, feedback, input, interactive, overlays, surfaces) reorganised for cleaner presentation. More work to come...

---

# 0.12.8

## 🐛 Fix — `GlassTextField` reverted to v0.12.4 + icon drift fix

- **Reverted to v0.12.4** — restored exact line-count and layout logic. The v0.12.6–0.12.7 changes introduced regressions (line breaks at wrong character boundary, icons pinned to container bottom).
- **Fixed icon drift under system text scaling** — in fixed-height mode, icons are now always centred relative to the container rather than relative to the text row. This prevents icons from shifting position when users change system text scaling. In dynamic-height mode (no `height` parameter), `iconAlignment` is respected as before.

Thanks [@g3mf0r](https://github.com/g3mf0r) for the detailed testing.

---

# 0.12.7

## 🐛 Fix — `GlassTextField` icon alignment (retained) + line-count regression fix

- **`iconAlignment: .end` no longer drifts under system Large Text.** The `Center` widget wraps only the `TextField`, not the entire icon `Row`, so `CrossAxisAlignment.end/.start` works correctly against the full container height. *(retained from 0.12.6)*
- **Reverted line-count measurement** back to `renderBox.size.width` (the v0.12.4 approach). The v0.12.6 `RenderEditable` width change caused line breaks to fire a couple of characters early. Thanks [@g3mf0r](https://github.com/g3mf0r) for catching this.

---

# 0.12.6

## 🐛 Fix — `GlassTextField` icon alignment and line-count accuracy

- **`iconAlignment: .end` no longer drifts under system Large Text.** The `Center` widget now wraps only the `TextField`, not the entire icon `Row`, so `CrossAxisAlignment.end/.start` works correctly against the full container height.
- **Line-count measurement is now pixel-perfect.** `_measureLineCount` walks the render tree to find the actual `RenderEditable` and uses its layout width (which accounts for the internal `_caretMargin` ≈ 3 px). Falls back gracefully if the render walk fails.

---

# 0.12.5

## ✨ New — `GlassMenu.onClose` callback

Added `onClose: VoidCallback?` to `GlassMenu`. Fires when a close is triggered
(barrier tap, trigger re-tap, or item selection), before the animation completes.
Useful for synchronising external state such as a `GlassMorphController`.

Thanks to [@g3mf0r](https://github.com/g3mf0r) for the contribution ([#67](https://github.com/sdegenaar/liquid_glass_widgets/pull/67)).

---

# 0.12.4

## 🐛 Fix — `GlassTextField` layout and reactivity

### `onLineCountChanged` fires correctly under fixed-height constraints

The `onLineCountChanged` callback silently stopped firing after the first
measurement when the field was inside a fixed-height container (e.g.
`SizedBox(height: 46)` or `height: 46` on the field itself). The internal
guard used `size == _lastTextFieldSize` — but a fixed outer height keeps the
`RenderBox` size constant, so the guard always exited early after the first
call. The fix replaces the size-equality guard with a `(text, constrainedWidth)`
guard: the callback fires whenever the text content or available wrapping width
changes, regardless of what the outer height is doing.

This also resolves the stale-state reactivity bug where `_lines` stored in
`State` stopped updating `borderRadius` after re-opening the keyboard.

### Placeholder and text stay vertically centred under system Large Text

When `height` is specified (fixed-height mode), the outer `padding`'s vertical
component was applied inside the `SizedBox`, pushing placeholder text and icons
downward when the user enabled a large system font. The field now strips
vertical padding in fixed-height mode and centres the text row via `Align`,
matching the behaviour of `GlassSearchBar`. The `padding` parameter's
horizontal values are unchanged.

## ✨ New — `bottom` panel for `GlassTextField` and `GlassTextArea`

Both widgets now accept an optional `bottom` widget that renders below the text
area inside the same glass card. Use it to build the "rich composer" pattern — a
text input on top with an action bar, attachment strip, or formatting toolbar
below, all sharing one glass surface:

```dart
GlassTextField(
  maxLines: 5,
  minHeight: 44,
  maxHeight: 160,
  bottom: Padding(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: [
        IconButton(icon: Icon(Icons.attach_file), onPressed: _attach),
        const Spacer(),
        IconButton(icon: Icon(Icons.send), onPressed: _send),
      ],
    ),
  ),
)
```

The panel renders inside the glass surface alongside the text area.
Callers can add a `Divider` between the text area and the panel if a visual
separator is desired. Not available on `GlassTextField.search` (that
constructor is single-line only; `bottom` is always `null` there).

---

# 0.12.3

## 🎨 Visual — Slider & Switch thumb refraction tuning

- **`GlassSlider` thumb** — increased `refractiveIndex` (1.15 → 1.3) and `thickness` (10 → 13) for a more pronounced glass lens feel. Reduced `glassColor` alpha (0.1 → 0.08), `lightIntensity` (2.0 → 1.8 premium), `baseAlphaMultiplier` (0.2 → 0.08 premium), and `edgeAlphaMultiplier` (0.4 → 0 premium) for a cleaner, more transparent thumb.
- **`GlassSwitch` thumb** — reduced `refractiveIndex` (1.15 → 1.12) and `glassColor` alpha (0.1 → 0.08) for subtler refraction.
- **Material fade via `Opacity` widget** — slider thumb now uses widget-level `Opacity` (matching `GlassSwitch` pattern) instead of color alpha for the press-down fade. Critical for Impeller: properly removes the child from the compositing tree so native refraction shows through.

## ⚡ Jelly physics — spring-based velocity

- **`GlassSlider` jelly** — replaced raw `_velocity` tracking with a `SingleSpringController` feeding `buildJellyTransform`. Produces smooth squash/stretch with natural deceleration and elastic bounce-back, matching the tab bar / bottom bar pill feel. `maxDistortion` raised (0.25 → 0.6), `velocityScale` lowered (30 → 2) to account for the spring's normalised 0→1 position range.

---

# 0.12.2

## ✨ New — `GlassTextField` enhancements

Three community-requested features for `GlassTextField` (and `GlassTextArea`):

### Explicit size properties

`height`, `minHeight`, and `maxHeight` give direct control over the field's dimensions — no wrapping `SizedBox` needed:

```dart
// Fixed height — matches GlassSearchBar's 44pt:
GlassTextField(height: 44, placeholder: 'Search')

// Constrained range — grows with content:
GlassTextField(minHeight: 44, maxHeight: 200, maxLines: 10)
```

`height` is mutually exclusive with `minHeight`/`maxHeight` (assertion enforced).

### `onLineCountChanged` callback

Fires whenever the number of **rendered** lines changes (accounting for text wrapping, not `\n` characters). Also fires on initial build. Uses the `TextField`'s own `RenderBox` height — no external `TextPainter` math, so it works correctly with text scaling and system accessibility settings.

```dart
GlassTextField(
  maxLines: 6,
  onLineCountChanged: (lines) {
    setState(() => _borderRadius = lines > 1 ? 8.0 : 20.0);
  },
)
```

### `iconAlignment` parameter

Controls where prefix/suffix icons sit when the field spans multiple lines:

```dart
// Pin send button to bottom — chat composer pattern:
GlassTextField(
  maxLines: 6,
  iconAlignment: CrossAxisAlignment.end,
  suffixIcon: Icon(Icons.send),
)
```

Accepts `CrossAxisAlignment.start` (top), `.center` (default), or `.end` (bottom). No visible effect on single-line fields.

All three features are forwarded through `GlassTextArea`.

### `GlassTextField.search` named constructor

A new convenience constructor that pre-configures `GlassTextField` with compact search-bar defaults: `height: 44`, `iconSpacing: 8`, `padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)`, `borderRadius: 22`, and `textInputAction: TextInputAction.search`. Eliminates the boilerplate previously required to match `GlassSearchBar` visuals:

```dart
GlassTextField.search(
  placeholder: 'Search messages…',
  prefixIcon: Icon(CupertinoIcons.search, size: 20),
  useOwnLayer: true,
)
```

`GlassSearchBar` now uses this constructor internally, reducing duplicated decoration code.

## 🐛 Fix

- **`onLineCountChanged` now fires on programmatic controller changes** — Previously the callback only responded to physical keyboard input (`TextField.onChanged`). Setting `controller.text = '...'` or calling `controller.clear()` (e.g. in a chat "Send" handler) did not re-measure the line count. The widget now actively listens to the `TextEditingController` and re-measures on any text mutation.

- **Suffix icon spacing now respects `iconSpacing`** — The gap before the suffix icon was hard-coded to 12px while the prefix icon correctly used `widget.iconSpacing`. Both sides now use the same parameter.

# 0.12.1

## 🐛 Fix — eliminate rectangular blur halo over PlatformViews (iOS Impeller)

`LightweightLiquidGlass` and `_FrostedFallback` previously wrapped their glass surface in `ClipPath(ShapeBorderClipper(...))`. When the parent was an iOS PlatformView (e.g. `mapbox_maps_flutter` `MapWidget`, `video_player` on iOS), the descendant `BackdropFilter`'s rectangular blur output leaked past the rounded clip — visible as a faint square halo around the rounded glass shape, most obvious when light backdrop content scrolled underneath.

Flutter framework [PR #177551](https://github.com/flutter/flutter/pull/177551) (merged Dec 2025, shipped in 3.41.0-0.0.pre+) fixed this at the engine level by forwarding `ClipRRect` clip data to the iOS PlatformView mutator stack — but **only `ClipRRect`, not `ClipPath`**, even when the path inside is mathematically a rounded rect.

This release routes shapes that resolve to a `RoundedRectangleBorder` (i.e. `LiquidRoundedSuperellipse`, `LiquidVerticalRoundedSuperellipse`) through `ClipRRect` instead of `ClipPath`. The engine fix now triggers and the halo disappears for those shapes.

`LiquidOval` is intentionally NOT routed through `ClipRRect` — empirically the engine fix doesn't forward `ClipRRect` with `circular(double.infinity)` nor a `LayoutBuilder`-computed finite radius on the `LiquidOval` path. Callers that need a halo-free circular glass surface over a PlatformView should use `LiquidRoundedSuperellipse(borderRadius: size / 2)` instead, which renders identically on a square widget and triggers the engine fix.

Closes upstream Flutter [#175048](https://github.com/flutter/flutter/issues/175048) and [#115926](https://github.com/flutter/flutter/issues/115926) for `liquid_glass_widgets` users.

*Based on [PR #61](https://github.com/sdegenaar/liquid_glass_widgets/pull/61) by [@jfhair](https://github.com/jfhair).*

# 0.12.0

## ✨ New

### `LiquidGlassWidgets.wrap()` — `theme` parameter

`wrap()` now accepts an optional `GlassThemeData? theme` parameter. When provided, it wraps the child in a `GlassTheme` — eliminating the need for a separate `GlassTheme` widget in your tree.

### `LiquidGlassSettings.standardOpacityMultiplier`

A new multiplier applied to the glass colour alpha when rendering in Standard mode. This allows tuning Standard 2D compositing opacity to achieve more parity with Premium 3D volumetric refraction without needing separate colour values for each mode.

```dart
LiquidGlassSettings(
  glassColor: Colors.white.withValues(alpha: 0.3),
  standardOpacityMultiplier: 0.4, // Standard renders at 0.3 × 0.4 = 0.12 alpha
)
```

Defaults to `1.0` (no change). Fully interpolated via `LiquidGlassSettings.lerp()` and wired through `copyWith()`.

### `GlassPage` — full-screen glass scaffold

A new full-screen scaffold widget for glass-based layouts. Handles background imagery, status bar styling, and background sampling in a single widget.

`enableBackgroundSampling` defaults to `true` when a `background` widget is provided, and `false` otherwise — so the common case just works without extra configuration.

```dart
GlassPage(
  background: Image.asset('assets/wallpaper.jpg'),
  child: Scaffold(...),
)
```

### Export hygiene

- `glass_page.dart` now uses a `show` clause: only `GlassPage` and `GlassStatusBarStyle` are exported (internal state classes are no longer public).
- `liquid_glass_scope.dart` now uses a `show` clause: only `LiquidGlassScope`, `GlassBackgroundSource`, and `GlassRefractionSource` are exported.

## 🎨 Visual — Standard/Premium parity improvements

### Shader composite improvements (`lightweight_glass.frag`)

The Standard-tier lightweight shader composite logic has been improved for closer visual parity with the Premium Impeller path. Shader rim constants are **unchanged** from 0.11.0 — AdaptiveGlass normalization now handles Premium → Standard scaling in Dart space instead:

- **PATH A** (background texture): now uses `applyGlassColorLW()` — a luminosity-preserving glass tint that matches Premium's colour handling for both chromatic (mint, bronze) and achromatic (white, grey) glass colours.
- **PATH A** ambient darkening: `ambientStrength × 0.25 + 0.08` creates the glass shadow effect that visually separates glass from non-glass, matching what Premium achieves through blur compositing.
- **PATH A** adaptive rim colour: `mix(bgRgb, white, 0.7)` brightens the background at the edge, matching Premium's `getHighlightColor`.
- **PATH A** edge-zone refraction: indicator-style background warping at rounded corners using `smoothstep` edge zone with quadratic falloff — the same proven approach as `interactive_indicator.frag` but scaled for containers. Zero transcendentals (polynomial `smoothstep` + multiplies only). Flat interior pixels naturally produce zero offset. Currently active on surface widgets (`GlassBottomBar`, `GlassTabBar`, `GlassSideBar`, `GlassToolbar`) when a `backgroundKey` is provided; `GlassCard` and `GlassButton` use PATH B and will benefit once `AdaptiveGlass` gains scope-aware background key passthrough.
- **PATH A** unified interactive glow: `uGlowIntensity` press-feedback now applies in PATH A, closing an architectural gap where switch/slider thumbs inside background-sampled containers had no glow.
- **Volumetric depth gradient**: subtle top-to-bottom ambient shading (`+vertCoord × 0.04`) in both PATH A and PATH B creates a natural 3D anchored depth feel, simulating light entering from above. Cost: one multiply + one add per fragment.
- **PATH B** frost floor: 8% minimum material alpha ensures glass surfaces are always visible when `glassColor.a = 0` (Premium default), preventing invisible glass in SrcOver compositing.
- **PATH B** contrast-adaptive rim: shifts rim colour toward mid-grey on bright backgrounds so white-on-white borders remain distinguishable.
- **Directional rim bonus**: a small `0.15 × directionalInfluence × lightIntensity` term adds subtle lit-side variation on top of the constant rim base — matching how Premium's 3D bevel naturally brightens toward the light source.

### Interactive widget transparency tuning

- `GlassSwitch` standard thumb: `baseAlphaMultiplier: 0.0`, `edgeAlphaMultiplier: 0.15` — fully transparent body with subtle edge presence for a cleaner glass look.
- `GlassSlider` standard thumb: `baseAlphaMultiplier: 0.08`, `edgeAlphaMultiplier: 0.1` — minimal body opacity with soft edge glow.

### Elevated widget predictability

Removed the arbitrary `+0.2` alpha boost on elevated widgets inside `AdaptiveGlass`. Elevation is now expressed purely through the shader's `densityFactor` physics, making the opacity response predictable and proportional to user settings.

### Interactive widget normalisation (`GlassEffect`)

Standard-tier interactive indicators (slider thumbs, switch thumbs, segmented control pills) now apply the same normalisation as `AdaptiveGlass` — `thickness × 0.4`, `lightIntensity × 0.6` — preventing the 2D shader from rendering these elements heavier than their Premium counterparts.

## 📦 Example app

- Quality comparison demo background image bundled as a local asset (`example/assets/mountain_landscape.jpg`) — eliminates network dependency and first-frame loading flash.

---

# 0.11.0

## ✨ New — Liquid Morph Engine (new architectural system)

This release introduces the **Liquid Morph Engine** — a standalone, reusable physics and animation system for iOS 26-style liquid glass morphing. It lives in `lib/engine/` and is fully decoupled from any specific widget.

`GlassMenu` is the **first consumer** of the engine. Future widgets (sheets, cards, buttons) will use the same engine to achieve consistent, physics-correct liquid glass transitions throughout the library.

> **Documentation:** [`docs/LIQUID_MORPH_ENGINE.md`](docs/LIQUID_MORPH_ENGINE.md) — full guide covering `GlassMorphController`, `LiquidMorphState`, `LiquidMorphPhysics`, and how to integrate the engine into your own custom widgets.

### Core engine types

| Type | Role |
|---|---|
| `GlassMorphController` | Lifecycle owner — manages the spring, exposes `open()` / `close()` |
| `LiquidMorphState` | Immutable value object — one per frame, contains all render values |
| `MorphPhase` | Semantic lifecycle enum — tells you where in the animation you are |
| `MorphSpeed` | Enum — controls spring stiffness without exposing raw physics constants |
| `LiquidMorphPhysics` | Internal stateless math engine |

### How it works

Two conceptual "blobs" drive every morphing animation:

- **Blob A** (anchor) — the ghost trigger that shrinks away over the first 40 % of the animation, cleanly breaking the liquid bridge.
- **Blob B** (body) — travels from the trigger centre to the widget centre along a J-curve overshoot trajectory, expanding from trigger size to target size.

The SDF metaball shader creates the teardrop neck between the blobs automatically — there is no explicit neck geometry. `LiquidMorphPhysics.compute()` determines each blob's position, scale, and blend factor on every frame.

### `GlassMenu` — first engine consumer

- **Teardrop open animation** · The menu grows from the trigger point along the dual-curve SDF path, producing the iOS 26 "bubble emerging from button" effect.
- **Rubber-band close physics** · On dismiss the teardrop recoils with a critically-damped spring + overshoot tail, matching the tactile snap of native iOS context menus.
- **Velocity-bump alignment** · Spring initial velocity is seeded from touch velocity at release — fast flicks close snappily, slow releases settle deliberately.
- **Handoff latching** · Re-opening during a close animation inherits the in-flight velocity and reverses smoothly — no pop or cut.
- **Blob scaling** · Blob sizes scale relative to trigger size and computed menu height, so short and tall menus receive proportionally correct teardrop curvature.

> **See it live:** The [Apple Messages demo](example/lib/apple_messages/apple_messages_demo.dart) (`cd example && flutter run -t lib/apple_messages/apple_messages_demo.dart`) showcases the morphing engine in a real-world context — tap the menu or **Edit** button at the top of the screen to trigger the `GlassMenu` with full teardrop open/close physics.

### Spring physics refinements

- Critical damping (`ζ = 1.0`) on all spring controllers prevents oscillation on rapid successive opens.
- `interactionScale`, `stretch`, and `stretchResistance` integrate into the morphing path via the same spring solver used by `LiquidStretch`.

## 🐛 Fixes

- **`GlassMenu` — safe area / notch clipping on iOS and Android** · Menu position and maximum height were computed from `MediaQuery.padding`, which is consumed by ancestor `SafeArea` widgets and reports `0` inside a fully-safe tree. Switched to `View.of(context).padding` (raw hardware insets) so the menu is always clamped correctly regardless of `SafeArea` nesting depth. Fixes the menu appearing under the Dynamic Island on iPhone 14 Pro and similar devices.

- **`GlassMenu` (scrollable) — scrolling now works on large menus** · Menus with more items than fit on screen can now be scrolled reliably.

## 🗂 Example restructure — `demos/` suite

The `example/` package has been reorganised for a cleaner public-facing demo experience:

- New `example/lib/demos/` folder containing seven self-contained, copy-pasteable demos:
  - **`glass_menu_demo.dart`** — all 9 `GlassMenuAlignment` positions, scrollable item list
  - **`glass_tab_bar_scrollable_demo.dart`** — scrollable `GlassTabBar` with dynamic tab add
  - **`glass_modal_sheet_demo.dart`** — all sheet states (peek / half / full), Apple Maps peek style
  - **`glass_bottom_bar_demo.dart`** — magic-lens masking with `GlassBottomBar`
  - **`bottom_bar_tab_width_demo.dart`** — `tabWidth` on both bar variants side-by-side
  - **`searchable_bar_demo.dart`** — `GlassSearchableBottomBar` edge cases
  - **`shape_debug_demo.dart`** — `GlassButton` shape visualiser

- **Apple Messages demo** (`example/lib/apple_messages/`) — showcases the Liquid Morph Engine in a full real-world context; tap the menu or **Edit** button at the top to trigger `GlassMenu`.
- `example/lib/modal_sheet_showcase/` removed (file moved to `demos/glass_modal_sheet_demo.dart`).
- Experimental scratchpad scripts moved to git-ignored `example/lib/playground/`.

---

# 0.10.10


Thanks to [@g3mf0r](https://github.com/g3mf0r) for [PR #55](https://github.com/sdegenaar/liquid_glass_widgets/pull/55). 🙏

## ✨ New

- **`GlassMenu` — `menuAlignment` enum** · A new `GlassMenuAlignment` enum (10 values: `none`, `topLeft`, `topCenter`, `topRight`, `centerLeft`, `center`, `centerRight`, `bottomLeft`, `bottomCenter`, `bottomRight`) lets you pin the menu to a specific edge or corner of its trigger instead of relying solely on auto-detection. The enum is now part of the public API surface exported from `glass_menu.dart`.

- **`GlassMenu` — `autoAdjustToScreen` with `menuPadding`** · When `autoAdjustToScreen: true`, the new `menuPadding: EdgeInsets?` parameter applies additional inset constraints so the menu body never clips against device edges.

- **`GlassMenu` — `itemBorderRadius`** · Controls the corner radius of individual menu item cells, independent of the outer `menuBorderRadius`.

## 🐛 Fixes

- **`GlassTabBar` — multi-tab drag jump** · Dragging the indicator across multiple tab widths in a single gesture now snaps to the correct distant tab. The previous implementation only incremented/decremented by ±1 regardless of drag distance, causing the indicator to teleport unexpectedly when the finger crossed more than one tab boundary.

- **`GlassTabBar` — glass refraction during indicator drag** · Refraction and shadow effects are correctly suppressed during the drag animation and restored on settlement, eliminating a visual glitch where the glass distortion would persist after releasing the indicator.

## 🧪 Tests

- Added 4 new `GlassMenu` tests covering `GlassMenuAlignment` enum values, `menuAlignment` parameter, `autoAdjustToScreen` + `menuPadding`, and `itemBorderRadius`.
- Added 2 new `GlassTabBar` tests covering multi-tab drag jump (left and right) to prevent regression of the PR #55 fix.

---

# 0.10.9

Thanks to [@g3mf0r](https://github.com/g3mf0r) for [PR #54](https://github.com/sdegenaar/liquid_glass_widgets/pull/54). 🙏

## ✨ New

- **`GlassTabBar` (scrollable) — jelly physics on indicator drag** · The scrollable indicator pill now feeds real-time drag velocity into the liquid glass shader, producing the same organic stretch-and-settle effect that fixed-mode tabs already had.

## 🐛 Fixes

- **`LiquidGlassWidgets.wrap` — `adaptiveQuality: true` without `adaptiveConfig` permanently locks to `standard`** · The default fallback config was created with `initialQuality: GlassQuality.standard`, which the adapter treats as a skip-Phase-2 signal — immediately jumping to Phase 3 at `standard` without ever running the warmup benchmark. On capable devices (including the iPhone simulator on Apple Silicon) this prevented the adapter from ever discovering that the device can sustain `premium`. Fixed by removing the erroneous `initialQuality` from the fallback; Phase 2 now always runs when no explicit quality is provided.

- **`GlassTabBar` (scrollable) — indicator overflows bar on low tab counts** · The right drag boundary was computed as `viewMax` instead of `viewMax - indicatorWidth`, allowing the pill to slide outside the bar when there were only 2–3 wide tabs. Corrected to `viewMax - targetWidth`.

- **`GlassTabBar` (fixed) — tiny accidental drags switch tabs** · Tab switching on drag-end now requires either a displacement greater than 20 % of the tab width **or** a flick velocity above 400 px/s, preventing unintended switches from small incidental movements.

- **`GlassTabBar` (scrollable) — flick gesture ignored in scrollable mode** · A horizontal flick with sufficient velocity now overrides the nearest-tab distance calculation and advances the indicator in the flick direction, matching the fixed-mode behaviour.

---

# 0.10.8


Thanks to [@g3mf0r](https://github.com/g3mf0r) for [PR #52](https://github.com/sdegenaar/liquid_glass_widgets/pull/52). 🙏

## 🐛 Fixes

- **`GlassTabBar` — indicator drag drift on desktop/web** · The indicator position was accumulated via `delta.dx` additions each frame, causing the pill to visually lag behind the pointer on desktop platforms where pointer events arrive at a higher frequency than the frame budget. Fixed by computing position from the absolute global pointer coordinate on every update event, eliminating accumulated drift.

- **`GlassTabBar` (scrollable) — tab labels hidden behind indicator pill** · The `SingleChildScrollView` (tab labels) and the background pill were inserted in the wrong stack order — labels were painted first, then the pill on top, obscuring them. Fixed by inserting the pill before the labels so labels always paint above the pill (correct z-order).

- **`GlassTabBar` (scrollable) — indicator fly-off past bar edges** · The indicator pill had no boundary clamping in scrollable mode, allowing it to animate outside the visible bar area. Drag offset is now clamped to `[scrollOffset - 35 %, scrollOffset + screen + 35 %]`.

## ✨ New

- **`DividerSettings`** — new optional `dividerSettings` parameter on `GlassTabBar`. Renders animated vertical dividers between tabs with configurable `thickness`, `indent`, `endIndent`, custom `decoration`, animation `duration`/`curve`, and an `isHideAutomatically` flag that fades out dividers adjacent to the active tab. Includes a `copyWith` helper for convenient inline customisation.

- **Grab-to-drag in scrollable mode** — the indicator pill in scrollable mode can now be directly grabbed and dragged to a new tab. Uses a `GestureArenaTeam` (`HorizontalDragGestureRecognizer` as captain + `TapGestureRecognizer`) to correctly win the arena against the `SingleChildScrollView` when the initial touch is within the active indicator's bounds. The scroll view retains natural scrolling behaviour when touching outside the pill.

- **`indicatorShadow`** — new optional `indicatorShadow: List<BoxShadow>?` parameter on `GlassTabBar`. Applies a drop shadow to the resting (solid-colour) indicator pill, improving contrast in light-mode themes where the pill and track share similar colours. The shadow is automatically suppressed during the liquid glass drag animation so it does not interact with the backdrop blur, and restored when the pill returns to its idle state.

---

# 0.10.7


Thanks to [@yukinoaruu](https://github.com/yukinoaruu) for [PR #51](https://github.com/sdegenaar/liquid_glass_widgets/pull/51). 🙏

## 🐛 Fixes

- **`GlassMenu` — trigger button dead zone after closing** · After closing the menu, the trigger button would ignore taps for the duration of the closing spring animation (~95% of travel), forcing the user to wait several seconds before being able to reopen it. Fixed by separating the visual-hide threshold (`0.05`) from the input-block threshold (`0.80`) into two independent booleans: `isButtonVisible` and `isMenuBlocking`. The button now becomes tappable again as soon as the animation drops below 80%, and the morphing glass overlay wraps in `IgnorePointer(ignoring: value < 0.8)` to prevent the contracting container from consuming the tap instead.

---

# 0.10.6

## 🐛 Fixes

- **`GlassBottomBar` — `extraButton` causes bar to float in the middle of the screen** · Wrapped the inner `Row` in a `SizedBox(height: barHeight)` so the `Scaffold.bottomNavigationBar` slot always receives an explicit tight height constraint. Without this, the `Expanded` child introduced by `extraButton` propagated an unbounded height through `LiquidGlassLayer`, causing Flutter to render the bar centred on screen instead of pinned to the bottom edge.

---


# 0.10.5

## ✨ New

- **`SearchableBottomBarController`** — added `openSearch()`, `closeSearch()`, and `isSearchOpen` getter for programmatic search control. Previously the only way to open search was by driving `isSearchActive` from parent state.
- **`GlassTabBar`** — added `maskingQuality` parameter (`MaskingQuality.high` / `MaskingQuality.off`), matching the existing `GlassBottomBar` API. Set to `off` to disable the 8 px jelly-bloom expansion on lower-end devices.
- **`GlassSlider`** — added `interactionBehavior`, `glowColor`, and `glowRadius` for consistent drag-glow customisation across all interactive widgets.
- **`GlassSegmentedControl`** — same `interactionBehavior`, `glowColor`, `glowRadius` params added for API parity with `GlassSlider` and `GlassTextField`.
- **`LiquidGlassWidgets.respectsAccessibility`** — deprecated alias added pointing to `respectSystemAccessibility`. Will be removed in v1.0.

## 🐛 Fixes

- **`GlassTextField`** — fixed a use-after-dispose crash when `focusNode` cycled `null → external → null`. The widget now tracks ownership with an explicit `_ownsNode` flag and correctly creates a fresh internal node on each transition.
- **`GlassTabBar`** — resolved scrollable-mode visual glitches. The indicator now stays perfectly glued to the active tab during scrolling without drifting, uses native "snappy" spring physics for consistent feel, and implements a three-layer rendering architecture so the solid indicator pill cleanly clips at the rounded viewport corners while the 8px jelly bloom expands freely over the tab bar boundaries.

# 0.10.4

A huge, heartfelt thank-you to [@yukinoaruu](https://github.com/yukinoaruu) for [PR #49](https://github.com/sdegenaar/liquid_glass_widgets/pull/49). 🙏

We made a mess of the original 0.10.3 merge of his work — introducing regressions that broke the very things he had so carefully built. He came straight back, fixed every issue, and did it with incredible patience and generosity. This release is entirely his. If you are enjoying `GlassMenu`, it is because of him.

## 🐛 Fixes (regressions from 0.10.3 merge)

- **GlassMenu — full-list rebuilds on every pointer event** · Restored the `_cachedWrappedItems` mechanism that was accidentally dropped. The previous merge caused the entire wrapped-item list to be recreated on each pointer move, resetting pressed/hover states mid-gesture and tanking performance on menus with many items.
- **GlassMenu — selection and hover state precision** · Migrated to a `ValueNotifier` system (`_hoveredIndexNotifier`, `_isDraggingNotifier`). Individual menu items now rebuild in isolation instead of triggering a full `setState` on the entire menu tree, keeping animations at a steady 60 fps.
- **GlassMenu — ghosting on selection pill** · Fixed a double-background artifact where the selected `GlassMenuItem` painted its own hover fill on top of the sliding pill, producing a faint ghost ring. Selected items now transition to `Colors.transparent` instantly.
- **GlassMenu — disabled items could be tapped** · Tapping a disabled item no longer calls `onTap` or closes the menu. The pill highlight correctly skips disabled items during pointer tracking.
- **GlassMenu — double `onTap` firing** · Removed a redundant `onTap` callback in the internal wrapped-item builder that was causing every selection to fire twice.
- **GlassMenu — `RangeError` when item list shrinks while open** · `didUpdateWidget` now clears `_hoveredIndex` when `items.length` decreases, preventing an out-of-bounds crash when the pill tried to measure a deleted item.
- **GlassMenuItem — disabled opacity** · Disabled items now render at `Opacity(0.4)` to match the design spec and test expectations.
- **GlassMenuLabel — hybrid `title`/`child` API** · `GlassMenuLabel` now accepts either a `title` String (rendered as stylised uppercase) or an arbitrary `child` Widget, enabling diverse non-interactive content beyond simple section headers.
- **GlassMenuLabel — `height` default** · Default `height` set to `30.0` so the selection pill cannot drift when items with non-standard font sizes are mixed in.
- **GlassMenu — `glowIntensity` parameter** · Added `glowIntensity` and wired it through to `GlassContainer`, completing the full interaction-glow parameter surface.
- **GlassMenu — `glowOnTapOnly` default corrected** · Default changed to `true` to prevent a permanently stuck glow artefact during scroll and drag gestures.
- **GlassMenu — stretch parameter rename** · Renamed `allowPositiveXStretch` / `allowNegativeXStretch` / `allowPositiveYStretch` / `allowNegativeYStretch` to `allowPositiveX` / `allowNegativeX` / `allowPositiveY` / `allowNegativeY` to align with the `LiquidStretch` API surface.
- **GlassMenu — compositing architecture** · Removed redundant `RepaintBoundary` nodes that were leaving descendant glass layers DETACHED from the compositor scene, and moved `GlassGlow` inside `GlassContainer`'s clip subtree to prevent glow bleed onto the background.

## ⚠️ Breaking — `GlassMenu` stretch parameter renames

The four optional stretch-axis override parameters introduced in 0.10.3 have been renamed:

| 0.10.3 name | 0.10.4 name |
|---|---|
| `allowPositiveXStretch` | `allowPositiveX` |
| `allowNegativeXStretch` | `allowNegativeX` |
| `allowPositiveYStretch` | `allowPositiveY` |
| `allowNegativeYStretch` | `allowNegativeY` |

All four remain optional with `null` defaults (auto-inferred from menu position). Only code explicitly passing the old names needs updating.


