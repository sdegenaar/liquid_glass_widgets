# 1.20.0

## Features

- **Native iOS 26 / 27 selection jelly for `GlassTabBar` and `GlassSegmentedControl` (`indicatorJelly`, `IndicatorJellyPhysics`) (#523, #530):** The indicator now moves like the native `UITabBar` lens instead of squashing into a tall, narrow blob. On a tap the edge facing the destination is pulled ahead while the lens thins; on landing the pill squishes from the trailing side (≈0.95× after one tab, ≈0.8× after four), bulges, and settles in ≈0.75 s without a rebound while preserving native outer edge overhang. During drags an acceleration-driven oscillator fitted to `_UILiquidLensView` stretches on speed-up, relaxes at steady speed, and bulges vertically on deceleration or direction reversal while keeping the top/bottom refractive pinch intact. The resting pill and the selected-icon mask follow the same shape. Every value is tunable through `IndicatorJellyPhysics`, and `IndicatorJellyPhysics.disabled` keeps the classic squash.
- **`GlassThemeData.minimal(...)` convenience constructor (#517 follow-up):** Adds `const GlassThemeData.minimal({style, interaction, brightness})` pairing `GlassThemeVariant.minimalLight` and `GlassThemeVariant.minimalDark` for shader-free `GlassQuality.minimal` theming across light and dark modes (matching `.ios27()`, `.ios26()`, and `.classic()`).

## Bug Fixes

- **`GlassModalSheet` under a `MediaQuery` that isn't the window's size (#525, #526):** The sheet now measures its detents, progress, snap targets and expand-first scroll gate against the `MediaQuery` height it rests by, and converts drags into its own layout pixels. Where the two differed — one side of a half-folded display presented by `show()`, or a page laid out at one width and scaled to the screen — the sheet rested by one height and judged itself by the other: a two-detent sheet at full couldn't scroll its content, a resting half-only sheet with a pixel `halfSize` couldn't either, and drags rubber-banded or fell behind the finger.
- **`GlassMenu` & morph overlays settling after slow frames (#522):** Advance `GlassMorphController.phaseElapsedSeconds` to its settled state when `AnimationController` stops on a slow frame (such as cold shader compilation with `GlassWarmUpMode.never`), preventing `GlassMenu` from getting stuck as a blurred round bubble with hidden rows.
- **Premium glass morphs (#520):** Refresh the backdrop clip when the glass shape changes without a layout change, preventing a second contour at the frosted corners of an expanded `GlassMenu`.
- **`GlassQuality.standard` morph overlays on Impeller:** Gate `LiquidGlassBlendGroup` creation in `GlassModalSheet`, `GlassMenu`, and `GlassPopover` morph overlays strictly on `GlassQuality.premium`, preventing missing-`InheritedGeometryRenderLink` assertions when morphing with `GlassQuality.standard` on Impeller.
- **`GlassModalSheet` morphed close-origin after detent change (#507 follow-up):** When a `morphFrom` sheet opened at `half` is dragged to `full` or `peek` and dismissed at rest (barrier tap, close button, or `Navigator.pop`), frame 1 of the closing droplet morph now starts from the sheet's live resting detent (matching its active margins, bottom offset, corner radii, and fill) instead of snapping back to the initial `restingState`.

## Performance

- **Scrolling & bar chrome (`GlassScaffold`, `GlassTabBar`, `GlassAppBar`, `GlassToolbar`, `GlassScrollEdgeEffect`):** Shares backdrop reads across top and bottom bar chrome and progressive blur strips, removes idle `saveLayer` clipping from resting `GlassTabBar` indicators, and caches scroll-edge mask strips to reduce per-frame compositor passes while scrolling.
- **Sheets & menus (`GlassModalSheet`, `GlassMenu`, `GlassContextMenu`):** Pre-builds sheet content outside drag animations, removes unused fade masks and per-item `Opacity` layers during menu morphs, and unmounts `GlassContextMenu`'s offstage measurement pass after layout — reducing UI rebuilds and offscreen passes during drags and open/close transitions.
- **Shaders & GPU workload:** Reduces texture fetches and shader ALU work across the glass, indicator, geometry, and progressive blur shaders (skipping frost sampling on outer hairlines, using isotropic frost kernels and hardware filtering where safe, and taking a single-tap path across flat interiors) while preserving visual fidelity.
- **Memory, readbacks & idle overhead:** Avoids duplicate geometry matte allocations on standalone `useOwnLayer` surfaces, tightens shadow clip bounds, crops `GlassContentAwareScope` luminance reads to control bounds instead of full-screen snapshots, skips unnecessary geometry rebuilds on no-op relayouts, lazily allocates spring/animation tickers so resting controls hold zero active tickers, and narrows `MediaQuery` dependencies so keyboard animations do not rebuild unrelated widgets.
- **Adaptive quality (`GlassAdaptiveScope` / `GlassQualityAdapter`):** Fixes frost-step synchronization when stepping quality up or down, shortens initial warmup so slower devices adapt sooner, and keeps `GlassFrostBudget` in sync with blended glass groups.

## Documentation

- **`GlassModalSheet` solid content opt-in (`1.x`) (#514):** Documented wrapping dense controls, chips, and inputs inside `GlassModalSheet` in `InheritedGlassSurfaceStyle(surfaceStyle: GlassSurfaceStyle.solid, child: ...)` in `docs/GLASS_MODAL_SHEETS_GUIDE.md` and `skills/liquid-glass-widgets/SKILL.md`.

Thanks to [@Hamdym12](https://github.com/Hamdym12) (#523), [@jfhair](https://github.com/jfhair) (#525, #526), and [@yugai](https://github.com/yugai) (#520) for their contributions, and to [@AlexDochioiu](https://github.com/AlexDochioiu) (#522) and [@almazfm](https://github.com/almazfm) (#514) for their detailed reports.

# 1.19.0

## Features

- **`GlassThemeVariant.minimalLight` and `GlassThemeVariant.minimalDark` (#517):** Adds brightness-matched minimal-quality theme variants using iOS 27's neutral tints (`#F8F8F8` at 53% in light mode, white at 12% in dark mode) while leaving `GlassThemeVariant.minimal` unchanged.
- **`GlassDialog` and `GlassDialog.show` overrides (`shape`, `actionShape`, `actionTextStyle`) (#512, #518):** Adds optional shape and action typography overrides (all `null` by default to keep native `ios26`/`ios27` and `classic` defaults) while preserving role colors and side-by-side vs. stacked label measurement.
- **`GlassPopoverController` and `GlassPopover.controller` (#511, #518):** Adds programmatic `open()`, `close()`, `toggle()`, and `isOpen` control for `GlassPopover` (mirroring `GlassMenuController`), with idempotent transitions and mid-close blur continuity.
- **`GlassSearchBar.cancelButtonAlwaysVisible` (#510, #518):** Keeps the cancel button visible without focus when `showsCancelButton: true` (for modal search flows), applies post-mount flag changes dynamically, and forwards `enabled` to the cancel button.
- **`GlassChip.enabled` (#509, #518):** Adds optional `bool? enabled` across both `glass` and `solid` styles — `null` preserves handler-derived defaults, `true` without handlers draws an inert full-strength informational pill read as static text, and `false` disables both `onTap` and `onDeleted` at 50% opacity.
- **Text input & selection controls (`autofillHints`, `autocorrect`, `enableSuggestions`, `selectionControls`) (#505):** Forwards all four parameters to `CupertinoTextField` across `GlassTextField`, `GlassPasswordField`, `GlassTextArea`, and `GlassSearchBar` (`GlassPasswordField` defaults `autocorrect` and `enableSuggestions` to `false`).
- **`GlassSwipeActions` `enabled` & `backgroundColor` (`GlassListTile.swipeBackgroundColor`) (#505):** Adds `enabled` (default `true`) and `backgroundColor` (resolving `CupertinoDynamicColor`; pass `Color(0x00000000)` to suppress the backing highlight).
- **`GlassTabBarExtraButton.selected` and `GlassButton.isSelected` (#505):** Allows destination extra buttons in `GlassTabBar.bottom` and `GlassTabBar.searchable` to announce selection, adopt `selectedIconColor`, and suppress the main tab pill's indicator when active.

## Bug Fixes

- **`GlassModalSheet` post-handoff hit-testing with `morphFrom` (#507):** Clears the morph blob clipper once the open morph hands off so taps and drags above the initial detent (e.g. after dragging `half` → `full`) hit the sheet instead of the modal barrier.
- **`GlassSheet.show` top safe-area bound (#508):** Bounds tall content-sized sheets below the top status bar / Dynamic Island so their content scrolls cleanly regardless of `useSafeArea` (which continues to govern the bottom inset).
- **`GlassMenu` on premium tab bars (#504, #506):** Excludes fully dematerialized grouped triggers from the shared `LiquidGlassBlendGroup` geometry matte while the menu is open, removing the lingering circular glass rim on Impeller.
- **`GlassSwipeActions` drag arena & child state (#505):** Stops claiming horizontal drags when disabled, empty, or dragging toward an empty side so ancestor horizontal scrollables (`PageView`, horizontal `ListView`) swipe freely without remounting `child`.
- **`GlassTabBar` keyboard `Tab` focus & RTL order (#505):** Excludes the magnified indicator overlay from keyboard focus so `Tab` visits each tab once in reading order (right-to-left in RTL).
- **`GlassNavigationShell` & `GlassAppBar.pinned` in `IndexedStack` / `StatefulShellRoute.indexedStack` (#505):** Ignores pinned bar registrations in offstage/muted branches and re-resolves when a tab returns onstage.

Thanks to [@almazfm](https://github.com/almazfm) (#507–#512, #517) and [@yugai](https://github.com/yugai) (#504, #506) for their contributions.

# 1.18.0

## Features

- **`GlassButton` and `GlassIconButton` solid surface & glass tint support (`surfaceStyle`, `color`, `tintColor`, `GlassIconButton.iconColor`, `GlassIconButton.style`) (PR #495):** Both buttons (including `GlassButton.custom`) now accept `surfaceStyle`, `color`, and `tintColor` (resolving `CupertinoDynamicColor`), and `GlassIconButton` adds `iconColor`, `style`, and continuous superellipse `roundedSquare` corners. In `GlassSurfaceStyle.solid` mode (explicit or auto-inherited inside a solid `GlassContainer.card` / `GlassGroupedSection`), buttons render shader-free `tertiarySystemFill` (`filled`), `primaryColor` (`prominent`), or borderless (`transparent`) surfaces while preserving press stretch, keyboard focus, contrast-aware foregrounds/press highlights, and `GlassMaterialize` transitions. In `glass` mode, `tintColor` tints `filled` and `prominent` glass bodies while keeping active `GlassStyle` refraction, frost, and rim light.
- **`GlassPullDownButton` intrinsic capsule width, recursive submenu selection, and `GlassMenu` passthroughs (PR #494):** `GlassPullDownButton.buttonWidth` is now `double?` (`null` by default, resolving to `44.0` for icon-only buttons and intrinsic capsule width for labeled buttons without clipping). `onSelected` now recurses into nested `GlassMenuItem.submenu` items, and `GlassPullDownButton` forwards `menuPadding` (defaulting to `EdgeInsets.symmetric(horizontal: 12)` so clamped menus keep a safe screen-edge margin), `menuBorderRadius`, `morphSpeed`, `controller`, and `onClose` to `GlassMenu`.
- **`GlassPopover` morph speed & platform-view backdrop support (`morphSpeed`, `platformViewBackdrop`) (PR #494):** `GlassPopover` now accepts `morphSpeed` (`MorphSpeed.normal` default) and `platformViewBackdrop` (`false` default), and renders its overlay through `AdaptiveLiquidGlassLayer`.
- **iOS 27 `GlassMorphController` & `LiquidMorphState` morph channels (PR #494):** Exposes `triggerPushDx` / `triggerPushDy`, `triggerImpactScale`, `triggerWidthProgress`, `platterScale`, `platterOpacity`, `contentOpacity`, `contentBlurSigma`, and `isPlatterActive` on `LiquidMorphState`, plus `GlassMorphController.speed` setter, `speedMultiplier`, `phaseElapsedSeconds`, `phaseStartTriggerWidth`, `openStartProgress`, `closeStartProgress`, `recoilHalfTravelPx`, `verticalOnlyRecoil`, and `GlassMorphController.computeCornerRadius` for custom morphing widgets.

## Bug Fixes

- **`GlassPageRoute` and `GlassPageTransitionsBuilder` rounded transition shadow (PR #496):** Uses the sliding card's superellipse shadow during horizontal transitions instead of Cupertino's rectangular edge gradient, removing the straight shadow visible above and below rounded leading corners while preserving Flutter's Cupertino edge shadow when the resolved corner radius is `0`. Thanks to [@wow-sven](https://github.com/wow-sven) for the fix (#496).
- **iOS 27 Liquid Morph open, teardrop close, and recoil parity (`GlassMenu`, `GlassPullDownButton`, `GlassPopover`, `GlassModalSheet`, `GlassMorphTrigger`, `GlassContextMenu`) (PR #494):** Calibrated open (`ω₀ = 17.0 rad/s, ζ ≈ 0.76`) and close (`ω₀ = 18.0 rad/s, ζ ≈ 0.86`) springs and trajectories against 60 fps native iOS 27 captures — `GlassMenu` inflates as a near-circular bubble that relaxes into its resting superellipse while rows resolve from soft blur to crisp text; `GlassMenu` and `GlassPopover` retract into `trigger.center` as a single concave teardrop with softened content fade, height-adapted droplet envelopes across short to tall platters, outer-edge non-overshoot clamping, and C⁰ mid-flight open/close reversals; wide triggers contract in place on open and splash horizontally (`+1.6%` at `~400 ms`) on close; triggers ride an immediate parallel `~183 ms` catch recoil (`GlassContextMenu` upgraded to matching iOS 27 spring physics with Reduce Motion support); and expanded `submenu` stacks collapse coherently with the root platter.
- **Impeller overlay backdrop & blend-group compositing (`GlassMenu`, `GlassPopover`, `GlassModalSheet`, `GlassContextMenu`) (PR #494):** Eliminated ancestor fractional `Opacity` (`saveLayer`) wrappers over `AdaptiveLiquidGlassLayer` and `useOwnLayer: true` platters, removed duplicate nested `LiquidGlassBlendGroup` passes on premium Impeller layers, and kept underlying glass triggers suppressed until platter handoff so `BackdropFilter` never double-tints or blurs the resting button during close.

# 1.17.5

## Bug Fixes

- **`GlassDialog`, `showGlassActionSheet`, and `GlassQuality.standard` / `minimal` materialize transitions (PR #491, #492):** Eliminates the fade-in backdrop blur pop by dissolving alert platters and `standard` / `minimal` glass without an ancestor `OpacityLayer`, preserves child focus/state across transitions, and calibrates `GlassQuality.standard` alert legibility on `ios26` / `ios27`.
- **`GlassTabBar.searchable` right-edge anchor during parent resize (PR #488):** Animates the search pill's right inset and width so the pill stays anchored to its trailing edge while a parent container resizes or reverses mid-transition. Thanks to [@wow-sven](https://github.com/wow-sven) for the fix (#488).
- **`GlassTabBar.searchable` input retention and keyboard-lifted hit targets (PR #489):** Retains the `CupertinoTextField` input client, selection, and composing state across compact/expanded transitions, and keeps search dismiss controls tappable above the keyboard when a bottom accessory is mounted. Thanks to [@wow-sven](https://github.com/wow-sven) for the fix (#489).

# 1.17.4

## Features

- **`GlassSwitch` disabled state (`GlassSwitch.onChanged` is now `ValueChanged<bool>?`) (#485, #486):** Passing `onChanged: null` disables the switch — rendering it at 50% group opacity (matching `UISwitch` and `CupertinoSwitch`), ignoring touch, drag, and keyboard input without lifting into a glass lens, reporting disabled state to assistive technology, and still sliding the thumb on programmatic `value` updates. Direct callers should update `switchWidget.onChanged(v)` to `switchWidget.onChanged?.call(v)`.

## Bug Fixes

- **`LiquidVerticalRoundedRectangle` corner radii in `GlassQuality.standard` (PR #487):** Preserves independent top and bottom corner radii in the Standard glass renderer (`LightweightLiquidGlass`) instead of applying the larger `effectiveRadius` to all four corners. Thanks to [@wow-sven](https://github.com/wow-sven) for the fix (#487).
- **Flutter 3.50.0 / Windows HLSL & Web ANGLE shader single-exit `main()` (`flutter/flutter#190809`):** Refactored `void main()` across all five fragment shaders (`progressive_blur.frag`, `lightweight_glass.frag`, `interactive_indicator.frag`, `liquid_glass_render.frag`, and `liquid_glass_geometry_blended.frag`) to eliminate early/multiple `return;` statements alongside `sampler2D` texture sampling — silencing all four `impellerc` warnings on Flutter `3.50.0` (`flutter build web --wasm`, Windows, and mobile) and preventing `d3dcompiler_47.dll` (FXC) HLSL compilation failures on Windows Direct3D and Chrome ANGLE with zero visual or GPU performance regressions.
- **Shader CI & test guards (`scripts/validate_shaders.sh`, `test/shaders/single_return_main_test.dart`):** Extended shader validation to enforce single-exit `main()` statically, run Flutter's `impellerc` multi-target runtime stage check (failing on any `[WARNING]`) alongside `glslangValidator`, and guard against regressions in `flutter test` across all platforms.

# 1.17.3

## Features

- **Disabled dialog actions (`GlassDialogAction.onPressed` is now `VoidCallback?`) (PR #480):** Passing `null` keeps an action in place while ignoring input and reporting disabled state to assistive technology (`tertiaryLabel` on `ios27` / `ios26`; dimmed `GlassButton` on `classic`). Direct callers should update `action.onPressed()` to `action.onPressed?.call()`. Thanks to [@ncosgray](https://github.com/ncosgray) for the contribution (#478, #480).
- **`GlassTextField` and `GlassTextArea` text capitalization (`textCapitalization`) (PR #477):** Forwards `TextCapitalization` (default `none`) to the underlying `CupertinoTextField`. Thanks to [@RuslanTsitser](https://github.com/RuslanTsitser) for the contribution (#477).

## Bug Fixes

- **iOS 26 / 27 lifted lens contours, `GlassTabBar` platter physics, and `GlassSegmentedControl` parity (PR #481):** Calibrated `GlassTabBar` lifted magnification (`1.15×`), press-lift/overdrag platter motion, and solid-pill foreground contrast during drag; refined lifted indicator perimeter contours and dark-mode interior clarity across `GlassTabBar`, `GlassSegmentedControl`, `GlassSwitch`, and `GlassSlider`; and aligned `GlassSegmentedControl` resting `ios26` appearance with `ios27`.
- **`GlassDialog` and `showGlassActionSheet` content scrolling, keyboard avoidance, and semantics (PR #479):** Scrolls tall headers while keeping actions pinned, re-centers above the keyboard, adds `alertDialog` / `dialog` route semantics and accessibility-scale label wrapping, and fixes `MaterialApp` text styling. Thanks to [@ncosgray](https://github.com/ncosgray) for the fix (#478, #479).
- **`GlassMenu` and `GlassPopover` modal barrier semantics (PR #470):** Blocks background page semantics while an overlay is open without detaching the overlay from the semantics tree, and retains `GlassPopover` across open/close cycles. Thanks to [@imariman](https://github.com/imariman) for the fix (#470, #471).
- **`GlassNavigationShell` pinned chrome behind open page `GlassMenu` barriers (PR #476):** Places pinned top and bottom bars behind open page menu barriers for both hit-testing and assistive traversal. Thanks to [@imariman](https://github.com/imariman) for the fix (#472, #476).
- **`GlassPicker.showSheet` selection result, semantics, and `MaterialApp` styling (PR #474):** Returns the picked item via a Cancel / title / Done header, exposes the wheel as a single adjustable semantics node, and applies Cupertino `DefaultTextStyle` in both `GlassPicker.showSheet` and `showGlassDatePicker` under `MaterialApp`. Thanks to [@imariman](https://github.com/imariman) for the fix (#473, #474).

# 1.17.2

## Features

- **`GlassChip` solid surface support (`GlassChip.surfaceStyle`, `GlassChip.color`):** `GlassChip` now accepts `surfaceStyle` and `color`, automatically inheriting `GlassSurfaceStyle.solid` inside solid cards/sections to render a zero-shader pill well with keyboard focus and single-line ellipsis clamping.

## Bug Fixes

- **Improved `GlassQuality.standard` visual parity (`GlassTabBar`, `GlassSegmentedControl`, `GlassSwitch`, `GlassSlider`, `AdaptiveGlass`):** Upgraded standard-tier surfaces and lifted indicator pills across `classic`, `ios26`, and `ios27` (Skia, Web, and standard quality) with meniscus rim shading, directional specular highlights, and inner lens depth; tuned `GlassTabBar` lifted pill height on `standard`; and fixed `GlassSwitch` press-hold bloom deflating across parent rebuilds.
- **`GlassSegmentedControl` `GlassStyle.ios27` resting appearance:** Calibrated the Light Mode track fill, removed resting Light Mode indicator shadow bleed across the track border, and aligned default unselected label weight and contrast with native iOS 27.
- **`GlassNavigationShell` pinned chrome over fullscreen dialogs and sheets (PR #466):** Fixed newly pushed `fullscreenDialog` routes (and routes pushed over modal sheets) keeping the previous route's pinned bar items instead of showing their own. Thanks to [@veloce](https://github.com/veloce) for the fix (#466).
- **Linear interactive back-swipe parallax (`GlassPageRoute`, `GlassPageTransitionsBuilder`) (PR #468):** Keeps the underlying route's delegated parallax linear with the finger during interactive swipe-back while preserving the Cupertino curve for non-interactive transitions, and aligns `GlassPageTransitionsBuilder` with the `500 ms` Cupertino duration. Thanks to [@yohom](https://github.com/yohom) for the fix (#468).

# 1.17.1

## Features

- **`GlassMenuItem` checked radio semantics (`GlassMenuItem.semanticsChecked`) (PR #462):** Reports a menu row as a checked or unchecked item of a mutually exclusive group (`AXRadioButton` on macOS VoiceOver) without changing visuals. Thanks to [@imariman](https://github.com/imariman) for the contribution (#462).
- **Rounded page clipping during navigation transitions (`GlassPage`, `GlassScaffold`, `GlassNavigationStack`, `GlassPageRoute`, `GlassPageTransitionsBuilder`, `GlassPageTransitionClip`) (#451):** Clips transitioning pages with a continuous superellipse corner radius (adaptive to the active iPhone display bezel radius by default, or configurable via `transitionCornerRadius`) and card-edge shadow during push, pop, and interactive swipe-back gestures. Thanks to [@Vincen-dev](https://github.com/Vincen-dev) for suggesting the feature (#451).

## Bug Fixes

- **`GlassSwitch`, `GlassSlider`, and `GlassSegmentedControl` lifted lens & theme quality defaults:** Kept theme-level `GlassThemeVariant.quality` at `null` so body widgets (`GlassButton`, `GlassCard`, `GlassPage`) default to `GlassQuality.standard` without hitting the 16-shape layer limit, while `GlassSwitch`, `GlassSlider`, and `GlassSegmentedControl` default to `GlassQuality.premium` in `ios27`/`ios26` (`standard` in `classic`) even inside `GlassGroupedSection` / `GlassContainer`.
- **`GlassTabBar` and `AnimatedGlassIndicator` pill rendering:** Fixed right-edge frost bleed on `GlassTabBar.searchable` when the search bar is collapsed and eliminated stair-stepped edge pixelation inside lifted indicator pills while preserving the concave lens pinch.
- **iOS 27 `GlassQuality.standard` rim and corner outlines:** Added native iOS 27 rim light and light-mode rim shade to the lightweight shader and aligned the widget clip with the shader's rounded-rect SDF for smooth, continuous corner outlines.
- **`GlassMenu`, `GlassPullDownButton`, and `GlassPopover` liquid morph parity (#453):** Restored native iOS 26/27 open and close morph physics for `GlassQuality.premium` — immediate trigger handoff, pill-to-droplet open contour, full J-curve overshoot on open, symmetric ~350 ms close spring, and smooth trigger-anchored contraction and trigger re-materialization on close. Thanks to [@denweeLabs](https://github.com/denweeLabs) for reporting (#453).
- **`GlassFullScreenCoverBar`, `GlassFullScreenCoverBarButton`, and `GlassEditButton` default quality:** Default to `GlassQuality.premium` in `GlassStyle.ios27` and `GlassStyle.ios26` so full-screen cover and edit toolbar buttons preserve native material optics.
- **`GlassSegmentedControl` active-lens text and icon contrast (`activeSelectedColor`):** Phase-locked the selected segment's text and icon color to the indicator's glass-bloom phase (`thickness: 0.0 → 0.15`) across fixed and `.scrollable` modes so high-contrast inverted resting pills (e.g. a dark pill in Light Mode or a white pill in Dark Mode) smoothly transition to the ambient label color (or an explicit `activeSelectedColor`) while the solid pill dissolves into the clear glass lens.

# 1.17.0

## Breaking & Behavior Changes (Upgrading from ≤ 1.16.x)

- **Default style is now `GlassStyle.ios27` (with or without a `GlassTheme`):** All surfaces, tab bars, overlays, and interactive lenses now default to **`GlassStyle.ios27`** (`LiquidGlassSettings.ios27Light` / `ios27Dark` and `LiquidGlassSettings.ios27Indicator`). To keep the classic `v1.x` look globally, wrap your app in `GlassTheme(data: const GlassThemeData.classic(), child: ...)` (or `const GlassThemeData.ios26()` for iOS 26.0).
- **`AnimatedGlassIndicator` (`GlassTabBar` & `GlassSegmentedControl` pill) defaults to `ios27Indicator` when `indicatorSettings` is omitted:** Pass `indicatorSettings: LiquidGlassSettings.classicIndicator` to use the classic spherical pill on an individual widget without a global `GlassThemeData.classic()`.
- **`GlassDialog` and `showGlassActionSheet` use the native 320 pt centered floating platter in `ios27` / `ios26`:** Renders a 320 pt platter with 34 pt continuous corners, leading-aligned header, and 48 pt capsule action buttons (`GlassStyle.classic` preserves the 280 pt dialog and bottom-docked action sheet).
- **`GlassQuality.premium` defaults on `ios27` / `ios26` and `GlassPage` quality inheritance:** Transient overlays (`GlassDialog`, `showGlassActionSheet`, `GlassMenu`, `GlassPopover`, `GlassToast`), `GlassScaffold.bodyOverlays`, and hero controls (`GlassSwitch`, `GlassSlider`, `GlassSegmentedControl`) now default to `GlassQuality.premium` in `ios27`/`ios26` (`classic` keeps `standard`). An ambient `AdaptiveLiquidGlassLayer` or `GlassPage` that omits `quality:` no longer forces `GlassQuality.standard` onto premium-default descendants.
- **`GlassTabBar` sizing and `GlassModalSheet` / `GlassSheet` defaults follow active `GlassStyle`:** `GlassTabBar.iconSize` and `magnification` are now `double?` (`27.5` pt / `1.25` in `ios27`/`ios26` vs `24.0` pt / `1.15` in `classic`). `GlassModalSheet` and `GlassSheet` default to `38.0` pt top corners (was `32.0`), `8.0` pt floating margins, `#24000000` barrier dimming, and `#F2F2F7` light-mode full-detent fill in `ios27`/`ios26`.

## Features

- **Unified 3-tier `GlassStyle` theming (`GlassStyle.ios27`, `GlassStyle.ios26`, `GlassStyle.classic`):**
  - Added `enum GlassStyle { classic, ios26, ios27 }`, `const GlassThemeData.ios27()`, `const GlassThemeData.ios26()`, `const GlassThemeData.classic()`, `GlassThemeVariant.indicatorSettings` (`GlassThemeData.indicatorSettingsFor`), and `LiquidGlassSettings` presets (`classicLight`, `classicDark`, `classicTabBar`, `classicIndicator`, `ios26Light`, `ios26Dark`, `ios26Indicator`, `ios27Light`, `ios27Dark`, `ios27Indicator`, plus `classic(context)` / `ios26(context)` / `ios27(context)`).
  - Calibrated `GlassTabBar`, `GlassSegmentedControl`, `AnimatedGlassIndicator`, `GlassSwitch` (adding `thumbShadow`), and `GlassSlider` to match native UIKit platters, resting wells, lifted lens refraction/dispersion, and specular rim shading; `GlassSwitch` and `GlassSlider` lazy-mount their shader layer only while pressed or dragged.
  - Calibrated `GlassMenu`, `GlassMenuItem`, `GlassMenuDivider`, `GlassMenuLabel`, `GlassPullDownButton` (adding `settings` and capsule trigger default for non-square sizes), `GlassContextMenu`, `GlassModalSheet` / `GlassModalSheetScaffold` (adding `quality`), `GlassSheet`, `GlassDialog`, and `showGlassActionSheet` across `ios27`, `ios26`, and `classic`.
  - Added a live `iOS 27` / `iOS 26` style switcher to the `example/` showcase app.
- **`GlassButton` pressed base light color (`GlassButton.pressLightColor`, `GlassGlowColors.pressLight`) (PR #457):** Tints the ambient press lift and native sheen over colored surfaces (including `GlassTabBar.searchable`). Thanks to [@Nixxx19](https://github.com/Nixxx19) for the contribution (#457).
- **`GlassMenu`, `GlassPullDownButton`, and `GlassMenuItem` accessibility & surface overrides (PRs #455, #458, #460, #461):**
  - Added `GlassMenuItem.semanticsSelected` (`bool?`) for picker selection state (#455) and `GlassMenuItem.semanticLabel` (`String?`) to override spoken row labels (#461).
  - Added `GlassMenu.menuSemanticLabel` and `GlassPullDownButton.menuSemanticLabel` (`String?`) and kept open menu panels in the semantics tree as a named route scope (#458).
  - Added `GlassMenu.opaqueColor` (`Color?`) and `GlassMenu.border` (`BorderSide?`) for Reduce Transparency fills and Increase Contrast borders (#460).
  - Thanks to [@imariman](https://github.com/imariman) for the contributions (#455, #458, #460, #461).
- **`GlassSwitch` iOS On/Off Labels and RTL mirroring (PR #459):** Draws the native `I` and `O` track glyphs when `MediaQuery.onOffSwitchLabelsOf(context)` is enabled (`onLabelColor`, `offLabelColor`) and mirrors thumb travel, drag direction, and track labels in `TextDirection.rtl`. Thanks to [@imariman](https://github.com/imariman) for the contribution (#459).

## Bug Fixes

- **Theme & modal inheritance:** `GlassThemeData()` and `GlassThemeData.simple()` no longer overwrite the active `GlassStyle` tab bar platter when unmodified; ambient `AdaptiveLiquidGlassLayer` scopes without explicit `settings` no longer mask `GlassThemeData` for nested overlays; and all modal/overlay presenters (`GlassModalSheet.show`, `GlassSheet.show`, `GlassDialog.show`, `showGlassActionSheet`, `GlassToast.show`, `showGlassFullScreenCover`, `GlassPicker.showSheet`, `GlassDatePicker`) preserve the caller's ambient `GlassTheme` and `CupertinoTheme`.
- **Consistent 3-tier `GlassStyle` & `GlassQuality` resolution:** `GlassDialog` (`quality` now `GlassQuality?`, forwarding `barrierColor`), `GlassActionSheet`, `GlassPopover`, `GlassToast`, `GlassToolbar`, `GlassBadge`, `GlassPicker`, `GlassProgressIndicator`, `GlassStepper`, `GlassChip`, `GlassPasswordField` (`quality` now `GlassQuality?`), `GlassListTile.standalone` (honouring `settings`), and tinted `GlassBarItem` capsules now resolve settings and quality from the active `GlassTheme` and translate `ios26`/`ios27` frost parameters onto `GlassQuality.standard` shaders.
- **Visual & transition fixes:** Fixed `GlassSwitch` and `GlassSlider` resting thumb shadow clipping and perimeter rim hairline, `GlassSegmentedControl(useOwnLayer: true)` theme resolution, `GlassModalSheet` half-to-full frost/rim interpolation, and `CupertinoDynamicColor` resolution in `GlassMenuItem`, `GlassMenuDivider`, and `GlassMenuLabel`.

# 1.16.1

## Features

- **Custom menu glass for bar and button-group menus (`GlassBarItem.menu`, `GlassButtonGroupItem.menu`) (PR #450):** Both now accept `menuSettings` (`LiquidGlassSettings?`), forwarded to the `GlassMenu` panel across `GlassNavigationShell`, `GlassPinnedBarChrome`, and `GlassButtonGroup` so menus can use a thicker, more readable material than the button they morph out of. Defaults to `null` (inherits the button's glass).

  Thanks to [@veloce](https://github.com/veloce) for the contribution (#450).

## Bug Fixes

- **Swipe actions with long labels no longer shrink (`GlassSwipeActions`, `GlassSwipeAction`) (PR #449):** Action buttons with labels wider than `buttonDiameter` now stretch into capsules to fit their single-line `Text` label at full size instead of scaling down via `FittedBox`. Open actions are capped at 75% of the row width (truncating the longest labels equally with an ellipsis), and when open actions exceed `fullSwipeThreshold`, full-swipe triggers after pulling slightly past their open width.

  Thanks to [@veloce](https://github.com/veloce) for the fix (#449).

# 1.16.0

## Features

- **Solid surface style for inputs, pickers, and standalone disclosure groups (`GlassTextField`, `GlassSearchBar`, `GlassTextArea`, `GlassPasswordField`, `GlassPicker`, `GlassDisclosureGroup.standalone`):**
  - `GlassTextField` (and `GlassTextField.search`), `GlassSearchBar`, `GlassTextArea`, `GlassPasswordField`, and `GlassPicker` now accept `surfaceStyle` (`GlassSurfaceStyle?`) and `color` (`Color?`). When `surfaceStyle` is `null`, they automatically inherit `InheritedGlassSurfaceStyle` from an enclosing `GlassContainer.card` or `GlassGroupedSection` (falling back to `GlassSurfaceStyle.glass`).
  - In `GlassSurfaceStyle.solid` mode, inputs and pickers render a flat, shader-free iOS `tertiarySystemFill` well (`kGlassSolidWellLight` `#1E767680` in light mode, `kGlassSolidWellDark` `#3D767680` in dark mode, via `resolveGlassSolidWellColor`) using a `DecoratedBox` with zero `AdaptiveGlass`, `BackdropFilter`, `GlassGlow`, or `pressScale` overhead, and use native `CupertinoColors.label` / `CupertinoColors.placeholderText` / `CupertinoColors.secondaryLabel` typography contrast (`GlassSurfaceStyle.glass` colors remain unchanged).
  - `GlassDisclosureGroup.standalone` now accepts `surfaceStyle`, `color`, and `shape`, delegating to `GlassContainer.card` (with 26pt continuous corners and 16pt divider `endIndent` in `solid` mode).

## Bug Fixes

- **Controls inside solid `GlassContainer.card` / `GlassGroupedSection` retain full visual quality (`avoidsRefraction: false`):** `GlassContainer._buildSolid` now sets `avoidsRefraction: false` on its `InheritedLiquidGlass` scope so `GlassSwitch`, `GlassSlider`, and `GlassSegmentedControl` inside a solid card keep their full glass thumb/pill shader instead of degrading to a static vibrancy box.
- **`GlassPicker` grouped-mode `settings` warning:** `GlassPicker` with `useOwnLayer: false` now resolves ambient/theme settings via `GlassThemeHelpers.resolveSettings` (with `LiquidGlassSettings(blur: 8)` as the standalone fallback) and logs a debug warning if explicit `settings` are passed while `useOwnLayer: false`.

# 1.15.1

## Bug Fixes

- **`GlassModalSheet` content stays hidden until `morphFrom`:** Sheet content now scales, clips, and fades in continuously inside the expanding Liquid Glass droplet during `morphFrom` / `morphFromRect` transitions, and nested glass controls inside the sheet preserve their glass settings and backdrop alignment across the morph handoff.

- **Dark-mode `GlassContextMenu` platter blur:** Dark-mode context menu platters now match light-mode frost density so underlying content does not bleed through.

# 1.15.0

## Features

- **Swipe actions (`GlassSwipeActions`, `GlassSwipeAction`, `GlassSwipeController`, `GlassSwipeActionScope`):** iOS-style leading and trailing swipe actions with spring physics (`GlassSpring.snappy()`), rubber-band overscroll damping, full-swipe execution (`fullSwipeThreshold`), mutual exclusion across rows via `GlassSwipeActionScope`, and both `tintedGlass` and `solidVibrancy` styles. `GlassListTile` adds `leadingSwipeActions`, `trailingSwipeActions`, `swipeActionStyle`, and `onDismissed`.

- **Disclosure accordion sections (`GlassDisclosureGroup`):** Collapsible list sections with rotating chevron (RTL-aware), spring or curve expansion, controlled/uncontrolled `isExpanded` state, automatic divider interleaving inside `GlassGroupedSection`, and `GlassDisclosureGroup.standalone` for standalone glass cards.

- **Edit Mode & reorderable lists (`GlassEditScope`, `GlassEditController`, `GlassEditButton`, `GlassReorderableList`):** Ambient list editing modeled on SwiftUI's `EditButton` and `ForEach`. `GlassReorderableList` and `GlassReorderableList.grouped` support grabber drag or press-and-hold reorder with native lift shadow and split card edges. `GlassListTile` adds `isEditing`, `canDelete`/`onDelete` (with animated slide-in delete confirmation), `canInsert`/`onInsert`, `canReorder`/`reorderIndex`, and `canSelect`/`isSelected`/`onSelectedChanged`. `GlassReorderableList.grouped` and `GlassGroupedSection` take `dividerIndent` (and `dividerEndIndent` on the list) to match native row insets.
  - **Behavior change:** `GlassListTile.leading` is now a 28pt *minimum* width (so row text lines up with the default 56pt divider inset); a larger leading widget, e.g. a 44pt avatar, keeps its size.

- **Context menus (`GlassContextMenu`, `GlassContextMenuAction`, `showGlassContextMenu`):** Long-press and secondary-click context menus with touch-and-hold row lift, custom preview cards (`previewBuilder`), glide-to-select with selection haptics, and retract-to-source dismissal. Available as `GlassContextMenu`, the `.glassContextMenu()` widget extension, `showGlassContextMenu`, or directly on `GlassListTile` (`contextMenuActions`, `contextMenuPreviewBuilder`).

- **Full-screen covers (`GlassFullScreenCover`, `GlassFullScreenCoverBar`, `showGlassFullScreenCover`):** Edge-to-edge modal presentation with interactive swipe-down dismissal, progressive top-corner rounding, rubber-band overscroll resistance, and `GlassFullScreenCoverBar` with glass Done/Cancel (`GlassFullScreenCoverBarButton`) or close buttons. Also available via the `.glassFullScreenCover()` extension.

- **Date and time pickers (`GlassDatePicker`, `GlassMultiDatePicker`, `showGlassDatePicker`):** Supports `.compact` (glass pills opening anchored calendar/wheel popovers), `.graphical` (inline paged month calendar with expandable month/year wheel), and `.wheel` styles across `date`, `time`, and `dateAndTime` modes, plus multi-date selection (`GlassMultiDatePicker`) and optional `monthNames`, `weekdayNames`, and `dateFormatter` localization overrides.

- **Declarative navigation stack (`GlassNavigationStack`, `GlassNavigationLink`, `GlassNavigationPath`):** Value-based and builder-based declarative routing synchronized bidirectionally with native swipe-back gestures and `GlassNavigationShell` pinned chrome. Includes the `.navigationTitle()` widget extension, which automatically drives enclosing or descendant `GlassAppBar` / `GlassAppBar.pinned` titles (when `title` is null) via `GlassNavigationTitleScope`.

- **iOS 27 theme presets (`GlassThemeData.ios27`):** Added `const GlassThemeData.ios27()`, `GlassThemeSettings.ios27Light` / `ios27Dark`, and `GlassThemeVariant.ios27Light` / `ios27Dark`, plus `shadowElevation` and `shadow` overrides on `GlassThemeSettings` and explicit horizontal leading-inset forwarding on `GlassAppBar.pinned(padding:)`.

- **Solid card surfaces (`GlassSurfaceStyle`, `GlassContainer.card`):** Added `enum GlassSurfaceStyle { glass, solid }` and `GlassContainer.card` (plus `surfaceStyle` on `GlassGroupedSection`, `GlassReorderableList.grouped`, `GlassDatePicker`, and `GlassMultiDatePicker`). `GlassSurfaceStyle.solid` bypasses the glass shader to render a flat, opaque inset-grouped card (`#FFFFFF` light, `#1C1C1E` dark, and `#2C2C2E` inside elevated modal sheets/covers). `solid` ignores `settings`, `quality` and `useOwnLayer`. Defaults to `glass` in 1.x, so nothing changes unless you opt in; the default flips to `solid` for list sections, date pickers and `GlassContainer.card` in 2.0.0 (see `docs/ROADMAP.md`).

- **Example demo:** Added `example/lib/demos/lists_pickers_and_nav_demo.dart` ("Lists, Pickers & Nav") showcasing swipe actions, context menus, disclosure groups, edit/reorder, date pickers, full-screen covers, and `GlassNavigationStack`.

## Deprecations

- **`GlassCard` is deprecated in favour of `GlassContainer.card`:** `GlassCard` forwards to `GlassContainer.card` with identical defaults and renders identically; it will be removed in 2.0.0. Migration is a rename (see `docs/MIGRATION_0.x_TO_1.0.md`).

## Bug Fixes

- **Automatic `useOwnLayer` fallback for `AdaptiveGlass` outside of `LiquidGlassLayer`:** `AdaptiveGlass` now detects when no ancestor `LiquidGlassLayer` is present and provisions its own layer (`effectiveUseOwnLayer = true`) instead of asserting when `GlassQuality.premium` is requested.

# 1.14.2

## Features

- **Hold adaptive quality measurement during heavy app work (PR #445):** `GlassAdaptiveScope.holdMeasurement()` returns a `GlassMeasurementHold` that suspends Phase 2 warm-up and Phase 3 runtime frame-timing measurement while open (plus `GlassAdaptiveScope.settleFramesAfterHold` frames after the last nested hold is released), preventing CPU/GPU-heavy app tasks such as on-device model loading from falsely demoting capable devices.

  Thanks to [@almazfm](https://github.com/almazfm) for the contribution (#445).

## Bug Fixes

- **`ProgressiveBlur` did not repaint when an ancestor moved its retained layer (PR #444):** `_RenderProgressiveBlur` now mixes in `TransformTrackingRenderObjectMixin` and marks itself for paint when its global transform changes, preventing misplaced or missing blur regions after route transitions or animated ancestor transforms over a `RepaintBoundary`.

  Thanks to [@almazfm](https://github.com/almazfm) for the fix (#444).

- **Open `GlassMenuItem.submenu` cards stayed stale when `GlassMenu.items` changed (PR #443):** Open submenu levels now track their parent row's `sourceIndex` and rebuild their header and child rows in `didUpdateWidget`, allowing live parent titles and updated submenu checkmarks to update in place while the submenu card is open.

  Thanks to [@almazfm](https://github.com/almazfm) for the fix (#443).

- **`GlassDialog` two-action row clipped long or large-scale labels (PR #442):** `GlassDialog` now measures two-action labels with `TextPainter` against half the dialog width (accounting for `DefaultTextStyle`, `Directionality`, and `MediaQuery.textScalerOf`) and stacks the actions vertically when either label does not fit on one line, matching native iOS alert layout.

  Thanks to [@almazfm](https://github.com/almazfm) for the fix (#442).

- **`GlassButton` press highlight bled outside the button shape when `blur: 0` (PR #441):** The ambient base light overlay in `GlassButton` is now clipped directly to `ShapeBorderClipper(shape: widget.shape)` so buttons without a blur layer do not show a rectangular press highlight around rounded or circular shapes.

  Thanks to [@almazfm](https://github.com/almazfm) for the fix (#441).

# 1.14.1

## Bug Fixes

- **Standalone premium glass buttons and pinned navigation bar buttons had clipped, flattened edges:** Standalone `useOwnLayer` glass surfaces without `rimShade` or `frost` now reserve the full outer anti-aliasing border so circular buttons are not clipped at their top, bottom, left, and right poles, and shared navigation bar items now use a half-height (`23pt`) corner radius so single-item shared buttons are true circles.

- **`GlassBarItem.menu`, `GlassButtonGroupItem.menu`, and `GlassPullDownButton` menus ran off screen and could not scroll (PR #440):** These menus and their `GlassMenuItem.submenu` cards now enable `autoAdjustToScreen: true` by default so long menus stop at the screen edge and scroll.

  Thanks to [@veloce](https://github.com/veloce) for the fix (#440).

- **Tab-bar icon masking alignment (PR #439):** `JellyClipper` now matches `AnimatedGlassIndicator` by applying the 4px track inset before dividing into tabs, preventing unselected icon fragments from refracting beside the active icon during press and drag interactions.

  Thanks to [@xuwucv](https://github.com/xuwucv) for the report and fix (#439).

- **Glass moved by layout was drawn at its previous position for one frame (PR #438, fixes #418):** Premium glass translated by layout (such as during a window resize or scroll) now updates its composite position in the same frame instead of lagging by one frame.

  Thanks to [@erikjara](https://github.com/erikjara) for the report (#418) and the fix (#438).

## Performance

- **Layout-only moves of premium glass no longer rebuild the geometry matte:** Translating an entire glass layer no longer schedules a follow-up repaint or re-rasterizes its local-space geometry matte, while shapes or groups that move *within* a layer now rebuild the matte in the same frame.

# 1.14.0

## Features

- **Configurable button size for `GlassAppBar.pinned` (PR #433, fixes #425):** `GlassAppBar.pinned` and `GlassPinnedBarChrome` now accept an optional `buttonSize` (`double?`, default `44.0`), sizing standalone bar buttons (the automatic back button and `separate` / `own` / `none` items) to `buttonSize`, scaling shared multi-item capsules proportionally (`buttonSize + 2.0`), and forwarding `toolbarHeight` to the pinned host so buttons are vertically centered and custom items (e.g. a 48×48 `GlassButton` with `GlassBarItemBackground.own`) are never squeezed to 44pt. `buttonSize` is ignored in iPhone Duo's vertical strip, which keeps its native metrics; in the upright status-row layout the chrome keeps its 44pt row and is not re-centred for a larger `buttonSize`.

  **Behaviour note:** a `GlassAppBar.pinned` bar's in-route buttons are no longer capped at the toolbar height, so a shared multi-item capsule drawn in-route now measures 46pt like the pinned copy, where it was previously clamped to 44pt (a 2pt jump at hand-over). Custom items inside a capsule are likewise held to the capsule's height in-route, as they already were when pinned.

  Thanks to [@AlexT15-al](https://github.com/AlexT15-al) for the feature request (#425).

- **Modal sheet animation style (PR #427):** `GlassModalSheet.show` accepts an optional `sheetAnimationStyle` to customize the slide's duration and curve in each direction while keeping the morph spring.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the contribution (#427).

- **Status-row navigation bars on iPhone Duo upright inner display (PR #426, fixes #368):** Pinned `GlassAppBar` and `GlassNavigationShell` chrome now sit beside the corner status cluster in the status bar's row when iPhone Duo is held upright, with `GlassScaffold` starting content below the status bar.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the contribution (#426, fixes #368).

## Bug Fixes

- **`GlassBarItem.custom` without `onTap` wrapped its child in an unlabelled button (PR #434, fixes #432):** Omitting `onTap` defaulted to a no-op callback that still wrapped the slot in a button, so a custom child that was already a button exposed two nested buttons to screen readers and keyboard navigation. Omitting `onTap` on `GlassBarItem.custom` or `GlassButtonGroupItem` now leaves the slot passive — no outer button semantics, focus stop, tap recognizer, or strip overflow entry — and a `label` on a passive slot names it as a single node.

  Thanks to [@veloce](https://github.com/veloce) for the bug report (#432).

- **`GlassMenu` mouse hover pill (PR #430):** The `selectionColor` highlight pill now follows a resting mouse pointer across menu rows and clears when the pointer exits, giving visible hover feedback on light glass where the white item wash was invisible.

  Thanks to [@Ahmadre](https://github.com/Ahmadre) for the fix (#430).

- **Offstage pinned bar resize assertion (PR #429):** `GlassPinnedBarChrome` now removes its in-route `OverlayPortal` strip while its route is offstage, preventing `size == theater.size` assertions when rotating or unfolding iPhone Duo under a full-screen route.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix (#429).

- **Locked modal sheet outside-tap dismissal (PR #428):** `GlassModalSheetScaffold` now accepts `barrierDismissible` (wired from `GlassModalSheet.show(isDismissible:)`), keeping non-dismissible sheets open when tapping outside.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix (#428).

# 1.13.0

## Features

- **Dialogs and sheets on a half-folded iPhone Duo (PR #411):** Half folded, native alerts and sheets present into one side of the fold; `GlassDialog` and `GlassModalSheet` stayed centred across it. The iOS plugin now also reports the fold, `UIView.reservedRegions(kind: .division)`, and `GlassNavigationShell` publishes it with the cutouts as a hinge in `MediaQuery.displayFeatures`, so dialogs present into a side through `DisplayFeatureSubScreen`. `GlassModalSheet` presents into the same side as a card with its margins and a horizontal bar, and `GlassModalSheet.restingWidthOf` measures that side.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the contribution (#411, part of #368).

- **Modal sheet route settings (PR #419):** `GlassModalSheet.show` accepts optional `routeSettings`, allowing callers to provide a route name and arguments for navigation observers and sheet content.

  Thanks to [@leoluobuqi](https://github.com/leoluobuqi) for the contribution (#419).

## Bug Fixes

- **The vertical bar strip jumped into the content during a presentation (PR #420, fixes #422):** On iPhone Duo, presenting anything over a screen hands its chrome back to the route, which draws the strip itself. It placed the strip against the bar's own box, so a bar laid out clear of the strip, under a `SafeArea` say, drew its back button and items a strip's width into the content until the presentation ended. The strip is now placed across against the screen, or the sheet, that its `GlassVerticalBar` spans.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix (#420).

- **Menus from the vertical bar strip covered its status cluster (PR #421, fixes #423):** On iPhone Duo, a `GlassMenu` opened from the strip was centred on its item, as a popover is, so a tall one rose over the clock and the status icons at the top of the strip. Natively a menu covers its item with their edges aligned and grows away from the nearer of the top and bottom of the screen, and stops level with the strip's first control. `GlassMenu` now does the same.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix (#421).

# 1.12.0

## Features

- **Opt-in scroll edge pointer absorption (PR #413):** `GlassScrollEdgeEffect` and `GlassScaffold` can absorb touches in their fade zones when `absorbPointer` (`edgeFadeAbsorbsPointers` on `GlassScaffold`) is enabled; defaults to `false`.

  Thanks to [@yohom](https://github.com/yohom) for the contribution (#413).

## Bug Fixes

- **Anti-aliased premium pill and curved silhouettes (PR #415):** Fixed stair-stepping artifacts on curved glass silhouettes (notably `GlassTabBar`'s indicator pill during drags) by extending the geometry matte's coverage fade to full transparency and filtering transformed mattes bilinearly.

  Thanks to [@gbahry](https://github.com/gbahry) for the fix (#415).

## Performance

- **Morph spring early settle & frame savings (PR #417):** `GlassMorphController` now uses an optimized settling tolerance so springs complete once motion is visually imperceptible. Eliminates trailing rebuild and repaint ticks across `GlassMenu`, `GlassPopover`, and modal sheets, reducing frame draw overhead by ~30%.

  Thanks to [@Ahmadre](https://github.com/Ahmadre) for the contribution (#417).

# 1.11.1

## Bug Fixes

- **`GlassBackdropGroup` dropped `backerColor` on members after the first (fixes #412):** Surfaces with a visible `backerColor` now take an isolated backdrop read so their dimming pad is preserved, while members without a backer continue sharing the group's backdrop read.

- **Engine lifecycle hardening (PR #410):** Fragment shaders are no longer reloaded on every rebuild. Blend groups release their group link on dispose and follow `renderLink` changes when reparented. Removing a glass shape from a layer repaints its matte, so no ghost of it remains. Duplicate shape registrations on detached render objects are prevented, and the native picture recorded for an asynchronous geometry cache is released as soon as it is rendered.

- **Fragment shaders are now disposed:** `MultiShaderBuilder` disposes the shaders it creates when it unmounts, and the ones it replaces when its keys change (after the frame that last used them), instead of leaving them to the garbage collector.

# 1.11.0

## Features

- **Layered `GlassMenu` submenus (PR #386):** `GlassMenuItem.submenu` opens a native iOS-style card over its parent. The parent recedes to 0.971× and dims its rows to 50%; the full-width card's bold header repeats the source row's icon and title with a downward chevron and sits on that row. Selecting the header, or tapping or gliding onto the exposed parent, collapses one level. Submenus nest, only the top card is interactive or exposed to semantics, and Reduce Motion makes transitions instant. The card's rows arrive with its material while the parent rows it covers cross-fade away, and closing reverses this; the fade drives the glass visibility channel, so the card keeps blurring its backdrop. `GlassMenu.onLevelChanged` reports the depth and the whole stack's extent so an owner can make room for a card that overhangs the parent, and `GlassMenu.maxStackHeight` constrains the stack, scrolling a card that would not otherwise fit. `GlassMenuController.submenuDepth` reports the current depth.

  Thanks to [@F1orian](https://github.com/F1orian) for the contribution (#386).

- **`stripRowTop` on `GlassPinnedBarChrome` and `GlassNavBarRegistration` (fixes #398, PR #399):** In iPhone Duo's vertical bar strip, the items that stay horizontal were always pinned in the row `GlassAppBar` draws its title in, so beside a bespoke header lower down they sat a row above it. `stripRowTop` puts that row where the bar's own header is.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the contribution (#399).

- **`GlassVerticalBar.disabled` keeps a subtree's bars horizontal (fixes #400, PR #401):** In a list/detail split on iPhone Duo the strip belongs to the column against it, as with `UISplitViewController`, and the other column keeps horizontal bars. Wrap that column in `GlassVerticalBar.disabled`. A pinned bar inside it draws its chrome in-route rather than handing it to the shell, which would pin it against the window, in the strip.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the contribution (#401).

- **`GlassModalSheet.restingWidthOf` (fixes #402, PR #403):** The width a sheet rests at, for content measured before the sheet is presented. In iPhone Duo's vertical bar strip layout a window 800pt wide or more lays every detent out as a card the display's shorter side wide, so content measured at the screen's width less the margins gained a wrapped row the sheet's height did not allow for.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the contribution (#403).

- **The vertical `GlassTabBar` shows its labels under a finger (fixes #406, PR #407):** In iPhone Duo's vertical bar strip the tab bar is icons only, as natively, so its tabs had no visible names. Touching it now behaves as UIKit's does: the capsule swells, then after a short hold grows into a labelled form with each label beneath its icon, and the indicator lifts into a lens that follows the finger and selects the tab under it on release. A drag shows the labels at once. `GlassTabBar.indicatorSettings` now reaches the vertical bar's lens.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the contribution (#407).

## Bug Fixes

- **`GlassTabBar.searchable` in iPhone Duo's vertical bar strip (fixes #392, PR #393):** With `GlassSearchBarConfig.showPill` false the strip still ended the capsule with a search slot; it now leaves search out, as a native `TabView` without its search tab does. `GlassTabBar.searchable` and `GlassTabBar.minimizable` also take `passthroughOverPlatformView`, which only the internal layout accepted, so a bar over a map no longer has to drive that layout directly, which kept it horizontal in the strip.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix (#393).

- **Vertical `GlassTabBar` asserted outside a `GlassScaffold` (fixes #394, PR #395):** In iPhone Duo's vertical bar strip, the tab bar's capsule, search field and ✕ relied on the `GlassScaffold` around them for a glass layer, so at `GlassQuality.premium` a bar placed any other way failed the `renderLink != null` assertion. Each now brings its own layer, as the horizontal bar does; under a `GlassScaffold` nothing changes.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix (#395).

- **`GlassPinnedBarChrome` builder can now tell the package draws the strip (fixes #396, PR #397):** On iPhone Duo, a `GlassPinnedBarChrome` the shell has not hoisted, such as one in a nested navigator, draws the vertical bar strip itself, but `builder` still got `hoisted: false`, so a bar drawing its own capsules from it showed the back button and actions twice. The new `GlassPinnedBarChromeData.inStrip` is true whenever the chrome is laid out for the strip, which the package draws whatever `hoisted` says.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix (#397).

- **iPhone Duo's vertical bar strip now follows the status cluster (fixes #404, PR #405):** The strip's first control sat at a height measured on the 27.1 simulator, so on a device, where the cluster grows with live activities and goes with the status bar, the controls no longer lined up with it. The strip's ends now come from the regions UIKit reserves for the cluster and the camera, `UIView.reservedRegions(kind: .occlusion)`, read by a small iOS plugin and updated as they change. `GlassVerticalBar.resolve` takes them as cutout `displayFeatures`, which is where Flutter will report them once it does on iOS (flutter/flutter#193025).

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix (#405).

- **iPhone Duo's vertical bar strip in Split View (fixes #408, PR #409):** The strip was only found where the top inset was zero and one side was inset, so in Split View the app fell back to horizontal bars. The left-hand app gets no inset for its strip at all, only `UITraitCollection.verticalBarEdge`, which the iOS plugin now reports; the shell keeps an 84pt strip on that edge and insets the content for it. Below a status bar along the top, the strip and the title row start beneath it.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix (#409).

- **Submenu card touch glow was opaque white:** A layered submenu card defaulted its interaction glow to fully opaque white, so the highlight under a finger blew out the card's rows. It now uses the same theme-aware specular colour as the root menu (white at `GlassDefaults.specularLightAlpha` in dark mode, black at `GlassDefaults.specularDarkAlpha` in light mode). An explicit `GlassMenu.glowColor` still wins.

- **`GlassPullDownButton` dropped item properties when `onSelected` was set:** Wrapping each `GlassMenuItem` to report the selection rebuilt it with only a few fields, so `submenu`, `height`, `titleStyle`, `subtitleStyle`, `iconColor`, `iconSize`, `maxLines`, `enablePressScale`, `closeDelay`, `isPressed` and `isSelected` were lost. A submenu row in a pull-down button showed no chevron and opened nothing. All properties are now forwarded.

# 1.10.0

## Features

- **`GlassBarItem.spacer()` multi-capsule rendering (#245, PR #390):** A spacer now splits a pinned bar's run of shared items into separate capsules, as `ToolbarSpacer(.fixed)` does natively, where it used to assert. Across a transition each capsule follows its items, matched by `id` and otherwise by position, rather than one capsule morphing into another. A capsule the destination adds beside one buds out of it through a liquid bridge, as on iOS 27, and one it drops merges back in.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the contribution (#390).

- **External slide-to-select on `GlassMenu` (discussion #369, PR #384):** Added `glideTo(Offset)`, `endGlide()`, and `cancelGlide()` to `GlassMenuController`. Enables external gesture recognizers (such as a long-press on an outer card) to drive menu item highlighting, selection haptics, and activation without needing direct touch ownership.

  Thanks to [@F1orian](https://github.com/F1orian) for the contribution (#384).

- **Dynamic sheet appearance with `expandedDarkColor` (PR #385):** Added optional `expandedDarkColor` parameter to `GlassModalSheet` and `GlassModalSheet.show` so presented full-height sheets and morph droplets dynamically follow system light/dark appearance switches while open.

  Thanks to [@DFelten](https://github.com/DFelten) for the contribution (#385).

- **Accessibility semantic label overrides (PR #387):** Added optional `semanticLabel` parameters across `GlassPicker`, `GlassMenu`, `GlassPopover`, `GlassTextField`, `GlassChip`, `GlassPasswordField`, `GlassSearchBar`, and `GlassSearchBarConfig` to allow custom screen reader announcements.

  Thanks to [@Ahmadre](https://github.com/Ahmadre) for the contribution (#387).

## Bug Fixes

- **Tinted `GlassBarItem` dropped the bar's `buttonSettings` (fixes #372, PR #389):** A `GlassBarItem` with a `tintColor` built its capsule's settings from scratch, so under `LiquidGlassSettings.ios27Light` it lost the outline, rim light and shadow the untinted capsules beside it kept. The tint now replaces only the body colour of the bar's button settings, hoisted and in-route.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix (#389).

- **`LiquidGlassSettings.ios27Dark` over bright backdrops (fixes #373, PR #388):** From mid-grey up, `ios27Dark` lifted the backdrop and drew a light rim where the native dark material darkens it and keeps a dark outline, and over a white page it stayed white where native greys to about 184. The new `bodyShade` term pulls a bright backdrop down by its luminance squared, outline included; `ios27Dark` sets it to `0.28` and raises `rimShade` to `1`.

  Thanks to [@JakeThomson](https://github.com/JakeThomson) for the fix (#388).

- **Screen reader, dynamic type, and Reduce Motion pass (PR #387):** Exposed missing button semantics and dismiss actions on menu/popover barriers and plain triggers; prevented chip delete buttons from merging into name text; allowed `GlassPicker` to grow with large system fonts; and honored Reduce Motion across toasts, page controls, and searchable tabs.

  Thanks to [@Ahmadre](https://github.com/Ahmadre) for the contribution (#387).

- **Controlled `GlassSwitch` state synchronization (PR #383):** Fixed visual state desynchronization when `widget.value` is unchanged or rejected by the parent. Reconciles the position controller to authoritative `widget.value` after gestures and settles thickness bloom correctly.

  Thanks to [@sbezhuk](https://github.com/sbezhuk) for the fix (#383).

- **One screen-reader node per control (issue #381):** Every interactive control now surfaces as a single semantics node carrying its label, role, state, tap and focus. Previously `GlassFocusRegion` split its focus semantics into a second node — unlabelled on switches, icon buttons, tabs, steppers and button groups (an extra TalkBack stop), and a repeat of the visible text on segments, chips and menu rows (read twice by VoiceOver). The drag detectors on `GlassSegmentedControl` and `GlassSwitch`, and the inner detector on `GlassListTile`, no longer add unlabelled scroll/tap nodes either.
  - An explicit label (`GlassButton.label`, `GlassSegment.semanticLabel`, `GlassMenuItem.title`, …) now replaces the control's visible text instead of being announced alongside it, as `GlassButton.label` documents.
  - `GlassMenuItem.subtitle` is announced as the row's value; `GlassListTile.onLongPress` is reachable by screen readers.
  - `GlassChip`'s delete button defaults to "Remove ‹label›" instead of being unnamed.
  - `canRequestFocus: false` is now honoured; it was silently overridden, so such controls still took keyboard focus.

  Thanks to [@cosmeao](https://github.com/cosmeao) for the detailed report and reproduction (#381).

---

For `1.9.0` and earlier history see [CHANGELOG_ARCHIVE.md](https://github.com/sdegenaar/liquid_glass_widgets/blob/main/CHANGELOG_ARCHIVE.md) or the [GitHub Releases page](https://github.com/sdegenaar/liquid_glass_widgets/releases).
