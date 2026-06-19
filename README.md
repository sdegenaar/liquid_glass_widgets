# Liquid Glass Widgets

Bring Apple's iOS 26 Liquid Glass to your Flutter app — a comprehensive glass widget library with real shader-based blur, physics-driven jelly animations, and dynamic lighting. Works on every platform out of the box.

[![pub package](https://img.shields.io/pub/v/liquid_glass_widgets.svg?label=pub.dev&labelColor=333940&logo=dart)](https://pub.dev/packages/liquid_glass_widgets)
[![pub points](https://img.shields.io/pub/points/liquid_glass_widgets?label=pub%20points&labelColor=333940)](https://pub.dev/packages/liquid_glass_widgets/score)
[![likes](https://img.shields.io/pub/likes/liquid_glass_widgets?label=likes&labelColor=333940)](https://pub.dev/packages/liquid_glass_widgets/score)
[![CI](https://github.com/sdegenaar/liquid_glass_widgets/actions/workflows/ci.yml/badge.svg)](https://github.com/sdegenaar/liquid_glass_widgets/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/sdegenaar/liquid_glass_widgets/graph/badge.svg)](https://codecov.io/gh/sdegenaar/liquid_glass_widgets)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)


https://github.com/user-attachments/assets/2fe28f46-96ad-459d-b816-e6d6001d90de

*[Wanderlust](example/showcase/) — a luxury travel showcase built entirely with `liquid_glass_widgets`*


## Features

- **Comprehensive glass widget library** — containers, interactive controls, inputs, feedback, overlays, and navigation surfaces (see [Widget Categories](#widget-categories))
- **Liquid Morph Engine** — a standalone physics system powering iOS 26-style liquid morphing. `GlassMenu` is the first consumer; future widgets will use the same engine for consistent liquid transitions. See [`docs/LIQUID_MORPH_ENGINE.md`](docs/LIQUID_MORPH_ENGINE.md)
- **Real frosted glass** — native two-pass Gaussian blur + shader refraction on Impeller; lightweight shader on Skia/Web
- **Just works everywhere** — iOS, Android, macOS, Web, Windows, Linux; rendering path chosen automatically
- **Adaptive quality** *(experimental)* — `GlassAdaptiveScope` benchmarks the device at startup and adjusts quality in real time: `minimal` on slow hardware, `standard` on mid-range, `premium` on fast devices. Degrades on thermal throttle, recovers when cool
- **Minimal dependencies** — only `equatable`, `flutter_shaders`, and `logging` beyond the Flutter SDK
- **One-line setup** — `LiquidGlassWidgets.wrap(child: myApp)` handles accessibility bridging, adaptive quality, and global theming; use `GlassScaffold` per screen for automatic backdrop isolation, z-ordering, edge fading, and status bar styling
- **Content-aware brightness** — glass bars automatically flip between light and dark icons/labels based on the content scrolling behind them. One flag on `GlassScaffold`, matches iOS 26 behaviour
- **Gyroscope lighting** — `GlassMotionScope` drives specular highlights from any `Stream<double>`
- **WCAG-compliant by default** — Reduce Motion and Reduce Transparency are respected automatically; no setup required


## Examples

### [Wanderlust](example/showcase/) — Luxury Travel Showcase

A premium app demonstrating `liquid_glass_widgets` in a real-world production context — full-bleed imagery, parallax scroll, hero transitions, and a concierge chat interface. **This is the app shown in the video above.**

```bash
cd example/showcase && flutter pub get && flutter run
```


### [Apple Music Demo](example/lib/apple_music/) — iOS 26 Replica

A recreation of the Apple Music app demonstrating `GlassSearchableBottomBar`, a floating playback pill, and the full iOS 26 navigation model with smooth morphing transitions.

```bash
cd example && flutter pub get && flutter run -t lib/apple_music/apple_music_demo.dart
```


### [Apple Messages Demo](example/lib/apple_messages/) — iOS 26 Replica

A replica showcasing the **Liquid Morph Engine** via `GlassMenu`. Tap the menu or **Edit** button at the top to see the teardrop open/close physics live.

```bash
cd example && flutter pub get && flutter run -t lib/apple_messages/apple_messages_demo.dart
```


### [Apple News Demo](example/lib/apple_news/) — iOS 26 Replica

A recreation of the Apple News app demonstrating `GlassSearchableBottomBar` with its morphing search pill, category chips, hero cards, and rounded article tiles.

```bash
cd example && flutter pub get && flutter run -t lib/apple_news/apple_news_demo.dart
```

<img width="390" height="844" alt="Apple News Demo" src="https://raw.githubusercontent.com/sdegenaar/liquid_glass_widgets/main/docs/assets/apple_news_demo.jpg" />

### [Widget Showcase](example/) — Full Component Library

A complete catalogue of every glass widget organised by category. Use it to explore components, try live settings, and copy patterns directly into your app.

```bash
cd example && flutter pub get && flutter run
```

<img width="390" height="847" alt="Widget Showcase" src="https://raw.githubusercontent.com/sdegenaar/liquid_glass_widgets/main/docs/assets/showcase.jpg" />


### [Component Demos](example/lib/demos/) — Copy-Pasteable Examples

Eight focused, self-contained demos — one widget, one file, runnable standalone:

| Demo | Run command (from `example/`) |
|---|---|
| `glass_menu_demo.dart` — all 9 menu alignments | `cd example && flutter run -t lib/demos/glass_menu_demo.dart` |
| `glass_tab_bar_scrollable_demo.dart` — scrollable tab bar | `cd example && flutter run -t lib/demos/glass_tab_bar_scrollable_demo.dart` |
| `glass_modal_sheet_demo.dart` — peek / half / full states | `cd example && flutter run -t lib/demos/glass_modal_sheet_demo.dart` |
| `glass_bottom_bar_demo.dart` — magic-lens masking | `cd example && flutter run -t lib/demos/glass_bottom_bar_demo.dart` |
| `bottom_bar_tab_width_demo.dart` — tabWidth showcase | `cd example && flutter run -t lib/demos/bottom_bar_tab_width_demo.dart` |
| `searchable_bar_demo.dart` — searchable bar edge cases | `cd example && flutter run -t lib/demos/searchable_bar_demo.dart` |
| `shape_debug_demo.dart` — GlassButton shapes | `cd example && flutter run -t lib/demos/shape_debug_demo.dart` |
| `quality_comparison_demo.dart` — premium & standard quality comparison playground | `cd example && flutter run -t lib/demos/quality_comparison_demo.dart` |
| `nav_bar_patterns_demo.dart` — GlassScaffold layout patterns | `cd example && flutter run -t lib/demos/nav_bar_patterns_demo.dart` |
| `content_aware_brightness_demo.dart` — light/dark bar adaptation on scroll | `cd example && flutter run -t lib/demos/content_aware_brightness_demo.dart` |
| `indicator_parity_demo.dart` — all four pill widgets side-by-side with live pinch/expansion/tint sliders | `cd example && flutter run -t lib/demos/indicator_parity_demo.dart` |


## Glass vs Content — Design Philosophy

In iOS 26, **glass is reserved for the navigation and control layer** — the
floating UI that sits above your app's content. Content areas (lists, cards,
article tiles) stay opaque.

| ✅ Use glass for | ❌ Keep opaque |
|---|---|
| Navigation bars, tab bars, toolbars | List cells, table rows |
| Floating action buttons | Full-screen backgrounds |
| Sheets, popovers, menus | Scrollable content cards |
| Toggles, sliders, segmented controls | Article tiles, media players |

**Typical screen composition:**

```
┌──────────────────────────┐
│   GlassAppBar (glass)    │  ← Navigation chrome
├──────────────────────────┤
│                          │
│   Opaque content area    │  ← Standard Flutter widgets
│   (ListView, Cards, etc) │
│                          │
├──────────────────────────┤
│  GlassBottomBar (glass)  │  ← Navigation chrome
└──────────────────────────┘
```

Building a Settings screen? Use `GlassScaffold` + `GlassAppBar` for navigation
chrome, and `CupertinoListTile` or standard Flutter containers for the rows.
Use `GlassGroupedSection` when you want glass-styled grouped rows.


## Widget Categories

### Containers
`GlassCard` · `GlassContainer`\* · `GlassDivider` · `GlassGroupedSection` · `GlassListTile` · `GlassStepper`

\* `GlassContainer` is a low-level building block for custom glass surfaces.
Most apps should use `GlassCard` or `GlassGroupedSection` instead.

### Interactive
`GlassButton` · `GlassIconButton` · `GlassChip` · `GlassSwitch` · `GlassSlider` · `GlassSegmentedControl` · `GlassPullDownButton` · `GlassButtonGroup` · `GlassBadge` · `GlassPageControl`

### Input
`GlassTextField` · `GlassTextArea` · `GlassPasswordField` · `GlassSearchBar` · `GlassPicker` · `GlassFormField`

### Feedback
`GlassProgressIndicator` · `GlassToast`

### Overlays
`GlassDialog` · `GlassSheet` · `GlassModalSheet` · `showGlassActionSheet` · `GlassMenu` · `GlassMenuItem` · `GlassMenuDivider` · `GlassMenuLabel` · `GlassPopover`

### Surfaces
`GlassScaffold` · `GlassAppBar` · `GlassBottomBar` · `GlassSearchableBottomBar` · `GlassTabBar` · `GlassToolbar` · `GlassContentAwareScope` · `GlassContentAwareContent` · `GlassContentAwareBrightness`


## Installation

```yaml
dependencies:
  liquid_glass_widgets: ^0.17.0
```

```bash
flutter pub get
```


## Quick Start

Two steps — that's the entire setup:

**Step 1.** Call `initialize()` in `main()` to pre-warm shaders.

**Step 2.** Wrap your app with `LiquidGlassWidgets.wrap()`:

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LiquidGlassWidgets.initialize();

  runApp(LiquidGlassWidgets.wrap(child: const MyApp()));
}
```

That's it. Then use `GlassScaffold` on each screen — it handles background, status bar, z-ordering, and edge fading automatically:

```dart
GlassScaffold(
  background: Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
  statusBarStyle: GlassStatusBarStyle.auto,
  appBar: GlassAppBar(title: const Text('My App')),
  body: Center(child: GlassCard(child: Text('Hello, Glass!'))),
)
```

> **Why `GlassScaffold`?** Glass effects refract and blur against whatever is behind them. Without a controlled background, glass surfaces can appear flat, incorrectly tinted, or invisible. `GlassScaffold` wires up the background source, glass rendering layer, and bar isolation automatically — one widget instead of five.

> **Accessibility is on by default.** The library automatically reads the
> device's Reduce Motion and Reduce Transparency settings — no extra setup
> required. See [Accessibility](#accessibility) for details.

### Optional: quality & theming

For production apps, pass `adaptiveQuality` and/or `theme` to `wrap()` at the same call site:

```dart
runApp(LiquidGlassWidgets.wrap(
  child: const MyApp(),
  adaptiveQuality: true,          // auto-benchmarks device, degrades gracefully
  theme: GlassThemeData.simple(   // optional app-wide glass defaults
    blur: 10,
    thickness: 30,
    quality: GlassQuality.standard,
  ),
));
```

Both parameters are optional — omit them and the library uses sensible defaults.



## Theming

Pass a `theme:` to `LiquidGlassWidgets.wrap()` to set your app-wide defaults — every glass widget inherits them automatically, no per-widget configuration needed:

```dart
runApp(LiquidGlassWidgets.wrap(
  child: const MyApp(),
  theme: GlassThemeData(
    light: GlassThemeVariant(
      settings: GlassThemeSettings(thickness: 30, blur: 6),
      quality: GlassQuality.standard,
    ),
    dark: GlassThemeVariant(
      settings: GlassThemeSettings(thickness: 40, blur: 8),
      quality: GlassQuality.standard,
    ),
  ),
));
```

For a quick single-quality theme, use the `GlassThemeData.simple` shorthand:

```dart
runApp(LiquidGlassWidgets.wrap(
  child: const MyApp(),
  theme: GlassThemeData.simple(
    blur: 10,
    thickness: 30,
    quality: GlassQuality.standard,
  ),
));
```

> **`GlassThemeSettings` vs `LiquidGlassSettings`:** Use `GlassThemeSettings` inside `GlassThemeVariant`. It accepts the same parameters but all are nullable — only fields you explicitly set are applied; everything else inherits from each widget's own defaults. `LiquidGlassSettings` is the full settings type used on individual widgets.

Three-level override hierarchy (highest wins):

1. **Widget `settings` parameter** — explicit, widget-level override
2. **`GlassPage(themeOverride: ...)`** — per-screen override for special pages (onboarding, paywalls)
3. **`GlassTheme` / `wrap(theme:...)`** — app-wide defaults

Access the current theme programmatically:

```dart
final variant = GlassThemeData.of(context).variantFor(context);
```

#### Per-subtree theming

For advanced use cases where you need different glass styles within a single screen, place a `GlassTheme` widget anywhere in your tree:

```dart
GlassTheme(
  data: GlassThemeData.simple(blur: 4, quality: GlassQuality.minimal),
  child: MyListSection(), // list cards get minimal quality
)
```

### Glow Colors

`GlassGlowColors` controls the interaction glow emitted by surfaces like `GlassBottomBar` and `GlassSearchableBottomBar`:

```dart
GlassThemeVariant(
  glowColors: GlassGlowColors(
    primary: Colors.blue,
    glowBlurRadius: 12,
    glowSpreadRadius: 0.2,
    glowOpacity: 0.8,
  ),
)
```


## Platform Support

| Platform | Renderer | Notes |
|---|---|---|
| iOS | Impeller (Metal) | Full shader pipeline, chromatic aberration |
| Android | Impeller (Vulkan) | Full shader pipeline, chromatic aberration |
| macOS | Impeller (Metal) | Full shader pipeline, chromatic aberration |
| Web | CanvasKit | Lightweight fragment shader |
| Windows | Skia | Lightweight fragment shader |
| Linux | Skia | Lightweight fragment shader |

Platform detection is automatic — no configuration required.


## Glass Quality Modes

### Standard — Default, Recommended

The right choice for 95% of use cases. Works on every platform with iOS 26-accurate glass effects.

```dart
GlassContainer(
  quality: GlassQuality.standard, // this is the default
  child: const Text('Great for scrollable content'),
)
```

### Premium — Impeller Only

Enables the full Impeller shader pipeline with texture capture and chromatic aberration. On Skia/Web, automatically falls back to Standard.

```dart
GlassCard(
  quality: GlassQuality.premium,
  child: const Text('Static hero section'),
)
```

> **Use Premium only for static, non-scrolling surfaces** (hero sections, feature cards). It may not render correctly inside `ListView` or `CustomScrollView` on Impeller. `GlassScaffold` automatically promotes app bars and bottom bars to premium quality via `GlassIsolationScope`.

### Minimal — Shader-Free

Zero custom fragment shader cost on any device. Uses `BackdropFilter` blur + a Rec. 709 saturation matrix + a specular rim stroke. Visually equivalent to a high-quality frosted panel.

```dart
GlassCard(
  quality: GlassQuality.minimal,
  child: const Text('No shader overhead'),
)
```

Two ideal use cases:
- **Device fallback** — very old Android devices or any device where `ImageFilter.isShaderFilterSupported` is `false`
- **GPU budget management** — use `minimal` for background panels and list cards while keeping `standard` or `premium` on the focal element. A screen with 15 glass list cards running `minimal` fires zero shader invocations during scroll

> **Theme shorthand**: `GlassThemeVariant.minimal` applies `minimal` quality globally via `GlassThemeData`.


## GlassScaffold

`GlassScaffold` is the recommended way to build any screen that uses glass surfaces. It replaces the manual assembly of `GlassPage` + `Scaffold` + `GlassScrollEdgeEffect` + `Stack` with a single widget:

```dart
GlassScaffold(
  background: Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
  statusBarStyle: GlassStatusBarStyle.light,
  appBar: GlassAppBar(
    title: const Text('Messages'),
    trailing: GlassButton(
      icon: const Icon(CupertinoIcons.compose),
      onTap: () {},
    ),
  ),
  bottomBar: GlassBottomBar(
    selectedIndex: 0,
    onTabSelected: (_) {},
    tabs: const [
      GlassBottomBarTab(icon: Icon(Icons.home), label: 'Home'),
      GlassBottomBarTab(icon: Icon(Icons.search), label: 'Search'),
    ],
  ),
  body: CustomScrollView(
    slivers: [...],
  ),
)
```

| What it handles | Without `GlassScaffold` |
|---|---|
| Background + glass layer | Must wrap in `GlassPage` + set `scaffoldBackgroundColor: transparent` |
| Z-ordering (bars above body) | Must build a manual `Stack` with correct paint order |
| Edge fading | Must add `GlassScrollEdgeEffect` and calculate fade heights |
| Safe-area padding | Must calculate top/bottom padding for app bar and bottom bar |
| Bar isolation | Must wrap bars in `GlassIsolationScope` manually |
| Status bar icons | Must call `SystemChrome.setSystemUIOverlayStyle` and restore it |

> See `example/lib/demos/nav_bar_patterns_demo.dart` for complete `GlassScaffold` usage patterns.

### Content-Aware Brightness

Glass bars automatically adapt their icon and label colors to match the content
scrolling behind them — light icons over dark content, dark icons over light
content — with a smooth cross-fade transition. One flag on `GlassScaffold`,
one on the bar:

```dart
GlassScaffold(
  contentAwareBrightness: true,
  bottomBar: GlassBottomBar(
    adaptiveBrightness: true,
    onBrightnessChanged: (b) => debugPrint('Bar is now: $b'),
    tabs: [...],
    selectedIndex: _index,
    onTabSelected: (i) => setState(() => _index = i),
  ),
  body: CustomScrollView(
    slivers: [...], // content scrolls underneath the bar
  ),
)
```

`GlassScaffold.contentAwareBrightness` handles all the wiring — it wraps the
body in `GlassContentAwareContent` and the layout in `GlassContentAwareScope`
automatically. The bar uses WCAG contrast ratios with dual-threshold hysteresis
to prevent flickering on borderline content.

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

> See `example/lib/demos/content_aware_brightness_demo.dart` for a focused showcase.

---

## GlassPage

`GlassPage` is the lower-level building block that `GlassScaffold` uses internally. Use it directly when you need full manual control over your layout — custom `Stack` ordering, non-standard bar placements, or screens without a traditional scaffold structure.

> **For most apps, `GlassScaffold` is simpler** — it handles background, bars, edge fading, and isolation automatically. Use `GlassPage` only when you need to build a custom layout that `GlassScaffold` doesn't support.

`GlassPage` eliminates several common setup mistakes in one widget:

```dart
// Minimum — just wrap your Scaffold, GlassPage handles everything else:
GlassPage(
  child: Scaffold(
    appBar: GlassAppBar(title: const Text('Home')),
    body: MyContent(),
  ),
)

// With a wallpaper:
GlassPage(
  background: Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
  edgeToEdge: true,
  statusBarStyle: GlassStatusBarStyle.auto,
  child: Scaffold(
    appBar: GlassAppBar(title: const Text('Home')),
    body: MyContent(),
  ),
)
```

| What it handles | Without `GlassPage` |
|---|---|
| Transparent `Scaffold` | Must set `scaffoldBackgroundColor: transparent` manually |
| Navigation ghosting | Handled automatically — each glass layer isolates its own backdrop |
| Background scope setup | Must wrap in `LiquidGlassScope` manually |
| Status bar icons | Must call `SystemChrome.setSystemUIOverlayStyle` and restore it |
| Edge-to-edge mode | Must call `SystemChrome.setEnabledSystemUIMode` and restore it |
| Per-screen theme | Must wrap subtree in a local `GlassTheme` manually |

### Parameters

| Parameter | Default | Purpose |
|---|---|---|
| `background` | `null` | Optional wallpaper/background widget. When omitted, `Scaffold` background is left unchanged |
| `child` | required | Screen content, typically a `Scaffold` |
| `enableBackgroundSampling` | `true` when `background` is set, `false` otherwise | GPU texture capture for real colour absorption. Set `false` explicitly to opt out |
| `statusBarStyle` | `GlassStatusBarStyle.none` | Status bar icon brightness; `auto` is recommended for wallpaper screens |
| `edgeToEdge` | `false` | Draw content behind system bars (full immersive) |
| `themeOverride` | `null` | Per-screen `GlassThemeData` override for special screens |
> 
> **Tip for `edgeToEdge` on Android:** When `true`, content draws underneath the Android navigation bar. Remember to wrap your `Scaffold` body in a `SafeArea` (or use `extendBody: true` and pad the bottom) so your content isn't hidden behind the system buttons.

### Specular Sharpness

Control the tightness of the specular highlight on any glass surface via `LiquidGlassSettings.specularSharpness`:

```dart
GlassCard(
  settings: LiquidGlassSettings(
    specularSharpness: GlassSpecularSharpness.sharp, // tight, mirror-like
  ),
  child: ...,
)
```

| Value | Look |
|---|---|
| `GlassSpecularSharpness.soft` | Wide, diffuse — frosted / matte glass |
| `GlassSpecularSharpness.medium` | **Default** — matches iOS 26 |
| `GlassSpecularSharpness.sharp` | Tight, polished — mirror-like surface |

Each value maps to a fixed power-of-2 exponent. The GPU uses a zero-transcendental multiply chain for each — no `pow()` overhead.


## Performance Tips

1. **`LiquidGlassWidgets.initialize()`** at startup — pre-caches shaders, eliminates the white flash on first render
2. **`LiquidGlassWidgets.wrap()`** in `main.dart` — installs accessibility bridging and global theming; pass `adaptiveQuality: true` for automatic per-device quality tuning
3. **Standard quality for scrollable content** — lists, forms, interactive widgets
4. **Premium quality for fixed surfaces** — app bars, bottom bars, and hero sections
5. **Minimal quality for shader-dense screens** — use `GlassQuality.minimal` for background panels and list cards to fire zero custom shader invocations during scroll, then keep `standard` or `premium` only on the focal element
6. **Accessibility fallbacks are zero-cost** — when Reduce Transparency is active, the glass shader is bypassed entirely; `BackdropFilter` blur runs in Flutter's own paint layer with no custom shader overhead

### Automatic Quality Adaptation *(experimental)*

> ### 📊 Help us tune the thresholds — takes 2 minutes
>
> `GlassAdaptiveScope` is `@experimental` because its Phase 2 timing thresholds
> are based on limited community data, not yet validated across the full Android
> device landscape. Current defaults (v0.12.0):
>
> | P75 warmup | Quality assigned |
> |---|---|
> | < 20 ms | `premium` *(based on 1 report — please share yours)* |
> | 20–28 ms | `standard` *(provisional — no real-device data yet)* |
> | > 28 ms | `minimal` |
>
> **If you use `adaptiveQuality: true`, please post your results to our
> [Threshold Calibration Discussion](https://github.com/sdegenaar/liquid_glass_widgets/discussions)
> with the snippet below.** Every report directly informs the threshold calibration
> and gets us closer to removing `@experimental`. Thank you 🙏
>
> ```dart
> // Add to your GlassAdaptiveScopeConfig while testing — remove before shipping:
> // Option A: zero-wiring (recommended for quick reports)
> GlassAdaptiveScopeConfig(
>   debugLogDiagnostics: true, // prints to console in debug builds only
> )
>
> // Option B: custom handler for analytics
> GlassAdaptiveScopeConfig(
>   onDiagnostic: (d) {
>     // d.reason, d.p75Ms, d.p95Ms, d.framesMeasured, d.phase are all set
>     debugPrint('📊 ${d.from.name} → ${d.to.name} | reason: ${d.reason.name} | P75: ${d.p75Ms?.toStringAsFixed(1)}ms');
>   },
> )
> ```

`GlassAdaptiveScope` (enabled via `wrap(adaptiveQuality: true)`) automatically
benchmarks the device at startup and adjusts quality in real time:

```dart
// Minimal — let the library decide the best quality for the device:
runApp(LiquidGlassWidgets.wrap(child: const MyApp(), adaptiveQuality: true));

// Per-screen — fine-grained control on specific routes:
GlassAdaptiveScope(
  initialQuality: GlassQuality.standard, // conservative start
  allowStepUp: true,
  // Android calibration — raise if your device is incorrectly demoted to standard.
  // Post your P75 + device model to the Threshold Calibration Discussion!
  // warmupPremiumThresholdMs: 24.0,  // default 20.0
  // warmupStandardThresholdMs: 32.0, // default 28.0
  child: Scaffold(...),
)
```

#### Eliminating repeat warmup jank (recommended for production)

On the first launch, `GlassAdaptiveScope` runs a ~3-second warm-up benchmark
to measure real raster performance. On a Pixel 4a, this benchmark observes slow
frames and steps down to `minimal`. Without persistence, this happens on every
cold start — the user sees 3 seconds of degraded quality every time they open
the app.

**Within a single app process**, the library caches the settled quality
automatically. If the scope is disposed and remounted (e.g. navigating away and
back to the root), Phase 2 is not re-run — no extra code required.

**Across cold starts**, use `onQualityChanged` + `initialQuality` with your
preferred storage mechanism:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load previously settled quality — avoids warmup jank on repeat launches.
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('glass_quality');
  final initial = saved != null
      ? GlassQuality.values.byName(saved) // Dart 2.15+ built-in
      : null; // null = run Phase 2 on first launch, then persist

  await LiquidGlassWidgets.initialize();

  runApp(LiquidGlassWidgets.wrap(
    child: const MyApp(),
    adaptiveQuality: true,
    adaptiveConfig: GlassAdaptiveScopeConfig(
      initialQuality: initial,       // restore immediately — no warmup window
      allowStepUp: true,             // allow recovery after thermal throttle
      onQualityChanged: (_, to) =>   // persist whenever quality settles
          prefs.setString('glass_quality', to.name),
    ),
  ));
}
```

On first launch: `initial` is null → Phase 2 runs → quality settles → persisted.  
On every subsequent launch: `initial` is non-null → Phase 2 skipped → no jank.

### GPU Budget Monitoring

`GlassPerformanceMonitor` watches raster frame durations while `GlassQuality.premium` surfaces are active. When frames exceed the GPU budget for 60 consecutive frames it emits a single `FlutterError` with actionable guidance — which widget to change, which quality tier to try, and why.

**Zero production overhead** — automatically disabled in release builds. Enabled by default in debug/profile via `LiquidGlassWidgets.initialize()`:

```dart
// Default — auto-enabled in debug/profile, zero-cost in release
await LiquidGlassWidgets.initialize();

// Opt out entirely
await LiquidGlassWidgets.initialize(enablePerformanceMonitor: false);

// Custom thresholds
GlassPerformanceMonitor.rasterBudget = const Duration(microseconds: 8333); // 120 fps
GlassPerformanceMonitor.sustainedFrameThreshold = 120;
```

## Custom Refraction for Interactive Indicators

On Skia and Web, interactive widgets like `GlassSegmentedControl` can display
true liquid glass refraction from a background image.

**Recommended: use `GlassPage(background:...)`** — it wires up the refraction source
automatically and is the cleanest integration path:

```dart
// GlassPage handles LiquidGlassScope + GlassBackgroundSource for you:
GlassPage(
  background: Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
  child: Scaffold(
    body: Center(
      child: GlassSegmentedControl(
        segments: const ['Option A', 'Option B', 'Option C'],
        selectedIndex: 0,
        onSegmentSelected: (i) {},
        quality: GlassQuality.standard,
      ),
    ),
  ),
)
```

**Manual alternative — `LiquidGlassScope`:**

For advanced scenarios (e.g. isolated sections within a screen, non-`GlassPage` setups),
use `LiquidGlassScope` directly:

```dart
// Shorthand — wallpaper behind your Scaffold:
LiquidGlassScope.stack(
  background: Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
  content: Scaffold(
    body: Center(child: GlassSegmentedControl(...)),
  ),
)

// Manual — granular control over which surface is sampled:
LiquidGlassScope(
  child: Stack(
    children: [
      Positioned.fill(
        child: GlassBackgroundSource(
          child: Image.asset('assets/wallpaper.jpg'),
        ),
      ),
      Center(child: GlassSegmentedControl(...)),
    ],
  ),
)
```

On Impeller, `GlassQuality.premium` uses the native scene graph — no
`LiquidGlassScope` needed.

> **Migration note (0.7.0):** `LiquidGlassBackground` was renamed to
> `GlassRefractionSource`. The old name still compiles (deprecated typedef)
> and will be removed in 1.0.0.

| When | Recommendation |
|---|---|
| Skia / Web (recommended) | `GlassPage(background:...)` — automatic wiring |
| Skia / Web (manual) | `LiquidGlassScope.stack` with `GlassQuality.standard` |
| iOS / macOS (Impeller) | `GlassQuality.premium` — native scene graph |
| Multiple isolated sections | Separate `LiquidGlassScope` per section |


## Gyroscope Lighting

`GlassMotionScope` drives the specular highlight angle from any `Stream<double>`, including a device gyroscope via [`sensors_plus`](https://pub.dev/packages/sensors_plus):

```dart
GlassMotionScope(
  stream: gyroscopeEvents.map((e) => e.y * 0.5),
  child: Scaffold(
    appBar: GlassAppBar(title: const Text('My App')),
    body: ...,
  ),
)
```

No new dependencies required — connect any stream source (scroll position, mouse, gyroscope).


## Accessibility

Every glass widget in this package respects the user's system accessibility preferences **automatically** — no setup required.

| System Setting | Effect on glass widgets |
|---|---|
| **Reduce Motion** (iOS/macOS/Android) | All spring/jelly animations snap instantly to their target |
| **Reduce Transparency / High Contrast** | Glass shader replaced with a plain frosted `BackdropFilter` panel — zero GPU shader cost |

### No setup needed

Just ship your app. If the user has Reduce Motion on, your widgets snap. If they have Reduce Transparency on, they get a solid frosted fallback. Nothing to configure.

### Optional: `GlassAccessibilityScope`

Place `GlassAccessibilityScope` in your tree to **override** system defaults — useful for testing, showcases, or per-subtree customisation:

```dart
// In your app (optional — place inside MaterialApp.builder for full coverage)
MaterialApp(
  builder: (context, child) => GlassAccessibilityScope(
    child: child!, // reads system flags automatically
  ),
)

// Force a specific state (e.g. demo frosted fallback in a settings screen)
GlassAccessibilityScope(
  reduceTransparency: true,
  child: GlassSettingsPreview(),
)
```

`GlassAccessibilityScope` always wins over the system flag — it's the highest-priority override.

### Opting out globally

For experiences where full glass fidelity is intentional (games, creative tools):

```dart
// 0.10.0+: child is a required named parameter
runApp(LiquidGlassWidgets.wrap(
  child: const MyApp(),
  respectSystemAccessibility: false,
));
```

This disables only the automatic system-flag bridge. An explicit `GlassAccessibilityScope` in the widget tree still works regardless.

### Priority order (highest wins)

1. `GlassAccessibilityScope` in the widget tree — explicit developer override
2. System `MediaQuery` flags — automatic, respects user's OS setting
3. `wrap(respectSystemAccessibility: false)` — disables (2) globally


## Architecture

### Rendering pipeline

On Impeller, every `GlassQuality.premium` surface uses a two-pass pipeline:

1. **Blur pass** — `BackdropFilterLayer(ImageFilter.blur)`, clipped to the exact widget shape. Each `LiquidGlassLayer` manages its own isolated `BackdropGroup` for GPU capture.
2. **Shader pass** — `BackdropFilterLayer(ImageFilter.shader)` — refraction, edge lighting, glass tint, and chromatic aberration.

On Skia/Web, `lightweight_glass.frag` runs as a single pass with no backdrop capture.

### Liquid Morph Engine

A standalone physics and animation system powering iOS 26-style teardrop morphing. It lives in `lib/engine/` and is fully decoupled from any specific widget — `GlassMenu` is its first consumer.

Key types: `GlassMorphController` · `LiquidMorphState` · `LiquidMorphPhysics` · `MorphPhase` · `MorphSpeed`

See [`docs/LIQUID_MORPH_ENGINE.md`](docs/LIQUID_MORPH_ENGINE.md) for a full integration guide.

### Content-Adaptive Glass Strength (0.7.0)

Both render paths automatically adapt glass strength to background brightness:

- **Dark backgrounds** → richer, more opaque glass (1.2× strength, brighter Fresnel rim)
- **Light backgrounds** → subtler, more translucent glass (0.8× strength)

On Impeller, backdrop luminance is sampled directly from the refracted texture (zero extra reads).
On Skia/Web, `MediaQuery.platformBrightnessOf` provides a lightweight proxy.


## Testing

```bash
# All tests
flutter test

# Exclude golden tests
flutter test --exclude-tags golden

# macOS golden tests (require Impeller)
flutter test --tags golden
```


## Dependencies

Minimal runtime dependencies beyond the Flutter SDK: `equatable`, `flutter_shaders`, and `logging`.

The glass rendering pipeline builds on the open-source work of [whynotmake-it](https://github.com/whynotmake-it). Their [`liquid_glass_renderer`](https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages/liquid_glass_renderer) (MIT) has been vendored and extended with bug fixes, performance improvements, and shader optimisations.


## Contributing

Contributions are welcome. For major changes, open an issue first to discuss your proposal.


## License

MIT — see the [LICENSE](LICENSE) file for details.


## Credits

**Special thanks** to the [whynotmake-it](https://github.com/whynotmake-it) team for their [`liquid_glass_renderer`](https://github.com/whynotmake-it/flutter_liquid_glass/tree/main/packages/liquid_glass_renderer) (MIT), whose shader pipeline, texture capture, and chromatic aberration work forms the foundation of the rendering engine in this library.

## Links

- [pub.dev](https://pub.dev/packages/liquid_glass_widgets)
- [Repository](https://github.com/sdegenaar/liquid_glass_widgets)
- [Issue Tracker](https://github.com/sdegenaar/liquid_glass_widgets/issues)
