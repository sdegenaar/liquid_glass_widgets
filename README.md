# Liquid Glass Widgets

Bring Apple's iOS 26 Liquid Glass to your Flutter app — 37 glass widgets with real shader-based blur, physics-driven jelly animations, and dynamic lighting. Works on every platform out of the box.

[![pub package](https://img.shields.io/pub/v/liquid_glass_widgets.svg?label=pub.dev&labelColor=333940&logo=dart)](https://pub.dev/packages/liquid_glass_widgets)
[![pub points](https://img.shields.io/pub/points/liquid_glass_widgets?label=pub%20points&labelColor=333940)](https://pub.dev/packages/liquid_glass_widgets/score)
[![likes](https://img.shields.io/pub/likes/liquid_glass_widgets?label=likes&labelColor=333940)](https://pub.dev/packages/liquid_glass_widgets/score)
[![CI](https://github.com/sdegenaar/liquid_glass_widgets/actions/workflows/ci.yml/badge.svg)](https://github.com/sdegenaar/liquid_glass_widgets/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/sdegenaar/liquid_glass_widgets/graph/badge.svg)](https://codecov.io/gh/sdegenaar/liquid_glass_widgets)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)


https://github.com/user-attachments/assets/2fe28f46-96ad-459d-b816-e6d6001d90de

*[Wanderlust](example/showcase/) — a luxury travel showcase built entirely with `liquid_glass_widgets`*


## Features

- **36 glass widgets** — containers, interactive controls, inputs, feedback, overlays, and navigation surfaces
- **Real frosted glass** — native two-pass Gaussian blur + shader refraction on Impeller; lightweight shader on Skia/Web
- **Just works everywhere** — iOS, Android, macOS, Web, Windows, Linux; rendering path chosen automatically
- **Adaptive quality** *(experimental)* — `GlassAdaptiveScope` benchmarks the device at startup and adjusts quality in real time: `minimal` on slow hardware, `standard` on mid-range, `premium` on fast devices. Degrades on thermal throttle, recovers when cool
- **Zero dependencies** — no third-party runtime libraries, just the Flutter SDK
- **One-line setup** — `LiquidGlassWidgets.wrap(myApp)` handles shader prewarming, accessibility bridging, and root backdrop sharing; add `GlassBackdropScope` per screen to prevent ghost artifacts on navigation (see [Backdrop Isolation](#backdrop-isolation--preventing-ghost-artifacts))
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


### [Apple News Demo](example/lib/apple_news/) — iOS 26 Replica

A recreation of the Apple News app demonstrating `GlassSearchableBottomBar` with its morphing search pill, category chips, hero cards, and rounded article tiles.

```bash
cd example && flutter pub get && flutter run -t lib/apple_news/apple_news_demo.dart
```

<img width="390" height="844" alt="Apple News Demo" src="https://raw.githubusercontent.com/sdegenaar/liquid_glass_widgets/main/docs/assets/apple_news_demo.jpg" />

### [Widget Showcase](example/) — Full Component Library

A complete catalogue of all 36 widgets organized by category. Use it to explore every component, try live settings, and copy patterns directly into your app.

```bash
cd example && flutter pub get && flutter run
```

<img width="1280" height="589" alt="Widget Showcase" src="https://github.com/user-attachments/assets/b65551cf-7ee8-4494-9c0a-f3c870b5eb70" />


## Widget Categories

### Containers
`GlassCard` · `GlassPanel` · `GlassContainer` · `GlassDivider` · `GlassListTile` · `GlassStepper` · `GlassWizard`

### Interactive
`GlassButton` · `GlassIconButton` · `GlassChip` · `GlassSwitch` · `GlassSlider` · `GlassSegmentedControl` · `GlassPullDownButton` · `GlassButtonGroup` · `GlassBadge`

### Input
`GlassTextField` · `GlassTextArea` · `GlassPasswordField` · `GlassSearchBar` · `GlassPicker` · `GlassFormField`

### Feedback
`GlassProgressIndicator` · `GlassToast` · `GlassSnackBar`

### Overlays
`GlassDialog` · `GlassSheet` · `GlassModalSheet` · `showGlassActionSheet` · `GlassMenu` · `GlassMenuItem`

### Surfaces
`GlassAppBar` · `GlassBottomBar` · `GlassSearchableBottomBar` · `GlassTabBar` · `GlassSideBar` · `GlassToolbar`


## Installation

```yaml
dependencies:
  liquid_glass_widgets: ^0.9.6
```

```bash
flutter pub get
```


## Quick Start

Set up the library once in `main.dart`. `initialize()` pre-caches shaders and
registers the debug performance monitor. `wrap()` installs the root backdrop
scope and accessibility bridge:

```dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Async platform setup: shader prewarming + Impeller pipeline.
  await LiquidGlassWidgets.initialize();

  // Widget-tree composition: installs GlassBackdropScope (required).
  // Enable adaptiveQuality to automatically tune glass quality per device.
  runApp(LiquidGlassWidgets.wrap(
    const MyApp(),
    adaptiveQuality: true,
  ));
}
```

> **Accessibility is on by default.** The library automatically reads the
> device's Reduce Motion and Reduce Transparency settings — no extra setup
> required. See [Accessibility](#accessibility) for details.

Then add any glass widget to your tree:

```dart
Scaffold(
  appBar: GlassAppBar(title: const Text('My App')),
  bottomNavigationBar: GlassBottomBar(
    tabs: [
      GlassBottomBarTab(label: 'Home', icon: const Icon(Icons.home)),
      GlassBottomBarTab(label: 'Profile', icon: const Icon(Icons.person)),
    ],
    selectedIndex: 0,
    onTabSelected: (i) {},
  ),
  body: const Center(child: GlassCard(child: Text('Hello, Glass!'))),
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
GlassAppBar(
  quality: GlassQuality.premium,
  title: const Text('Static header'),
)
```

> **Use Premium only for static, non-scrolling surfaces** (app bars, bottom bars, hero sections). It may not render correctly inside `ListView` or `CustomScrollView` on Impeller.

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


## Theming

All widgets automatically inherit from `GlassTheme` and adapt to light/dark mode:

```dart
GlassTheme(
  data: GlassThemeData(
    light: GlassThemeVariant(
      settings: GlassThemeSettings(thickness: 30, blur: 12),
      quality: GlassQuality.standard,
    ),
    dark: GlassThemeVariant(
      settings: GlassThemeSettings(thickness: 50, blur: 18),
      quality: GlassQuality.premium,
    ),
  ),
  child: MaterialApp(home: MyHomePage()),
)
```

> **`GlassThemeSettings` vs `LiquidGlassSettings`:** Use `GlassThemeSettings` inside `GlassThemeVariant`. It accepts the same parameters but all are nullable — only the fields you explicitly set are applied; everything else inherits from each widget's own defaults. `LiquidGlassSettings` is the full settings type used on individual widgets.

Access the current theme variant programmatically:

```dart
final variant = GlassThemeData.of(context).variantFor(context);
```

### Glow Colors

`GlassGlowColors` controls the interaction glow emitted by surfaces like `GlassBottomBar` and `GlassSearchableBottomBar`. Set it once in your theme and every navigation surface picks it up automatically:

```dart
GlassThemeVariant(
  glowColors: GlassGlowColors(
    primary: Colors.blue,   // tab indicator & search pill glow
    blurRadius: 12,         // glow softness (default: 0 = crisp edge)
    spreadRadius: 0.2,      // glow spread beyond the widget edge (default: 0)
    opacity: 0.8,           // overall glow intensity (default: 1.0)
  ),
)
```

Individual widgets can still override via their `interactionGlowColor` parameter — the explicit param always wins over the theme.

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
2. **`LiquidGlassWidgets.wrap()`** in `main.dart` — installs root backdrop sharing and accessibility; pass `adaptiveQuality: true` for automatic per-device quality tuning. For multi-screen apps, also add `GlassBackdropScope` to each route — see [Backdrop Isolation](#backdrop-isolation--preventing-ghost-artifacts)
3. **Standard quality for scrollable content** — lists, forms, interactive widgets
4. **Premium quality for fixed surfaces** — app bars, bottom bars, and hero sections
5. **Minimal quality for shader-dense screens** — use `GlassQuality.minimal` for background panels and list cards to fire zero custom shader invocations during scroll, then keep `standard` or `premium` only on the focal element
6. **Accessibility fallbacks are zero-cost** — when Reduce Transparency is active, the glass shader is bypassed entirely; `BackdropFilter` blur runs in Flutter's own paint layer with no custom shader overhead

### Automatic Quality Adaptation *(experimental)*

> ### 📊 Help us tune the thresholds — takes 2 minutes
>
> `GlassAdaptiveScope` is `@experimental` because its Phase 2 timing thresholds
> (P75 < 12 ms → `premium`, 12–20 ms → `standard`, > 20 ms → `minimal`) are based
> on reasoning, not yet validated across the full Android device landscape.
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
runApp(LiquidGlassWidgets.wrap(const MyApp(), adaptiveQuality: true));

// Per-screen — fine-grained control on specific routes:
GlassAdaptiveScope(
  initialQuality: GlassQuality.standard, // conservative start
  allowStepUp: true,
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
    const MyApp(),
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




## Backdrop Isolation — Preventing Ghost Artifacts

`LiquidGlassWidgets.wrap()` installs one root `BackdropGroup` that all glass
surfaces share for GPU backdrop captures. When navigating between screens, the
previous screen's backdrop texture stays bound for 1–2 frames — causing the old
page's content to briefly bleed through glass on the new screen.

**Fix: wrap each screen in `GlassBackdropScope`.**

```dart
class MyNewPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassBackdropScope(        // ← forces a fresh capture on mount
      child: Scaffold(
        appBar: GlassAppBar(title: const Text('New Page')),
        body: ...,
        bottomNavigationBar: GlassBottomBar(...),
      ),
    );
  }
}
```

`GlassBackdropScope` creates a child `BackdropGroup` scoped to that screen. The
moment it mounts, it captures a fresh GPU backdrop — no memory of the previous
page's content.

> **Rule of thumb:** place a `GlassBackdropScope` at the top of every route or
> screen that hosts glass surfaces. Think of it like a `RepaintBoundary` for
> backdrop textures.

**Why `adaptiveQuality` tabs don't ghost:**  
When switching tabs *within the same screen*, all glass surfaces share the same
`GlassBackdropScope` which is refreshed correctly during animation.
The ghost appears only when crossing a `Navigator` route boundary or an
`AnimatedSwitcher` that replaces the whole screen widget.

## Custom Refraction for Interactive Indicators


On Skia and Web, interactive widgets like `GlassSegmentedControl` can display
true liquid glass refraction. Use `GlassRefractionSource` to mark the capture
surface (or use the `LiquidGlassScope.stack()` shorthand for the common
wallpaper-behind-content pattern):

```dart
// Shorthand — wallpaper behind your Scaffold:
LiquidGlassScope.stack(
  background: Image.asset('assets/wallpaper.jpg', fit: BoxFit.cover),
  content: Scaffold(
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

// Manual — granular control over which surface is sampled:
LiquidGlassScope(
  child: Stack(
    children: [
      Positioned.fill(
        child: GlassRefractionSource(
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
| Skia / Web | `LiquidGlassScope.stack` with `GlassQuality.standard` |
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
// 0.8.0+: pass via wrap(), not initialize()
runApp(LiquidGlassWidgets.wrap(
  const MyApp(),
  respectSystemAccessibility: false,
));
```

This disables only the automatic system-flag bridge. An explicit `GlassAccessibilityScope` in the widget tree still works regardless.

### Priority order (highest wins)

1. `GlassAccessibilityScope` in the widget tree — explicit developer override
2. System `MediaQuery` flags — automatic, respects user's OS setting
3. `wrap(respectSystemAccessibility: false)` — disables (2) globally


## Architecture

On Impeller, every `GlassQuality.premium` surface uses a two-pass pipeline:

1. **Blur pass** — `BackdropFilterLayer(ImageFilter.blur)`, clipped to the exact widget shape. Shared across all surfaces inside a `GlassBackdropScope` (injected automatically by `LiquidGlassWidgets.wrap()`).
2. **Shader pass** — `BackdropFilterLayer(ImageFilter.shader)` — refraction, edge lighting, glass tint, and chromatic aberration.

On Skia/Web, `lightweight_glass.frag` runs as a single pass with no backdrop capture.

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

Zero third-party runtime dependencies beyond the Flutter SDK.

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
